#!/usr/bin/env bash

# ensure paths are correct irrespective from where user runs the script
scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
maindir="$(dirname "$scriptdir")"

n=75

# base paths
for TASK in socialdoors; do
for MASK in "seed-VS.nii.gz"; do
	for TYPE in "act"; do	
	#for TYPE in "act" "nppi-dmn" "ppi_seed-VS"; do
		for COPEINFO in "4 win-loss"; do		
		#for COPEINFO in "1 win" "2 loss" "4 win-loss"; do
			set -- $COPEINFO
			COPENUM=$1
			COPENAME=$2

			# Make filteredfunc_diff image
			INPUT1=${maindir}/derivatives/fsl/L3_model-1_task-socialdoors_n${n}_flame1+2/L3_task-socialdoors_type-${TYPE}_cnum-${COPENUM}_cname-${COPENAME}_flame1+2_single-task.gfeat/cope1.feat/filtered_func_data.nii.gz
			INPUT2=${maindir}/derivatives/fsl/L3_model-1_task-socialdoors_n${n}_flame1+2/L3_task-doors_type-${TYPE}_cnum-${COPENUM}_cname-${COPENAME}_flame1+2_single-task.gfeat/cope1.feat/filtered_func_data.nii.gz
			OUTPUT=${maindir}/derivatives/fsl/palm/L3_model-1_task-socialdoors_type-${TYPE}_cnum-${COPENUM}_cname-${COPENAME}/
			
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

			#DATA=`ls -1 ${maindir}/derivatives/fsl/L3_model-1_task-socialdoors_n${n}_flame1+2_single-task/L3_task-${TASK}_type-${TYPE}_cnum-${COPENUM}_cname-${COPENAME}_flame1+2_single-task.gfeat/cope1.feat/filtered_func_data.nii.gz`
			DATA=`ls -1 ${OUTPUT}/filteredfunc_diff.nii.gz`			
			
			printf "Completing extraction .txt file"
			fslmeants -i $DATA -o ${OUTPUT}/L3_task-${TASK}_mask-VS_type-${TYPE}_n${n}_cnum-${COPENUM}_cname-${COPENAME}_single-task.csv -m ${maindir}/masks/${MASK}
		done
	done
done
done
