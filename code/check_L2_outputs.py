#!/usr/bin/env python3
"""Check manifest-selected L2 FEAT outputs."""

from __future__ import annotations

import argparse
import csv
import os
import re
import sys
import tempfile
from pathlib import Path


MANIFEST_FIELDS = ["subject", "session"]
TYPE_RE = re.compile(r"^(?:act|ppi_seed-[A-Za-z0-9._-]+|nppi-(?:dmn|ecn))$")


def parse_args() -> argparse.Namespace:
    project_root = Path(__file__).resolve().parent.parent
    default_fsl_root = Path(
        os.environ.get("FSL_DERIVATIVES_ROOT", project_root / "derivatives" / "fsl")
    )
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", required=True, type=Path)
    parser.add_argument("--types", default="act", help="Comma-separated L2 types")
    parser.add_argument("--fsl-root", type=Path, default=default_fsl_root)
    parser.add_argument("--missing-output", type=Path)
    return parser.parse_args()


def nonempty_file(path: Path) -> bool:
    return path.is_file() and path.stat().st_size > 0


def load_manifest(path: Path) -> list[dict[str, str]]:
    if not path.is_file():
        raise ValueError(f"manifest not found: {path}")
    rows: list[dict[str, str]] = []
    seen: set[tuple[str, str]] = set()
    with path.open(newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle, delimiter="\t")
        if reader.fieldnames != MANIFEST_FIELDS:
            raise ValueError(
                f"manifest header must be exactly: {' '.join(MANIFEST_FIELDS)}"
            )
        for line_number, raw in enumerate(reader, start=2):
            row = {field: (raw.get(field) or "").strip() for field in MANIFEST_FIELDS}
            if not all(row.values()):
                raise ValueError(f"empty manifest field on line {line_number}")
            key = tuple(row[field] for field in MANIFEST_FIELDS)
            if key in seen:
                raise ValueError(f"duplicate manifest row on line {line_number}: {key}")
            seen.add(key)
            rows.append(row)
    if not rows:
        raise ValueError("manifest has no data rows")
    return rows


def parse_types(value: str) -> list[str]:
    types = [item.strip() for item in value.split(",") if item.strip()]
    if not types:
        raise ValueError("--types must contain at least one analysis type")
    invalid = [item for item in types if not TYPE_RE.fullmatch(item)]
    if invalid:
        raise ValueError(f"unsupported analysis type(s): {', '.join(invalid)}")
    if len(types) != len(set(types)):
        raise ValueError("--types contains a duplicate analysis type")
    return types


def output_directory(root: Path, row: dict[str, str], analysis_type: str) -> Path:
    subject = row["subject"].removeprefix("sub-")
    session = row["session"].removeprefix("ses-")
    return (
        root
        / f"sub-{subject}"
        / f"ses-{session}"
        / f"L2_task-socialdoors_ses-{session}_model-1_type-{analysis_type}_sm-5.gfeat"
    )


def check_model(
    root: Path, row: dict[str, str], analysis_type: str
) -> tuple[Path, list[str]]:
    gfeat_dir = output_directory(root, row, analysis_type)
    if not gfeat_dir.is_dir():
        return gfeat_dir, ["GFEAT directory"]

    missing: list[str] = []
    cope_count = 4 if analysis_type == "act" else 5
    for cope in range(1, cope_count + 1):
        cope_root = Path(f"cope{cope}.feat")
        for relative in (
            cope_root / "mask.nii.gz",
            cope_root / "report.html",
            cope_root / "cluster_mask_zstat1.nii.gz",
            cope_root / "stats" / "cope1.nii.gz",
            cope_root / "stats" / "zstat1.nii.gz",
        ):
            if not nonempty_file(gfeat_dir / relative):
                missing.append(str(relative))
    return gfeat_dir, missing


def write_report(path: Path, failures: list[dict[str, str]]) -> None:
    fields = MANIFEST_FIELDS + ["type", "missing", "gfeat_directory"]
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary_name = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        with os.fdopen(fd, "w", newline="", encoding="utf-8") as handle:
            writer = csv.DictWriter(
                handle, delimiter="\t", fieldnames=fields, lineterminator="\n"
            )
            writer.writeheader()
            writer.writerows(failures)
        os.replace(temporary_name, path)
    except BaseException:
        Path(temporary_name).unlink(missing_ok=True)
        raise


def main() -> int:
    args = parse_args()
    try:
        rows = load_manifest(args.manifest)
        analysis_types = parse_types(args.types)
    except ValueError as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 2

    failures: list[dict[str, str]] = []
    for row in rows:
        for analysis_type in analysis_types:
            gfeat_dir, missing = check_model(args.fsl_root, row, analysis_type)
            if missing:
                failures.append(
                    {
                        **row,
                        "type": analysis_type,
                        "missing": ";".join(missing),
                        "gfeat_directory": str(gfeat_dir),
                    }
                )

    if args.missing_output:
        write_report(args.missing_output, failures)

    model_count = len(rows) * len(analysis_types)
    print(f"Manifest subject-sessions checked: {len(rows)}")
    print(f"L2 models checked: {model_count}")
    print(f"Complete models: {model_count - len(failures)}")
    print(f"Incomplete models: {len(failures)}")
    if failures:
        print("\nFirst incomplete models:")
        for failure in failures[:30]:
            print(
                "\t".join(
                    failure[field]
                    for field in MANIFEST_FIELDS + ["type", "missing"]
                )
            )
        if args.missing_output:
            print(f"\nFull report: {args.missing_output}")
        print("CHECK FAILED: one or more requested L2 models are incomplete.")
        return 1

    print(f"CHECK PASSED: all {model_count} requested L2 models are complete.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
