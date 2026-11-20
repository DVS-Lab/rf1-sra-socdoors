"""Render production seed PPI against a synthetic BOLD with known regional means."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

try:
    import nibabel as nib
    import numpy as np
except ImportError:
    nib = None


ROOT = Path(__file__).resolve().parents[1]
SEEDS = ("vmpfc", "ffa_left", "ffa_right", "ffa_bilateral")


@unittest.skipUnless(nib and shutil.which("fslnvols") and shutil.which("fslmeants"),
                     "requires nibabel, numpy and FSL")
class LocalizerSeeds(unittest.TestCase):
    def test_production_regressor_and_output(self):
        images = [nib.load(ROOT/"masks"/f"seed-{seed}.nii.gz") for seed in SEEDS]
        ref = images[0]
        masks = [np.asarray(im.dataobj) for im in images]
        for im, m in zip(images, masks):
            np.testing.assert_array_equal(im.affine, ref.affine)
            np.testing.assert_array_equal(np.unique(m), [0, 1])
        self.assertEqual([int(m.sum()) for m in masks], [27, 27, 27, 54])
        xyz = nib.affines.apply_affine(ref.affine, np.indices(ref.shape).reshape(3, -1).T)
        for m, center in zip(masks[:3], [(-4.6,46.8,-6.66),(-42.4,-50.4,-21.51),(44,-45,-21.51)]):
            np.testing.assert_array_equal(m.ravel(), np.linalg.norm(xyz-center, axis=1) <= 5)
        np.testing.assert_array_equal(masks[-1], masks[1] | masks[2])
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            ev, fsl = root/"ev", root/"fsl"
            sub = fsl/"sub-10001/ses-01"
            conf = root/"conf.tsv"
            conf.write_text("0\n1\n0\n1\n")
            env = dict(os.environ, FSL_DERIVATIVES_ROOT=str(fsl), EV_FILES_ROOT=str(ev))
            for task, base in (("doors",100), ("socialdoors",200)):
                prefix = ev/"sub-10001/ses-01"/task
                prefix.mkdir(parents=True)
                for effect in ("win","loss","decision"):
                    (prefix/f"run-1_{effect}.txt").write_text("1 1 1\n")
                act = sub/f"L1_task-{task}_ses-01_model-1_type-act_run-1_sm-5.feat"
                act.mkdir(parents=True)
                nib.save(ref, act/"mask.nii.gz")
                data = np.zeros((*ref.shape,4), dtype="f4")
                for i, m in enumerate(masks[:3], 1):
                    data[m==1] = base + i*(np.arange(4)+1)
                bold = root/f"{task}.nii.gz"
                nib.save(nib.Nifti1Image(data, ref.affine), bold)
                for seed, factor in zip(SEEDS, (1,2,3,2.5)):
                    subprocess.run(["bash", ROOT/"code/L1stats.sh", "10001", "1", seed, task,
                                    "--bold", bold, "--confounds", conf, "--render-only"],
                                   env=env, check=True, capture_output=True)
                    ts = sub/f"ts_task-{task}_ses-01_mask-{seed}_run-1.txt"
                    np.testing.assert_allclose(np.loadtxt(ts), base + factor*(np.arange(4)+1))
                    fsf = (sub/f"L1_sub-10001_task-{task}_ses-01_model-1_type-ppi_seed-{seed}_run-1.fsf").read_text()
                    self.assertIn(f'set fmri(custom5) "{ts}"', fsf)
                    self.assertIn(f"_type-ppi_seed-{seed}_run-1_sm-5", fsf)
