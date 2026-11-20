import csv
import hashlib
import json
import os
from pathlib import Path
import subprocess
from tempfile import TemporaryDirectory
import unittest


RUNNER = Path(__file__).resolve().parents[1] / "code/L1stats.sh"


class TargetSix(unittest.TestCase):
    def test_render_only_both_tasks_and_input_guard(self):
        with TemporaryDirectory() as tmp:
            root = Path(tmp)
            def put(path, content="fixture"):
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(content)
                return path
            def digest(path):
                return hashlib.sha256(path.read_bytes()).hexdigest()
            tools = root / "bin"
            put(tools / "fslnvols", '#!/bin/sh\necho 10\n').chmod(0o755)
            put(tools / "fslmeants", '#!/bin/sh\nprintf "%s\\n" "$2" > "$4"\n').chmod(0o755)
            evaluation = root / "derivatives/smoothness-evaluation-6mm-v1"
            put(evaluation / "validation.json", '{"technical_complete": true}')
            conf = put(root / "confounds.tsv")
            env = dict(os.environ, RF1_SRA_UPSTREAM_ROOT=tmp, FSL_DERIVATIVES_ROOT=str(root / "fsl"),
                       FMRIPREP_ROOT=str(root / "derivatives/fmriprep"), EV_FILES_ROOT=str(root / "events"),
                       PATH=str(tools) + ":" + os.environ["PATH"])
            for task in ("socialdoors", "doors"):
                stem = f"sub-10317_ses-01_task-{task}_run-1"
                func = root / "derivatives/fmriprep/sub-10317/ses-01/func"
                base = stem + "_part-mag_space-MNI152NLin6Asym_desc-"
                source = put(func / (base + "preproc_bold.nii.gz"))
                mask = put(func / (base + "brain_mask.nii.gz"))
                for event in ("win", "loss", "decision"):
                    put(root / f"events/sub-10317/ses-01/{task}/run-1_{event}.txt")
                directory = evaluation / "runs" / stem
                image = put(directory / (stem + "_space-MNI152NLin6Asym_desc-smoothToFWHM6_bold.nii.gz"))
                after = put(directory / "after.tsv", "classic_fwhm_combined\n5.29\n")
                put(directory / "receipt.json", json.dumps(dict(target_mm=6, output_sha256=digest(image),
                    measurement_sha256=digest(after), input_hashes=dict(input_bold=digest(source),input_mask=digest(mask)))))
                row = dict(input_bold=source,input_mask=mask,output_bold=image,status="outside_tolerance",
                           after_classic_fwhm_combined=5.29)
                with (evaluation / "run_results.tsv").open("w") as stream:
                    writer = csv.DictWriter(stream, fieldnames=row, delimiter="\t")
                    writer.writeheader()
                    writer.writerow(row)
                def run(model, *options):
                    return subprocess.run(["bash",RUNNER,"10317","1",model,task,"--render-only",*options],
                                          env=env,capture_output=True,text=True)
                dest = root / "fsl-afni6/sub-10317/ses-01"
                for model, kind in (("0","act"),("VS","ppi_seed-VS")):
                    proc = run(model,"--afni-target6","--confounds",conf)
                    self.assertEqual(proc.returncode,0,proc.stderr)
                    fsf = (dest / f"L1_sub-10317_task-{task}_ses-01_model-1_type-{kind}_run-1.fsf").read_text()
                    for setting in ('set fmri(smooth) 0', f'set feat_files(1) "{image}"',f'set confoundev_files(1) "{conf}"'):
                        self.assertIn(setting,fsf.splitlines())
                    if model=="0":
                        put(dest / f"L1_task-{task}_ses-01_model-1_type-act_run-1_sm-0.feat/mask.nii.gz")
                    else:
                        self.assertEqual((dest / f"ts_task-{task}_ses-01_mask-VS_run-1.txt").read_text().strip(),str(source))
                self.assertFalse((root / "fsl").exists())
                self.assertNotEqual(run("0","--bold",image,"--confounds",conf).returncode,0)
                self.assertNotEqual(run("0","--afni-target6").returncode,0)
                image.write_text("stale")
                self.assertNotEqual(run("0","--afni-target6","--confounds",conf).returncode,0)
