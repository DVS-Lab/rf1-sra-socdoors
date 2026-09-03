# Run Record: L1-activation-refresh-preflight

- Timestamp: 20260902-224307
- Branch: main
- Commit: bd02675
- Host: CLA19787.tu.temple.edu
- User: tug87422
- Working directory: `/ZPOOL/data/projects/rf1-sra-socdoors`
- Raw log: `/ZPOOL/data/projects/rf1-sra-socdoors/logs/runs/20260902-224307_L1-activation-refresh-preflight.log`
- Command exit: 1
- Check exit: none
- Summary: COMMAND FAILED: exit 1.

## Command

```bash
bash code/run_L1stats.sh --manifest logs/runlists/L1-ready.tsv --ppi 0 --jobs 50 --dry-run
```

## Log Tail

```text
  confounds: /ZPOOL/data/projects/rf1-sra-linux2/derivatives/fsl/confounds_tedana/sub-12037/sub-12037_ses-01_task-doors_run-1_desc-TedanaPlusConfounds.tsv
  EV prefix: /ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/EVfiles/sub-12037/ses-01/doors/run-1
  template: /ZPOOL/data/projects/rf1-sra-socdoors/templates/L1_task-doors_model-1_type-act.fsf
  output: /ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/sub-12037/ses-01/L1_task-doors_ses-01_model-1_type-act_run-1_sm-5.feat
L1 plan
  BOLD: /ZPOOL/data/projects/rf1-sra-linux2/derivatives/fmriprep/sub-12037/ses-01/func/sub-12037_ses-01_task-socialdoors_run-1_part-mag_space-MNI152NLin6Asym_desc-preproc_bold.nii.gz
  confounds: /ZPOOL/data/projects/rf1-sra-linux2/derivatives/fsl/confounds_tedana/sub-12037/sub-12037_ses-01_task-socialdoors_run-1_desc-TedanaPlusConfounds.tsv
  EV prefix: /ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/EVfiles/sub-12037/ses-01/socialdoors/run-1
  template: /ZPOOL/data/projects/rf1-sra-socdoors/templates/L1_task-socialdoors_model-1_type-act.fsf
  output: /ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/sub-12037/ses-01/L1_task-socialdoors_ses-01_model-1_type-act_run-1_sm-5.feat
L1 plan
  BOLD: /ZPOOL/data/projects/rf1-sra-linux2/derivatives/fmriprep/sub-12038/ses-01/func/sub-12038_ses-01_task-doors_run-1_part-mag_space-MNI152NLin6Asym_desc-preproc_bold.nii.gz
  confounds: /ZPOOL/data/projects/rf1-sra-linux2/derivatives/fsl/confounds_tedana/sub-12038/sub-12038_ses-01_task-doors_run-1_desc-TedanaPlusConfounds.tsv
  EV prefix: /ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/EVfiles/sub-12038/ses-01/doors/run-1
  template: /ZPOOL/data/projects/rf1-sra-socdoors/templates/L1_task-doors_model-1_type-act.fsf
  output: /ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/sub-12038/ses-01/L1_task-doors_ses-01_model-1_type-act_run-1_sm-5.feat
L1 plan
  BOLD: /ZPOOL/data/projects/rf1-sra-linux2/derivatives/fmriprep/sub-12038/ses-01/func/sub-12038_ses-01_task-socialdoors_run-1_part-mag_space-MNI152NLin6Asym_desc-preproc_bold.nii.gz
  confounds: /ZPOOL/data/projects/rf1-sra-linux2/derivatives/fsl/confounds_tedana/sub-12038/sub-12038_ses-01_task-socialdoors_run-1_desc-TedanaPlusConfounds.tsv
  EV prefix: /ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/EVfiles/sub-12038/ses-01/socialdoors/run-1
  template: /ZPOOL/data/projects/rf1-sra-socdoors/templates/L1_task-socialdoors_model-1_type-act.fsf
  output: /ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/sub-12038/ses-01/L1_task-socialdoors_ses-01_model-1_type-act_run-1_sm-5.feat
L1 plan
  BOLD: /ZPOOL/data/projects/rf1-sra-linux2/derivatives/fmriprep/sub-12039/ses-01/func/sub-12039_ses-01_task-doors_run-1_part-mag_space-MNI152NLin6Asym_desc-preproc_bold.nii.gz
  confounds: /ZPOOL/data/projects/rf1-sra-linux2/derivatives/fsl/confounds_tedana/sub-12039/sub-12039_ses-01_task-doors_run-1_desc-TedanaPlusConfounds.tsv
  EV prefix: /ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/EVfiles/sub-12039/ses-01/doors/run-1
  template: /ZPOOL/data/projects/rf1-sra-socdoors/templates/L1_task-doors_model-1_type-act.fsf
  output: /ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/sub-12039/ses-01/L1_task-doors_ses-01_model-1_type-act_run-1_sm-5.feat
L1 plan
  BOLD: /ZPOOL/data/projects/rf1-sra-linux2/derivatives/fmriprep/sub-12039/ses-01/func/sub-12039_ses-01_task-socialdoors_run-1_part-mag_space-MNI152NLin6Asym_desc-preproc_bold.nii.gz
  confounds: /ZPOOL/data/projects/rf1-sra-linux2/derivatives/fsl/confounds_tedana/sub-12039/sub-12039_ses-01_task-socialdoors_run-1_desc-TedanaPlusConfounds.tsv
  EV prefix: /ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/EVfiles/sub-12039/ses-01/socialdoors/run-1
  template: /ZPOOL/data/projects/rf1-sra-socdoors/templates/L1_task-socialdoors_model-1_type-act.fsf
  output: /ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/sub-12039/ses-01/L1_task-socialdoors_ses-01_model-1_type-act_run-1_sm-5.feat
L1 plan
  BOLD: /ZPOOL/data/projects/rf1-sra-linux2/derivatives/fmriprep/sub-12041/ses-01/func/sub-12041_ses-01_task-doors_run-1_part-mag_space-MNI152NLin6Asym_desc-preproc_bold.nii.gz
  confounds: /ZPOOL/data/projects/rf1-sra-linux2/derivatives/fsl/confounds_tedana/sub-12041/sub-12041_ses-01_task-doors_run-1_desc-TedanaPlusConfounds.tsv
  EV prefix: /ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/EVfiles/sub-12041/ses-01/doors/run-1
  template: /ZPOOL/data/projects/rf1-sra-socdoors/templates/L1_task-doors_model-1_type-act.fsf
  output: /ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/sub-12041/ses-01/L1_task-doors_ses-01_model-1_type-act_run-1_sm-5.feat
L1 plan
  BOLD: /ZPOOL/data/projects/rf1-sra-linux2/derivatives/fmriprep/sub-12041/ses-01/func/sub-12041_ses-01_task-socialdoors_run-1_part-mag_space-MNI152NLin6Asym_desc-preproc_bold.nii.gz
  confounds: /ZPOOL/data/projects/rf1-sra-linux2/derivatives/fsl/confounds_tedana/sub-12041/sub-12041_ses-01_task-socialdoors_run-1_desc-TedanaPlusConfounds.tsv
  EV prefix: /ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/EVfiles/sub-12041/ses-01/socialdoors/run-1
  template: /ZPOOL/data/projects/rf1-sra-socdoors/templates/L1_task-socialdoors_model-1_type-act.fsf
  output: /ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/sub-12041/ses-01/L1_task-socialdoors_ses-01_model-1_type-act_run-1_sm-5.feat
L1 plan
  BOLD: /ZPOOL/data/projects/rf1-sra-linux2/derivatives/fmriprep/sub-12047/ses-01/func/sub-12047_ses-01_task-doors_run-1_part-mag_space-MNI152NLin6Asym_desc-preproc_bold.nii.gz
  confounds: /ZPOOL/data/projects/rf1-sra-linux2/derivatives/fsl/confounds_tedana/sub-12047/sub-12047_ses-01_task-doors_run-1_desc-TedanaPlusConfounds.tsv
  EV prefix: /ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/EVfiles/sub-12047/ses-01/doors/run-1
  template: /ZPOOL/data/projects/rf1-sra-socdoors/templates/L1_task-doors_model-1_type-act.fsf
  output: /ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/sub-12047/ses-01/L1_task-doors_ses-01_model-1_type-act_run-1_sm-5.feat
L1 plan
  BOLD: /ZPOOL/data/projects/rf1-sra-linux2/derivatives/fmriprep/sub-12047/ses-01/func/sub-12047_ses-01_task-socialdoors_run-1_part-mag_space-MNI152NLin6Asym_desc-preproc_bold.nii.gz
  confounds: /ZPOOL/data/projects/rf1-sra-linux2/derivatives/fsl/confounds_tedana/sub-12047/sub-12047_ses-01_task-socialdoors_run-1_desc-TedanaPlusConfounds.tsv
  EV prefix: /ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/EVfiles/sub-12047/ses-01/socialdoors/run-1
  template: /ZPOOL/data/projects/rf1-sra-socdoors/templates/L1_task-socialdoors_model-1_type-act.fsf
  output: /ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/sub-12047/ses-01/L1_task-socialdoors_ses-01_model-1_type-act_run-1_sm-5.feat
L1 plan
  BOLD: /ZPOOL/data/projects/rf1-sra-linux2/derivatives/fmriprep/sub-12049/ses-01/func/sub-12049_ses-01_task-doors_run-1_part-mag_space-MNI152NLin6Asym_desc-preproc_bold.nii.gz
  confounds: /ZPOOL/data/projects/rf1-sra-linux2/derivatives/fsl/confounds_tedana/sub-12049/sub-12049_ses-01_task-doors_run-1_desc-TedanaPlusConfounds.tsv
  EV prefix: /ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/EVfiles/sub-12049/ses-01/doors/run-1
  template: /ZPOOL/data/projects/rf1-sra-socdoors/templates/L1_task-doors_model-1_type-act.fsf
  output: /ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/sub-12049/ses-01/L1_task-doors_ses-01_model-1_type-act_run-1_sm-5.feat
L1 plan
  BOLD: /ZPOOL/data/projects/rf1-sra-linux2/derivatives/fmriprep/sub-12049/ses-01/func/sub-12049_ses-01_task-socialdoors_run-1_part-mag_space-MNI152NLin6Asym_desc-preproc_bold.nii.gz
  confounds: /ZPOOL/data/projects/rf1-sra-linux2/derivatives/fsl/confounds_tedana/sub-12049/sub-12049_ses-01_task-socialdoors_run-1_desc-TedanaPlusConfounds.tsv
  EV prefix: /ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/EVfiles/sub-12049/ses-01/socialdoors/run-1
  template: /ZPOOL/data/projects/rf1-sra-socdoors/templates/L1_task-socialdoors_model-1_type-act.fsf
  output: /ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/sub-12049/ses-01/L1_task-socialdoors_ses-01_model-1_type-act_run-1_sm-5.feat
L1 plan
  BOLD: /ZPOOL/data/projects/rf1-sra-linux2/derivatives/fmriprep/sub-12051/ses-01/func/sub-12051_ses-01_task-doors_run-1_part-mag_space-MNI152NLin6Asym_desc-preproc_bold.nii.gz
  confounds: /ZPOOL/data/projects/rf1-sra-linux2/derivatives/fsl/confounds_tedana/sub-12051/sub-12051_ses-01_task-doors_run-1_desc-TedanaPlusConfounds.tsv
  EV prefix: /ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/EVfiles/sub-12051/ses-01/doors/run-1
  template: /ZPOOL/data/projects/rf1-sra-socdoors/templates/L1_task-doors_model-1_type-act.fsf
  output: /ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/sub-12051/ses-01/L1_task-doors_ses-01_model-1_type-act_run-1_sm-5.feat
L1 plan
  BOLD: /ZPOOL/data/projects/rf1-sra-linux2/derivatives/fmriprep/sub-12051/ses-01/func/sub-12051_ses-01_task-socialdoors_run-1_part-mag_space-MNI152NLin6Asym_desc-preproc_bold.nii.gz
  confounds: /ZPOOL/data/projects/rf1-sra-linux2/derivatives/fsl/confounds_tedana/sub-12051/sub-12051_ses-01_task-socialdoors_run-1_desc-TedanaPlusConfounds.tsv
  EV prefix: /ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/EVfiles/sub-12051/ses-01/socialdoors/run-1
  template: /ZPOOL/data/projects/rf1-sra-socdoors/templates/L1_task-socialdoors_model-1_type-act.fsf
  output: /ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/sub-12051/ses-01/L1_task-socialdoors_ses-01_model-1_type-act_run-1_sm-5.feat
L1 plan
  BOLD: /ZPOOL/data/projects/rf1-sra-linux2/derivatives/fmriprep/sub-12054/ses-01/func/sub-12054_ses-01_task-doors_run-1_part-mag_space-MNI152NLin6Asym_desc-preproc_bold.nii.gz
  confounds: /ZPOOL/data/projects/rf1-sra-linux2/derivatives/fsl/confounds_tedana/sub-12054/sub-12054_ses-01_task-doors_run-1_desc-TedanaPlusConfounds.tsv
  EV prefix: /ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/EVfiles/sub-12054/ses-01/doors/run-1
  template: /ZPOOL/data/projects/rf1-sra-socdoors/templates/L1_task-doors_model-1_type-act.fsf
  output: /ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/sub-12054/ses-01/L1_task-doors_ses-01_model-1_type-act_run-1_sm-5.feat
L1 plan
  BOLD: /ZPOOL/data/projects/rf1-sra-linux2/derivatives/fmriprep/sub-12054/ses-01/func/sub-12054_ses-01_task-socialdoors_run-1_part-mag_space-MNI152NLin6Asym_desc-preproc_bold.nii.gz
  confounds: /ZPOOL/data/projects/rf1-sra-linux2/derivatives/fsl/confounds_tedana/sub-12054/sub-12054_ses-01_task-socialdoors_run-1_desc-TedanaPlusConfounds.tsv
  EV prefix: /ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/EVfiles/sub-12054/ses-01/socialdoors/run-1
  template: /ZPOOL/data/projects/rf1-sra-socdoors/templates/L1_task-socialdoors_model-1_type-act.fsf
  output: /ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/sub-12054/ses-01/L1_task-socialdoors_ses-01_model-1_type-act_run-1_sm-5.feat
L1 plan
  BOLD: /ZPOOL/data/projects/rf1-sra-linux2/derivatives/fmriprep/sub-12055/ses-01/func/sub-12055_ses-01_task-doors_run-1_part-mag_space-MNI152NLin6Asym_desc-preproc_bold.nii.gz
  confounds: /ZPOOL/data/projects/rf1-sra-linux2/derivatives/fsl/confounds_tedana/sub-12055/sub-12055_ses-01_task-doors_run-1_desc-TedanaPlusConfounds.tsv
  EV prefix: /ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/EVfiles/sub-12055/ses-01/doors/run-1
  template: /ZPOOL/data/projects/rf1-sra-socdoors/templates/L1_task-doors_model-1_type-act.fsf
  output: /ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/sub-12055/ses-01/L1_task-doors_ses-01_model-1_type-act_run-1_sm-5.feat
L1 plan
  BOLD: /ZPOOL/data/projects/rf1-sra-linux2/derivatives/fmriprep/sub-12055/ses-01/func/sub-12055_ses-01_task-socialdoors_run-1_part-mag_space-MNI152NLin6Asym_desc-preproc_bold.nii.gz
  confounds: /ZPOOL/data/projects/rf1-sra-linux2/derivatives/fsl/confounds_tedana/sub-12055/sub-12055_ses-01_task-socialdoors_run-1_desc-TedanaPlusConfounds.tsv
  EV prefix: /ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/EVfiles/sub-12055/ses-01/socialdoors/run-1
  template: /ZPOOL/data/projects/rf1-sra-socdoors/templates/L1_task-socialdoors_model-1_type-act.fsf
  output: /ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/sub-12055/ses-01/L1_task-socialdoors_ses-01_model-1_type-act_run-1_sm-5.feat
L1 plan
  BOLD: /ZPOOL/data/projects/rf1-sra-linux2/derivatives/fmriprep/sub-12057/ses-01/func/sub-12057_ses-01_task-doors_run-1_part-mag_space-MNI152NLin6Asym_desc-preproc_bold.nii.gz
  confounds: /ZPOOL/data/projects/rf1-sra-linux2/derivatives/fsl/confounds_tedana/sub-12057/sub-12057_ses-01_task-doors_run-1_desc-TedanaPlusConfounds.tsv
  EV prefix: /ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/EVfiles/sub-12057/ses-01/doors/run-1
  template: /ZPOOL/data/projects/rf1-sra-socdoors/templates/L1_task-doors_model-1_type-act.fsf
  output: /ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/sub-12057/ses-01/L1_task-doors_ses-01_model-1_type-act_run-1_sm-5.feat
L1 plan
  BOLD: /ZPOOL/data/projects/rf1-sra-linux2/derivatives/fmriprep/sub-12057/ses-01/func/sub-12057_ses-01_task-socialdoors_run-1_part-mag_space-MNI152NLin6Asym_desc-preproc_bold.nii.gz
  confounds: /ZPOOL/data/projects/rf1-sra-linux2/derivatives/fsl/confounds_tedana/sub-12057/sub-12057_ses-01_task-socialdoors_run-1_desc-TedanaPlusConfounds.tsv
  EV prefix: /ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/EVfiles/sub-12057/ses-01/socialdoors/run-1
  template: /ZPOOL/data/projects/rf1-sra-socdoors/templates/L1_task-socialdoors_model-1_type-act.fsf
  output: /ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/sub-12057/ses-01/L1_task-socialdoors_ses-01_model-1_type-act_run-1_sm-5.feat

COMMAND EXIT: 1
```
