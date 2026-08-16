# Neurodesk teaching notebooks

These two short notebooks teach the downstream workflow without requiring access to Linux2. They use only public OpenNeuro data and call the same repository event/L1 scripts and FEAT templates used by production.

## Neurodesk Play

1. Launch [Neurodesk Play](https://play.neurodesk.org/) in a browser.
2. Wait for JupyterLab to start.
3. Open a Terminal from the JupyterLab launcher.
4. Clone this repository:

   ```bash
   git clone https://github.com/DVS-Lab/rf1-sra-socdoors.git
   ```

5. In the file browser, open `rf1-sra-socdoors/notebooks/`.
6. Start with `01_download_and_preprocess.ipynb`, then run `02_first_level_feat.ipynb`.

The notebooks load pinned Neurodesk modules internally with `await module.load(...)`. First-time container loads may take a few minutes. fMRIPrep can take several hours and may exceed the practical limits of a short Play session. Play storage is not permanent indefinitely, so copy important outputs elsewhere. The same notebooks can be run from a local Neurodesk or HPC environment after cloning this repository.

## Contents

- `01_download_and_preprocess.ipynb` installs OpenNeuro `ds005123` at snapshot `1.1.3`, retrieves only the anatomical/fieldmap/Doors/Social Doors files needed for public participant `sub-10317`, and runs fMRIPrep 25.2.5 for those two tasks.
- `02_first_level_feat.ipynb` previews BIDS events, calls `gen3colfiles.sh`, creates a clearly labeled simplified fMRIPrep-only nuisance file, and runs the existing model-1 activation templates for both tasks with FSL 6.0.7.22.

## Production difference

The teaching workflow uses a nuisance subset containing cosine terms, non-steady-state regressors, six motion parameters, six aCompCor components, and framewise displacement.

> This nuisance model is simplified for teaching and is not an exact reproduction of the production RF1-SRA analysis, which uses the canonical TEDANA-enhanced confounds from `rf1-sra-linux2`.

No public-data simplification changes the production defaults in `code/project_config.sh`.

## Storage layout

Both notebooks use `~/socialdoors_teaching/` by default:

```text
socialdoors_teaching/
├── ds005123/            # DataLad dataset
├── derivatives/         # fMRIPrep BIDS derivatives
├── fsl/                 # EVs and FEAT outputs
├── teaching_confounds/  # simplified nuisance files
├── scratch/             # fMRIPrep working directory
└── bids_filters.json
```

The notebooks are restartable: selective DataLad retrieval is idempotent, existing complete fMRIPrep task outputs are reused, EV replacement is explicit, and complete FEAT outputs are skipped.

## Requirements and safety

- Obtain a free personal FreeSurfer license from the [FreeSurfer registration page](https://surfer.nmr.mgh.harvard.edu/registration.html) and save it as `~/.license`. The notebook stops with a friendly message if it is missing; no credential is embedded.
- Expect a substantial download and compute time for multi-echo fMRI.
- Do not commit `~/socialdoors_teaching/` outputs to this repository.
- The public dataset is frozen to `ds005123` version `1.1.3` for the exercise.

The section order and explicit version loading follow the [Neurodesk EDU notebook guidance](https://neurodesk.org/edu/examples/template.html), making later adaptation to the EDU examples collection straightforward.
