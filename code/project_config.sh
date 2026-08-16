#!/usr/bin/env bash

# Shared path and naming configuration for the downstream SocDoors analysis.
# Source this file; do not execute it directly.

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)"
UPSTREAM_ROOT="${RF1_SRA_UPSTREAM_ROOT:-/ZPOOL/data/projects/rf1-sra-linux2}"
BIDS_ROOT="${BIDS_ROOT:-${UPSTREAM_ROOT}/bids}"
FMRIPREP_ROOT="${FMRIPREP_ROOT:-${UPSTREAM_ROOT}/derivatives/fmriprep}"
CONFOUNDS_ROOT="${CONFOUNDS_ROOT:-${UPSTREAM_ROOT}/derivatives/fsl/confounds_tedana}"
FSL_DERIVATIVES_ROOT="${FSL_DERIVATIVES_ROOT:-${PROJECT_ROOT}/derivatives/fsl}"

normalize_subject() {
    printf '%s\n' "${1#sub-}"
}

normalize_session() {
    printf '%s\n' "${1#ses-}"
}

analysis_type_from_ppi() {
    case "$1" in
        0|act) printf '%s\n' "act" ;;
        dmn|ecn) printf '%s\n' "nppi-$1" ;;
        *) printf '%s\n' "ppi_seed-$1" ;;
    esac
}

l1_output_base() {
    local sub session task run type smoothing
    sub="$(normalize_subject "$1")"
    session="$(normalize_session "$2")"
    task="$3"
    run="$4"
    type="$5"
    smoothing="${6:-5}"
    printf '%s/sub-%s/ses-%s/L1_task-%s_ses-%s_model-1_type-%s_run-%s_sm-%s\n' \
        "$FSL_DERIVATIVES_ROOT" "$sub" "$session" "$task" "$session" "$type" "$run" "$smoothing"
}

l2_output_base() {
    local sub session type smoothing
    sub="$(normalize_subject "$1")"
    session="$(normalize_session "$2")"
    type="$3"
    smoothing="${4:-5}"
    printf '%s/sub-%s/ses-%s/L2_task-socialdoors_ses-%s_model-1_type-%s_sm-%s\n' \
        "$FSL_DERIVATIVES_ROOT" "$sub" "$session" "$session" "$type" "$smoothing"
}
