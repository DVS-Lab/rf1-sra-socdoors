#!/bin/bash

# This script will perform Level 3 statistics in FSL.
# Rather than having multiple scripts, we are merging three analyses
# into this one script:
#		1) two groups (older vs. younger)
#		2) two groups (older vs. younger), with covariates
#		3) single group average
#
# This script can also run randomise (permutation-based stats) on existing output.
# By default, randomise will not be be run if FEAT analyses do not exist. In addition,
# randomise will only be run on copes above a specified number (see copenum_thresh_randomise variable).
# If you have no intention of running randomise, you set copenum_thresh_randomise=20 (> max of 19 copes)
# and you could uncomment out the rm lines that remove the filtered_func_data file (save disk space).

# ensure paths are correct irrespective from where user runs the script
scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
maindir="$(dirname "$scriptdir")"

# study-specific inputs and general output folder

N=51
copenum=$1
copename=$2
copenum_thresh_randomise=99 # actual contrasts start here. no need to do randomise main effects (e.g., reward > nothing/fixation/baseline)
REPLACEME=$3 # this defines the parts of the path that differ across analyses
TASK=$4

#for MODEL in "agexfevs" "agexmspss" "agexsusd" "agexpromis" "agexoafem"; do
#for MODEL in "agexpm" "agexadi"; do
#for MODEL in "agexoafem55" "agexfevs55" "agexmspss55" "agexsusd55" "agexpromis55" "agexoafem55"; do
#for MODEL in "ecogxmspss55" "adixecog55" "pmxecog55"; do
#for MODEL in "pmxmspss55" "adixmspss55"; do
#for MODEL in "mscwH1" "mscwH2"; do
#for MODEL in "agexpm-L2"; do
#for MODEL in "depressxmspss55" "depressxadi55" "depressxpm55" "depressxecog55"; do
for MODEL in "depressxpm55"; do

	MAINOUTPUT=${maindir}/derivatives/fsl/L3_model-${MODEL}_task-${TASK}_n${N}_flame1+2
	mkdir -p $MAINOUTPUT

	### --- One group ------------------------------
	# set outputs and check for existing
	OUTPUT=${MAINOUTPUT}/L3_task-${TASK}_model-${MODEL}_${REPLACEME}_cnum-${copenum}_cname-${copename}_onegroup
	if [ -e ${OUTPUT}.gfeat/cope1.feat/cluster_mask_zstat1.nii.gz ]; then

		# run randomise if output doesn't exist and the contrasts (copes) are valid
		cd ${OUTPUT}.gfeat/cope1.feat
		if [ ! -e randomise_tfce_corrp_tstat2.nii.gz ] && [ $copenum -ge $copenum_thresh_randomise ]; then
			randomise -i filtered_func_data.nii.gz -o randomise -d design.mat -t design.con -m mask.nii.gz -T -c 2.6 -n 10000
		fi

	else # try to run feat and clean up previous effort with partial output

		echo "re-doing: ${OUTPUT}" >> re-runL3.log
		rm -rf ${OUTPUT}.gfeat

	# create template and run FEAT analyses
		#ITEMPLATE=${maindir}/templates/L3_model-${MODEL}_task-${TASK}_type-ppi_seed-ROI_n${N}.fsf
		ITEMPLATE=${maindir}/templates/L3_model-${MODEL}_task-${TASK}_type-act_n${N}.fsf
		OTEMPLATE=${MAINOUTPUT}/L3_task-${TASK}_model-${MODEL}_type-${REPLACEME}_copenum-${copenum}.fsf
		sed -e 's@OUTPUT@'$OUTPUT'@g' \
		-e 's@COPENUM@'$copenum'@g' \
		-e 's@REPLACEME@'$REPLACEME'@g' \
		<$ITEMPLATE> $OTEMPLATE
		feat $OTEMPLATE

	fi

	# delete unused files
	rm -rf ${OUTPUT}.gfeat/cope${copenum}.feat/stats/res4d.nii.gz
	rm -rf ${OUTPUT}.gfeat/cope${copenum}.feat/stats/corrections.nii.gz
	rm -rf ${OUTPUT}.gfeat/cope${copenum}.feat/stats/threshac1.nii.gz
	#rm -rf ${OUTPUT}.gfeat/cope${cope}.feat/filtered_func_data.nii.gz
	#rm -rf ${OUTPUT}.gfeat/cope${cope}.feat/var_filtered_func_data.nii.gz

done
