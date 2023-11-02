#!/bin/bash

# This script will creates filtered_func_diff images for use in randomise
# Updated JBW Nov 2023

# Ensure paths are correct irrespective from where user runs the script
scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
basedir="$(dirname "$scriptdir")"

n=58
for model in 1; do
	#for type in "act"; do
	for type in "act" "nppi-dmn" "ppi_seed-VS"; do
                #for COPEINFO in "4 win-loss"; do
		for COPEINFO in "1 win" "2 loss" "4 win-loss"; do
                        set -- $COPEINFO
                        COPENUM=$1
                        COPENAME=$2

			INPUT1=${basedir}/derivatives/fsl/L3_model-${model}_task-socialdoors_n${n}_flame1+2_single-task/L3_task-socialdoors_type-${type}_cnum-${COPENUM}_cname-${COPENAME}_flame1+2_single-task.gfeat/cope1.feat/filtered_func_data.nii.gz
			INPUT2=${basedir}/derivatives/fsl/L3_model-${model}_task-socialdoors_n${n}_flame1+2_single-task/L3_task-doors_type-${type}_cnum-${COPENUM}_cname-${COPENAME}_flame1+2_single-task.gfeat/cope1.feat/filtered_func_data.nii.gz
			OUTPUT=${basedir}/derivatives/randomise/L3_model-${model}_task-socialdoors_type-${type}_cnum-${COPENUM}_cname-${COPENAME}/

			fslmaths $INPUT1 -add $INPUT2 filtered_func_sum.nii.gz
			if [ -e ${OUTPUT} ]; then
				echo "${OUTPUT} already exists"
			else
				echo "Creating ${OUTPUT}"
				mkdir $OUTPUT
			fi
			fslmaths filtered_func_sum.nii.gz -div 2 ${OUTPUT}/filteredfunc_diff.nii.gz
			rm filtered_func_sum.nii.gz
			printf "Completed: model ${model} ${type} ${COPENUM} ${COPENAME}\n"
		done
	done
done
