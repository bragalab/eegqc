#!/bin/bash
#
#SBATCH --account=b1134                	# Our account/allocation
#SBATCH --partition=buyin      		# 'Buyin' submits to our node qhimem0018
#SBATCH --mem=12GB
#SBATCH -t 1:00:00
#SBATCH --job-name QC
#SBATCH -o /projects/b1134/analysis/ccyr/logs/Stanford_2_BIDS.out
#SBATCH -e /projects/b1134/analysis/ccyr/logs/Stanford_2_BIDS.err

#Created by Chris Cyrin Februrary 2022


#Usage:
#sh /projects/b1134/tools/eeqc/Stanford2BIDS.sh or sbatch /projects/b1134/tools/eeqc/Stanford2BIDS.sh
#creates BIDS mat files for all stanford runs in eegqc directory and outputs to BIDS directory unless eegqc file already has BIDS file associated with it
##########################################################################
module load matlab/r2020b

BIDSDIR=/projects/b1134/raw/bids
STANSTIMDIR=/projects/b1134/processed/eegqc

BIDSv=iEEGBIDS.sh

echo "----"
echo "Running iEEG BIDS Conversion"
echo "----"

echo "Checking for new EEG runs collected"

OLDIFS=$IFS

for i  in `ls -d $STANSTIMDIR/S[0123456789]*/*/*/*/downsampled_data_uV.mat 2> /dev/null`
do
	IFS='/'
	read -a INPATH <<< "$i"
	end=${#INPATH[*]}
	SubjectID=${INPATH[$end-5]}
	SessionID=${INPATH[$end-4]}
	TaskID=${INPATH[$end-3]}
	AcqID=${INPATH[$end-2]}


	IFS=$OLDIFS
	SessionID=${SessionID//[^[:alnum:]]/} #remove dashes and underscores
	AcqID=${AcqID//[^[:alnum:]]/} #remove dashes and underscores
        OUTPATH="/projects/b1134/raw/bids/Stanford/sub-$SubjectID/ses-$SessionID/ieeg"
	
	if [ ! -d ${OUTPATH} ]
	then
       		mkdir -p ${OUTPATH}
		echo "New directory made ${OUTPATH}"
	fi
	
	if [ -f ${OUTPATH}/sub-${SubjectID}_ses-${SessionID}_task-${TaskID}_acq-${AcqID}_ieeg.mat ]
	then
		echo  "BIDS-compatible file for $TaskID already exists at $OUTPATH"
	else
		echo "Converting data for $i"
		matlab -batch "Stanford2BIDS('$i', '$OUTPATH')"
	fi
done


