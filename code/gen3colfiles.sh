#!/usr/bin/env bash

# Convert canonical BIDS events into the FSL 3-column EV layout used by FEAT.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# shellcheck source=project_config.sh
source "${SCRIPT_DIR}/project_config.sh"

usage() {
    cat <<'EOF'
Usage: gen3colfiles.sh [--sublist FILE | --subject ID] [options]

Options:
  --sublist FILE        One participant ID per line (default: code/sublist_full-dataset.txt)
  --subject ID          Convert one participant; accepts 10317 or sub-10317
  --session ID          BIDS session (default: 01)
  --task NAME           doors, socialdoors, or all (default: all)
  --run ID              Run number (default: 1)
  --dry-run             Print the plan without writing files
  --overwrite           Replace existing EV files for the selected runs
  -h, --help            Show this help

Paths can be redirected with BIDS_ROOT and FSL_DERIVATIVES_ROOT.
EOF
}

sublist="${SCRIPT_DIR}/sublist_full-dataset.txt"
subject=""
session="01"
task_selection="all"
run="1"
dry_run=0
overwrite=0

while (( $# )); do
    case "$1" in
        --sublist) sublist="$2"; shift 2 ;;
        --subject) subject="$2"; shift 2 ;;
        --session) session="$2"; shift 2 ;;
        --task) task_selection="$2"; shift 2 ;;
        --run) run="$2"; shift 2 ;;
        --dry-run) dry_run=1; shift ;;
        --overwrite) overwrite=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "ERROR: unknown argument: $1" >&2; usage >&2; exit 2 ;;
    esac
done

session="$(normalize_session "$session")"
case "$task_selection" in
    all) tasks=(doors socialdoors) ;;
    doors|socialdoors) tasks=("$task_selection") ;;
    *) echo "ERROR: --task must be doors, socialdoors, or all." >&2; exit 2 ;;
esac

if [[ -n "$subject" ]]; then
    subjects=("$(normalize_subject "$subject")")
else
    [[ -f "$sublist" ]] || { echo "ERROR: subject list not found: $sublist" >&2; exit 1; }
    subjects=()
    while IFS= read -r value || [[ -n "$value" ]]; do
        value="${value%%#*}"
        value="${value//[[:space:]]/}"
        [[ -n "$value" ]] && subjects+=("$(normalize_subject "$value")")
    done < "$sublist"
fi

(( ${#subjects[@]} > 0 )) || { echo "ERROR: no participants selected." >&2; exit 1; }

validate_events() {
    local events="$1"
    awk -F '\t' '
        function numeric(x) { return x ~ /^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$/ }
        NR == 1 {
            sub(/\r$/, "")
            for (i = 1; i <= NF; i++) {
                if ($i == "onset") onset = i
                if ($i == "duration") duration = i
                if ($i == "trial_type") trial_type = i
            }
            if (!onset || !duration || !trial_type) {
                print "ERROR: required columns are onset, duration, and trial_type: " FILENAME > "/dev/stderr"
                exit 2
            }
            next
        }
        {
            sub(/\r$/, "")
            if (!numeric($onset)) {
                print "ERROR: nonnumeric onset on row " NR ": " FILENAME > "/dev/stderr"
                exit 2
            }
            if (!numeric($duration)) {
                print "ERROR: nonnumeric duration on row " NR ": " FILENAME > "/dev/stderr"
                exit 2
            }
            if (($duration + 0) < 0) {
                print "ERROR: negative duration on row " NR ": " FILENAME > "/dev/stderr"
                exit 2
            }
            seen[$trial_type] = 1
        }
        END {
            if (NR < 2) {
                print "ERROR: no event rows: " FILENAME > "/dev/stderr"
                exit 2
            }
            for (i = 1; i <= 3; i++) {
                required = (i == 1 ? "decision" : (i == 2 ? "win" : "loss"))
                if (!seen[required]) {
                    print "ERROR: required trial_type missing (" required "): " FILENAME > "/dev/stderr"
                    exit 2
                }
            }
        }
    ' "$events"
}

printf 'EV conversion plan: %d participant(s), session %s, run %s, task(s): %s\n' \
    "${#subjects[@]}" "$session" "$run" "${tasks[*]}"

failures=0
for sub in "${subjects[@]}"; do
    for task in "${tasks[@]}"; do
        stem="sub-${sub}_ses-${session}_task-${task}_run-${run}"
        events="${BIDS_ROOT}/sub-${sub}/ses-${session}/func/${stem}_events.tsv"
        outdir="${FSL_DERIVATIVES_ROOT}/EVfiles/sub-${sub}/ses-${session}/${task}"
        outbase="${outdir}/run-${run}"
        printf '  %s -> %s_[trial_type].txt\n' "$events" "$outbase"

        if (( dry_run )); then
            continue
        fi
        if [[ ! -f "$events" ]]; then
            echo "ERROR: canonical events file not found: $events" >&2
            failures=$((failures + 1))
            continue
        fi
        if compgen -G "${outbase}_*.txt" >/dev/null && (( ! overwrite )); then
            echo "ERROR: EV files already exist for ${stem}; use --overwrite to replace them." >&2
            failures=$((failures + 1))
            continue
        fi
        if ! validate_events "$events"; then
            failures=$((failures + 1))
            continue
        fi

        temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/socdoors-ev.XXXXXX")"
        if ! bash "${SCRIPT_DIR}/BIDSto3col.sh" "$events" "${temp_dir}/run-${run}"; then
            echo "ERROR: 3-column conversion failed for $events" >&2
            rm -rf -- "$temp_dir"
            failures=$((failures + 1))
            continue
        fi
        missing_required=0
        for event in decision win loss; do
            if [[ ! -s "${temp_dir}/run-${run}_${event}.txt" ]]; then
                echo "ERROR: converter did not produce required EV ${event}: $events" >&2
                missing_required=1
            fi
        done
        if (( missing_required )); then
            rm -rf -- "$temp_dir"
            failures=$((failures + 1))
            continue
        fi

        mkdir -p "$outdir"
        rm -f -- "${outbase}_decision.txt" "${outbase}_decision-missed.txt" \
            "${outbase}_win.txt" "${outbase}_loss.txt"
        for event in decision decision-missed win loss; do
            if [[ -f "${temp_dir}/run-${run}_${event}.txt" ]]; then
                cp "${temp_dir}/run-${run}_${event}.txt" "${outbase}_${event}.txt"
            fi
        done
        rm -rf -- "$temp_dir"
    done
done

if (( failures )); then
    echo "ERROR: EV conversion failed for ${failures} run(s)." >&2
    exit 1
fi
