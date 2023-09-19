#!/bin/sh
#
#SBATCH --account=b1134                	# Our account/allocation
#SBATCH --partition=buyin      		# 'Buyin' submits to our node qhimem0018
#SBATCH --mem=18GB
#SBATCH -t 01:00:00
#SBATCH --job-name QC
#SBATCH -o /projects/b1134/processed/eegqc/logs/QC_%a_%A.out
#SBATCH -e /projects/b1134/processed/eegqc/logs/QC_%a_%A.err
###############################################################################
#This script was created by the Braga Lab in August 2021 and
#creates a quality control pdf from CSC files, and NEV file, and a custom made channellabels.txt file. This currently only works for NU data.

#This script is meant to be called by EEGQC.sh, but can also be run directly
# via an analytics quest node or an sbatch command. R version 4.0.3 must be 
#installed on quest within the user's home directory

#To execute this script
#sbatch QCpdf.sh Rawdatapath Processeddatapath
#EXAMPLE:sbatch QCpdf.sh /projects/b1134/raw/chris_raw/ATHUAT/136986uV/2021-07-07_11-28-12 /projects/b1134/processed/eegqc/BNI/9ATHUAT/EMU0018/FIX01

#A pdf will be saved to the processed directory 
#/projects/b1134/processed/eegqc/ProjectID/SubjectID/SessionID/TaskID
###############################################################################
INPATH=$1
OUTPATH=$2

module load matlab/r2020b
mkdir -p $OUTPATH
if [ ! -e ${OUTPATH}/downsampled_data_uV.mat ] && [ ! -e ${INPATH}/downsampled_data_uV.mat ]; then
matlab -batch "addpath('/projects/b1134/tools/eegqc'); load_dataCSC('$INPATH', '$OUTPATH')"
fi
matlab -batch "addpath('/projects/b1134/tools/eegqc'); headertable('$OUTPATH')"
matlab -batch "addpath('/projects/b1134/tools/eegqc'); carpetplot('$OUTPATH')"
matlab -batch "addpath('/projects/b1134/tools/eegqc'); statsplot('$OUTPATH')"
matlab -batch "addpath('/projects/b1134/tools/eegqc'); powerspectrum('$OUTPATH')"
matlab -batch "addpath('/projects/b1134/tools/eegqc'); rawplot('$OUTPATH')"

module load R/4.0.3
module load fftw/3.3.3-gcc
Rscript  /projects/b1134/tools/eegqc/MakeQCpdf.R $OUTPATH
