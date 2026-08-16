#!/usr/bin/env bash

# Batch wrapper for L1stats.sh with deterministic shell job control.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

usage() {
    cat <<'EOF'
Usage: run_L1stats.sh [options]

Options:
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
EOF
}

sublist="${SCRIPT_DIR}/sublist_full-dataset.txt"
subject=""
session="01"
task_csv="doors,socialdoors"
run="1"
ppi="0"
jobs=20
mode="run"
overwrite=0
while (( $# )); do
    case "$1" in
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
        -h|--help) usage; exit 0 ;;
        *) echo "ERROR: unknown argument: $1" >&2; exit 2 ;;
    esac
done
[[ "$jobs" =~ ^[1-9][0-9]*$ ]] || { echo "ERROR: --jobs must be a positive integer." >&2; exit 2; }

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

total=$(( ${#subjects[@]} * ${#tasks[@]} ))
printf 'L1 batch plan: %d unit(s), %d job(s), session %s, run %s, PPI=%s\n' \
    "$total" "$jobs" "${session#ses-}" "$run" "$ppi"

pids=()
labels=()
failures=0
wait_oldest() {
    local pid="${pids[0]}" label="${labels[0]}"
    if ! wait "$pid"; then
        echo "ERROR: failed L1 unit: $label" >&2
        failures=$((failures + 1))
    fi
    pids=("${pids[@]:1}")
    labels=("${labels[@]:1}")
}

for sub in "${subjects[@]}"; do
    for task in "${tasks[@]}"; do
        cmd=(bash "${SCRIPT_DIR}/L1stats.sh" "$sub" "$run" "$ppi" "$task" --session "$session")
        [[ "$mode" == "dry-run" ]] && cmd+=(--dry-run)
        [[ "$mode" == "render-only" ]] && cmd+=(--render-only)
        (( overwrite )) && cmd+=(--overwrite)
        if [[ "$mode" == "dry-run" ]]; then
            "${cmd[@]}" || failures=$((failures + 1))
        else
            "${cmd[@]}" &
            pids+=("$!")
            labels+=("sub-${sub} task-${task}")
            (( ${#pids[@]} >= jobs )) && wait_oldest
        fi
    done
done
while (( ${#pids[@]} )); do wait_oldest; done
(( failures == 0 )) || exit 1
