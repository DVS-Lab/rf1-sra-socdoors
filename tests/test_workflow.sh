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
    printf 'synthetic nifti placeholder\n' > "${bold_dir}/${stem}_part-mag_space-MNI152NLin6Asym_desc-preproc_bold.nii.gz"
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
[[ "$l2_output" == *"FSLSUB_PARALLEL: 1"* ]]
bash "${PROJECT_ROOT}/code/L2stats.sh" 10317 act --session 01 --render-only >/dev/null
l2_rendered="${FSL_DERIVATIVES_ROOT}/sub-10317/ses-01/L2_sub-10317_task-socialdoors_ses-01_model-1_type-act.fsf"
[[ -s "$l2_rendered" ]]
grep -Fq "L1_task-socialdoors_ses-01_model-1_type-act_run-1_sm-5.feat" "$l2_rendered"
grep -Fq "L1_task-doors_ses-01_model-1_type-act_run-1_sm-5.feat" "$l2_rendered"
echo "PASS: L1 outputs exactly match rendered L2 inputs"

# Add a second session for the same participant so the batch contract is not
# accidentally reduced to a uniform-session subject list.
func_ses02="${BIDS_ROOT}/sub-10317/ses-02/func"
bold_ses02="${FMRIPREP_ROOT}/sub-10317/ses-02/func"
mkdir -p "$func_ses02" "$bold_ses02"
for task in doors socialdoors; do
    source_stem="sub-10317_ses-01_task-${task}_run-1"
    target_stem="sub-10317_ses-02_task-${task}_run-1"
    cp "${func}/${source_stem}_events.tsv" "${func_ses02}/${target_stem}_events.tsv"
    cp "${FMRIPREP_ROOT}/sub-10317/ses-01/func/${source_stem}_part-mag_space-MNI152NLin6Asym_desc-preproc_bold.nii.gz" \
        "${bold_ses02}/${target_stem}_part-mag_space-MNI152NLin6Asym_desc-preproc_bold.nii.gz"
    cp "${CONFOUNDS_ROOT}/sub-10317/${source_stem}_desc-TedanaPlusConfounds.tsv" \
        "${CONFOUNDS_ROOT}/sub-10317/${target_stem}_desc-TedanaPlusConfounds.tsv"
done

# A canonical events file can exist yet still be structurally incompatible
# with this FEAT model. An all-missed run has decision-missed but no decision.
all_missed_func="${BIDS_ROOT}/sub-11125/ses-01/func"
all_missed_bold="${FMRIPREP_ROOT}/sub-11125/ses-01/func"
mkdir -p "$all_missed_func" "$all_missed_bold" "${CONFOUNDS_ROOT}/sub-11125"
for task in doors socialdoors; do
    stem="sub-11125_ses-01_task-${task}_run-1"
    printf 'onset\tduration\ttrial_type\n1\t1\tdecision-missed\n3\t1\twin\n5\t1\tloss\n' \
        > "${all_missed_func}/${stem}_events.tsv"
    printf 'synthetic nifti placeholder\n' \
        > "${all_missed_bold}/${stem}_part-mag_space-MNI152NLin6Asym_desc-preproc_bold.nii.gz"
    printf 'motion\n0\n' \
        > "${CONFOUNDS_ROOT}/sub-11125/${stem}_desc-TedanaPlusConfounds.tsv"
done

manifest="${TEST_ROOT}/l1_ready.tsv"
missing_report="${TEST_ROOT}/l1_missing.tsv"
python3 "${PROJECT_ROOT}/code/build_L1_manifest.py" \
    --bids-root "$BIDS_ROOT" \
    --fmriprep-root "$FMRIPREP_ROOT" \
    --confounds-root "$CONFOUNDS_ROOT" \
    --source-exclusions-root "${TEST_ROOT}/source-exclusions" \
    --sessions 01,02 \
    --output "$manifest" \
    --missing-output "$missing_report" >/dev/null
[[ "$(awk 'NR > 1 && NF {count++} END {print count + 0}' "$manifest")" == "4" ]]
grep -Fq $'10317\t01\tdoors\t1' "$manifest"
grep -Fq $'10317\t01\tsocialdoors\t1' "$manifest"
grep -Fq $'10317\t02\tdoors\t1' "$manifest"
grep -Fq $'10317\t02\tsocialdoors\t1' "$manifest"
[[ "$(grep -Fc $'11125\t01\t' "$missing_report")" == "2" ]]
grep -Fq $'11125\t01\tdoors\t1\tevents:missing_trial_type=decision' "$missing_report"
grep -Fq $'11125\t01\tsocialdoors\t1\tevents:missing_trial_type=decision' "$missing_report"
bash "${PROJECT_ROOT}/code/run_gen3colfiles.sh" --manifest "$manifest" --jobs 2 --overwrite >/dev/null
manifest_plan="$(bash "${PROJECT_ROOT}/code/run_L1stats.sh" --manifest "$manifest" --jobs 50 --dry-run)"
[[ "$manifest_plan" == *"L1 batch plan: 4 unit(s), 50 job(s)"* ]]
echo "PASS: manifest enforces model EVs and feeds mixed-session EV/L1 wrappers"

while IFS=$'\t' read -r subject session task run; do
    [[ "$subject" == "subject" ]] && continue
    for type in act ppi_seed-VS; do
        feat_dir="${FSL_DERIVATIVES_ROOT}/sub-${subject}/ses-${session}/L1_task-${task}_ses-${session}_model-1_type-${type}_run-${run}_sm-5.feat"
        mkdir -p "${feat_dir}/stats"
        printf '/NumWaves 1\n' > "${feat_dir}/design.mat"
        printf '/NumContrasts 2\n' > "${feat_dir}/design.con"
        for relative in mask.nii.gz report.html cluster_mask_zstat1.nii.gz \
            stats/cope1.nii.gz stats/cope2.nii.gz stats/zstat1.nii.gz stats/zstat2.nii.gz; do
            printf 'synthetic output placeholder\n' > "${feat_dir}/${relative}"
        done
        if [[ "$type" == "ppi_seed-VS" ]]; then
            printf '0.0\n' > "${FSL_DERIVATIVES_ROOT}/sub-${subject}/ses-${session}/ts_task-${task}_ses-${session}_mask-VS_run-${run}.txt"
        fi
    done
done < "$manifest"

checker_report="${TEST_ROOT}/l1_incomplete.tsv"
python3 "${PROJECT_ROOT}/code/check_L1_outputs.py" \
    --manifest "$manifest" \
    --types act,ppi_seed-VS \
    --missing-output "$checker_report" >/dev/null
[[ "$(awk 'END {print NR}' "$checker_report")" == "1" ]]

broken="${FSL_DERIVATIVES_ROOT}/sub-10317/ses-02/L1_task-socialdoors_ses-02_model-1_type-ppi_seed-VS_run-1_sm-5.feat/stats/zstat2.nii.gz"
rm -f -- "$broken"
if python3 "${PROJECT_ROOT}/code/check_L1_outputs.py" \
    --manifest "$manifest" \
    --types act,ppi_seed-VS \
    --missing-output "$checker_report" >/dev/null; then
    echo "ERROR: incomplete L1 output passed the completion checker." >&2
    exit 1
fi
grep -Fq $'10317\t02\tsocialdoors\t1\tppi_seed-VS\tstats/zstat2.nii.gz' "$checker_report"
echo "PASS: manifest-driven L1 completion checker detects exact missing outputs"
