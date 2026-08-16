#!/usr/bin/env bash

# Conservative wrapper for the currently documented historical n=98 group model.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

usage() {
    cat <<'EOF'
Usage: run_L3stats.sh [options]

Options:
  --task NAME       doors or socialdoors (default: socialdoors)
  --analysis NAME   Template analysis token (default: type-act)
  --cope N:NAME     Cope number and label (default: 4:win-loss)
  --n N             Historical template sample size (default: 98)
  --jobs N          Maximum concurrent jobs (default: 15)
  --dry-run         Print and validate model contracts
  --render-only     Render templates and validate all inputs
  --overwrite       Replace existing generated group outputs
EOF
}

task="socialdoors"
analysis="type-act"
cope_spec="4:win-loss"
n=98
jobs=15
mode="run"
overwrite=0
while (( $# )); do
    case "$1" in
        --task) task="$2"; shift 2 ;;
        --analysis) analysis="$2"; shift 2 ;;
        --cope) cope_spec="$2"; shift 2 ;;
        --n) n="$2"; shift 2 ;;
        --jobs) jobs="$2"; shift 2 ;;
        --dry-run) mode="dry-run"; shift ;;
        --render-only) mode="render-only"; shift ;;
        --overwrite) overwrite=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "ERROR: unknown argument: $1" >&2; exit 2 ;;
    esac
done
[[ "$jobs" =~ ^[1-9][0-9]*$ ]] || { echo "ERROR: --jobs must be a positive integer." >&2; exit 2; }
IFS=',' read -r -a cope_specs <<< "$cope_spec"
printf 'L3 batch plan: %d unit(s), %d job(s), task %s, analysis %s, historical n=%s\n' \
    "${#cope_specs[@]}" "$jobs" "$task" "$analysis" "$n"

pids=()
labels=()
failures=0
wait_oldest() {
    local pid="${pids[0]}" label="${labels[0]}"
    if ! wait "$pid"; then
        echo "ERROR: failed L3 unit: $label" >&2
        failures=$((failures + 1))
    fi
    pids=("${pids[@]:1}")
    labels=("${labels[@]:1}")
}

for spec in "${cope_specs[@]}"; do
    [[ "$spec" == *:* ]] || { echo "ERROR: --cope must use N:NAME." >&2; exit 2; }
    copenum="${spec%%:*}"
    copename="${spec#*:}"
    cmd=(bash "${SCRIPT_DIR}/L3stats.sh" "$copenum" "$copename" "$analysis" "$task" --n "$n")
    [[ "$mode" == "dry-run" ]] && cmd+=(--dry-run)
    [[ "$mode" == "render-only" ]] && cmd+=(--render-only)
    (( overwrite )) && cmd+=(--overwrite)
    if [[ "$mode" == "dry-run" ]]; then
        "${cmd[@]}" || failures=$((failures + 1))
    else
        "${cmd[@]}" &
        pids+=("$!")
        labels+=("cope-${copenum}-${copename}")
        (( ${#pids[@]} >= jobs )) && wait_oldest
    fi
done
while (( ${#pids[@]} )); do wait_oldest; done
(( failures == 0 )) || exit 1
