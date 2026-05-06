#!/bin/bash

# This script will creates filtered_func win>loss images (task-agnostic) for use in randomise
# Averages wins across tasks, averages losses across tasks, then subtracts
# Updated JBW Nov 2023

# Ensure paths are correct irrespective from where user runs the script
scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
basedir="$(dirname "$scriptdir")"

n=229
#for model in "agexfevs" "agexmspss" "agexsusd" "agexpromis" "agexoafem"; do
#for model in "mscwH1" "mscwH2"; do
for model in "agexadi" "agexpm"; do
   for type in "act"; do

      INPUT1=${basedir}/derivatives/fsl/L3_model-${model}_task-socialdoors_n${n}_flame1+2/L3_task-socialdoors_model-${model}_${type}_cnum-1_cname-win_onegroup.gfeat/cope1.feat/filtered_func_data.nii.gz
      INPUT2=${basedir}/derivatives/fsl/L3_model-${model}_task-doors_n${n}_flame1+2/L3_task-doors_model-${model}_${type}_cnum-1_cname-win_onegroup.gfeat/cope1.feat/filtered_func_data.nii.gz
      INPUT3=${basedir}/derivatives/fsl/L3_model-${model}_task-socialdoors_n${n}_flame1+2/L3_task-socialdoors_model-${model}_${type}_cnum-2_cname-loss_onegroup.gfeat/cope1.feat/filtered_func_data.nii.gz
      INPUT4=${basedir}/derivatives/fsl/L3_model-${model}_task-doors_n${n}_flame1+2/L3_task-doors_model-${model}_${type}_cnum-2_cname-loss_onegroup.gfeat/cope1.feat/filtered_func_data.nii.gz
      OUTPUT=${basedir}/derivatives/fsl/randomise/L3_model-${model}_taskagnostic_type-${type}_cname-winVSloss


      MAT=${basedir}/derivatives/fsl/L3_model-${model}_task-doors_n${n}_flame1+2/L3_task-doors_model-${model}_${type}_cnum-1_cname-win_onegroup.gfeat/cope1.feat/design.mat
      CON=${basedir}/derivatives/fsl/L3_model-${model}_task-doors_n${n}_flame1+2/L3_task-doors_model-${model}_${type}_cnum-1_cname-win_onegroup.gfeat/cope1.feat/design.con

      echo "((${INPUT1} + ${INPUT2}) - (${INPUT3} + ${INPUT4})) / 2"
      fslmaths $INPUT1 -add $INPUT2 -sub $INPUT3 -sub $INPUT4 -div 2 filteredfunc_diff.nii.gz

      if [ -e ${OUTPUT}/filteredfunc_diff.nii.gz ]; then
         echo "${OUTPUT}/filteredfunc_diff.nii.gz already exists"
      else
         echo "Creating ${OUTPUT}/filteredfunc_diff.nii.gz"
         mkdir $OUTPUT
      fi
      mv filteredfunc_diff.nii.gz ${OUTPUT}/filteredfunc_diff.nii.gz
      cp $MAT ${OUTPUT}/design.mat
      cp $CON ${OUTPUT}/design.con
      printf "Completed: model ${model} ${type} winVSloss (task-agnostic)\n"
   done
done
