# RF1-SRA Social Doors downstream analysis

This repository contains the downstream fMRI analyses for the RF1-SRA Doors tasks. `socialdoors` measures responses to social peer feedback; `doors` is the matched monetary-reward task. The scientific workflow is an established FSL FEAT analysis and this repository preserves its model definitions.

Data curation, BIDS conversion, fMRIPrep, TEDANA, and production confound generation belong to [`DVS-Lab/rf1-sra-linux2`](https://github.com/DVS-Lab/rf1-sra-linux2). This repository consumes those outputs; it does not read raw DICOMs, raw behavioral logs, or private stimulus folders.

The frozen public teaching example is [OpenNeuro ds005123 version 1.1.3](https://openneuro.org/datasets/ds005123/versions/1.1.3). The two introductory notebooks use one public participant and do not contain private RF1-SRA data.

## Analysis path

```text
rf1-sra-linux2
  BIDS _events.tsv
  fMRIPrep optimally combined multi-echo BOLD
  TEDANA-enhanced confounds
       ↓
rf1-sra-socdoors
  BIDS events → FSL 3-column EVs
       ↓
  L1: doors and socialdoors separately
       ↓
  L2: within-participant social/monetary combination
       ↓
  L3: historical group FEAT models
```

L1 uses the fMRIPrep optimally combined magnitude BOLD in `MNI152NLin6Asym` space. Individual echo outputs produced with `--me-output-echos` are inputs to the upstream TEDANA workflow, not the default FEAT input here. TEDANA provenance is recorded by the nuisance file, so the canonical FEAT output name does not carry a `_Tedana` suffix.

## Internal quick start

The defaults point to the production Linux2 checkout on the Smith Lab system:

```bash
cd /path/to/rf1-sra-socdoors

export RF1_SRA_UPSTREAM_ROOT=/ZPOOL/data/projects/rf1-sra-linux2

# Inspect, then generate ses-01 EVs from canonical BIDS events.
bash code/gen3colfiles.sh --sublist code/sublist_full-dataset.txt --session 01 --dry-run
bash code/gen3colfiles.sh --sublist code/sublist_full-dataset.txt --session 01

# Validate paths before launching activation FEAT jobs.
bash code/run_L1stats.sh --sublist code/sublist_full-dataset.txt --session 01 --ppi 0 --dry-run
bash code/run_L1stats.sh --sublist code/sublist_full-dataset.txt --session 01 --ppi 0 --jobs 20

# Combine each participant's Social Doors and Doors activation estimates.
bash code/run_L2stats.sh --sublist code/sublist_all.txt --session 01 --types act --dry-run
bash code/run_L2stats.sh --sublist code/sublist_all.txt --session 01 --types act --jobs 20
```

Environment overrides are documented in [`code/project_config.sh`](code/project_config.sh). They allow the same scripts to target a public-data workspace without editing source files.

### Fresh full-cohort L1 rerun

Do not use the historical SocDoors subject lists for a new full-cohort run. On Linux2, build a readiness manifest from the actual session-aware upstream tree. `ses-02` is never added implicitly; include it explicitly only when the intended rerun covers both sessions.

```bash
cd /ZPOOL/data/projects/rf1-sra-socdoors
mkdir -p logs/runlists logs/L1-20260816

export RF1_SRA_UPSTREAM_ROOT=/ZPOOL/data/projects/rf1-sra-linux2

# Use a new output root so the fresh rerun cannot overwrite historical FEAT trees.
export FSL_DERIVATIVES_ROOT=/ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl-20260816

python3 code/build_L1_manifest.py \
  --sessions 01,02 \
  --output logs/runlists/L1-ready-20260816.tsv \
  --missing-output logs/runlists/L1-missing-20260816.tsv

# Generate canonical EVs for exactly the ready manifest units.
bash code/run_gen3colfiles.sh \
  --manifest logs/runlists/L1-ready-20260816.tsv \
  --jobs 16

# Validate every path.
bash code/run_L1stats.sh \
  --manifest logs/runlists/L1-ready-20260816.tsv \
  --jobs 50 --dry-run

# Run a four-subject-session (eight-task) pilot. Completed pilot outputs will
# be detected and skipped when the full manifest is launched afterward.
awk 'NR == 1 || (NR >= 2 && NR <= 9)' \
  logs/runlists/L1-ready-20260816.tsv \
  > logs/runlists/L1-pilot-20260816.tsv
bash code/run_L1stats.sh \
  --manifest logs/runlists/L1-pilot-20260816.tsv \
  --ppi 0 --jobs 8 \
  --log-dir logs/L1-pilot-20260816

# Full activation launch: at most 50 FEAT processes, one log per unit.
bash code/run_L1stats.sh \
  --manifest logs/runlists/L1-ready-20260816.tsv \
  --ppi 0 --jobs 50 \
  --log-dir logs/L1-20260816
```

Review the manifest summary before launching. A fully paired subject-session contributes two task rows, so approximately 359 paired sessions would produce approximately 718 L1 work units. Confirm CPU and memory headroom for 50 simultaneous FEAT jobs on Linux2; reduce `--jobs` if the host is shared or memory pressure is high.

L3 is intentionally conservative. The current wrapper defaults to the historical `n=98` Social Doors activation design; confirm its cohort and design are appropriate before running it:

```bash
bash code/run_L3stats.sh --dry-run
```

The stored n=98 template references historical task-specific L1 cope paths rather than the canonical L2 outputs, and one ordered path lacks a participant directory. The worker will refuse to run when these paths are absent. Deciding whether a repaired group model should consume L1 or L2 is a scientific workflow decision and remains unresolved here.

## Public teaching quick start

See [`notebooks/README.md`](notebooks/README.md), then run in order:

1. `01_download_and_preprocess.ipynb` — retrieve only `sub-10317` from ds005123 v1.1.3 and run focused fMRIPrep.
2. `02_first_level_feat.ipynb` — use this repository's event conversion and L1 activation workflow for both reward tasks.

The teaching nuisance model uses a documented fMRIPrep-only subset to keep the exercise tractable. Production analyses instead use the canonical TEDANA-enhanced confounds from Linux2.

## Repository layout

| Path | Contents |
| --- | --- |
| `code/` | Production L1/L2/L3 scripts, shared configuration, validation, and retained historical analyses. |
| `templates/` | FEAT `.fsf` model definitions and historical group-design exports. |
| `masks/` | Seed masks and result-derived masks; provenance gaps are documented rather than inferred. |
| `derivatives/` | Lightweight, intentionally tracked EVs, extracted values, and result assets; generated FEAT trees are ignored. |
| `MRIcroGL/` | MRIcroGL-ready result maps and screenshots used for visual communication. |
| `imaging_plots/` | Coordinate/value text files used by historical imaging figures. |
| `notebooks/` | Two public, introductory Neurodesk notebooks. |
| `tests/` | Synthetic event and path-contract checks; no participant data. |

The root `mriqc-metrics_DoorsSocDoors_n_ses-01.csv` is a retained session-01 QC summary, not a preprocessing input.

## Reproducibility and validation

The scientific model is defined by the active `.fsf` files in `templates/`; the shell scripts substitute paths and volume counts without changing contrasts or FEAT parameters. Upstream requirements are canonical BIDS events, fMRIPrep outputs in `MNI152NLin6Asym`, and Linux2 TEDANA-enhanced nuisance regressors. FSL provides `fslnvols`, FEAT, and PPI time-series tools.

Run the lightweight checks with:

```bash
make test
```

The checks cover active shell syntax, obsolete production paths, synthetic BIDS-to-3-column conversion, optional missed trials, and exact L1-to-L2 path agreement. ShellCheck is used when installed.

## Historical notes

Earlier versions of this repository read behavioral events from `rf1-sra/stimuli` and imaging derivatives from `rf1-sra-data`. Those are obsolete production dependencies. Historical group templates, covariates, plotting code, and result files remain for research provenance; they are not silently promoted to the current workflow. See [`code/WORKFLOW_AUDIT.md`](code/WORKFLOW_AUDIT.md) for the conservative classification.

The final authoritative L3 cohort, covariate order, L1-versus-L2 inputs, and relationship among the many historical group models still require scientific confirmation. This cleanup does not change sample sizes, exclusions, covariates, task definitions, EVs, contrasts, smoothing, thresholds, ROIs, or PPI definitions.

## Acknowledgments

This work was supported in part by NIH grants R03-DA046733 (DVS) and R15-MH122927 (DSF). DVS was a Research Fellow of the Public Policy Lab at Temple University during the 2019–2020 academic year.
