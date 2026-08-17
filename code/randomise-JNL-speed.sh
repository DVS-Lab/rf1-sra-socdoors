#!/bin/bash

# This script will perform Level 3 stats across social 
# and nonsocial conditions in the ISTART Social Doors task
# for models containing covariates

# Ensure paths are correct irrespective from where user runs the script
scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
maindir="$(dirname "$scriptdir")"

n=231
model="1"

# Set to test directory
TESTDIR=${maindir}/derivatives/fsl/randomise-ryan
mkdir -p ${TESTDIR}

for type in "act"; do
    for COPEINFO in "1 win" "2 loss" "4 win-loss"; do
        set -- $COPEINFO
        COPENUM=$1
        COPENAME=$2
        
        # Original input directory (where the data is)
        INPUTDIR=${maindir}/derivatives/fsl/randomise/L3_model-${model}_task-socialdoors_type-${type}_cnum-${COPENUM}_cname-${COPENAME}
        
        # Test output directory (where results will go)
        OUTPUTDIR=${TESTDIR}/L3_model-${model}_task-socialdoors_type-${type}_cnum-${COPENUM}_cname-${COPENAME}
        mkdir -p ${OUTPUTDIR}
        
        # Check if the directory and required files exist
        if [ -e ${INPUTDIR}/filteredfunc_diff.nii.gz ] && [ -e ${INPUTDIR}/design.mat ] && [ -e ${INPUTDIR}/design.con ]; then
            
            # Copy necessary files to output directory
            cp ${INPUTDIR}/filteredfunc_diff.nii.gz ${OUTPUTDIR}/
            cp ${INPUTDIR}/design.mat ${OUTPUTDIR}/
            cp ${INPUTDIR}/design.con ${OUTPUTDIR}/
            
            # Count number of contrasts in design.con
            NCON=$(grep -v "^#" ${INPUTDIR}/design.con | grep -v "^$" | wc -l)
            
            # Run separate randomise for each contrast
            for CON_NUM in $(seq 1 $NCON); do
                
                # Check if this contrast already completed
                if [ -e ${OUTPUTDIR}/randomise_con${CON_NUM}_tfce_corrp_tstat1.nii.gz ]; then
                    echo "Already completed: model ${model}, type ${type}, cope ${COPENUM} (${COPENAME}), contrast ${CON_NUM}"
                    continue
                fi
                
                echo "Running randomise for model ${model}, type ${type}, cope ${COPENUM} (${COPENAME}), contrast ${CON_NUM}"
                
                cd ${OUTPUTDIR}
                
                # Create temporary contrast file with only this contrast
                TEMP_CON="design_con${CON_NUM}.con"
                head -n 1 design.con > $TEMP_CON  # Copy header
                sed -n "$((CON_NUM + 1))p" design.con >> $TEMP_CON  # Add specific contrast line
                
                nohup randomise -i filteredfunc_diff.nii.gz \
                          -o randomise_con${CON_NUM} \
                          -d design.mat \
                          -t $TEMP_CON \
                          -m ${maindir}/derivatives/fsl/L3_model-${model}_task-socialdoors_n${n}_flame1+2/L3_task-socialdoors_model-${model}_${type}_cnum-${COPENUM}_cname-${COPENAME}_onegroup.gfeat/cope1.feat/mask.nii.gz \
                          -T -c 3.1 -n 5000 \
                          > randomise_con${CON_NUM}.out 2>&1 &
                
                printf "Submitted: model ${model} ${type} ${COPENUM} ${COPENAME} contrast ${CON_NUM}\n"
                
            done
        else
            echo "Skipping: Required files not found in ${INPUTDIR}"
        fi
    done
done

echo "All randomise jobs submitted to ${TESTDIR}"
