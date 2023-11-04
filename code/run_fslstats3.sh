#!/bin/bash

# Find significant clusters & generate thresholded tstat images from randomise output
# Updated Nov 2023 for SfN JBW

scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
maindir="$(dirname "$scriptdir")"

location=fsl

for ana in "age" "agexnbs" "agexoafem"; do
  for type in "act" "nppi-dmn" "ppi_seed-VS"; do
    for img in "clustere"; do
      for copeinfo in "4 win-loss"; do
        
        set -- $copeinfo
        cnum=$1
        cname=$2
        
        count=1
        if [ "$location" == "randomise" ] then
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
      elif [ "$location" == "fsl" ]; then
        
      fi
      
      done
    done
  done
done
