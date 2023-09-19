#!/bin/bash
#
#SBATCH --array=0-50 ## number of jobs to run "in parallel"
#SBATCH --account=b1134                	# Our account/allocation
#SBATCH --partition=buyin      		# 'Buyin' submits to our node qhimem0018
#SBATCH --mem=18GB
#SBATCH -t 0:30:00
#SBATCH --job-name EEGQC
#SBATCH -o /projects/b1134/processed/eegqc/logs/QC_%a_%A.out
#SBATCH -e /projects/b1134/processed/eegqc/logs/QC_%a_%A.err
##########################################################################
#Braga Lab EEG QC Master Script
#Created by Chris Cyr (and others!) in August 2021
#creates QC documents for all eeg runs in raw directory and outputs to processed
#directory unless raw file already has QC doc associated with it.
#
#Usage:
#sbatch /projects/b1134/tools/eegqc/EEGQC.sh 


#set search paths
#for nonstimulation BNI data collected on the Atlas
BNIDIR=/projects/b1134/raw/sourcedata/BragaLab/atlas

#for stimulation BNI data collected on the Atlas
STIMDIR=/projects/b1134/processed/ieeg_stim

#for data collected at Stanford and BNI data collected on the clinical system
PROCDIR=/projects/b1134/processed/eegproc

#build list of directories that need to be QC'd
OLDIFS=$IFS
directories=$(ls -d $BNIDIR/*/*/*/202* $STIMDIR/*/*/*/*/*/*/202* $PROCDIR/*/*/*/FIX* 2> /dev/null)
directory_list=(${directories// / })
INPATHS_to_QC=()
OUTPATHS_to_QC=()
for i in ${directory_list[@]} 
do

#extract directory information
IFS='/'
read -a INPATH <<< "$i"
end=${#INPATH[*]}
IFS=$OLDIFS

if [[ $i == *"atlas"* ]]; then #for BNIDIR data
	ProjectID=BNI
	SubjectID=${INPATH[$end-4]}
	SessionID=${INPATH[$end-3]}
	TaskID=${INPATH[$end-2]}
elif [[ $i == *"ieeg_stim"* ]]; then #for STIMDIR data
	ProjectID=${INPATH[$end-7]}
	SubjectID=${INPATH[$end-6]}
	SessionID=${INPATH[$end-5]}
	TaskID="${INPATH[$end-4]}/${INPATH[$end-3]}/${INPATH[$end-2]}"
elif [[ $i == *"eegqc"*"STIM"* ]]; then #for PROCDIR STIM data
	ProjectID=${INPATH[$end-6]}
	SubjectID=${INPATH[$end-5]}
	SessionID=${INPATH[$end-4]}
	TaskID="${INPATH[$end-3]}/${INPATH[$end-2]}/${INPATH[$end-1]}"
elif [[ $i == *"eegproc"*"FIX"* ]]; then #for PROCDIR STIM data
	ProjectID=${INPATH[$end-4]}
	SubjectID=${INPATH[$end-3]}
	SessionID=${INPATH[$end-2]}
	TaskID="${INPATH[$end-1]}"
fi
OUTPATH="/projects/b1134/processed/eegqc/$ProjectID/$SubjectID/$SessionID/$TaskID"


#skip Stim data in BNIDIR as well as any original_raw directories
if [[ $SessionID == *"original_raw"* ]] || [[ $i == *"atlas"*"STIM"* ]]; 
then
	continue
elif [ -f ${OUTPATH}/${SubjectID}_${SessionID}*_QC.pdf ]; #skip directories that have already been QC'd
then
	continue
else
	INPATHS_to_QC+=("$i")
	OUTPATHS_to_QC+=("$OUTPATH")
fi
done

#Run Job Array on directories that need to be QCd
if (( $SLURM_ARRAY_TASK_ID > ${#INPATHS_to_QC[@]} )); then
    echo "This array ID is unused because it exceeds the number of EEG directories."
    exit
fi

echo "Creating New QC doc: ${INPATHS_to_QC[$SLURM_ARRAY_TASK_ID]}"
bash /projects/b1134/tools/eegqc/QCpdf.sh ${INPATHS_to_QC[$SLURM_ARRAY_TASK_ID]} ${OUTPATHS_to_QC[$SLURM_ARRAY_TASK_ID]}




