# Workflow audit

This pre-edit inventory was used to keep the cleanup conservative. Classification describes repository role, not scientific quality.

## Active workflow

- `project_config.sh`, `BIDSto3col.sh`, `gen3colfiles.sh`
- `build_L1_manifest.py`, `L1stats.sh`, `run_L1stats.sh`, `check_L1_outputs.py`
- `build_L2_manifest.py`, `L2stats.sh`, `run_L2stats.sh`, `check_L2_outputs.py`
- `run_gen3colfiles.sh`, `run_logged.sh`
- `L3stats.sh`, `run_L3stats.sh`
- The nine L1/L2 templates listed in `templates/README.md`
- `L3_model-1_task-socialdoors_type-act_n98.fsf` for the current wrapper's historical default

## Active support/input

- `sublist_full-dataset.txt` and `sublist_all.txt` as legacy uniform-session wrapper defaults; current production uses generated manifests
- L1 seed masks and any locally supplied network masks
- FEAT templates and canonical Linux2 BIDS/fMRIPrep/confound outputs
- `validate_workflow.sh` and `tests/test_workflow.sh`

## Result/figure assets

- `MRIcroGL/`, `imaging_plots/`, and `derivatives/imaging_plots/`
- Result-derived NIfTI files in `masks/`
- Extracted ROI/value text files and tracked lightweight derivative files

## Legacy/historical

- `archive/L1stats-hpc.sh`: obsolete PBS/Gpfs worker retained for provenance; it is not sourced by production.
- ROI extraction, PALM/randomise, `run_fslstats*`, `make_filteredfunc_diff*`, `move_randomise.sh`, and plotting scripts.
- MATLAB behavioral/covariate scripts and R scripts tied to earlier manuscripts, posters, and group models.
- The many sample-size/model-specific L3 templates and FSL design exports not selected by the current wrapper.

Historical status does not mean safe to delete. These files preserve the provenance of prior results.

## Obvious temporary/junk

- Removed: `code/.Rhistory` and the `.~lock.*` spreadsheet lock file.
- Ignored going forward: R history, office lock files, notebook checkpoints, downloaded public data, work/scratch directories, and generated FEAT/fMRIPrep trees.

## Uncertain

- `Untitled.R`, older covariate spreadsheets/CSVs, multiple subject lists, and standalone FEAT/design exports.
- Model-specific cohort authority and the current final L3 sample.
- Provenance for seed and result-derived masks where the repository contains no citation or construction record.

These items remain in place. A domain owner should confirm provenance and authority before archival or deletion.

## Verified relationships

- L1 uses the session-aware canonical Linux2 BIDS/fMRIPrep/confound contract.
- L1 and L2 obtain their exact paths from shared naming functions.
- L2 combines `socialdoors` and `doors` within participant.
- L3 templates contain fixed, model-specific ordered inputs; the active worker checks declared `n` against the number of inputs rather than regenerating a cohort. The n=98 default currently references historical L1 paths rather than L2 and has one path with no participant directory. Both the missing identity and intended input level need scientific confirmation.
