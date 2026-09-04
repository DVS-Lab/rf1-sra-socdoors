#!/usr/bin/env bash

# Batch wrapper for L2stats.sh.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

usage() {
    cat <<'EOF'
Usage: run_L2stats.sh [options]

Options:
  --manifest FILE   TSV columns: subject, session
  --sublist FILE    Participant list (default: code/sublist_all.txt)
  --subject ID      Run one participant instead of a list
  --session ID      BIDS session (default: 01)
  --types LIST      Comma-separated L2 types (default: act,ppi_seed-VS,nppi-dmn)
  --jobs N          Maximum concurrent jobs (default: 20)
  --dry-run         Validate inputs and print each L2 plan
  --render-only     Render .fsf files without running FEAT
  --overwrite       Replace existing generated GFEAT outputs
  --log-dir DIR     Write one log per L2 unit
EOF
}

sublist="${SCRIPT_DIR}/sublist_all.txt"
manifest=""
subject=""
session="01"
type_csv="act,ppi_seed-VS,nppi-dmn"
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
        --types) type_csv="$2"; shift 2 ;;
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
if [[ -n "$manifest" ]]; then
    [[ -z "$subject" ]] || { echo "ERROR: --manifest cannot be combined with --subject." >&2; exit 2; }
    [[ -f "$manifest" ]] || { echo "ERROR: manifest not found: $manifest" >&2; exit 1; }
    while IFS=$'\t' read -r unit_sub unit_session extra || [[ -n "${unit_sub:-}" ]]; do
        unit_sub="${unit_sub%$'\r'}"; unit_session="${unit_session%$'\r'}"
        [[ "$unit_sub" == "subject" ]] && continue
        [[ -z "$unit_sub" ]] && continue
        [[ -n "$unit_session" && -z "${extra:-}" ]] || {
            echo "ERROR: malformed L2 manifest row for sub-${unit_sub}; expected two columns." >&2
            exit 1
        }
        unit_subs+=("${unit_sub#sub-}")
        unit_sessions+=("${unit_session#ses-}")
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
    for unit_sub in "${subjects[@]}"; do
        unit_subs+=("$unit_sub")
        unit_sessions+=("${session#ses-}")
    done
fi
IFS=',' read -r -a types <<< "$type_csv"
(( ${#types[@]} > 0 )) || { echo "ERROR: --types must select at least one type." >&2; exit 2; }
for type in "${types[@]}"; do
    case "$type" in
        act|ppi_seed-*|nppi-dmn|nppi-ecn) ;;
        *) echo "ERROR: unsupported L2 type: $type" >&2; exit 2 ;;
    esac
done
duplicate_types="$(printf '%s\n' "${types[@]}" | sort | uniq -d)"
[[ -z "$duplicate_types" ]] || { echo "ERROR: duplicate L2 types:" >&2; echo "$duplicate_types" >&2; exit 2; }

(( ${#unit_subs[@]} > 0 )) || { echo "ERROR: no L2 subject-sessions selected." >&2; exit 1; }
subject_session_units=()
for index in "${!unit_subs[@]}"; do
    subject_session_units+=("${unit_subs[$index]}|${unit_sessions[$index]}")
done
duplicates="$(printf '%s\n' "${subject_session_units[@]}" | sort | uniq -d)"
[[ -z "$duplicates" ]] || { echo "ERROR: duplicate L2 subject-sessions:" >&2; echo "$duplicates" >&2; exit 1; }

units=()
for unit in "${subject_session_units[@]}"; do
    for type in "${types[@]}"; do
        units+=("${unit}|${type}")
    done
done
total="${#units[@]}"
printf 'L2 batch plan: %d unit(s), %d job(s), type(s): %s' \
    "$total" "$jobs" "${types[*]}"
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
        echo "ERROR: failed L2 unit: $label${logfile:+ (log: $logfile)}" >&2
        failures=$((failures + 1))
    else
        echo "DONE: $label"
    fi
    pids=("${pids[@]:1}")
    labels=("${labels[@]:1}")
    logfiles=("${logfiles[@]:1}")
}

for unit in "${units[@]}"; do
    IFS='|' read -r sub unit_session type <<< "$unit"
    label="sub-${sub} ses-${unit_session} type-${type}"
    cmd=(bash "${SCRIPT_DIR}/L2stats.sh" "$sub" "$type" --session "$unit_session")
    [[ "$mode" == "dry-run" ]] && cmd+=(--dry-run)
    [[ "$mode" == "render-only" ]] && cmd+=(--render-only)
    (( overwrite )) && cmd+=(--overwrite)
    if [[ "$mode" == "dry-run" ]]; then
        "${cmd[@]}" || failures=$((failures + 1))
    else
        logfile=""
        if [[ -n "$log_dir" ]]; then
            logfile="${log_dir}/sub-${sub}_ses-${unit_session}_type-${type}.log"
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
