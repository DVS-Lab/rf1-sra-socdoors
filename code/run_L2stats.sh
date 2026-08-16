#!/usr/bin/env bash

# Batch wrapper for L2stats.sh.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

usage() {
    cat <<'EOF'
Usage: run_L2stats.sh [options]

Options:
  --sublist FILE    Participant list (default: code/sublist_all.txt)
  --subject ID      Run one participant instead of a list
  --session ID      BIDS session (default: 01)
  --types LIST      Comma-separated L2 types (default: act,ppi_seed-VS,nppi-dmn)
  --jobs N          Maximum concurrent jobs (default: 20)
  --dry-run         Validate inputs and print each L2 plan
  --render-only     Render .fsf files without running FEAT
  --overwrite       Replace existing generated GFEAT outputs
EOF
}

sublist="${SCRIPT_DIR}/sublist_all.txt"
subject=""
session="01"
type_csv="act,ppi_seed-VS,nppi-dmn"
jobs=20
mode="run"
overwrite=0
while (( $# )); do
    case "$1" in
        --sublist) sublist="$2"; shift 2 ;;
        --subject) subject="$2"; shift 2 ;;
        --session) session="$2"; shift 2 ;;
        --types) type_csv="$2"; shift 2 ;;
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
IFS=',' read -r -a types <<< "$type_csv"

total=$(( ${#subjects[@]} * ${#types[@]} ))
printf 'L2 batch plan: %d unit(s), %d job(s), session %s, type(s): %s\n' \
    "$total" "$jobs" "${session#ses-}" "${types[*]}"

pids=()
labels=()
failures=0
wait_oldest() {
    local pid="${pids[0]}" label="${labels[0]}"
    if ! wait "$pid"; then
        echo "ERROR: failed L2 unit: $label" >&2
        failures=$((failures + 1))
    fi
    pids=("${pids[@]:1}")
    labels=("${labels[@]:1}")
}

for sub in "${subjects[@]}"; do
    for type in "${types[@]}"; do
        cmd=(bash "${SCRIPT_DIR}/L2stats.sh" "$sub" "$type" --session "$session")
        [[ "$mode" == "dry-run" ]] && cmd+=(--dry-run)
        [[ "$mode" == "render-only" ]] && cmd+=(--render-only)
        (( overwrite )) && cmd+=(--overwrite)
        if [[ "$mode" == "dry-run" ]]; then
            "${cmd[@]}" || failures=$((failures + 1))
        else
            "${cmd[@]}" &
            pids+=("$!")
            labels+=("sub-${sub} type-${type}")
            (( ${#pids[@]} >= jobs )) && wait_oldest
        fi
    done
done
while (( ${#pids[@]} )); do wait_oldest; done
(( failures == 0 )) || exit 1
