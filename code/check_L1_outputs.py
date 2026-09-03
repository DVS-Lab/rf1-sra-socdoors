#!/usr/bin/env python3
"""Check manifest-selected L1 FEAT outputs without reading participant data."""

from __future__ import annotations

import argparse
import csv
import os
import re
import sys
import tempfile
from pathlib import Path


MANIFEST_FIELDS = ["subject", "session", "task", "run"]
TYPE_RE = re.compile(r"^(?:act|ppi_seed-[A-Za-z0-9._-]+|nppi-(?:dmn|ecn))$")
NUM_CONTRASTS_RE = re.compile(r"^/NumContrasts\s+(\d+)\s*$", re.MULTILINE)


def parse_args() -> argparse.Namespace:
    project_root = Path(__file__).resolve().parent.parent
    default_fsl_root = Path(
        os.environ.get("FSL_DERIVATIVES_ROOT", project_root / "derivatives" / "fsl")
    )
    parser = argparse.ArgumentParser(
        description="Verify L1 FEAT outputs for every row of a readiness manifest."
    )
    parser.add_argument("--manifest", required=True, type=Path)
    parser.add_argument(
        "--types",
        default="act",
        help="Comma-separated analysis types (default: act), e.g. act,ppi_seed-VS",
    )
    parser.add_argument("--fsl-root", type=Path, default=default_fsl_root)
    parser.add_argument(
        "--missing-output",
        type=Path,
        help="Optional TSV report with one row per incomplete model",
    )
    return parser.parse_args()


def nonempty_file(path: Path) -> bool:
    return path.is_file() and path.stat().st_size > 0


def load_manifest(path: Path) -> list[dict[str, str]]:
    if not path.is_file():
        raise ValueError(f"manifest not found: {path}")
    with path.open(newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle, delimiter="\t")
        if reader.fieldnames != MANIFEST_FIELDS:
            raise ValueError(
                f"manifest header must be exactly: {' '.join(MANIFEST_FIELDS)}"
            )
        rows: list[dict[str, str]] = []
        seen: set[tuple[str, str, str, str]] = set()
        for line_number, raw in enumerate(reader, start=2):
            row = {field: (raw.get(field) or "").strip() for field in MANIFEST_FIELDS}
            if not all(row.values()):
                raise ValueError(f"empty manifest field on line {line_number}")
            if row["task"] not in {"doors", "socialdoors"}:
                raise ValueError(f"unsupported task on line {line_number}: {row['task']}")
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


def feat_directory(root: Path, row: dict[str, str], analysis_type: str) -> Path:
    sub = row["subject"].removeprefix("sub-")
    session = row["session"].removeprefix("ses-")
    return (
        root
        / f"sub-{sub}"
        / f"ses-{session}"
        / (
            f"L1_task-{row['task']}_ses-{session}_model-1_type-{analysis_type}_"
            f"run-{row['run']}_sm-5.feat"
        )
    )


def check_model(
    root: Path, row: dict[str, str], analysis_type: str
) -> tuple[Path, list[str]]:
    feat_dir = feat_directory(root, row, analysis_type)
    if not feat_dir.is_dir():
        return feat_dir, ["FEAT directory"]

    missing: list[str] = []
    required = [
        "design.mat",
        "design.con",
        "mask.nii.gz",
        "report.html",
        "cluster_mask_zstat1.nii.gz",
    ]
    for relative in required:
        if not nonempty_file(feat_dir / relative):
            missing.append(relative)

    design_con = feat_dir / "design.con"
    if nonempty_file(design_con):
        match = NUM_CONTRASTS_RE.search(design_con.read_text(encoding="utf-8"))
        if not match:
            missing.append("valid /NumContrasts in design.con")
        else:
            for contrast in range(1, int(match.group(1)) + 1):
                for image in (f"stats/cope{contrast}.nii.gz", f"stats/zstat{contrast}.nii.gz"):
                    if not nonempty_file(feat_dir / image):
                        missing.append(image)

    if analysis_type.startswith("ppi_seed-"):
        seed = analysis_type.removeprefix("ppi_seed-")
        sub = row["subject"].removeprefix("sub-")
        session = row["session"].removeprefix("ses-")
        series = (
            root
            / f"sub-{sub}"
            / f"ses-{session}"
            / (
                f"ts_task-{row['task']}_ses-{session}_mask-{seed}_"
                f"run-{row['run']}.txt"
            )
        )
        if not nonempty_file(series):
            missing.append("physiological time series")

    return feat_dir, missing


def write_report(path: Path, failures: list[dict[str, str]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary_name = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        with os.fdopen(fd, "w", newline="", encoding="utf-8") as handle:
            writer = csv.DictWriter(
                handle,
                delimiter="\t",
                fieldnames=MANIFEST_FIELDS + ["type", "missing", "feat_directory"],
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
            feat_dir, missing = check_model(args.fsl_root, row, analysis_type)
            if missing:
                failures.append(
                    {
                        **row,
                        "type": analysis_type,
                        "missing": ";".join(missing),
                        "feat_directory": str(feat_dir),
                    }
                )

    if args.missing_output:
        write_report(args.missing_output, failures)

    model_count = len(rows) * len(analysis_types)
    print(f"Manifest units checked: {len(rows)}")
    print(f"Analysis models checked: {model_count}")
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
        print("CHECK FAILED: one or more requested L1 models are incomplete.")
        return 1

    print(f"CHECK PASSED: all {model_count} requested L1 models are complete.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
