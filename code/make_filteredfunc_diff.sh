#!/bin/bash

# This script will creates filtered_func_diff images for use in randomise
# Updated JBW Nov 2023

# Ensure paths are correct irrespective from where user runs the script
scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
basedir="$(dirname "$scriptdir")"

n=75
for model in 1; do
	for type in "ppi_seed-VS"; do
	#for type in "act" "nppi-dmn" "ppi_seed-VS"; do
   	for COPEINFO in "4 win-loss"; do
		   #for COPEINFO in "1 win" "2 loss" "4 win-loss"; do
      	set -- $COPEINFO
      	COPENUM=$1
      	COPENAME=$2

			INPUT1=${basedir}/derivatives/fsl/L3_model-${model}_task-socialdoors_n${n}_flame1+2/L3_task-socialdoors_type-${type}_cnum-${COPENUM}_cname-${COPENAME}_flame1+2_single-task.gfeat/cope1.feat/filtered_func_data.nii.gz
			INPUT2=${basedir}/derivatives/fsl/L3_model-${model}_task-socialdoors_n${n}_flame1+2/L3_task-doors_type-${type}_cnum-${COPENUM}_cname-${COPENAME}_flame1+2_single-task.gfeat/cope1.feat/filtered_func_data.nii.gz
			OUTPUT=${basedir}/derivatives/fsl/randomise/L3_model-${model}_task-socialdoors_type-${type}_cnum-${COPENUM}_cname-${COPENAME}/
			
			echo "${INPUT1} -sub ${INPUT2}"
			fslmaths $INPUT1 -sub $INPUT2 filteredfunc_diff.nii.gz
			
			if [ -e ${OUTPUT}/filteredfunc_diff.nii.gz ]; then
				echo "${OUTPUT}/filteredfunc_diff.nii.gz already exists"
			else
				echo "Creating ${OUTPUT}/filteredfunc_diff.nii.gz"
				mkdir $OUTPUT
			fi
			mv filteredfunc_diff.nii.gz ${OUTPUT}/filteredfunc_diff.nii.gz
			printf "Completed: model ${model} ${type} ${COPENUM} ${COPENAME}\n"
		done
	done
done
