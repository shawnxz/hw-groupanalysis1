#!/usr/bin/env tcsh

# Quality check
mkdir group_results
gen_ss_review_table.py \
-tablefile group_results/test_qa.tsv \
-infiles subjects/*-retest.results/out.ss_review*

# Group brain mask
3dmask_tool \
-input subjects/*test.results/mask_group+tlrc.HEAD \
-frac 1.0 \
-prefix group_results/mask

# Note that in my result files "Foot-Lips" is actually "foot-lips"
# One-sample t-test
3dttest++ -mask group_results/mask+tlrc \
-prefix group_results/Foot-Lips \
-setA 'subjects/*-retest.results/stats.*-retest+tlrc.HEAD[foot-lips_GLT#0_Coef]'

# Average blur estimate
chmod 755 scripts/average_blur.py
scripts/average_blur.py subjects/*-retest.results/blur.errts.1D

# Clustering
3dClustSim \
-mask group_results/mask+tlrc \
-acf `scripts/average_blur.py subjects/*-retest.results/blur.errts.1D` \
-both -pthr .05 .01 .001 \
-athr .1 .05 .025 .01 \
-iter 2000 \
-prefix group_results/cluster \
-cmd group_results/refit.cmd

# Add cluster table
`cat group_results/refit.cmd` \
group_results/Foot-Lips+tlrc

# Look at cluster table
# 3dAttribute AFNI_CLUSTSIM_NN3_bisided group_results/Foot-Lips+tlrc

# Because it is difficult to visualize anatomical images in group_results
cp /usr/local/afni/MNI152_T1_2009c+tlrc* group_results/ 

#########################################################################
# Move to the results folder
cd group_results

# Mask the stat image
3dcalc -a Foot-Lips+tlrc \
-b mask+tlrc \
-expr 'a*b' \
-prefix Foot-Lips_masked

# Convert to Z-scores
3dmerge -1zscore -prefix Foot-Lips_zstat \
'Foot-Lips_masked+tlrc[1]'

# Find clusters
# 3dAttribute AFNI_CLUSTSIM_NN3_1sided Foot-Lips+tlrc
# Minimum cluster size = 17
3dclust -1Dformat -nosum  \
-prefix Foot-Lips_clusters \
-savemask Foot-Lips_cluster_mask \
-inmask -1noneg \
-1clip 3 \
-dxyz=1 \
1.74 17 \
Foot-Lips_zstat+tlrc > Foot-Lips.txt

cd ../
mkdir results
mv group_results/Foot-Lips.txt results/