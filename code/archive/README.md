# Archived code

This folder contains scripts that are clearly outside the current production path but remain useful for provenance.

`L1stats-hpc.sh` is the former PBS/GPFS submission implementation. It references the retired `rf1-sra-data` layout and must not be used for current analyses. The active equivalent is `../run_L1stats.sh`, which calls `../L1stats.sh` against configured Linux2 outputs.
