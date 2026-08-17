#!/bin/bash

# Set path to standard brain mask
#standard_img="$FSLDIR/data/standard/MNI152_T1_2mm_brain_mask_dil-resliced.nii.gz"
standard_img=/ZPOOL/data/projects/rf1-sra-socdoors/masks/MNI152_T1_2mm_brain_mask_dil_resliced.nii.gz
standard_voxels=$(fslstats "$standard_img" -V | awk '{print $1}')

# Output CSV header
echo "Subject,Run,Study,MaskVoxels,StandardVoxels,CoveragePercent" > mask_coverage_metrics.csv

# Loop through all masks
for mask in /ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/sub-*/ses-01/L1_task-*_ses-01_model-1_type-act_run-*_sm-5.feat/mask.nii.gz; do
    # Extract subject ID (e.g., sub-101 or sub-10101)
    sub=$(echo "$mask" | grep -o 'sub-[^/]*')

    # Determine study based on subject ID length (excluding 'sub-')
    sub_id=${sub#sub-}
    if [ ${#sub_id} -eq 3 ]; then
        study="SRNDNA"
    elif [ ${#sub_id} -eq 5 ]; then
        study="RF1"
    else
        study="UNKNOWN"
    fi

    # Extract run number from the filename (e.g., run-01)
    run=$(echo "$mask" | grep -oP '(?<=run-)[0-9]+')

    # Count voxels in mask
    mask_voxels=$(fslstats "$mask" -V | awk '{print $1}')

    # Compute % coverage
    coverage=$(echo "scale=4; $mask_voxels / $standard_voxels * 100" | bc)

    # Append to CSV
    echo "$sub,$run,$study,$mask_voxels,$standard_voxels,$coverage" >> mask_coverage_metrics.csv
done

echo "Done. Results saved to mask_coverage_metrics.csv"
