#!/bin/bash

# This script lists cope filenames to be pasted in as L3 data
# Jimmy Wyngaarden, Sept 2023


# Ensure paths are correct irrespective from where user runs the script
scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
basedir="$(dirname "$scriptdir")"

sm=5
cope=5
modelnum=1

for task in socialdoors doors; do
#for task in doors; do
	for ppi in "nppi-dmn"; do # "act" "ppi_seed-VS" "nppi-dmn"; do # putting 0 first will indicate "activation"
		for sub in `cat ${basedir}/code/sublist-all.txt`; do
	  		for run in 1; do
				# For comparisons between two groups:
	  			#echo /ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/sub-${sub}/L1_task-${task}_model-${modelnum}_type-${ppi}_run-${run}_sm-${sm}.feat/stats/cope${cope}.nii.gz

				# For one-group average
	  			 echo /ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/sub-${sub}/L2_task-${task}_model-${modelnum}_type-${ppi}_sm-${sm}.gfeat/cope${cope}.feat/stats/cope1.nii.gz
	  		done
	  	done
	done
done
