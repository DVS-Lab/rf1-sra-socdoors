# Derivatives

This repository tracks only lightweight derivatives needed for provenance and figures. Large, reproducible outputs belong in the configured analysis workspace and are ignored.

- `fsl/EVfiles/` contains historical FSL 3-column EVs. New runs use the session-aware layout `sub-*/ses-*/<task>/run-<n>_<event>.txt`.
- `imaging_plots/` contains extracted values and selected result maps used in figures or presentations.
- Generated participant `.feat`, `.gfeat`, rendered `.fsf`, notebook downloads, and fMRIPrep trees are not intended for Git.

Production upstream fMRIPrep and confound products live in `rf1-sra-linux2`; they are consumed, not copied, by this repository.
