#!/bin/bash

# This script will perform Level 3 stats across social 
# and nonsocial conditions in the ISTART Social Doors task
# for models containing covariates

# Ensure paths are correct irrespective from where user runs the script
scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
maindir="$(dirname "$scriptdir")"

n=51

#for model in "agexfevs55" "agexmspss55" "agexsusd55" "agexpromis55" "agexoafem55"; do
#for model in "mscwH1" "mscwH2"; do
#for model in "agexpm"; do
#for model in "ecogxmspss55" "adixecog55" "pmxecog55"; do
#for model in "pmxmspss55" "adixmspss55"; do
#for model in "adixmspss55"; do
#for model in "adixmspss55"; do
for model in "depressxadi55" "depressxmspss55" "depressxecog55" "depressxpm55"; do
#for type in "ppi_seed-postTPJ" "ppi_seed-VS" "ppi_seed-PCC" "ppi_seed-mPFC" "act"; do
for type in "act"; do
    for COPEINFO in "4 win-loss"; do
        set -- $COPEINFO
        COPENUM=$1
        COPENAME=$2
        
        INPUTDIR=${maindir}/derivatives/fsl/randomise/L3_model-${model}_task-socialdoors_type-${type}_cnum-${COPENUM}_cname-${COPENAME}
        WMHDIR=/ZPOOL/data/projects/rf1-wmh/derivatives/truenet-evaluate/merged/space-MNI152NLin6Asym_res-2/model-ukbb/group-model5

        # Check if the directory and required files exist
        if [ -e ${WMHDIR}/group-model5_ses-01_space-MNI152NLin6Asym_res-2_label-WMH_desc-truenetUKBBWMmasked_probseg.nii.gz ] && [ -e ${INPUTDIR}/design.mat ] && [ -e ${INPUTDIR}/design.con ]; then
        #if [ -e ${INPUTDIR}/filteredfunc_diff.nii.gz ] && [ -e ${INPUTDIR}/design.mat ] && [ -e ${INPUTDIR}/design.con ]; then
   
            # Create output directory if it doesn't exist
            mkdir -p ${INPUTDIR}
            
            # Run randomise
            echo "Running randomise for model ${model}, type ${type}, cope ${COPENUM} (${COPENAME})"
            
            cd ${INPUTDIR}
            OUTPUTDIR=${maindir}/derivatives/fsl/randomise-wmh/WMH_L3_model-${model}_task-socialdoors_type-${type}_cnum-${COPENUM}_cname-${COPENAME}
            mkdir -p ${OUTPUTDIR}
            #nohup randomise -i filteredfunc_diff.nii.gz \
                      #-o randomise \
                      #-d design.mat \
                      #-t design.con \
                      #-m ${maindir}/derivatives/fsl/L3_model-${model}_task-socialdoors_n${n}_flame1+2/L3_task-socialdoors_model-${model}_${type}_cnum-${COPENUM}_cname-${COPENAME}_onegroup.gfeat/cope1.feat/mask.nii.gz \
                      #-T -c 3.1 -n 5000 \
                      #> randomise.out 2>&1 &
            

	    nohup randomise -i ${WMHDIR}/group-model5_ses-01_space-MNI152NLin6Asym_res-2_label-WMH_desc-truenetUKBBWMmasked_probseg.nii.gz \
                      -o ${OUTPUTDIR}/randomise \
                      -d ${INPUTDIR}/design.mat \
                      -t ${INPUTDIR}/design.con \
                      -m ${WMHDIR}/group-model5_ses-01_space-MNI152NLin6Asym_res-2_label-WMH_desc-truenetUKBBWMmaskedProbP10Prev10_mask.nii.gz \
                      -T -c 3.1 -n 5000 \
                      > ${OUTPUTDIR}/randomise.out 2>&1 &
           


            printf "Submitted: model ${model} ${type} ${COPENUM} ${COPENAME}\n"
        else
            echo "Skipping: Required files not found in ${INPUTDIR}"
        fi
    done
done
done

echo "All randomise jobs submitted"
