#!/bin/bash
IMAGE1=$1
IMAGE2=$2
OUTPUT=$3

fslmaths $IMAGE1 -bin img1_bin
fslmaths $IMAGE2 -bin img2_bin
fslmaths img1_bin -mul img2_bin $OUTPUT

rm -f img1_bin.nii.gz img2_bin.nii.gz
