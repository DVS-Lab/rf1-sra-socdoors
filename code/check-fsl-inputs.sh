#!/bin/bash

# Script to check all required inputs for FSL Level 1 stats
# Usage: ./check_fsl_inputs.sh

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Base directories
BIDS_DIR="/ZPOOL/data/projects/rf1-sra-linux2/bids"
CONFOUNDS_DIR="/ZPOOL/data/projects/rf1-sra-linux2/derivatives/fsl/confounds_tedana-24"
EVFILES_DIR="/ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/EVfiles"
FMRIPREP_DIR="/ZPOOL/data/projects/rf1-sra-linux2/derivatives/fmriprep-24"
L1_DOORS_DIR="/ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl"
L1_SOCIALDOORS_DIR="/ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl"

# Initialize counters
total_subjects=0
complete_subjects=0
subjects_with_issues=()

# Arrays to track subjects missing files by category
declare -a missing_bids=()
declare -a missing_confounds_doors=()
declare -a missing_confounds_socialdoors=()
declare -a missing_evfiles_doors=()
declare -a missing_evfiles_socialdoors=()
declare -a missing_fmriprep_doors=()
declare -a missing_fmriprep_socialdoors=()

# Arrays to track L1 cope1 status
declare -a missing_l1_doors=()
declare -a missing_l1_socialdoors=()
declare -a complete_l1_subjects=()

# Header
echo "======================================================================"
echo "FSL Level 1 Stats Input Checker"
echo "======================================================================"
echo ""

# Find all subjects matching sub-1???? pattern
for subject_dir in ${BIDS_DIR}/sub-1????; do
    if [ -d "$subject_dir" ]; then
        subject=$(basename "$subject_dir")
        total_subjects=$((total_subjects + 1))
        
        missing_files=0
        subject_has_missing=false
        missing_output=""
        bids_missing=false
        
        # Check BIDS - doors
        filepath="${BIDS_DIR}/${subject}/ses-01/func/${subject}_ses-01_task-doors_run-1_echo-1_part-mag_bold.nii.gz"
        if [ ! -f "$filepath" ]; then
            missing_output+="  ${RED}✗${NC} BIDS: doors task\n"
            missing_files=$((missing_files + 1))
            bids_missing=true
            subject_has_missing=true
        fi
        
        # Check BIDS - socialdoors
        filepath="${BIDS_DIR}/${subject}/ses-01/func/${subject}_ses-01_task-socialdoors_run-1_echo-1_part-mag_bold.nii.gz"
        if [ ! -f "$filepath" ]; then
            missing_output+="  ${RED}✗${NC} BIDS: socialdoors task\n"
            missing_files=$((missing_files + 1))
            bids_missing=true
            subject_has_missing=true
        fi
        
        # Add to combined BIDS missing array if any BIDS files are missing
        if [ "$bids_missing" = true ]; then
            missing_bids+=("$subject")
        fi
        
        # Only check subsequent files if BIDS data is present
        if [ "$bids_missing" = false ]; then
            # Check EVfiles - doors (checking all 3 together)
            evfiles_doors_missing=0
            if [ ! -f "${EVFILES_DIR}/${subject}/ses-01/doors/_decision.txt" ]; then
                evfiles_doors_missing=$((evfiles_doors_missing + 1))
            fi
            if [ ! -f "${EVFILES_DIR}/${subject}/ses-01/doors/_loss.txt" ]; then
                evfiles_doors_missing=$((evfiles_doors_missing + 1))
            fi
            if [ ! -f "${EVFILES_DIR}/${subject}/ses-01/doors/_win.txt" ]; then
                evfiles_doors_missing=$((evfiles_doors_missing + 1))
            fi
            if [ $evfiles_doors_missing -gt 0 ]; then
                missing_output+="  ${RED}✗${NC} EVfiles: doors (${evfiles_doors_missing}/3 missing)\n"
                missing_files=$((missing_files + evfiles_doors_missing))
                missing_evfiles_doors+=("$subject")
                subject_has_missing=true
            fi
            
            # Check EVfiles - socialdoors (checking all 3 together)
            evfiles_socialdoors_missing=0
            if [ ! -f "${EVFILES_DIR}/${subject}/ses-01/socialdoors/_decision.txt" ]; then
                evfiles_socialdoors_missing=$((evfiles_socialdoors_missing + 1))
            fi
            if [ ! -f "${EVFILES_DIR}/${subject}/ses-01/socialdoors/_loss.txt" ]; then
                evfiles_socialdoors_missing=$((evfiles_socialdoors_missing + 1))
            fi
            if [ ! -f "${EVFILES_DIR}/${subject}/ses-01/socialdoors/_win.txt" ]; then
                evfiles_socialdoors_missing=$((evfiles_socialdoors_missing + 1))
            fi
            if [ $evfiles_socialdoors_missing -gt 0 ]; then
                missing_output+="  ${RED}✗${NC} EVfiles: socialdoors (${evfiles_socialdoors_missing}/3 missing)\n"
                missing_files=$((missing_files + evfiles_socialdoors_missing))
                missing_evfiles_socialdoors+=("$subject")
                subject_has_missing=true
            fi
            
            # Check fMRIPrep - doors
            filepath="${FMRIPREP_DIR}/${subject}/ses-01/func/${subject}_ses-01_task-doors_run-1_part-mag_space-MNI152NLin6Asym_desc-preproc_bold.nii.gz"
            if [ ! -f "$filepath" ]; then
                missing_output+="  ${RED}✗${NC} fMRIPrep: doors preprocessed\n"
                missing_files=$((missing_files + 1))
                missing_fmriprep_doors+=("$subject")
                subject_has_missing=true
            fi
            
            # Check fMRIPrep - socialdoors
            filepath="${FMRIPREP_DIR}/${subject}/ses-01/func/${subject}_ses-01_task-socialdoors_run-1_part-mag_space-MNI152NLin6Asym_desc-preproc_bold.nii.gz"
            if [ ! -f "$filepath" ]; then
                missing_output+="  ${RED}✗${NC} fMRIPrep: socialdoors preprocessed\n"
                missing_files=$((missing_files + 1))
                missing_fmriprep_socialdoors+=("$subject")
                subject_has_missing=true
            fi
            
            # Check Confounds - doors
            filepath="${CONFOUNDS_DIR}/${subject}/${subject}_ses-01_task-doors_run-1_desc-TedanaPlusConfounds.tsv"
            if [ ! -f "$filepath" ]; then
                missing_output+="  ${RED}✗${NC} Confounds: doors\n"
                missing_files=$((missing_files + 1))
                missing_confounds_doors+=("$subject")
                subject_has_missing=true
            fi
            
            # Check Confounds - socialdoors
            filepath="${CONFOUNDS_DIR}/${subject}/${subject}_ses-01_task-socialdoors_run-1_desc-TedanaPlusConfounds.tsv"
            if [ ! -f "$filepath" ]; then
                missing_output+="  ${RED}✗${NC} Confounds: socialdoors\n"
                missing_files=$((missing_files + 1))
                missing_confounds_socialdoors+=("$subject")
                subject_has_missing=true
            fi
        fi
        
        # Only print if subject has missing files
        if [ "$subject_has_missing" = true ]; then
            subjects_with_issues+=("$subject")
        else
            complete_subjects=$((complete_subjects + 1))
        fi
    fi
done

# Check for L1 cope1.nii.gz files for subjects with complete preprocessing
echo "======================================================================"
echo "Checking Level 1 outputs (cope1.nii.gz)..."
echo "======================================================================"
echo ""

l1_complete_count=0

for subject_dir in ${BIDS_DIR}/sub-1????; do
    if [ -d "$subject_dir" ]; then
        subject=$(basename "$subject_dir")
        
        # Only check L1 for subjects that passed the preprocessing checks
        is_complete=true
        for issue_sub in "${subjects_with_issues[@]}"; do
            if [ "$subject" = "$issue_sub" ]; then
                is_complete=false
                break
            fi
        done
        
        if [ "$is_complete" = true ]; then
            # Check for cope1.nii.gz in doors
            doors_cope="${L1_DOORS_DIR}/${subject}/ses-01/L1_task-doors_ses-01_model-1_type-act_run-1_sm-5.feat/stats/cope1.nii.gz"
            socialdoors_cope="${L1_SOCIALDOORS_DIR}/${subject}/ses-01/L1_task-socialdoors_ses-01_model-1_type-act_run-1_sm-5.feat/stats/cope1.nii.gz"
            
            doors_missing=false
            socialdoors_missing=false
            
            if [ ! -f "$doors_cope" ]; then
                doors_missing=true
                missing_l1_doors+=("$subject")
            fi
            
            if [ ! -f "$socialdoors_cope" ]; then
                socialdoors_missing=true
                missing_l1_socialdoors+=("$subject")
            fi
            
            # If both exist, add to L3 ready list
            if [ "$doors_missing" = false ] && [ "$socialdoors_missing" = false ]; then
                complete_l1_subjects+=("$subject")
                l1_complete_count=$((l1_complete_count + 1))
            fi
        fi
    fi
done

echo "Subjects with both L1 outputs: ${l1_complete_count}"
echo ""

# Final summary
echo "======================================================================"
echo "SUMMARY"
echo "======================================================================"
echo "Total subjects checked: ${total_subjects}"
echo -e "Subjects with all files: ${GREEN}${complete_subjects}${NC}"
echo -e "Subjects with missing files: ${RED}$((total_subjects - complete_subjects))${NC}"
echo ""

# Create output file with subjects that have all files
output_file="sublist-${complete_subjects}.txt"
> "$output_file"  # Clear file if it exists

# Get list of subjects with all files
for subject_dir in ${BIDS_DIR}/sub-1????; do
    if [ -d "$subject_dir" ]; then
        subject=$(basename "$subject_dir")
        # Check if subject is NOT in the subjects_with_issues array
        is_complete=true
        for issue_sub in "${subjects_with_issues[@]}"; do
            if [ "$subject" = "$issue_sub" ]; then
                is_complete=false
                break
            fi
        done
        if [ "$is_complete" = true ]; then
            # Remove 'sub-' prefix before writing to file
            subject_id="${subject#sub-}"
            echo "$subject_id" >> "$output_file"
        fi
    fi
done

echo -e "${GREEN}Created subject list: ${output_file}${NC}"
echo ""

# Summary by category
echo "----------------------------------------------------------------------"
echo "MISSING FILES BY CATEGORY:"
echo "----------------------------------------------------------------------"

if [ ${#missing_bids[@]} -gt 0 ]; then
    echo -e "${RED}BIDS (${#missing_bids[@]} subjects):${NC}"
    for subj in "${missing_bids[@]}"; do
        echo "  - ${subj}"
    done
    echo ""
fi

if [ ${#missing_evfiles_doors[@]} -gt 0 ]; then
    echo -e "${RED}EVfiles doors (${#missing_evfiles_doors[@]} subjects):${NC}"
    for subj in "${missing_evfiles_doors[@]}"; do
        echo "  - ${subj}"
    done
    echo ""
fi

if [ ${#missing_evfiles_socialdoors[@]} -gt 0 ]; then
    echo -e "${RED}EVfiles socialdoors (${#missing_evfiles_socialdoors[@]} subjects):${NC}"
    for subj in "${missing_evfiles_socialdoors[@]}"; do
        echo "  - ${subj}"
    done
    echo ""
fi

if [ ${#missing_fmriprep_doors[@]} -gt 0 ]; then
    echo -e "${RED}fMRIPrep doors (${#missing_fmriprep_doors[@]} subjects):${NC}"
    for subj in "${missing_fmriprep_doors[@]}"; do
        echo "  - ${subj}"
    done
    echo ""
fi

if [ ${#missing_fmriprep_socialdoors[@]} -gt 0 ]; then
    echo -e "${RED}fMRIPrep socialdoors (${#missing_fmriprep_socialdoors[@]} subjects):${NC}"
    for subj in "${missing_fmriprep_socialdoors[@]}"; do
        echo "  - ${subj}"
    done
    echo ""
fi

if [ ${#missing_confounds_doors[@]} -gt 0 ]; then
    echo -e "${RED}Confounds doors (${#missing_confounds_doors[@]} subjects):${NC}"
    for subj in "${missing_confounds_doors[@]}"; do
        echo "  - ${subj}"
    done
    echo ""
fi

if [ ${#missing_confounds_socialdoors[@]} -gt 0 ]; then
    echo -e "${RED}Confounds socialdoors (${#missing_confounds_socialdoors[@]} subjects):${NC}"
    for subj in "${missing_confounds_socialdoors[@]}"; do
        echo "  - ${subj}"
    done
    echo ""
fi

if [ $((total_subjects - complete_subjects)) -eq 0 ]; then
    echo -e "${GREEN}All subjects have complete data!${NC}"
    echo ""
fi

# L1 outputs summary
echo "----------------------------------------------------------------------"
echo "LEVEL 1 OUTPUTS (cope1.nii.gz):"
echo "----------------------------------------------------------------------"

if [ ${#missing_l1_doors[@]} -gt 0 ]; then
    echo -e "${RED}Missing L1 doors (${#missing_l1_doors[@]} subjects):${NC}"
    for subj in "${missing_l1_doors[@]}"; do
        echo "  - ${subj}"
    done
    echo ""
fi

if [ ${#missing_l1_socialdoors[@]} -gt 0 ]; then
    echo -e "${RED}Missing L1 socialdoors (${#missing_l1_socialdoors[@]} subjects):${NC}"
    for subj in "${missing_l1_socialdoors[@]}"; do
        echo "  - ${subj}"
    done
    echo ""
fi

if [ ${#complete_l1_subjects[@]} -gt 0 ]; then
    echo -e "${GREEN}Subjects with both L1 outputs (${#complete_l1_subjects[@]} subjects)${NC}"
    echo ""
    
    # Create L3 sublist
    l3_output_file="sublist-L3-${#complete_l1_subjects[@]}.txt"
    > "$l3_output_file"
    
    for subj in "${complete_l1_subjects[@]}"; do
        # Remove 'sub-' prefix
        subject_id="${subj#sub-}"
        echo "$subject_id" >> "$l3_output_file"
    done
    
    echo -e "${GREEN}Created L3 subject list: ${l3_output_file}${NC}"
    echo ""
fi

echo "======================================================================"
