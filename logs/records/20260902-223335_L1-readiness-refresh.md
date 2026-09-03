# Run Record: L1-readiness-refresh

- Timestamp: 20260902-223335
- Branch: main
- Commit: cf362e9
- Host: CLA19787.tu.temple.edu
- User: tug87422
- Working directory: `/ZPOOL/data/projects/rf1-sra-socdoors`
- Raw log: `/ZPOOL/data/projects/rf1-sra-socdoors/logs/runs/20260902-223335_L1-readiness-refresh.log`
- Command exit: 0
- Check exit: none
- Summary: COMMAND COMPLETED: no check command provided.

## Command

```bash
python3 code/build_L1_manifest.py --sessions 01\,02 --output logs/runlists/L1-ready.tsv --missing-output logs/runlists/L1-missing.tsv
```

## Full Log

```text
RUN START: 20260902-223335
PROJECT_ROOT: /ZPOOL/data/projects/rf1-sra-socdoors
GIT: main cf362e9
HOST: CLA19787.tu.temple.edu
USER: tug87422
PWD: /ZPOOL/data/projects/rf1-sra-socdoors
COMMAND: python3 code/build_L1_manifest.py --sessions 01\,02 --output logs/runlists/L1-ready.tsv --missing-output logs/runlists/L1-missing.tsv

Subjects considered: 354
Source-excluded subjects skipped: 2
BIDS session directories considered: 379
Ready L1 task units: 727
Fully paired subject-sessions (doors+socialdoors): 361
Partially ready subject-sessions: 5
Subject-sessions with zero ready tasks: 13
Ready manifest: /ZPOOL/data/projects/rf1-sra-socdoors/logs/runlists/L1-ready.tsv
Missing-input report: /ZPOOL/data/projects/rf1-sra-socdoors/logs/runlists/L1-missing.tsv

COMMAND EXIT: 0
```
