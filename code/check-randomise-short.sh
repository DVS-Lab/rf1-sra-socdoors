#!/bin/bash
# Script to check all FSL Randomise output images for significance
# Scans entire randomise folder, prints significant results, and saves thresholded/binarized images

scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
maindir="$(dirname "$scriptdir")"
BASE_DIR="${maindir}/derivatives/fsl/randomise"
OUTPUT_DIR="${maindir}/derivatives/imaging_plots/grant"
SIG_THRESHOLD=0.95

mkdir -p "$OUTPUT_DIR"

echo "==================================================="
echo "FSL Randomise Significance Check"
echo "Base directory: ${BASE_DIR}"
echo "Output directory: ${OUTPUT_DIR}"
echo "Significance threshold: ${SIG_THRESHOLD}"
echo "==================================================="
echo ""

SIG_COUNT=0

# Find all corrected p-value images recursively under BASE_DIR
while IFS= read -r IMAGE_FILE; do
    RANGE_OUTPUT=$(fslstats "$IMAGE_FILE" -R 2>/dev/null)
    MAX_VAL=$(echo "$RANGE_OUTPUT" | awk '{print $2}')

    if (( $(echo "$MAX_VAL >= $SIG_THRESHOLD" | bc -l) )); then
        SIG_COUNT=$((SIG_COUNT + 1))
        echo "SIGNIFICANT: ${IMAGE_FILE}"
        echo "  Max value: ${MAX_VAL}"

        # Build output filename from directory name (model/contrast info) + image basename
        DIR_NAME=$(basename "$(dirname "$IMAGE_FILE")")
        IMG_BASE=$(basename "$IMAGE_FILE" .nii.gz)
        OUT_PREFIX="${OUTPUT_DIR}/${DIR_NAME}__${IMG_BASE}"

        # Thresholded image
        fslmaths "$IMAGE_FILE" -thr "$SIG_THRESHOLD" "${OUT_PREFIX}_thr.nii.gz"
        echo "  Saved: ${OUT_PREFIX}_thr.nii.gz"

        # Binarized image
        fslmaths "$IMAGE_FILE" -thr "$SIG_THRESHOLD" -bin "${OUT_PREFIX}_bin.nii.gz"
        echo "  Saved: ${OUT_PREFIX}_bin.nii.gz"
        echo ""
    fi
done < <(find "$BASE_DIR" -path "*_cnum-4_cname-win-loss*" -name "*clustere_corrp_tstat*.nii.gz" ! -name "*_tstat1.nii.gz" ! -name "*_tstat2.nii.gz" | sort)

echo "==================================================="
echo "Done. ${SIG_COUNT} significant result(s) found."
echo "==================================================="
