#!/bin/bash
#
#SBATCH --account=b1134                	# Our account/allocation
#SBATCH --partition=buyin      		# 'Buyin' submits to our node qhimem0018
#SBATCH --mem=200GB
#SBATCH -t 1:00:00
#SBATCH --job-name EEGQC
#SBATCH -o /projects/b1134/processed/eegqc/logs/NWB_%a_%A.out
#SBATCH -e /projects/b1134/processed/eegqc/logs/NWB_%a_%A.err

#Usage: sbatch /projects/b1134/tools/eegqc/load_dataNWB.sh /projects/b1134/tmp/sourcedata/BragaLab/nwb/OAUOBH/NWB/STIM02/OAUOBH_clinical_export.edf

INPATH=$1
module load matlab/r2020b
matlab -batch "addpath('/projects/b1134/tools/eegqc'); load_dataNWB('$INPATH')"
