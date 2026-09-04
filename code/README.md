# Code reference

The active production path is deliberately familiar: `run_L1stats.sh` batches `L1stats.sh`, followed by the equivalent L2 and L3 pairs. `project_config.sh` centralizes only paths and output names; it is not a workflow framework.

## Active workflow

### `project_config.sh`

- **Status:** production configuration/helper
- **Purpose:** Derive the checkout root, define overridable upstream roots, and provide the canonical L1/L2 naming functions.
- **Inputs:** `RF1_SRA_UPSTREAM_ROOT`, `BIDS_ROOT`, `FMRIPREP_ROOT`, `CONFOUNDS_ROOT`, and `FSL_DERIVATIVES_ROOT` environment variables.
- **Outputs:** Shell variables and functions in the caller.
- **Typical command:** `source code/project_config.sh`
- **Called by / calls:** Sourced by active worker scripts; calls no analysis program.
- **Scientific role:** None; it keeps data provenance and naming consistent.
- **Notes / assumptions:** Production defaults point to `/ZPOOL/data/projects/rf1-sra-linux2`.

### `BIDSto3col.sh`

- **Status:** helper
- **Purpose:** Convert BIDS event rows into one FSL 3-column file per `trial_type`.
- **Inputs:** A BIDS `_events.tsv` and output basename.
- **Outputs:** `<basename>_<trial_type>.txt` files.
- **Typical command:** `bash code/BIDSto3col.sh events.tsv /tmp/run-1`
- **Called by / calls:** Called by `gen3colfiles.sh`; uses standard Unix tools and `awk`.
- **Scientific role:** Copies BIDS onset and duration into FEAT EVs with amplitude `1.0`.
- **Notes / assumptions:** Tom Nichols' bidsutils helper, version 1.2 (2016), retained for provenance. Production validation is performed by its wrapper.

### `gen3colfiles.sh`

- **Status:** production worker/helper
- **Purpose:** Resolve canonical, session-aware Linux2 BIDS events and create the repository EV layout.
- **Inputs:** `_events.tsv`, a subject or subject list, session, task, and run.
- **Outputs:** `derivatives/fsl/EVfiles/sub-*/ses-*/<task>/run-<n>_<event>.txt`.
- **Typical command:** `bash code/gen3colfiles.sh --subject 10317 --session 01 --task all`
- **Called by / calls:** Called directly; calls `BIDSto3col.sh`.
- **Scientific role:** Produces decision, win, loss, and optional decision-missed EVs without recreating behavior.
- **Notes / assumptions:** ses-01 and run-1 remain defaults. Missing required columns/events, ambiguous paths, nonnumeric values, and negative durations fail clearly.

### `build_L1_manifest.py`

- **Status:** production readiness helper
- **Purpose:** Discover subject/session/task units that have model-compatible canonical events, fMRIPrep BOLD, and TEDANA-enhanced confounds.
- **Inputs:** Linux2 BIDS/fMRIPrep/confound roots; optional subject list; explicit sessions/tasks.
- **Outputs:** A ready-unit TSV and optional missing-input report.
- **Typical command:** `python3 code/build_L1_manifest.py --sessions 01,02 --output logs/runlists/L1-ready.tsv --missing-output logs/runlists/L1-missing.tsv`
- **Called by / calls:** Called directly before EV/L1 batches; uses only the Python standard library.
- **Scientific role:** None; it inventories complete lower-level inputs and does not select an analysis cohort on scientific grounds.
- **Notes / assumptions:** Defaults to ses-01. Source-excluded Linux2 IDs are skipped unless explicitly included. Each events file must contain `decision`, `win`, and `loss`; `decision-missed` remains optional. Each manifest row is one L1 task unit.

### `run_gen3colfiles.sh`

- **Status:** production batch wrapper
- **Purpose:** Generate EVs for exactly the subject/session/task/run rows in an L1 readiness manifest.
- **Inputs:** Four-column manifest, job count, and overwrite/dry-run flags.
- **Outputs:** The session/run-aware EV files created by `gen3colfiles.sh`.
- **Typical command:** `bash code/run_gen3colfiles.sh --manifest logs/runlists/L1-ready.tsv --jobs 16`
- **Called by / calls:** Called directly; calls `gen3colfiles.sh` once per manifest row.
- **Scientific role:** None beyond enumerating ready BIDS event files.
- **Notes / assumptions:** Duplicate or malformed manifest rows fail before launch.

### `run_logged.sh`

- **Status:** production provenance helper
- **Purpose:** Capture a timestamped raw command log locally and a compact Markdown run record for Git.
- **Inputs:** A label, a command, and an optional post-run checker command.
- **Outputs:** Ignored `logs/runs/*.log` and tracked `logs/records/*.md`.
- **Typical command:** `bash code/run_logged.sh --label L1-readiness --include-full-log -- python3 code/build_L1_manifest.py ...`
- **Called by / calls:** Called directly; runs the exact command supplied after `--`.
- **Scientific role:** None; it records command provenance and status without copying upstream data or committing bulky logs.
- **Notes / assumptions:** Use `--include-full-log` only for concise diagnostics. FEAT output remains in ignored per-unit logs.

### `L1stats.sh`

- **Status:** production worker
- **Purpose:** Render and run one established activation, seed-PPI, or network-PPI FEAT model.
- **Inputs:** One optimally combined fMRIPrep BOLD, TEDANA-enhanced confounds, EVs, an L1 template, and any requested mask.
- **Outputs:** A rendered `.fsf`, one unsuffixed `.feat` directory, and PPI time series when applicable.
- **Typical command:** `bash code/L1stats.sh 10317 1 0 socialdoors --session 01 --dry-run`
- **Called by / calls:** Called by `run_L1stats.sh`; calls FSL (`fslnvols`, `feat`, and PPI utilities when needed).
- **Scientific role:** Implements the established 5-mm, TR 1.615-s L1 model and its existing contrasts.
- **Notes / assumptions:** Activation must precede PPI/nPPI. Missing BOLD, confounds, or required EVs stop the run. A missing decision-missed EV uses FEAT shape 10. `--bold` and `--confounds` support the teaching workspace.

### `run_L1stats.sh`

- **Status:** production batch wrapper
- **Purpose:** Launch selected L1 units with bounded shell job control and propagate child failures.
- **Inputs:** Readiness manifest, or a legacy uniform-session subject selection; PPI selection and job count.
- **Outputs:** The outputs of each `L1stats.sh` call.
- **Typical command:** `bash code/run_L1stats.sh --manifest logs/runlists/L1-ready.tsv --ppi 0 --jobs 50 --log-dir logs/L1-current`
- **Called by / calls:** Called directly; calls `L1stats.sh`.
- **Scientific role:** None beyond enumerating the requested established L1 units.
- **Notes / assumptions:** A manifest supports mixed ses-01/ses-02 units without silently adding sessions. `--log-dir` records one log per unit and the wrapper returns nonzero if any child fails.

### `check_L1_outputs.py`

- **Status:** production completion checker
- **Purpose:** Verify every manifest-selected activation and/or PPI FEAT model after a batch run.
- **Inputs:** Four-column readiness manifest, requested analysis types, and the FSL derivatives root.
- **Outputs:** A terminal summary and optional TSV listing incomplete models and their missing artifacts.
- **Typical command:** `python3 code/check_L1_outputs.py --manifest logs/runlists/L1-ready.tsv --types act,ppi_seed-VS --missing-output logs/runlists/L1-incomplete.tsv`
- **Called by / calls:** Called directly or as the checker for `run_logged.sh`; uses only the Python standard library.
- **Scientific role:** None; it checks mechanical completeness without defining a cohort or interpreting QC flags.
- **Notes / assumptions:** Contrast images are derived from each model's own `design.con`. Deliberately removed large intermediates are not required. Seed-PPI checks include the extracted physiological time series.

### `build_L2_manifest.py`

- **Status:** production pairing helper
- **Purpose:** Derive the exact mixed-session L2 cohort by retaining only subject-sessions with both Doors and Social Doors rows in the current L1 manifest.
- **Inputs:** Validated four-column L1 readiness manifest.
- **Outputs:** Two-column `subject, session` L2 manifest and optional partial-pair report.
- **Typical command:** `python3 code/build_L2_manifest.py --l1-manifest logs/runlists/L1-ready.tsv --output logs/runlists/L2-ready.tsv --partial-output logs/runlists/L2-partial.tsv`
- **Called by / calls:** Called directly before L2; uses only the Python standard library.
- **Scientific role:** Applies only the structural two-task requirement of the established L2 model; it does not apply imaging or behavioral QC exclusions.
- **Notes / assumptions:** L2 currently combines run 1 only. Subject-session identity is retained, so ses-02 is not collapsed into ses-01.

### `L2stats.sh`

- **Status:** production worker
- **Purpose:** Combine Social Doors and monetary Doors L1 estimates within one participant.
- **Inputs:** The two exact canonical L1 `.feat` paths and the matching L2 template.
- **Outputs:** A rendered `.fsf` and `.gfeat` directory.
- **Typical command:** `bash code/L2stats.sh 10317 act --session 01 --dry-run`
- **Called by / calls:** Called by `run_L2stats.sh`; calls FEAT.
- **Scientific role:** Preserves this project's unusual cross-task within-participant L2 comparison.
- **Notes / assumptions:** Both task inputs are required. Naming comes from the same function used by L1, preventing `_Tedana` drift. The worker defaults `FSLSUB_PARALLEL=1` so the batch wrapper's `--jobs` value remains the primary concurrency limit; export another value only when deliberately changing nested FSL parallelism.

### `run_L2stats.sh`

- **Status:** production batch wrapper
- **Purpose:** Launch selected L2 types with bounded shell job control.
- **Inputs:** Current two-column L2 manifest, or a legacy subject/list plus uniform session; analysis types and job count.
- **Outputs:** The outputs of each `L2stats.sh` call.
- **Typical command:** `bash code/run_L2stats.sh --manifest logs/runlists/L2-ready.tsv --types act,ppi_seed-VS --jobs 20 --log-dir logs/L2-current`
- **Called by / calls:** Called directly; calls `L2stats.sh`.
- **Scientific role:** None beyond enumerating participant/type units.
- **Notes / assumptions:** Use the manifest for current production so mixed sessions and partial task pairs are handled correctly. Historical defaults still list activation, VS seed PPI, and DMN nPPI; select only types whose L1 inputs exist.

### `check_L2_outputs.py`

- **Status:** production completion checker
- **Purpose:** Verify every manifest-selected L2 GFEAT and all expected cope outputs.
- **Inputs:** Two-column L2 manifest, requested analysis types, and the FSL derivatives root.
- **Outputs:** Terminal summary and optional TSV listing incomplete models and missing artifacts.
- **Typical command:** `python3 code/check_L2_outputs.py --manifest logs/runlists/L2-ready.tsv --types act,ppi_seed-VS --missing-output logs/runlists/L2-incomplete.tsv`
- **Called by / calls:** Called directly or as the checker for `run_logged.sh`; uses only the Python standard library.
- **Scientific role:** None; it verifies mechanical completeness.
- **Notes / assumptions:** Activation expects four cope directories and PPI/nPPI expects five, matching the established templates.

### `L3stats.sh`

- **Status:** production worker for a historical design
- **Purpose:** Render and run one existing group FEAT template while checking its declared sample size and ordered inputs.
- **Inputs:** Cope number/name, analysis token, task, historical `n`, and the matching L3 template.
- **Outputs:** A rendered group `.fsf` and `.gfeat` directory.
- **Typical command:** `bash code/L3stats.sh 4 win-loss type-act socialdoors --n 98 --dry-run`
- **Called by / calls:** Called by `run_L3stats.sh`; calls FEAT only after validation.
- **Scientific role:** Applies the stored group design without rebuilding it.
- **Notes / assumptions:** The wrapper does not establish that n=98 is the current final cohort. The historical template references L1 rather than L2 and contains one participant-less path, so real input validation currently stops it. The script fixes the former executable-comment and undefined-cleanup-variable bugs but does not guess the missing participant or redesign the input level.

### `run_L3stats.sh`

- **Status:** production batch wrapper for a historical design
- **Purpose:** Enumerate selected group copes and invoke `L3stats.sh`.
- **Inputs:** Task, analysis token, cope specification, historical sample size, and jobs.
- **Outputs:** The outputs of each L3 unit.
- **Typical command:** `bash code/run_L3stats.sh --dry-run`
- **Called by / calls:** Called directly; calls `L3stats.sh`.
- **Scientific role:** Defaults to the stored Social Doors activation win-loss n=98 model.
- **Notes / assumptions:** Scientific confirmation is required before a new production group run.

### `validate_workflow.sh`

- **Status:** validation helper
- **Purpose:** Run active shell syntax/static checks and the synthetic workflow test.
- **Inputs:** Tracked active scripts and `tests/test_workflow.sh`.
- **Outputs:** PASS/SKIP messages and a nonzero status on failure.
- **Typical command:** `bash code/validate_workflow.sh` or `make test`
- **Called by / calls:** Called directly/Make; calls Bash, optional ShellCheck, and the test script.
- **Scientific role:** Prevents plumbing drift; it does not test scientific hypotheses.
- **Notes / assumptions:** The fixture is generated at runtime and contains no participant data.

## Inputs and retained analysis material

- `sublist_full-dataset.txt` remains the legacy default L1/EV batch list; current production uses a generated L1 manifest.
- `sublist_all.txt` remains the legacy default L2 batch list; current production derives a paired L2 manifest from the validated L1 manifest.
- `sublist_model-*.txt`, other subject lists, covariate CSV/XLSX files, and FEAT design exports encode historical model-specific cohorts. Their authority is model-dependent and needs scientific confirmation.
- `MotionOutlierCapture.Rmd`, `OutlierID_SocDoors.py`, and `fdmean-outliers.py` are retained QC analyses, not part of the active L1/L2/L3 execution chain.
- ROI extraction, randomise/PALM, filtered-functional-difference, plotting, MATLAB, and R scripts are retained historical or secondary analyses. They may contain old absolute paths and are not production entry points.

See [`WORKFLOW_AUDIT.md`](WORKFLOW_AUDIT.md) for classification decisions. Files with uncertain scientific provenance were left in place rather than renamed or deleted.
