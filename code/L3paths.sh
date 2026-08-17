#!/bin/bash

#Add flag for activation/ppi {type} and model number

# Path to the subject list file
sublist="/ZPOOL/data/projects/rf1-sra-socdoors/code/sublist-datapush.txt"

for task in "doors" "socialdoors"; do

# Loop through each subject in the list
while IFS= read -r subject; do

    files=$(ls -1 "/ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/sub-$subject/ses-01/L2_task-${task}_ses-01_model-1_type-act_sm-5.gfeat/cope4.feat/stats/cope1.nii.gz" 2>/dev/null)

    if [ -z "$files" ]; then
        files=$(ls -1 "/ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/sub-$subject/ses-01/L1_task-${task}_ses-01_model-1_type-act_run-1_sm-5.feat/stats/cope1.nii.gz" 2>/dev/null)
    fi

    if [ -n "$files" ]; then
        echo "$files"
    fi

done < "$sublist"

done
