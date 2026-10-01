# Run Record: L1-L2-session-inventory

- Timestamp: 20261001-190737
- Branch: main
- Commit: 734f127
- Host: CLA19787.tu.temple.edu
- User: tug87422
- Working directory: `/ZPOOL/data/projects/rf1-sra-socdoors`
- Raw log: `/ZPOOL/data/projects/rf1-sra-socdoors/logs/runs/20261001-190737_L1-L2-session-inventory.log`
- Command exit: 0
- Check exit: none
- Summary: CHECK PASSED: session inventory is internally consistent.

## Command

```bash
python3 -
```

## Full Log

```text
RUN START: 20261001-190737
PROJECT_ROOT: /ZPOOL/data/projects/rf1-sra-socdoors
GIT: main 734f127
HOST: CLA19787.tu.temple.edu
USER: tug87422
PWD: /ZPOOL/data/projects/rf1-sra-socdoors
COMMAND: python3 -

| Available input | Session 01 | Session 02 | Total subject-sessions |
|---|---:|---:|---:|
| Both tasks completed, with completed L2 | 334 | 26 | 360 |
| Only one completed L1 task available | 4 | 1 | 5 |
| At least one completed L1 task | 338 | 27 | 365 |

Unique subjects with L1: 340
Unique subjects with L2: 336
Completed L1 task runs: 725

Counts apply to activation and VS PPI, based on previously validated manifests.
This inventory does not recheck derivative files or apply additional scientific exclusions.

CHECK PASSED: session inventory is internally consistent.

COMMAND EXIT: 0
```
