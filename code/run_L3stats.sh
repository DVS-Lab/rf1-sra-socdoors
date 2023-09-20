#!/bin/bash

# This run_* script is a wrapper for L3stats.sh, so it will loop over several
# copes and models. Note that Contrast N for PPI is always PHYS in these models.


# ensure paths are correct irrespective from where user runs the script
scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
maindir="$(dirname "$scriptdir")"


# this loop defines the different types of analyses that will go into the group comparisons
for TASK in socialdoors; do
	for analysis in act; do #ppi_seed-VS_thr5 nppi-dmn nppi-ecn; do # act ppi_seed-NAcc-act_n46 ppi_seed-vmpfc nppi-dmn nppi-ecn ppi_seed | type-${type}_run-01
		analysistype=type-${analysis}

		# these define the cope number (copenum) and cope name (copename)
		for copeinfo in "4 win-loss"; do #"1 win" "2 loss" "3 decision"; do #"3 dec" "4 win-loss" "5 phys"; do

			# split copeinfo variable
			set -- $copeinfo
			copenum=$1
			copename=$2

			if [ "${analysistype}" == "type-act" ] && [ "${copeinfo}" == "5 phys" ]; then
				echo "skipping phys for activation since it does not exist..."
				continue
			fi

			NCORES=15
			SCRIPTNAME=${maindir}/code/L3stats.sh
			while [ $(ps -ef | grep -v grep | grep $SCRIPTNAME | wc -l) -ge $NCORES ]; do
				sleep 1s
			done
			bash $SCRIPTNAME $copenum $copename $analysistype $TASK &

		done
	done
done