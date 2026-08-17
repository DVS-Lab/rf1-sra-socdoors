#!/bin/bash

# Replaces L1 cope paths with L2 cope paths in .fsf template files
# Preserves real subject IDs from the input files
# Always writes task-socialdoors in the output regardless of input task
# Treats type-REPLACEME and copeCOPENUM as literal placeholders (filled in later)
# Writes copies to a test output directory; originals are not modified

# Usage: ./replace_paths.sh <input_dir_or_files> <output_dir>

if [ $# -lt 2 ]; then
   echo "Usage: $0 <input_directory> <output_directory>"
   echo "   or: $0 <file1.fsf> [file2.fsf ...] <output_directory>"
   exit 1
fi

# Last argument is the output directory
OUTDIR="${@: -1}"
INPUTS=("${@:1:$#-1}")

mkdir -p "$OUTDIR"

# Build list of files to process
FILES=()
for arg in "${INPUTS[@]}"; do
   if [ -d "$arg" ]; then
      while IFS= read -r f; do
         FILES+=("$f")
      done < <(find "$arg" -name "*.fsf")
   else
      FILES+=("$arg")
   fi
done

# Regex matches the L1 path. Captures:
#   \1 = subject ID (e.g., sub-11897)
# Task name in input is matched but discarded; output always uses socialdoors.
# type-REPLACEME and copeCOPENUM stay as literal text in both old and new.
for fsf in "${FILES[@]}"; do
   outfile="${OUTDIR}/$(basename "$fsf")"
   echo "Processing: $fsf -> $outfile"

   sed -E 's|/ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/(sub-[0-9]+)/ses-01/L1_task-[^_]+_ses-01_model-1_type-REPLACEME_run-1_sm-5\.feat/stats/copeCOPENUM\.nii\.gz|/ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/\1/ses-01/L2_task-socialdoors_ses-01_model-1_type-REPLACEME_sm-5.gfeat/copeCOPENUM.feat/stats/cope1.nii.gz|g' "$fsf" > "$outfile"
done

echo "All files processed. Output in: $OUTDIR"
