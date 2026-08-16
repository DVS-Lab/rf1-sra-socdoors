#!/usr/bin/env bash

# Render and run one first-level FEAT analysis.
# Positional arguments are retained for compatibility with older Smith Lab usage.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# shellcheck source=project_config.sh
source "${SCRIPT_DIR}/project_config.sh"

usage() {
    cat <<'EOF'
Usage: L1stats.sh SUBJECT RUN PPI TASK [options]

PPI is 0/act for activation, a seed name for seed PPI, or dmn/ecn for nPPI.

Options:
  --session ID       BIDS session (default: 01)
  --bold FILE        Override the canonical fMRIPrep BOLD input
  --confounds FILE   Override the canonical TEDANA-enhanced nuisance file
  --dry-run          Validate inputs and print paths without writing
  --render-only      Render and validate the .fsf, but do not run FEAT
  --overwrite        Remove an incomplete/existing generated FEAT output
  -h, --help         Show this help
EOF
}

(( $# >= 4 )) || { usage >&2; exit 2; }
sub="$(normalize_subject "$1")"
run="$2"
ppi="$3"
task="$4"
shift 4

session="01"
bold_override=""
confounds_override=""
mode="run"
overwrite=0
while (( $# )); do
    case "$1" in
        --session) session="$2"; shift 2 ;;
        --bold) bold_override="$2"; shift 2 ;;
        --confounds) confounds_override="$2"; shift 2 ;;
        --dry-run) mode="dry-run"; shift ;;
        --render-only) mode="render-only"; shift ;;
        --overwrite) overwrite=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "ERROR: unknown argument: $1" >&2; usage >&2; exit 2 ;;
    esac
done

session="$(normalize_session "$session")"
case "$task" in doors|socialdoors) ;; *) echo "ERROR: TASK must be doors or socialdoors." >&2; exit 2 ;; esac

smoothing=5
type="$(analysis_type_from_ppi "$ppi")"
subject_output="${FSL_DERIVATIVES_ROOT}/sub-${sub}/ses-${session}"
output="$(l1_output_base "$sub" "$session" "$task" "$run" "$type" "$smoothing")"
stem="sub-${sub}_ses-${session}_task-${task}_run-${run}"
data="${bold_override:-${FMRIPREP_ROOT}/sub-${sub}/ses-${session}/func/${stem}_part-mag_space-MNI152NLin6Asym_desc-preproc_bold.nii.gz}"
confounds="${confounds_override:-${CONFOUNDS_ROOT}/sub-${sub}/${stem}_desc-TedanaPlusConfounds.tsv}"
ev_prefix="${FSL_DERIVATIVES_ROOT}/EVfiles/sub-${sub}/ses-${session}/${task}/run-${run}"
missed_ev="${ev_prefix}_decision-missed.txt"
shape_missed=10
[[ -s "$missed_ev" ]] && shape_missed=3

for required_ev in decision win loss; do
    path="${ev_prefix}_${required_ev}.txt"
    [[ -s "$path" ]] || { echo "ERROR: required EV is missing or empty: $path" >&2; exit 1; }
done
[[ -f "$data" ]] || { echo "ERROR: BOLD input not found: $data" >&2; exit 1; }
[[ -s "$confounds" ]] || { echo "ERROR: confounds file not found or empty: $confounds" >&2; exit 1; }

case "$type" in
    act) template="${PROJECT_ROOT}/templates/L1_task-${task}_model-1_type-act.fsf" ;;
    ppi_seed-*) template="${PROJECT_ROOT}/templates/L1_task-${task}_model-1_type-ppi.fsf" ;;
    nppi-*) template="${PROJECT_ROOT}/templates/L1_task-${task}_model-1_type-${type}.fsf" ;;
esac
[[ -f "$template" ]] || { echo "ERROR: FEAT template not found: $template" >&2; exit 1; }

rendered="${subject_output}/L1_sub-${sub}_task-${task}_ses-${session}_model-1_type-${type}_run-${run}.fsf"
printf 'L1 plan\n  BOLD: %s\n  confounds: %s\n  EV prefix: %s\n  template: %s\n  output: %s.feat\n' \
    "$data" "$confounds" "$ev_prefix" "$template" "$output"
if [[ "$mode" == "dry-run" ]]; then
    exit 0
fi

command -v fslnvols >/dev/null 2>&1 || { echo "ERROR: fslnvols is not available; load FSL first." >&2; exit 1; }
nvolumes="$(fslnvols "$data")"
[[ "$nvolumes" =~ ^[0-9]+$ ]] || { echo "ERROR: fslnvols returned an invalid volume count: $nvolumes" >&2; exit 1; }

feat_dir="${output}.feat"
if [[ -e "$feat_dir" ]]; then
    if (( ! overwrite )); then
        if [[ -f "$feat_dir/cluster_mask_zstat1.nii.gz" ]]; then
            echo "Complete output already exists; skipping: $feat_dir"
            exit 0
        fi
        echo "ERROR: incomplete output exists: $feat_dir (use --overwrite to replace it)." >&2
        exit 1
    fi
    case "$feat_dir" in
        "${FSL_DERIVATIVES_ROOT}"/*) rm -rf -- "$feat_dir" ;;
        *) echo "ERROR: refusing to remove output outside FSL_DERIVATIVES_ROOT: $feat_dir" >&2; exit 1 ;;
    esac
fi

mkdir -p "$subject_output"

sed_escape() { printf '%s' "$1" | sed 's/[&@\\]/\\&/g'; }

sed_args=(
    -e "s@OUTPUT@$(sed_escape "$output")@g"
    -e "s@DATA@$(sed_escape "$data")@g"
    -e "s@EVDIR@$(sed_escape "$ev_prefix")@g"
    -e "s@EV_MISSED_TRIAL@$(sed_escape "$missed_ev")@g"
    -e "s@SHAPE_MISSED_TRIAL@${shape_missed}@g"
    -e "s@SMOOTH@${smoothing}@g"
    -e "s@CONFOUNDEVS@$(sed_escape "$confounds")@g"
    -e "s@NVOLUMES@${nvolumes}@g"
)

if [[ "$type" == ppi_seed-* ]]; then
    seed="${type#ppi_seed-}"
    mask="${PROJECT_ROOT}/masks/seed-${seed}.nii.gz"
    [[ -f "$mask" ]] || { echo "ERROR: seed mask not found: $mask" >&2; exit 1; }
    activation="$(l1_output_base "$sub" "$session" "$task" "$run" act "$smoothing").feat"
    [[ -f "$activation/mask.nii.gz" ]] || { echo "ERROR: activation analysis must exist before PPI: $activation" >&2; exit 1; }
    command -v fslmeants >/dev/null 2>&1 || { echo "ERROR: fslmeants is not available; load FSL first." >&2; exit 1; }
    phys="${subject_output}/ts_task-${task}_ses-${session}_mask-${seed}_run-${run}.txt"
    fslmeants -i "$data" -o "$phys" -m "$mask"
    sed_args+=( -e "s@PHYS@$(sed_escape "$phys")@g" )
elif [[ "$type" == nppi-* ]]; then
    network="${type#nppi-}"
    activation="$(l1_output_base "$sub" "$session" "$task" "$run" act "$smoothing").feat"
    [[ -f "$activation/mask.nii.gz" ]] || { echo "ERROR: activation analysis must exist before nPPI: $activation" >&2; exit 1; }
    command -v fsl_glm >/dev/null 2>&1 || { echo "ERROR: fsl_glm is not available; load FSL first." >&2; exit 1; }
    network_series=()
    for net in {0..9}; do
        mask="${PROJECT_ROOT}/masks/networkmasks/nan_rPNAS_2mm_net000${net}.nii.gz"
        [[ -f "$mask" ]] || { echo "ERROR: network mask not found: $mask" >&2; exit 1; }
        series="${subject_output}/ts_task-${task}_ses-${session}_net000${net}_nppi-${network}_run-${run}.txt"
        fsl_glm -i "$data" -d "$mask" -o "$series" --demean -m "$activation/mask.nii.gz"
        network_series+=("$series")
    done
    main_index=3; other_index=7
    [[ "$network" == "ecn" ]] && { main_index=7; other_index=3; }
    sed_args+=(
        -e "s@MAINNET@$(sed_escape "${network_series[$main_index]}")@g"
        -e "s@OTHERNET@$(sed_escape "${network_series[$other_index]}")@g"
    )
    for net in 0 1 2 4 5 6 8 9; do
        sed_args+=( -e "s@INPUT${net}@$(sed_escape "${network_series[$net]}")@g" )
    done
fi

sed "${sed_args[@]}" "$template" > "$rendered"
if grep -En 'OUTPUT|DATA|EVDIR|CONFOUNDEVS|NVOLUMES|SHAPE_MISSED_TRIAL|MAINNET|OTHERNET|INPUT[0-9]|PHYS' "$rendered" >/dev/null 2>&1; then
    echo "ERROR: unresolved placeholder remains in rendered template: $rendered" >&2
    exit 1
fi
echo "Rendered: $rendered"
[[ "$mode" == "render-only" ]] && exit 0

command -v feat >/dev/null 2>&1 || { echo "ERROR: feat is not available; load FSL first." >&2; exit 1; }
feat "$rendered"

mkdir -p "$feat_dir/reg"
ln -sfn "${FSLDIR}/etc/flirtsch/ident.mat" "$feat_dir/reg/example_func2standard.mat"
ln -sfn "${FSLDIR}/etc/flirtsch/ident.mat" "$feat_dir/reg/standard2example_func.mat"
ln -sfn "$feat_dir/mean_func.nii.gz" "$feat_dir/reg/standard.nii.gz"
rm -f -- "$feat_dir/stats/res4d.nii.gz" "$feat_dir/stats/corrections.nii.gz" \
    "$feat_dir/stats/threshac1.nii.gz" "$feat_dir/filtered_func_data.nii.gz"
