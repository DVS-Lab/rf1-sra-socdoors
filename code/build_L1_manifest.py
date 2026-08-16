#!/usr/bin/env python3
"""Build a subject/session/task manifest from complete Linux2 L1 inputs."""

from __future__ import annotations

import argparse
import os
from pathlib import Path
from typing import Iterable


DEFAULT_UPSTREAM = Path(
    os.environ.get("RF1_SRA_UPSTREAM_ROOT", "/ZPOOL/data/projects/rf1-sra-linux2")
)


def comma_values(value: str) -> tuple[str, ...]:
    values = tuple(item.strip().removeprefix("ses-") for item in value.split(",") if item.strip())
    if not values:
        raise argparse.ArgumentTypeError("expected at least one comma-separated value")
    return values


def read_subjects(path: Path) -> list[str]:
    subjects: list[str] = []
    seen: set[str] = set()
    for raw_line in path.read_text().splitlines():
        value = raw_line.split("#", 1)[0].strip().removeprefix("sub-")
        if value and value not in seen:
            subjects.append(value)
            seen.add(value)
    return subjects


def discover_subjects(bids_root: Path) -> list[str]:
    return sorted(path.name.removeprefix("sub-") for path in bids_root.glob("sub-*") if path.is_dir())


def nonempty(path: Path) -> bool:
    return path.is_file() and path.stat().st_size > 0


def atomic_write(path: Path, header: str, rows: Iterable[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(f".{path.name}.tmp")
    temporary.write_text(header + "\n" + "\n".join(rows) + "\n")
    temporary.replace(path)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--bids-root", type=Path, default=DEFAULT_UPSTREAM / "bids")
    parser.add_argument(
        "--fmriprep-root", type=Path, default=DEFAULT_UPSTREAM / "derivatives" / "fmriprep"
    )
    parser.add_argument(
        "--confounds-root",
        type=Path,
        default=DEFAULT_UPSTREAM / "derivatives" / "fsl" / "confounds_tedana",
    )
    parser.add_argument("--sublist", type=Path, help="Optional subject list; otherwise discover BIDS sub-* folders.")
    parser.add_argument("--sessions", type=comma_values, default=("01",), help="Default: 01; use 01,02 explicitly for both sessions.")
    parser.add_argument(
        "--tasks", type=comma_values, default=("doors", "socialdoors"), help="Default: doors,socialdoors"
    )
    parser.add_argument("--run", default="1")
    parser.add_argument("--output", type=Path, required=True, help="Ready-unit TSV manifest.")
    parser.add_argument("--missing-output", type=Path, help="Optional TSV describing incomplete units.")
    parser.add_argument(
        "--source-exclusions-root",
        type=Path,
        default=Path(
            os.environ.get(
                "SOURCEDATA_EXCLUSIONS_ROOT",
                "/ZPOOL/data/sourcedata/sourcedata/rf1-sra-exclusions",
            )
        ),
    )
    parser.add_argument("--include-source-excluded", action="store_true")
    args = parser.parse_args()

    for task in args.tasks:
        if task not in {"doors", "socialdoors"}:
            parser.error(f"unsupported task: {task}")
    if not args.bids_root.is_dir():
        parser.error(f"BIDS root not found: {args.bids_root}")
    if args.sublist and not args.sublist.is_file():
        parser.error(f"subject list not found: {args.sublist}")

    subjects = read_subjects(args.sublist) if args.sublist else discover_subjects(args.bids_root)
    ready_rows: list[str] = []
    missing_rows: list[str] = []
    excluded: list[str] = []
    session_ready_counts: dict[tuple[str, str], int] = {}
    session_dirs = 0

    for subject in subjects:
        excluded_source = args.source_exclusions_root / f"Smith-SRA-{subject}"
        if not args.include_source_excluded and excluded_source.is_dir():
            excluded.append(subject)
            continue
        for session in args.sessions:
            func_dir = args.bids_root / f"sub-{subject}" / f"ses-{session}" / "func"
            if not func_dir.is_dir():
                missing_rows.append(
                    f"{subject}\t{session}\t*\t{args.run}\tmissing BIDS session func directory"
                )
                continue
            session_dirs += 1
            session_ready_counts[(subject, session)] = 0
            for task in args.tasks:
                stem = f"sub-{subject}_ses-{session}_task-{task}_run-{args.run}"
                events = func_dir / f"{stem}_events.tsv"
                bold = (
                    args.fmriprep_root
                    / f"sub-{subject}"
                    / f"ses-{session}"
                    / "func"
                    / f"{stem}_part-mag_space-MNI152NLin6Asym_desc-preproc_bold.nii.gz"
                )
                confounds = (
                    args.confounds_root
                    / f"sub-{subject}"
                    / f"{stem}_desc-TedanaPlusConfounds.tsv"
                )
                missing = [
                    label
                    for label, path in (("events", events), ("BOLD", bold), ("confounds", confounds))
                    if not nonempty(path)
                ]
                if missing:
                    missing_rows.append(
                        f"{subject}\t{session}\t{task}\t{args.run}\t{','.join(missing)}"
                    )
                    continue
                ready_rows.append(f"{subject}\t{session}\t{task}\t{args.run}")
                session_ready_counts[(subject, session)] += 1

    task_count = len(args.tasks)
    paired_sessions = sum(count == task_count for count in session_ready_counts.values())
    partial_sessions = sum(0 < count < task_count for count in session_ready_counts.values())
    empty_sessions = sum(count == 0 for count in session_ready_counts.values())

    atomic_write(args.output, "subject\tsession\ttask\trun", ready_rows)
    if args.missing_output:
        atomic_write(
            args.missing_output,
            "subject\tsession\ttask\trun\tmissing",
            missing_rows,
        )

    print(f"Subjects considered: {len(subjects)}")
    print(f"Source-excluded subjects skipped: {len(excluded)}")
    print(f"BIDS session directories considered: {session_dirs}")
    print(f"Ready L1 task units: {len(ready_rows)}")
    print(f"Fully paired subject-sessions ({'+'.join(args.tasks)}): {paired_sessions}")
    print(f"Partially ready subject-sessions: {partial_sessions}")
    print(f"Subject-sessions with zero ready tasks: {empty_sessions}")
    print(f"Ready manifest: {args.output.resolve()}")
    if args.missing_output:
        print(f"Missing-input report: {args.missing_output.resolve()}")
    if not ready_rows:
        print("ERROR: no complete L1 units were found.")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
