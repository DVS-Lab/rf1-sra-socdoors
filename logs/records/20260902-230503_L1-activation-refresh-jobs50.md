# Run Record: L1-activation-refresh-jobs50

- Timestamp: 20260902-230503
- Branch: main
- Commit: 5098d7f
- Host: CLA19787.tu.temple.edu
- User: tug87422
- Working directory: `/ZPOOL/data/projects/rf1-sra-socdoors`
- Raw log: `/ZPOOL/data/projects/rf1-sra-socdoors/logs/runs/20260902-230503_L1-activation-refresh-jobs50.log`
- Command exit: 0
- Check exit: 0
- Summary: CHECK PASSED: all 725 requested L1 models are complete.

## Command

```bash
bash code/run_L1stats.sh --manifest logs/runlists/L1-ready.tsv --ppi 0 --jobs 50 --overwrite --log-dir logs/L1-activation-refresh
```

## Check

```bash
python3 code/check_L1_outputs.py --manifest logs/runlists/L1-ready.tsv --types act --missing-output logs/runlists/L1-act-incomplete.tsv
```
