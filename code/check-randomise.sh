#!/bin/bash
# Script to check FSL Randomise output images for significance
# Processes socialdoors difference contrasts
# Creates thresholded and binarized images for significant results

# Define the base directory
scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
maindir="$(dirname "$scriptdir")"
BASE_DIR="${maindir}/derivatives/fsl/randomise-wmh"

# Define parameters
N=51
#MODELS=("agexfevs55" "agexoafem55" "agexmspss55" "agexpromis55" "agexsusd55")
#MODELS=("agexfevs" "agexoafem" "agexmspss" "agexpromis" "agexsusd")
#MODELS=("mscwH1" "mscwH2")
#MODELS=("agexpm" "agexadi")
TYPES=("act")
MODELS=("depressxecog55" "depressxadi55" "depressxmspss55" "depressxpm55")
COPEINFO=("4 win-loss")
TSTAT_NUMS=(1 2 3 4 5 6)
CORRECTION_TYPES=("clustere_corrp" "tstat")
SIG_THRESHOLD=0.95

echo "==================================================="
echo "Checking FSL Randomise Output Images for SocialDoors Difference"
echo "==================================================="
echo "Base directory: ${BASE_DIR}"
echo "N: ${N}"
echo "Significance threshold: ${SIG_THRESHOLD}"
echo "---------------------------------------------------"

# Loop through each model
for model in "${MODELS[@]}"; do
    echo ""
    echo "###################################################"
    echo "### Processing Model: ${model}"
    echo "###################################################"

    # Loop through each type
    for type in "${TYPES[@]}"; do
        # Loop through each cope
        for COPE in "${COPEINFO[@]}"; do
            set -- $COPE
            COPENUM=$1
            COPENAME=$2

            CURRENT_RESULTS_DIR="${BASE_DIR}/WMH_L3_model-${model}_task-socialdoors_type-${type}_cnum-${COPENUM}_cname-${COPENAME}"

            echo ""
            echo "--- Processing: Model=${model}, Type=${type}, Cope=${COPENUM} (${COPENAME}) ---"
            echo "Checking directory: ${CURRENT_RESULTS_DIR}"
            echo "---------------------------------------------------"

            # Validate directory
            if [ ! -d "$CURRENT_RESULTS_DIR" ]; then
                echo "Error: Results directory not found: ${CURRENT_RESULTS_DIR}"
                echo "Skipping this contrast."
                continue
            fi

            # Loop through each correction type
            for CORR_TYPE in "${CORRECTION_TYPES[@]}"; do
                # Loop through each tstat/contrast number
                for TSTAT_NUM in "${TSTAT_NUMS[@]}"; do
                    IMAGE_FILE="${CURRENT_RESULTS_DIR}/randomise_${CORR_TYPE}_tstat${TSTAT_NUM}.nii.gz"

                    # Skip if image file does not exist
                    if [ ! -f "$IMAGE_FILE" ]; then
                        continue
                    fi

                    # Get min and max values
                    RANGE_OUTPUT=$(fslstats "$IMAGE_FILE" -R 2>/dev/null)
                    MIN_VAL=$(echo "$RANGE_OUTPUT" | awk '{print $1}')
                    MAX_VAL=$(echo "$RANGE_OUTPUT" | awk '{print $2}')

                    printf "  %-40s Min: %10.6f   Max: %10.6f" \
                        "${CORR_TYPE}_tstat${TSTAT_NUM}" "$MIN_VAL" "$MAX_VAL"

                    # Check significance only for corrected p-value images
                    if [[ "$CORR_TYPE" == *"_corrp" ]]; then
                        if (( $(echo "$MAX_VAL >= $SIG_THRESHOLD" | bc -l) )); then
                            echo "    >>> SIGNIFICANT (Max >= ${SIG_THRESHOLD})! <<<"

                            # Define output filenames
                            OUTPUT_THR="${CURRENT_RESULTS_DIR}/randomise_${CORR_TYPE}_tstat${TSTAT_NUM}_thr.nii.gz"
                            OUTPUT_BIN="${CURRENT_RESULTS_DIR}/randomise_${CORR_TYPE}_tstat${TSTAT_NUM}_bin.nii.gz"

                            # Create thresholded image
                            echo "      Creating thresholded image: $(basename "$OUTPUT_THR")"
                            fslmaths "$IMAGE_FILE" -thr "$SIG_THRESHOLD" "$OUTPUT_THR"

                            # Create binarized image
                            echo "      Creating binarized image: $(basename "$OUTPUT_BIN")"
                            fslmaths "$IMAGE_FILE" -thr "$SIG_THRESHOLD" -bin "$OUTPUT_BIN"
                        else
                            echo ""
                        fi
                    else
                        echo ""
                    fi
                done
            done
            echo "---------------------------------------------------"
        done
    done
done

echo ""
echo "==================================================="
echo "All Image Analyses Complete."
echo "==================================================="
