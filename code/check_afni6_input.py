"""Read-only check against the completed Linux2 evaluation (no smoothing or QC decisions)."""
import csv
import hashlib
import json
import math
from pathlib import Path
import sys


def digest(path):
    sha = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(2**20), b""):
            sha.update(block)
    return sha.hexdigest()


def verify(image, source):
    root = image.parents[2]
    if json.loads((root / "validation.json").read_text())["technical_complete"] is not True:
        raise ValueError("No completed evaluation")
    with (root / "run_results.tsv").open() as stream:
        row, = (r for r in csv.DictReader(stream, delimiter="\t") if r["output_bold"] == str(image))
    receipt = json.loads((image.parent / "receipt.json").read_text())
    mask = source.with_name(source.name.replace("_desc-preproc_bold.", "_desc-brain_mask."))
    if (source == mask or Path(row["input_bold"]).resolve() != source.resolve()
            or Path(row["input_mask"]).resolve() != mask.resolve()
            or row["status"] not in {"within_tolerance", "outside_tolerance"}
            or receipt["target_mm"] != 6
            or receipt["input_hashes"] != {"input_bold": digest(source), "input_mask": digest(mask)}
            or receipt["output_sha256"] != digest(image)
            or receipt["measurement_sha256"] != digest(image.parent / "after.tsv")):
        raise ValueError("AFNI input identity, target, or file fingerprint mismatch")
    with (image.parent / "after.tsv").open() as stream:
        after, = csv.DictReader(stream, delimiter="\t")
    achieved = float(after["classic_fwhm_combined"])
    if not math.isfinite(achieved) or achieved <= 0 or achieved != float(row["after_classic_fwhm_combined"]):
        raise ValueError("Inconsistent achieved FWHM")
    return achieved


if __name__ == "__main__":
    print(f"Verified AFNI target 6 mm, achieved {verify(*map(Path, sys.argv[1:])):.3f} mm; FEAT smoothing off")
