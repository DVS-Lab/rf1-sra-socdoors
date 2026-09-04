#!/usr/bin/env python3
"""Build a paired subject/session L2 manifest from an L1 readiness manifest."""

from __future__ import annotations

import argparse
import csv
import os
import sys
import tempfile
from collections import defaultdict
from pathlib import Path


L1_FIELDS = ["subject", "session", "task", "run"]
L2_FIELDS = ["subject", "session"]
REQUIRED_TASKS = {"doors", "socialdoors"}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--l1-manifest", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument(
        "--partial-output",
        type=Path,
        help="Optional TSV report for subject-sessions missing one required task",
    )
    return parser.parse_args()


def atomic_write(path: Path, fields: list[str], rows: list[dict[str, str]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary_name = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        with os.fdopen(fd, "w", newline="", encoding="utf-8") as handle:
            writer = csv.DictWriter(
                handle, delimiter="\t", fieldnames=fields, lineterminator="\n"
            )
            writer.writeheader()
            writer.writerows(rows)
        os.replace(temporary_name, path)
    except BaseException:
        Path(temporary_name).unlink(missing_ok=True)
        raise


def load_l1(path: Path) -> list[dict[str, str]]:
    if not path.is_file():
        raise ValueError(f"L1 manifest not found: {path}")
    rows: list[dict[str, str]] = []
    seen: set[tuple[str, str, str, str]] = set()
    with path.open(newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle, delimiter="\t")
        if reader.fieldnames != L1_FIELDS:
            raise ValueError(f"L1 manifest header must be exactly: {' '.join(L1_FIELDS)}")
        for line_number, raw in enumerate(reader, start=2):
            row = {field: (raw.get(field) or "").strip() for field in L1_FIELDS}
            if not all(row.values()):
                raise ValueError(f"empty L1 manifest field on line {line_number}")
            if row["task"] not in REQUIRED_TASKS:
                raise ValueError(f"unsupported task on line {line_number}: {row['task']}")
            if row["run"] != "1":
                raise ValueError(
                    f"L2 currently combines run 1 only; found run {row['run']} on line {line_number}"
                )
            key = tuple(row[field] for field in L1_FIELDS)
            if key in seen:
                raise ValueError(f"duplicate L1 manifest row on line {line_number}: {key}")
            seen.add(key)
            rows.append(row)
    if not rows:
        raise ValueError("L1 manifest has no data rows")
    return rows


def main() -> int:
    args = parse_args()
    try:
        l1_rows = load_l1(args.l1_manifest)
    except ValueError as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 2

    tasks_by_unit: dict[tuple[str, str], set[str]] = defaultdict(set)
    for row in l1_rows:
        key = (row["subject"].removeprefix("sub-"), row["session"].removeprefix("ses-"))
        tasks_by_unit[key].add(row["task"])

    paired: list[dict[str, str]] = []
    partial: list[dict[str, str]] = []
    for (subject, session), tasks in sorted(tasks_by_unit.items()):
        missing = sorted(REQUIRED_TASKS - tasks)
        if not missing:
            paired.append({"subject": subject, "session": session})
        else:
            partial.append(
                {
                    "subject": subject,
                    "session": session,
                    "present_tasks": "+".join(sorted(tasks)),
                    "missing_tasks": "+".join(missing),
                }
            )

    atomic_write(args.output, L2_FIELDS, paired)
    if args.partial_output:
        atomic_write(
            args.partial_output,
            L2_FIELDS + ["present_tasks", "missing_tasks"],
            partial,
        )

    print(f"L1 task units considered: {len(l1_rows)}")
    print(f"Subject-sessions considered: {len(tasks_by_unit)}")
    print(f"Paired L2 subject-sessions: {len(paired)}")
    print(f"Partial subject-sessions omitted: {len(partial)}")
    print(f"L2 manifest: {args.output.resolve()}")
    if args.partial_output:
        print(f"Partial-unit report: {args.partial_output.resolve()}")
    if not paired:
        print("ERROR: no paired L2 subject-sessions were found.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
