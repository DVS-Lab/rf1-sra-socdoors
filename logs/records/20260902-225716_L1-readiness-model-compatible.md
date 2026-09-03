# Run Record: L1-readiness-model-compatible

- Timestamp: 20260902-225716
- Branch: main
- Commit: e51699a
- Host: CLA19787.tu.temple.edu
- User: tug87422
- Working directory: `/ZPOOL/data/projects/rf1-sra-socdoors`
- Raw log: `/ZPOOL/data/projects/rf1-sra-socdoors/logs/runs/20260902-225716_L1-readiness-model-compatible.log`
- Command exit: 0
- Check exit: none
- Summary: COMMAND COMPLETED: no check command provided.

## Command

```bash
python3 code/build_L1_manifest.py --sessions 01\,02 --output logs/runlists/L1-ready.tsv --missing-output logs/runlists/L1-missing.tsv
```

## Full Log

```text
RUN START: 20260902-225716
PROJECT_ROOT: /ZPOOL/data/projects/rf1-sra-socdoors
GIT: main e51699a
HOST: CLA19787.tu.temple.edu
USER: tug87422
PWD: /ZPOOL/data/projects/rf1-sra-socdoors
COMMAND: python3 code/build_L1_manifest.py --sessions 01\,02 --output logs/runlists/L1-ready.tsv --missing-output logs/runlists/L1-missing.tsv

Subjects considered: 354
Source-excluded subjects skipped: 2
BIDS session directories considered: 379
Ready L1 task units: 725
Fully paired subject-sessions (doors+socialdoors): 360
Partially ready subject-sessions: 5
Subject-sessions with zero ready tasks: 14
Ready manifest: /ZPOOL/data/projects/rf1-sra-socdoors/logs/runlists/L1-ready.tsv
Missing-input report: /ZPOOL/data/projects/rf1-sra-socdoors/logs/runlists/L1-missing.tsv

COMMAND EXIT: 0
```
