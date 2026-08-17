#!/usr/bin/env bash

scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
maindir="$(dirname "$scriptdir")"
baseout=/ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/EVfiles

if [ ! -d ${baseout} ]; then
  mkdir -p $baseout
fi

for sub in `cat ${maindir}/code/sublist-datapush.txt`; do
        for task in doors socialdoors; do
                for run in 1; do
                        for ses in "01"; do
                                input=/ZPOOL/data/projects/rf1-sra-linux2/bids/sub-${sub}/ses-${ses}/func/sub-${sub}_ses-${ses}_task-${task}_run-${run}_events.tsv
                                output=${baseout}/sub-${sub}/ses-${ses}/${task}
                                mkdir -p $output
                                if [ -e $input ]; then
                                bash ${scriptdir}/BIDSto3col.sh $input ${output}/
                                else
                        echo "PATH ERROR: cannot locate ${input}."
                        continue
                                fi
                        done
                done
        done
done
