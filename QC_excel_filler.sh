#!/bin/bash
#
#SBATCH --account=b1134                	# Our account/allocation
#SBATCH --partition=buyin      		# 'Buyin' submits to our node qhimem0018
#SBATCH --mem=18GB
#SBATCH -t 02:00:00
#SBATCH --job-name QC
#SBATCH -o /projects/b1134/processed/eegqc/logs/QC_excel_%a_%A.out
#SBATCH -e /projects/b1134/processed/eegqc/logs/QC_excel_%a_%A.err

#Braga Lab
#Created by Chris Cyr in January 2022

#Usage:
#sbatch /projects/b1134/tools/eegqc/QC_excel_filler.sh ATHUAT 1
#Argument 1 is the Subject ID
#Argument 2 is whether its stim data or not (STIM = 1)
#creates text file with QC info for each data set for a given subject
##########################################################################

module load matlab/r2020b
matlab -batch "addpath('/projects/b1134/tools/eegqc'); QC_excel_filler('$1', '$2');"
