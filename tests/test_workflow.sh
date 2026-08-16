#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/socdoors-test.XXXXXX")"
trap 'rm -rf -- "$TEST_ROOT"' EXIT

export BIDS_ROOT="${TEST_ROOT}/bids"
export FMRIPREP_ROOT="${TEST_ROOT}/fmriprep"
export CONFOUNDS_ROOT="${TEST_ROOT}/confounds"
export FSL_DERIVATIVES_ROOT="${TEST_ROOT}/fsl"

fake_bin="${TEST_ROOT}/bin"
mkdir -p "$fake_bin"
printf '#!/usr/bin/env bash\nprintf "10\\n"\n' > "${fake_bin}/fslnvols"
chmod +x "${fake_bin}/fslnvols"
export PATH="${fake_bin}:${PATH}"

func="${BIDS_ROOT}/sub-10317/ses-01/func"
mkdir -p "$func"

for task in doors socialdoors; do
    events="${func}/sub-10317_ses-01_task-${task}_run-1_events.tsv"
    {
        printf 'onset\tduration\ttrial_type\textra\n'
        printf '1.5\t0.5\tdecision\tx\n'
        printf '3\t1\twin\tx\n'
        printf '5.25\t1.5\tloss\tx\n'
        [[ "$task" == "socialdoors" ]] && printf '7\t0.25\tdecision-missed\tx\n'
    } > "$events"
done

bash "${PROJECT_ROOT}/code/gen3colfiles.sh" --subject 10317 --session 01 --task all
ev_root="${FSL_DERIVATIVES_ROOT}/EVfiles/sub-10317/ses-01"
[[ "$(cat "${ev_root}/doors/run-1_decision.txt")" == $'1.5\t0.5\t1.0' ]]
[[ "$(cat "${ev_root}/doors/run-1_win.txt")" == $'3\t1\t1.0' ]]
[[ "$(cat "${ev_root}/doors/run-1_loss.txt")" == $'5.25\t1.5\t1.0' ]]
[[ ! -e "${ev_root}/doors/run-1_decision-missed.txt" ]]
[[ "$(cat "${ev_root}/socialdoors/run-1_decision-missed.txt")" == $'7\t0.25\t1.0' ]]
echo "PASS: canonical 3-column conversion and optional missed-event handling"

invalid="${func}/sub-10317_ses-01_task-doors_run-2_events.tsv"
printf 'onset\tduration\ttrial_type\n1\t-1\tdecision\n2\t1\twin\n3\t1\tloss\n' > "$invalid"
if bash "${PROJECT_ROOT}/code/gen3colfiles.sh" --subject 10317 --task doors --run 2 >/dev/null 2>&1; then
    echo "ERROR: negative duration was accepted." >&2
    exit 1
fi
echo "PASS: invalid event duration rejected"

for task in doors socialdoors; do
    stem="sub-10317_ses-01_task-${task}_run-1"
    bold_dir="${FMRIPREP_ROOT}/sub-10317/ses-01/func"
    mkdir -p "$bold_dir" "${CONFOUNDS_ROOT}/sub-10317"
    : > "${bold_dir}/${stem}_part-mag_space-MNI152NLin6Asym_desc-preproc_bold.nii.gz"
    printf 'motion\n0\n' > "${CONFOUNDS_ROOT}/sub-10317/${stem}_desc-TedanaPlusConfounds.tsv"
    output="$(bash "${PROJECT_ROOT}/code/L1stats.sh" 10317 1 0 "$task" --session 01 --dry-run)"
    [[ "$output" == *"L1_task-${task}_ses-01_model-1_type-act_run-1_sm-5.feat"* ]]
    [[ "$output" != *"_Tedana.feat"* ]]
    bash "${PROJECT_ROOT}/code/L1stats.sh" 10317 1 0 "$task" --session 01 --render-only >/dev/null
    rendered="${FSL_DERIVATIVES_ROOT}/sub-10317/ses-01/L1_sub-10317_task-${task}_ses-01_model-1_type-act_run-1.fsf"
    [[ -s "$rendered" ]]
    grep -Fq "${bold_dir}/${stem}_part-mag_space-MNI152NLin6Asym_desc-preproc_bold.nii.gz" "$rendered"
    grep -Fq "${ev_root}/${task}/run-1_win.txt" "$rendered"
    mkdir -p "${FSL_DERIVATIVES_ROOT}/sub-10317/ses-01/L1_task-${task}_ses-01_model-1_type-act_run-1_sm-5.feat"
done
echo "PASS: L1 resolves Linux2-style inputs, renders both tasks, and uses canonical output names"

l2_output="$(bash "${PROJECT_ROOT}/code/L2stats.sh" 10317 act --session 01 --dry-run)"
[[ "$l2_output" == *"L1_task-socialdoors_ses-01_model-1_type-act_run-1_sm-5.feat"* ]]
[[ "$l2_output" == *"L1_task-doors_ses-01_model-1_type-act_run-1_sm-5.feat"* ]]
bash "${PROJECT_ROOT}/code/L2stats.sh" 10317 act --session 01 --render-only >/dev/null
l2_rendered="${FSL_DERIVATIVES_ROOT}/sub-10317/ses-01/L2_sub-10317_task-socialdoors_ses-01_model-1_type-act.fsf"
[[ -s "$l2_rendered" ]]
grep -Fq "L1_task-socialdoors_ses-01_model-1_type-act_run-1_sm-5.feat" "$l2_rendered"
grep -Fq "L1_task-doors_ses-01_model-1_type-act_run-1_sm-5.feat" "$l2_rendered"
echo "PASS: L1 outputs exactly match rendered L2 inputs"
