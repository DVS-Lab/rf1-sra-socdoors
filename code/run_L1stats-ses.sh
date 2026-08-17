#!/bin/bash

# Ensure paths are correct irrespective from where user runs the script
scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
basedir="$(dirname "$scriptdir")"
nruns=1

#for task in doors socialdoors; do
for task in doors socialdoors; do
	for ppi in mPFC postTPJ PCC; do #"VS_thr5" "dmn"; do # 0 "VS_thr5" "dmn"; do # putting 0 first will indicate "activation"
		for sub in `cat ${basedir}/code/sublist_all.txt`; do
		#for sub in 11867; do
	  		for run in `seq $nruns`; do
				for ses in "01"; do

					# Manages the number of jobs and cores
					SCRIPTNAME=${basedir}/code/L1stats-ses.sh
					NCORES=50
					while [ $(ps -ef | grep -v grep | grep $SCRIPTNAME | wc -l) -ge $NCORES ]; do
						sleep 5s
					done

					bash $SCRIPTNAME $sub $run $ppi $task $ses &
					sleep 1s

				done
			done
		done
	done
done
