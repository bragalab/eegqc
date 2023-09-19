% Creates txt file of raw data metrics for each raw data folder in
% DirectoryList. This only works for one subject at a time.
% This txt file can then be imported to an iEEG QC xlsx
function QC_excel_filler(SubjectID, IsStim)
%add directory
addpath('/projects/b1134/tools/eegqc')

if strcmp(IsStim, '0')
    IsStim = 0;
elseif strcmp(IsStim, '1')
    IsStim = 1;
end

%figure out if this is a Stanford or NU patient
IsNU = sum(isstrprop( SubjectID, 'alpha')) == length(SubjectID); %NU IDs are all letters, no numbers

%find data folders
if IsStim && IsNU %NU Stim data
    RESEARCHDIR = '/projects/b1134/processed/ieeg_stim/BNI/';
    RESEARCHList = dir(fullfile( RESEARCHDIR, SubjectID, '**', '**', '**', '**', '202*'));
    CLINICALDIR = '/projects/b1134/processed/ieeg_stim/BNI';
    CLINICALList = dir(fullfile( CLINICALDIR, SubjectID, 'NWB', '**', '**', '**', 'downsampled_data_uV.mat'));
    DirectoryList = [RESEARCHList;CLINICALList];
    RawFolderList = cell(height(DirectoryList),1);
    for i = 1:height(DirectoryList) %convert from structure to cell array of folder names
        RawFolderList{i} = sprintf('%s/%s', DirectoryList(i).folder, DirectoryList(i).name);
    end
    RawFolderList = unique(RawFolderList); %remove duplicates
elseif IsNU %NU nonstim data
    ATLASDIR = '/projects/b1134/raw/sourcedata/BragaLab/atlas';
    ATLASList = dir(fullfile( ATLASDIR, SubjectID, 'EMU*', '**', '202*'));
    QCDIR = '/projects/b1134/processed/eegqc/BNI';
    QCList = dir(fullfile( QCDIR, SubjectID, 'NWB', '**'));    
    DirectoryList = [ATLASList; QCList];
    RawFolderList = cell(height(DirectoryList),1);
    for i = 1:height(DirectoryList) %convert from structure to cell array of folder names
        if DirectoryList(i).isdir && ~contains(DirectoryList(i).name,'.')
            RawFolderList{i} = sprintf('%s/%s', DirectoryList(i).folder, DirectoryList(i).name);
        end   
    end
    RawFolderList(cellfun(@isempty, RawFolderList)) = [];
    RawFolderList = unique(RawFolderList); %remove duplicates
    RawFolderList(contains(RawFolderList, 'STIM')) = []; %remove unprocessed stim folders
elseif ~IsNU && IsStim %Stanford data
    BNIDIR = '/projects/b1134/raw/bids/Stanford';
    DirectoryList = dir(fullfile( BNIDIR, sprintf('sub-%s', SubjectID), '**', 'ieeg', 'sub-*'));  
    RawFolderList = cell(height(DirectoryList),1);
    for i = 1:height(DirectoryList) %convert from structure to cell array of folder names
        RawFolderList{i} = sprintf('%s/%s', DirectoryList(i).folder, DirectoryList(i).name);
    end
    RawFolderList = unique(RawFolderList); %remove duplicates    
end

%% extract metrics for each dataset
RawDataInfo = cell(height(RawFolderList),1);

if IsStim && IsNU %NU Stim data
    for i = 1:length(RawFolderList) %for each raw dataset
        %find raw and processed data folders
        INPATH = RawFolderList{i};
        fileinfo = split(INPATH,'/');
        SUB = fileinfo{end-5};
        SESS = fileinfo{end-4};
        TASK = sprintf('%s/%s/%s', fileinfo{end-3}, fileinfo{end-2}, fileinfo{end-1});
        OUTPATH = sprintf('/projects/b1134/processed/eegqc/BNI/%s/%s/%s', SUB, SESS, TASK);
        fprintf('Now processing %s\n', OUTPATH)
        mkdir(OUTPATH)

        %create mat file from raw data
        if ~contains(INPATH, 'downsampled_data_uV.mat')
            load_dataCSC(INPATH, OUTPATH)
        end
        %extract dataset info, add to txt file
        RawDataInfo{i} = avgstats(OUTPATH);

        %remove mat file
        if ~contains(INPATH, 'downsampled_data_uV.mat')
            delete(sprintf('%s/downsampled_data_uV.mat', OUTPATH))   
        end
    end
elseif IsNU %NU nonstim data
    for i = 1:length(RawFolderList) %for each raw dataset
        %find raw and processed data folders
	if contains(RawFolderList{i}, '202')
		INPATH = RawFolderList{i};
		fileinfo = split(INPATH,'/');
		SUB = fileinfo{end-3};
		SESS = fileinfo{end-2};
		TASK = fileinfo{end-1};
		OUTPATH = sprintf('/projects/b1134/processed/eegqc/BNI/%s/%s/%s', SUB, SESS, TASK);
		mkdir(OUTPATH)
	else
		INPATH = RawFolderList{i};
		OUTPATH = INPATH;
	end
        fprintf('Now processing %s\n', OUTPATH)


        %create mat file from raw data
	if ~exist(sprintf('%s/downsampled_data_uV.mat', OUTPATH))
        	load_dataCSC(INPATH, OUTPATH)
	end

        %extract dataset info, add to txt file
        RawDataInfo{i} = avgstats(OUTPATH);

        %remove mat file
	if IsNU & ~contains(OUTPATH, 'NWB')
        	delete(sprintf('%s/downsampled_data_uV.mat', OUTPATH))   
	end 
    end
elseif ~IsNU && IsStim %Stanford Data
    for i = 1:length(RawFolderList) %for each raw dataset
        %find raw and processed data folders
        INPATH = RawFolderList{i};
        fileinfo = split(INPATH,'/');
        SUB = fileinfo{end-3}(5:end);
        SESS = sprintf('%s-%s_%s', fileinfo{end-2}(5:7), fileinfo{end-2}(8:end-4),...
            fileinfo{end-2}(end-3:end));
        stiminfo = split(fileinfo{end}, '_');
        outdir_info = struct2cell(dir(fullfile('/projects/b1134/processed/eegqc/Stanford',SUB,SESS, 'STIM')));
        TASK = outdir_info{1,contains(outdir_info(1,:), stiminfo{end-1}(5:6))};
        OUTPATH = sprintf('/projects/b1134/processed/eegqc/Stanford/%s/%s/%s', SUB, SESS, TASK);
        fprintf('Now processing %s\n', OUTPATH)
        
        %extract dataset info, add to txt file
        RawDataInfo{i} = avgstats(OUTPATH);
    end    
end
%%
%save out txt file
currenttime = replace(sprintf('%6.9f',now), '.', '_');
OUTFILE = sprintf('/projects/b1134/processed/eegqc/logs/QC_excel_%s_%s.txt', SubjectID, currenttime);
writecell(RawDataInfo, OUTFILE)

