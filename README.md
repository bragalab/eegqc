# EEGQC

The primary purpose EEGQC directory is to create quality control documents for individual iEEG datasets, utilizing parallel computing resources via SLURM workload manager. EEGQC.sh will search the raw data directory for unprocessed datasets, and then call QCpdf.sh to create each pdf, utilizing several helper functions (load_dataCSC.m, headertable.m, carpetplot.m, statsplot.m, powerspectrum.m, rawplot.m, MakeQCpdc.R), and save these in a processed data directory.

# Requirements

The raw data directory must be organized by .../ProjectID/SubjectID/SessionID/RunID/DateTimeID, which must contain CSC and NEV files within the DateTimeID folder, and a channellabels.txt file within the SessionID folder. This text file describes the electrodes for the given patient and session, with the following structure, with one row for each CSC file.

Name Type Dimension1 Dimension2 CSC# JackboxLetter Jackbox Number

A1     D      15           1    CSC1       A              1
A2     D      15           1    CSC2       A              2
.      .       .           .      .        .              .
.      .       .           .      .        .              .
.      .       .           .      .        .              .
.      .       .           .      .        .              .

You will also need matlab/r2020b or later and R/4.0.3.

# Usage
From the terminal:

To run EEGQC on an entire project, checking for new data and making QC documents for each dataset:
sbatch EEGQC.sh

Alternatively, you may run EEGQC on a specific dataset:
sh MakeQCpdf.sh RawPath ProcessedPath

# Troubleshooting
If the directory structure is different then what is listed in requirements, or you are receiving path related errors, then you may need to update paths within EEGQC.sh, load_dataCSC.m, and headertable.m.

Another major source of errors comes from the formatting and electrode naming within channellabels.txt, which will cause load_dataCSC.m to either crash or create a file that causes downstream errors. Check your channellabels.txt file or edit load_dataCSC.m to be able to handle your electrode labeling conventions.

# Auxillary Tools
There are some scripts for converting data from the Stanford format to other formats (Stanford2BIDS.m, Stanford2BIDS.sh, load_dataEDF.m) as well as some scripts for producing metrics (rather than QC documents) from raw data (avgstat_whiskerplot.m, avgstats.m, QC_excel_filler.m, QC_excel_filler.sh).

