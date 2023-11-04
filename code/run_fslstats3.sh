#!/bin/bash

# Find significant clusters & generate thresholded tstat images from randomise output
# Updated Nov 2023 for SfN JBW

scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
maindir="$(dirname "$scriptdir")"

location=randomise

for ana in "age" "agexnbs" "agexoafem" "ageXnbs" "ageXoafem"; do
  for type in "act" "nppi-dmn" "ppi_seed-VS"; do
    for img in "clustere"; do
      for copeinfo in "4 win-loss"; do

        set -- $copeinfo
        cnum=$1
        cname=$2

        count=1
        if [ "$location" == "randomise" ]; then
          for tfile in ${maindir}/derivatives/randomise/L3_model-1_task-socialdoors_type-${type}_cnum-${cnum}_cname-${cname}_${ana}/_${img}_corrp_tstat*.nii.gz; do
            echo "Type-${type}_cnum-${cnum}_cname-${cname}_${ana}/_${img}_corrp_tstat${count}_tstat.nii.gz"
            var=$(fslstats ${tfile} -R)

            yvar=$(echo ${var} | awk '{print $2}')
            echo "Max 1-p = $yvar"

            if (( $(echo "$yvar >= 0.95" |bc -l) )); then
              ofile=${maindir}/derivatives/randomise/L3_model-1_task-socialdoors_type-${type}_cnum-${cnum}_cname-${cname}_${ana}/_thresh_corrp_tstat${count}.nii.gz
              echo "Creating ${ofile}"
              fslmaths ${tfile} -thr .95 ${ofile}
            fi
            count=$(($count+1))
          done
      	elif [ "$location" ==  "fsl" ]; then
           for tfile in ${maindir}/derivatives/fsl/L3_model-1_task-socialdoors_n58_flame1+2/L3_task-socialdoors_type-${type}_cnum-${cnum}_cname-${cname}_flame1+2_single-group-average_${ana}.gfeat/cope1.feat/thresh_zstat*.nii.gz; do
            #echo "Type-${type}_cnum-${cnum}_cname-${cname}/thresh_zstat${count}.nii.gz"
            var=$(fslstats ${tfile} -R)

            yvar=$(echo ${var} | awk '{print $2}')
            #echo "Thresh zstat${count} max intensity = $yvar"

            if (( $(echo "$yvar > 0" |bc -l) )); then
              #ofile=${maindir}/derivatives/randomise/L3_model-1_task-socialdoors_type-${type}_cnum-${cnum}_cname-${cname}_${ana}/_thresh_corrp_tstat${count}.nii.gz
              echo "See significant cluster(s) in ${tfile}"
              #fslmaths ${tfile} -thr .95 ${ofile}
            fi
            count=$(($count+1))
          done
      	else
	  echo "Enter proper var for location"
	fi
      done
    done
  done
done
