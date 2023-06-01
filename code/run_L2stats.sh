#!/bin/bash

# ensure paths are correct irrespective from where user runs the script
scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
maindir="$(dirname "$scriptdir")"

# the "type" variable below is setting a path inside the main script
for type in "act" "ppi_seed-VS_thr5" "nppi-dmn"; do # act nppi-ecn #"ppi_seed-NAcc"
	#for sub in `cat ${scriptdir}/newsubs.txt`; do
	for sub in 10369 10402 10418 10462 10478 10486 10529 10541 10572 10581 10584 10585 10589 10596 10603 10606 10608 10617 10656 10663 10677; do

		# Manages the number of jobs and cores
  	SCRIPTNAME=${maindir}/code/L2stats.sh
  	NCORES=10
  	while [ $(ps -ef | grep -v grep | grep $SCRIPTNAME | wc -l) -ge $NCORES ]; do
    		sleep 1s
  	done
  	bash $SCRIPTNAME $sub $type &
  	sleep 1s

	done
done