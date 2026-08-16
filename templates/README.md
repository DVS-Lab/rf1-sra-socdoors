# FEAT templates

The `.fsf` files are the scientific model definitions. Shell workers substitute paths, volume counts, and the optional missed-event shape; they do not rewrite contrasts or FEAT settings.

## Active L1 templates

For each task (`doors`, `socialdoors`):

- `L1_task-<task>_model-1_type-act.fsf` — activation model.
- `L1_task-<task>_model-1_type-ppi.fsf` — seed-based PPI model.
- `L1_task-<task>_model-1_type-nppi-dmn.fsf` — DMN/ECN network-PPI structure.

Task-specific duplicates are retained even when their current contents match because they make the task workflow explicit. L1 models use the established TR (1.615 s), 5-mm smoothing, 100-s high-pass filter, FILM/prewhitening, and existing threshold/contrast definitions. Activation contrasts are win, loss, decision, and win > loss. The optional decision-missed EV uses shape 10 when no missed trials occurred.

## Active L2 templates

- `L2_task-socialdoors_model-1_type-act.fsf`
- `L2_task-socialdoors_model-1_type-ppi.fsf`
- `L2_task-socialdoors_model-1_type-nppi.fsf`

Despite the filename, each L2 template receives two inputs: participant-level `socialdoors` and monetary `doors` L1 outputs. L2 therefore combines/compares reward modalities within participant; it is not a repeated-run average of one task.

## L3 templates

`L3_model-1_task-socialdoors_type-act_n98.fsf` is the exact historical default selected by `run_L3stats.sh`. Its sample size, input order, group assignments, and covariates are stored in the template and are not regenerated.

This n=98 template currently points to historical task-specific L1 cope paths, not the canonical L2 output, and `feat_files(11)` omits a participant directory. The repository does not provide enough authoritative context to infer that participant or to decide whether a new group model should consume L1 or L2. `L3stats.sh` therefore validates and fails on absent paths instead of silently repairing the scientific input set.

Other `L3_*` files and associated `.con`, `.grp`, `.mat`, `.png`, and `.ppm` exports are model-specific historical designs. Their names encode task, analysis/seed, model, and sample size. They should be selected only with the matching subject list/covariate provenance; identical-looking files are not consolidated.

## Placeholders

| Placeholder | Replaced by |
| --- | --- |
| `OUTPUT` | FEAT output basename. |
| `DATA` | L1 preprocessed BOLD input. |
| `NVOLUMES` | `fslnvols` result. |
| `EVDIR` | Run-specific EV prefix, ending in `run-1`. |
| `SHAPE_MISSED_TRIAL` | `3` when a nonempty missed EV exists; otherwise `10`. |
| `CONFOUNDEVS` | Numeric nuisance-regressor file. |
| `PHYS` | Seed time series for PPI. |
| `MAINNET`, `OTHERNET`, `INPUT0`…`INPUT9` | Network time series for nPPI. |
| `INPUT1`, `INPUT2` | Social Doors and Doors L1 directories in L2. |
| `COPENUM`, `REPLACEME`, `BASEDIR`, `MODEL` | Existing L3 path/design substitutions. |

Before group FEAT, `L3stats.sh` checks that `fmri(multiple)` and the number of ordered `feat_files()` entries agree with the sample size encoded in the selected template.
