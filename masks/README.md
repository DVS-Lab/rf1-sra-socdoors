# Masks

Masks fall into two conceptually different groups: a priori seeds used to extract PPI time series and masks derived from historical statistical results. A filename is not sufficient provenance, so unresolved details are marked explicitly.

## Seed masks

| Name | Role | Definition | Space/resolution | Used by | Provenance |
| --- | --- | --- | --- | --- | --- |
| `seed-VS.nii.gz` | Seed PPI | Ventral striatum | Needs confirmation | `L1stats.sh ... VS ...` | Needs confirmation |
| `seed-mPFC.nii.gz` | Seed PPI | Medial prefrontal cortex | Needs confirmation | `L1stats.sh ... mPFC ...` | Needs confirmation |
| `seed-postTPJ.nii.gz` | Seed PPI | Posterior temporoparietal junction | Needs confirmation | `L1stats.sh ... postTPJ ...` | Needs confirmation |
| `seed-PCC.nii.gz` | Seed PPI | Posterior cingulate cortex | Needs confirmation | `L1stats.sh ... PCC ...` | Needs confirmation |

The historical `archive-09192023/` VS files are not active defaults. Network-PPI code expects a local `networkmasks/` set named `nan_rPNAS_2mm_net0000.nii.gz` through `net0009.nii.gz`; those masks are not tracked here, and their provenance needs confirmation before nPPI reproduction.

### Wave 1 localizer seeds for outcome PPI

Use the ordinary production `L1stats.sh SUBJECT 1 SEED TASK --session 01`
with the case-sensitive third argument below. These are exploratory seeds
localized in the same N=292 cohort, not new names for the historical mPFC
or VS masks. There is no change to the PPI template or to FEAT.

| Seed argument | Localizer | Rank | Native voxel (i,j,k) | MNI center (mm) |
| --- | --- | ---: | --- | --- |
| `vmpfc` | Mean outcome win > loss across tasks, center inside the Bhanji vmPFC mask | 37 | 26,58,22 | -4.6,46.8,-6.66 |
| `ffa_left` | Social > monetary decision, left posterior fusiform | 4 | 12,22,17 | -42.4,-50.4,-21.51 |
| `ffa_right` | Social > monetary decision, right posterior fusiform | 1 | 44,24,17 | 44,-45,-21.51 |
| `ffa_bilateral` | Equal-sized union of the left and right masks | | | |

Each unilateral image contains the 27 voxel centers within 5 mm of its peak
on the native MNI152NLin6Asym group grid; the bilateral mask contains 54.
No statistical threshold is applied within the spheres. Definitions and source:
[frozen seed code](https://github.com/DVS-Lab/rf1-sra-socdoors-psychosocial/blob/d5488d3/code/localizer_ppi.py),
[corrected peaks](https://github.com/DVS-Lab/rf1-sra-socdoors-psychosocial/blob/5478834/results/review/wave1-core-height-peaks-v1/peaks.tsv)
and [native maps and Bhanji check](https://github.com/DVS-Lab/rf1-sra-socdoors-psychosocial/tree/5478834/results/review/wave1-core-bhanji-v1).
The decision contrast localizes fusiform; the group outcomes are not decision PPIs.

Production `fslmeants` averages the fixed mask on the input BOLD. Thus the
54-voxel series is the average of the two **full-mask** means before interaction
construction. The earlier seed QA used only voxels inside the run mask.
Check the production time series against the QA series for each run before
group use; partial coverage can make them differ. The presence of a mask
does not clear a QA hold or authorize dropping participants.

## Result-derived masks

Files beginning with model/result labels such as `adix...`, `agex...`, `depressx...`, and `wmh_...` are thresholded masks from historical group findings. Their role is secondary extraction/visualization, not a priori seed definition. The model and statistic are partially encoded in each filename; anatomical definition, exact space/resolution, thresholding command, and source contrast need confirmation from the corresponding historical analysis records.

Do not substitute a result-derived mask as an L1 PPI seed without a separate scientific decision.
