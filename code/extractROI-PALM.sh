#!/usr/bin/env bash

# ensure paths are correct irrespective from where user runs the script
scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
maindir="$(dirname "$scriptdir")"
outputdir=${maindir}/derivatives/imaging_plots

n=58

# base paths
for TASK in doors socialdoors; do
	for TYPE in "act" "nppi-dmn" "ppi_seed-VS"; do
		for COPEINFO in "1 win" "2 loss" "4 win-loss"; do
			set -- $COPEINFO
			COPENUM=$1
			COPENAME=$2

			DATA=`ls -1 ${maindir}/derivatives/fsl/L3_model-1_task-socialdoors_n${n}_flame1+2_single-task/L3_task-${TASK}_type-${TYPE}_cnum-${COPENUM}_cname-${COPENAME}_flame1+2_single-task.gfeat/cope1.feat/filtered_func_data.nii.gz`

			fslmeants -i $DATA -o ${outputdir}/L3_task-${TASK}_type-${TYPE}_n${n}_cnum-${COPENUM}_cname-${COPENAME}_single-task.txt
		done
	done
done
