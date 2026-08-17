# Run Records

This directory is intentionally tracked. Use `code/run_logged.sh` to write a
small Markdown provenance record for important workflow commands. Full raw
logs remain local under ignored `logs/runs/`; generated runlists and per-unit
FEAT logs are also ignored.

Use `--include-full-log` for short inventories and validation commands whose
terminal summaries are useful in Git. Do not include full FEAT logs in a run
record.
