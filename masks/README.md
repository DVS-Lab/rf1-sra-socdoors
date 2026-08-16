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

## Result-derived masks

Files beginning with model/result labels such as `adix...`, `agex...`, `depressx...`, and `wmh_...` are thresholded masks from historical group findings. Their role is secondary extraction/visualization, not a priori seed definition. The model and statistic are partially encoded in each filename; anatomical definition, exact space/resolution, thresholding command, and source contrast need confirmation from the corresponding historical analysis records.

Do not substitute a result-derived mask as an L1 PPI seed without a separate scientific decision.
