#!/usr/bin/env bash

# Render and run one historical group FEAT model without changing its design.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# shellcheck source=project_config.sh
source "${SCRIPT_DIR}/project_config.sh"

usage() {
    cat <<'EOF'
Usage: L3stats.sh COPENUM COPENAME ANALYSIS TASK [options]

ANALYSIS is the template path token, for example type-act.

Options:
  --n N            Historical template sample size (default: 98)
  --dry-run        Validate the design contract and print paths
  --render-only    Render and validate all lower-level inputs, but do not run FEAT
  --overwrite      Replace an existing generated group output
EOF
}

(( $# >= 4 )) || { usage >&2; exit 2; }
copenum="$1"
copename="$2"
analysis="$3"
task="$4"
shift 4
n=98
mode="run"
overwrite=0
while (( $# )); do
    case "$1" in
        --n) n="$2"; shift 2 ;;
        --dry-run) mode="dry-run"; shift ;;
        --render-only) mode="render-only"; shift ;;
        --overwrite) overwrite=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "ERROR: unknown argument: $1" >&2; exit 2 ;;
    esac
done
[[ "$copenum" =~ ^[1-9][0-9]*$ ]] || { echo "ERROR: COPENUM must be a positive integer." >&2; exit 2; }
[[ "$n" =~ ^[1-9][0-9]*$ ]] || { echo "ERROR: --n must be a positive integer." >&2; exit 2; }
case "$task" in doors|socialdoors) ;; *) echo "ERROR: TASK must be doors or socialdoors." >&2; exit 2 ;; esac

model=1
template="${PROJECT_ROOT}/templates/L3_model-${model}_task-${task}_${analysis}_n${n}.fsf"
[[ -f "$template" ]] || { echo "ERROR: historical group template not found: $template" >&2; exit 1; }

declared_n="$(awk '$1 == "set" && $2 == "fmri(multiple)" {print $3; exit}' "$template")"
input_count="$(grep -Ec '^set feat_files\([0-9]+\)' "$template")"
[[ "$declared_n" == "$n" ]] || { echo "ERROR: template declares ${declared_n:-unknown} inputs, expected n=${n}: $template" >&2; exit 1; }
[[ "$input_count" == "$n" ]] || { echo "ERROR: template contains $input_count lower-level inputs, expected $n: $template" >&2; exit 1; }

group_root="${FSL_DERIVATIVES_ROOT}/L3_model-${model}_task-${task}_n${n}_flame1+2"
output="${group_root}/L3_task-${task}_${analysis}_cnum-${copenum}_cname-${copename}_twogroup"
rendered="${group_root}/L3_model-${model}_task-${task}_${analysis}_copenum-${copenum}.fsf"
printf 'L3 historical model plan\n  template: %s\n  declared/order-checked inputs: %s\n  output: %s.gfeat\n' \
    "$template" "$input_count" "$output"
[[ "$mode" == "dry-run" ]] && exit 0

gfeat_dir="${output}.gfeat"
if [[ -e "$gfeat_dir" ]]; then
    if (( ! overwrite )); then
        if [[ -f "$gfeat_dir/cope1.feat/cluster_mask_zstat1.nii.gz" ]]; then
            echo "Complete output already exists; skipping: $gfeat_dir"
            exit 0
        fi
        echo "ERROR: incomplete output exists: $gfeat_dir (use --overwrite to replace it)." >&2
        exit 1
    fi
    case "$gfeat_dir" in
        "${FSL_DERIVATIVES_ROOT}"/*) rm -rf -- "$gfeat_dir" ;;
        *) echo "ERROR: refusing to remove output outside FSL_DERIVATIVES_ROOT: $gfeat_dir" >&2; exit 1 ;;
    esac
fi

mkdir -p "$group_root"
sed_escape() { printf '%s' "$1" | sed 's/[&@\\]/\\&/g'; }
sed -e "s@OUTPUT@$(sed_escape "$output")@g" \
    -e "s@COPENUM@${copenum}@g" \
    -e "s@REPLACEME@$(sed_escape "$analysis")@g" \
    -e "s@BASEDIR@$(sed_escape "$PROJECT_ROOT")@g" \
    -e "s@MODEL@${model}@g" \
    "$template" > "$rendered"

missing=0
while IFS= read -r input; do
    if [[ ! -f "$input" ]]; then
        echo "ERROR: lower-level input missing: $input" >&2
        missing=$((missing + 1))
    fi
done < <(awk -F '"' '/^set feat_files\([0-9]+\)/ {print $2}' "$rendered")
(( missing == 0 )) || { echo "ERROR: $missing of $n ordered group inputs are missing." >&2; exit 1; }

echo "Rendered: $rendered"
[[ "$mode" == "render-only" ]] && exit 0
command -v feat >/dev/null 2>&1 || { echo "ERROR: feat is not available; load FSL first." >&2; exit 1; }
feat "$rendered"

cope_dir="$gfeat_dir/cope1.feat"
rm -f -- "$cope_dir/stats/res4d.nii.gz" "$cope_dir/stats/corrections.nii.gz" \
    "$cope_dir/stats/threshac1.nii.gz" "$cope_dir/var_filtered_func_data.nii.gz"
