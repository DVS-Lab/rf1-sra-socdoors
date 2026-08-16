#!/usr/bin/env bash

# Batch wrapper for L1stats.sh with deterministic shell job control.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

usage() {
    cat <<'EOF'
Usage: run_L1stats.sh [options]

Options:
  --manifest FILE   TSV columns: subject, session, task, run
  --sublist FILE    Participant list (default: code/sublist_full-dataset.txt)
  --subject ID      Run one participant instead of a list
  --session ID      BIDS session (default: 01)
  --tasks LIST      Comma-separated tasks (default: doors,socialdoors)
  --run ID          Run number (default: 1)
  --ppi VALUE       0/act, seed name, dmn, or ecn (default: 0)
  --jobs N          Maximum concurrent jobs (default: 20)
  --dry-run         Validate inputs and print each L1 plan
  --render-only     Render .fsf files without running FEAT
  --overwrite       Replace existing generated FEAT outputs
  --log-dir DIR     Write one log per L1 unit
EOF
}

sublist="${SCRIPT_DIR}/sublist_full-dataset.txt"
manifest=""
subject=""
session="01"
task_csv="doors,socialdoors"
run="1"
ppi="0"
jobs=20
mode="run"
overwrite=0
log_dir=""
while (( $# )); do
    case "$1" in
        --manifest) manifest="$2"; shift 2 ;;
        --sublist) sublist="$2"; shift 2 ;;
        --subject) subject="$2"; shift 2 ;;
        --session) session="$2"; shift 2 ;;
        --tasks) task_csv="$2"; shift 2 ;;
        --run) run="$2"; shift 2 ;;
        --ppi) ppi="$2"; shift 2 ;;
        --jobs) jobs="$2"; shift 2 ;;
        --dry-run) mode="dry-run"; shift ;;
        --render-only) mode="render-only"; shift ;;
        --overwrite) overwrite=1; shift ;;
        --log-dir) log_dir="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "ERROR: unknown argument: $1" >&2; exit 2 ;;
    esac
done
[[ "$jobs" =~ ^[1-9][0-9]*$ ]] || { echo "ERROR: --jobs must be a positive integer." >&2; exit 2; }

unit_subs=()
unit_sessions=()
unit_tasks=()
unit_runs=()

if [[ -n "$manifest" ]]; then
    [[ -z "$subject" ]] || { echo "ERROR: --manifest cannot be combined with --subject." >&2; exit 2; }
    [[ -f "$manifest" ]] || { echo "ERROR: manifest not found: $manifest" >&2; exit 1; }
    while IFS=$'\t' read -r unit_sub unit_session unit_task unit_run extra || [[ -n "${unit_sub:-}" ]]; do
        unit_sub="${unit_sub%$'\r'}"; unit_session="${unit_session%$'\r'}"
        unit_task="${unit_task%$'\r'}"; unit_run="${unit_run%$'\r'}"
        [[ "$unit_sub" == "subject" ]] && continue
        [[ -z "$unit_sub" ]] && continue
        [[ -z "${extra:-}" ]] || { echo "ERROR: malformed manifest row for sub-${unit_sub}; expected four columns." >&2; exit 1; }
        case "$unit_task" in doors|socialdoors) ;; *) echo "ERROR: unsupported task in manifest: $unit_task" >&2; exit 1 ;; esac
        unit_subs+=("${unit_sub#sub-}")
        unit_sessions+=("${unit_session#ses-}")
        unit_tasks+=("$unit_task")
        unit_runs+=("$unit_run")
    done < "$manifest"
else
    if [[ -n "$subject" ]]; then
        subjects=("${subject#sub-}")
    else
        [[ -f "$sublist" ]] || { echo "ERROR: subject list not found: $sublist" >&2; exit 1; }
        subjects=()
        while IFS= read -r value || [[ -n "$value" ]]; do
            value="${value%%#*}"
            value="${value//[[:space:]]/}"
            [[ -n "$value" ]] && subjects+=("${value#sub-}")
        done < "$sublist"
    fi
    IFS=',' read -r -a tasks <<< "$task_csv"
    for task in "${tasks[@]}"; do
        case "$task" in doors|socialdoors) ;; *) echo "ERROR: unsupported task: $task" >&2; exit 2 ;; esac
    done
    for unit_sub in "${subjects[@]}"; do
        for unit_task in "${tasks[@]}"; do
            unit_subs+=("$unit_sub")
            unit_sessions+=("${session#ses-}")
            unit_tasks+=("$unit_task")
            unit_runs+=("$run")
        done
    done
fi

(( ${#unit_subs[@]} > 0 )) || { echo "ERROR: no L1 work units selected." >&2; exit 1; }
units=()
for index in "${!unit_subs[@]}"; do
    units+=("${unit_subs[$index]}|${unit_sessions[$index]}|${unit_tasks[$index]}|${unit_runs[$index]}")
done
duplicates="$(printf '%s\n' "${units[@]}" | sort | uniq -d)"
[[ -z "$duplicates" ]] || { echo "ERROR: duplicate L1 work units:" >&2; echo "$duplicates" >&2; exit 1; }

total="${#units[@]}"
printf 'L1 batch plan: %d unit(s), %d job(s), PPI=%s' "$total" "$jobs" "$ppi"
[[ -n "$manifest" ]] && printf ', manifest %s' "$manifest"
printf '\n'
if [[ -n "$log_dir" && "$mode" != "dry-run" ]]; then
    mkdir -p "$log_dir"
    printf 'Per-unit logs: %s\n' "$log_dir"
fi

pids=()
labels=()
logfiles=()
failures=0
wait_oldest() {
    local pid="${pids[0]}" label="${labels[0]}" logfile="${logfiles[0]}"
    if ! wait "$pid"; then
        echo "ERROR: failed L1 unit: $label${logfile:+ (log: $logfile)}" >&2
        failures=$((failures + 1))
    else
        echo "DONE: $label"
    fi
    pids=("${pids[@]:1}")
    labels=("${labels[@]:1}")
    logfiles=("${logfiles[@]:1}")
}

for unit in "${units[@]}"; do
    IFS='|' read -r sub unit_session task unit_run <<< "$unit"
    label="sub-${sub} ses-${unit_session} task-${task} run-${unit_run}"
    cmd=(bash "${SCRIPT_DIR}/L1stats.sh" "$sub" "$unit_run" "$ppi" "$task" --session "$unit_session")
    [[ "$mode" == "dry-run" ]] && cmd+=(--dry-run)
    [[ "$mode" == "render-only" ]] && cmd+=(--render-only)
    (( overwrite )) && cmd+=(--overwrite)
    if [[ "$mode" == "dry-run" ]]; then
        "${cmd[@]}" || failures=$((failures + 1))
    else
        logfile=""
        if [[ -n "$log_dir" ]]; then
            logfile="${log_dir}/sub-${sub}_ses-${unit_session}_task-${task}_run-${unit_run}.log"
            echo "START: $label (log: $logfile)"
            "${cmd[@]}" > "$logfile" 2>&1 &
        else
            echo "START: $label"
            "${cmd[@]}" &
        fi
        pids+=("$!")
        labels+=("$label")
        logfiles+=("$logfile")
        (( ${#pids[@]} >= jobs )) && wait_oldest
    fi
done
while (( ${#pids[@]} )); do wait_oldest; done
(( failures == 0 )) || exit 1
