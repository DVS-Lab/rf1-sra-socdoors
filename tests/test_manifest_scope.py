import csv
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class ManifestScopeTests(unittest.TestCase):
    def test_expected_slots_roster_and_private_gate(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            bids, excluded = root / "bids", root / "excluded"
            bids.mkdir()
            excluded.mkdir()
            (bids / "participants.tsv").write_text("participant_id\nsub-10001\nsub-10002\n")
            (excluded / "Smith-SRA-10002").mkdir()
            for sub in ("10001", "10002", "10003"):
                stem = f"sub-{sub}_ses-01_task-socialdoors_run-1"
                paths = [bids / f"sub-{sub}/ses-01/func/{stem}_events.tsv",
                         root / f"preproc/sub-{sub}/ses-01/func/{stem}_part-mag_space-MNI152NLin6Asym_desc-preproc_bold.nii.gz",
                         root / f"confounds/sub-{sub}/{stem}_desc-TedanaPlusConfounds.tsv"]
                for path in paths:
                    path.parent.mkdir(parents=True, exist_ok=True)
                    path.write_text("trial_type\ndecision\nwin\nloss\n")
            cmd = [sys.executable, str(ROOT / "code/build_L1_manifest.py"),
                   "--bids-root", str(bids), "--fmriprep-root", str(root / "preproc"),
                   "--confounds-root", str(root / "confounds"), "--source-exclusions-root", str(excluded),
                   "--sessions", "01,02", "--output", str(root / "ready.tsv"),
                   "--missing-output", str(root / "missing.tsv")]
            proc = subprocess.run(cmd, capture_output=True, text=True)
            self.assertEqual(proc.returncode, 0, proc.stderr)
            self.assertEqual((root / "ready.tsv").read_text(), "subject\tsession\ttask\trun\n10001\t01\tsocialdoors\t1\n")
            with (root / "missing.tsv").open() as f:
                missing = list(csv.DictReader(f, delimiter="\t"))
            self.assertEqual(len(missing), 3)
            self.assertEqual({r["task"] for r in missing}, {"doors", "socialdoors"})
            self.assertTrue(all(r["subject"] == "10001" and r["run"] == "1" for r in missing))
            cmd[cmd.index("--source-exclusions-root") + 1] = str(root / "not-mounted")
            self.assertNotEqual(subprocess.run(cmd, capture_output=True).returncode, 0)


if __name__ == "__main__":
    unittest.main()
