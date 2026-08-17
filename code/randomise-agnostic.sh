#!/bin/bash

# This script will perform Level 3 stats across social 
# and nonsocial conditions in the ISTART Social Doors task
# for models containing covariates

# Ensure paths are correct irrespective from where user runs the script
scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
maindir="$(dirname "$scriptdir")"

n=229

#for model in "agexfevs" "agexmspss" "agexsusd" "agexpromis" "agexoafem"; do
#for model in "mscwH1" "mscwH2"; do
for model in "agexpm" "agexadi"; do
for type in "act"; do
    for COPEINFO in "1 winVSloss taskagnostic"; do
        set -- $COPEINFO
        COPENUM=$1
        COPENAME=$2
        TASK=$3
        
        # Build INPUTDIR and mask path based on task type
        if [ "${TASK}" == "taskagnostic" ]; then
            INPUTDIR=${maindir}/derivatives/fsl/randomise/L3_model-${model}_taskagnostic_type-${type}_cname-${COPENAME}
            MASK=${maindir}/derivatives/fsl/L3_model-${model}_task-socialdoors_n${n}_flame1+2/L3_task-socialdoors_model-${model}_${type}_cnum-1_cname-win_onegroup.gfeat/cope1.feat/mask.nii.gz
        else
            INPUTDIR=${maindir}/derivatives/fsl/randomise/L3_model-${model}_task-${TASK}_type-${type}_cnum-${COPENUM}_cname-${COPENAME}
            MASK=${maindir}/derivatives/fsl/L3_model-${model}_task-${TASK}_n${n}_flame1+2/L3_task-${TASK}_model-${model}_${type}_cnum-${COPENUM}_cname-${COPENAME}_onegroup.gfeat/cope1.feat/mask.nii.gz
        fi
        
        # Check if the directory and required files exist
        if [ -e ${INPUTDIR}/filteredfunc_diff.nii.gz ] && [ -e ${INPUTDIR}/design.mat ] && [ -e ${INPUTDIR}/design.con ]; then
            
            # Create output directory if it doesn't exist
            mkdir -p ${INPUTDIR}
            
            # Run randomise
            echo "Running randomise for model ${model}, type ${type}, cope ${COPENUM} (${COPENAME}) ${TASK}"
            
            cd ${INPUTDIR}
            nohup randomise -i filteredfunc_diff.nii.gz \
                      -o randomise \
                      -d design.mat \
                      -t design.con \
                      -m ${MASK} \
                      -T -c 3.1 -n 5000 \
                      > randomise.out 2>&1 &
            
            printf "Submitted: model ${model} ${type} ${COPENUM} ${COPENAME} ${TASK}\n"
        else
            echo "Skipping: Required files not found in ${INPUTDIR}"
        fi
    done
done
done

echo "All randomise jobs submitted"
