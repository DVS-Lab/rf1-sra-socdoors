#!/bin/bash

# Script for sending cope images and full brain masks of subs under age of 35 to Thais & Camille

# Ensure paths are correct irrespective from where user runs the script
scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
basedir="$(dirname "$scriptdir")"

for task in doors socialdoors; do
	for sub in `cat ${basedir}/code/sublist_under35.txt`; do

		# Create output directories
		copesdir="/ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/copes_under35/sub-${sub}"
		if [ ! -d "$copesdir" ]; then
			echo "Generating output dir for sub-${sub} ${task}"
			mkdir $copesdir
		fi
		outputdir="/ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/copes_under35/sub-${sub}/${task}"
		if [ ! -d "$outputdir" ]; then
			mkdir $outputdir
		fi

		# Check and see if files exist
		file_path_brain="/ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/sub-${sub}/L1_task-${task}_model-1_type-act_run-1_sm-5.feat/mask.nii.gz"
		if [ ! -f "$file_path_brain" ]; then
			echo "L1stats for sub-${sub} does not exist"
		else
			echo "The brain mask for sub-${sub} does exist"

			# Identify and copy over copes, zstats, & brain mask
			for copeinfo in "1 win" "2 loss" "3 decision" "4 win-loss"; do
				set -- $copeinfo
				copenum=$1
				copename=$2
				file_path_cope="/ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/sub-${sub}/L1_task-${task}_model-1_type-act_run-1_sm-5.feat/stats/cope${copenum}.nii.gz"
				file_path_zstat="/ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/sub-${sub}/L1_task-${task}_model-1_type-act_run-1_sm-5.feat/stats/zstat${copenum}.nii.gz"
				# Check and see if copes exist
				if [ ! -f "$file_path_cope" ]; then
					echo "The cope ${copenum} ${copename} image for sub-${sub} does not exist"
				else
					echo "The cope ${copenum} ${copename} image for sub-${sub} does exist"
					cp $file_path_brain ${outputdir}/sub-${sub}_task-${task}_type-act_mask.nii.gz
					cp $file_path_cope ${outputdir}/sub-${sub}_task-${task}_type-act_contrast-${copenum}_cope.nii.gz
                                        cp $file_path_zstat ${outputdir}/sub-${sub}_task-${task}_type-act_contrast-${copenum}_zstat.nii.gz
				fi
			done
		fi
	done
done
