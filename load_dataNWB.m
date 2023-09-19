%Converts raw .edf files from Stanford into our standardized .mat file
%format that all further preprocessing/analysis depends on.
%
%This script should be run manually to confirm that all file info (stim
%site, subject ID, etc.) has been captured, that the ends of the file have
%been clipped if necessary (sometimes there's large artifacts or 10-100
%seconds of unneeded data at the ends, and finally to confirm that all of the stim
%events have been detected accurately.
%
%This will output a mat file into the standard /processed/eegqc outpath and
%can then be used for all further preprocessing and analysis
function load_dataNWB(INPATH)
%% load fieldtrip tool
addpath('/projects/b1134/tools/fieldtrip-20220202')
ft_defaults

%% convert from edf to fieldtrip format

hdr = ft_read_header(INPATH, 'headerformat', 'edf');
orig_data = ft_read_data(INPATH, 'header', hdr, 'headerformat', 'edf', 'dataformat', 'edf');
  
%% extract file info
origsamplefreq = double(string(unique(hdr.orig.SampleRate)));
fileinfo = split(INPATH, '/');
SubjectID = fileinfo{end-3};
inputrange = [];
SessionID = fileinfo{end-2};
TaskID = fileinfo{end-1};
annotation_path = join(fileinfo(1:end-1), '/');
  
if strcmp(SubjectID, 'DQTAWH')
    hdr.label(106:107) = [];
elseif strcmp(SubjectID, 'OAUOBH')
    hdr.label(195) = [];
end

%% load channel info
%extract channel info from edf file
orig_labels = cell(height(hdr.label),3);
orig_labels(:,1:2) = split(hdr.label, ' ');
for i=1:height(hdr.label)
    if contains(orig_labels(i,2), '-') 
        orig_labels(i,2:3) = split(orig_labels(i,2), '-');
    end
end

%switch from clinical labeling to research labeling of channels
if strcmp(SubjectID, 'YKBYHS')
    for i = 1:height(orig_labels)
        if contains(orig_labels(i,2), "'")
            orig_labels{i,2} = ['L' replace(orig_labels{i,2}, "'",'')];
        elseif contains(orig_labels(i,2), {'AC', 's'})  
            continue
        elseif contains(orig_labels(i,2), {'A','C','D','O'})
            orig_labels{i,2} = replace(orig_labels{i,2}, {'A','C','D','O'},...
            {'RA','RC','RD','RO'});
        end
    end
elseif strcmp(SubjectID, 'OAUOBH')
    for i = 1:height(orig_labels)
        if contains(orig_labels(i,2), "'")
            orig_labels{i,2} = ['L' replace(orig_labels{i,2}, "'",'')];
        elseif contains(orig_labels(i,2), {'J','A','B','C','T'})
            orig_labels{i,2} = replace(orig_labels{i,2}, {'J','A','B','C','T'},...
            {'RJ','RA','RB','RC','RT'});
        end
    end    
end
%load additional info about each channel from subject directory
elec_path = dir(fullfile('/projects/b1134/raw/sourcedata/BragaLab/atlas', SubjectID, '**', 'channellabels.txt' ));
fid = fopen([elec_path(1).folder, '/', elec_path(1).name]);
txtinfo = textscan(fid, '%s', 'Delimiter','\n'); 
fclose(fid);
txtinfo = txtinfo{1,1};
txtinfo(cellfun(@(x) contains(x, {'#', '- - - -'}), txtinfo)) = []; %remove file header
channel_IDs = split(txtinfo, ' ');
channel_IDs(:,5:end) = [];

%% load signals and downsample if necessary
reordered_data = zeros(height(channel_IDs), width(orig_data));
for i = 1:height(channel_IDs)
    index = strcmpi(channel_IDs(i,1), orig_labels(:,2));
    if sum(index) == 1
        reordered_data(i,:) = orig_data(index,:);
    else
        fprintf('%s either isnt in the data or has duplicates\n', channel_IDs{i,1})
    end
end

if origsamplefreq == 1000
    newsamplefreq = 1000;
else    
    fprintf('Downsampling')    
    cfg = [];
    cfg.label = channel_IDs(:,1);
    cfg.fsample = origsamplefreq;
    cfg.trial{1} = reordered_data;
    cfg.time{1} = (1:size( cfg.trial{1}, 2))/cfg.fsample;
    ft_data = ft_datatype_raw(cfg);
    newsamplefreq = 1000; %hz
    cfg = [];
    cfg.resamplefs = newsamplefreq; %hz
    cfg.detrend = 'no';
    ft_data = ft_resampledata(cfg, ft_data);
    reordered_data = ft_data.trial{1,1};
end
clear orig_data

%% separate channel types

ref_indices = contains(channel_IDs(:,1), 'REF');
ref_labels = channel_IDs(ref_indices, :);
full_ref_channels = reordered_data(ref_indices,:);

blank_indices = strcmp(channel_IDs(:, 1), '-');
blank_channels = [];

chin_indices = contains(channel_IDs(:, 1), 'Chin');
chin_labels = channel_IDs(chin_indices, :);
chin_channels = [];

ekg_indices = contains(channel_IDs(:, 1), 'EKG');
ekg_labels = channel_IDs(ekg_indices, :);
full_ekg_channels = reordered_data(ekg_indices,:);

emg_indices = contains(channel_IDs(:, 1), 'EMG');
emg_labels = channel_IDs(emg_indices, :);
full_emg_channels = reordered_data(emg_indices,:);

surf_indices = contains(channel_IDs(:, 1), 's');
surf_labels = channel_IDs(surf_indices, :);
full_surf_channels = reordered_data(surf_indices,:);  

micro_indices = matches(channel_IDs(:,2), 'M');
micro_labels = channel_IDs(micro_indices,:);
micro_channels = []; 

photodiode_indices = contains(channel_IDs(:,1), 'PHOTO');
photodiode_labels = channel_IDs(photodiode_indices,:);
photodiode_channels = [];

microphone_indices = contains(channel_IDs(:,1), {'MIC', 'SPEAKER'});
microphone_labels = channel_IDs(microphone_indices,:);
microphone_channels = [];    

annotation_indices = contains(channel_IDs(:, 1), 'Annotations');
annotation_labels = channel_IDs(annotation_indices, 1);
annotation_channels = [];

reordered_data(logical(blank_indices + chin_indices + ekg_indices + ...
    ref_indices + emg_indices + surf_indices + micro_indices + ...
    photodiode_indices + microphone_indices), :) = [];
channel_IDs(logical(blank_indices + chin_indices + ekg_indices + ...
    ref_indices + emg_indices + surf_indices + micro_indices + ...
    photodiode_indices + microphone_indices), :) = [];


%% chop up and save out data
if contains(INPATH, 'STIM')
    %load either first or second annotations file, depending on which data file was loaded
    if contains(fileinfo{end}, '_1')
        fid = fopen(sprintf('%s/%s_ClinicalLFSAnnotations_1.txt', annotation_path{1}, SubjectID));    
    else
        fid = fopen(sprintf('%s/%s_ClinicalLFSAnnotations.txt', annotation_path{1}, SubjectID));
    end
    txtinfo = textscan(fid, '%s', 'Delimiter','\n');  
    txtinfo = txtinfo{1,1};
    txtinfo(cellfun(@(x) contains(x, '#'), txtinfo)) = []; %remove file header
    annotations = cell(length(txtinfo),3);
    for i = 1:length(annotations)
        annotations(i,:) = strsplit(txtinfo{i}, ' ');
    end
    fclose(fid);

    for i = 1:length(annotations)
        %create additional variables
        Stiminfo = split(annotations{i,1}, '_');
        Stiminfo = split(Stiminfo{1}, '-');
        Stim1 = Stiminfo{1};
        Stim1index = find(strcmp(Stim1, channel_IDs(:,1)));
        Stim2 = Stiminfo{2};
        Stim2index = find(strcmp(Stim2, channel_IDs(:,1)));
        Events = [];

        %split data
        Timeinfo = split(annotations{i,3}, '-');
        StartSample = seconds(datetime(Timeinfo{1}) - datetime('00:00:00'))*newsamplefreq;
        EndSample = seconds(datetime(Timeinfo{2}) - datetime('00:00:00'))*newsamplefreq;
        Buffer = 5000; %add an extra 5s to either side
        good_channels = reordered_data(:,(StartSample-Buffer):(EndSample+Buffer));
        ref_channels = full_ref_channels(:,(StartSample-Buffer):(EndSample+Buffer));
        ekg_channels = full_ekg_channels(:,(StartSample-Buffer):(EndSample+Buffer));
        emg_channels = full_emg_channels(:,(StartSample-Buffer):(EndSample+Buffer));
        surf_channels = full_surf_channels(:,(StartSample-Buffer):(EndSample+Buffer));    
        % Save workspace
        OUTPATH = sprintf('/projects/b1134/processed/eegqc/BNI/%s/%s/%s/%s/%s',...
            SubjectID, SessionID, TaskID, annotations{i,1}, annotations{i,2});
        mkdir(OUTPATH)

        save(sprintf('%s/downsampled_data_uV', OUTPATH),'good_channels','blank_channels','channel_IDs',...
                'inputrange','origsamplefreq','newsamplefreq', 'Events','ref_channels',...
                'ref_labels', 'Stim1', 'Stim1index', 'Stim2', 'Stim2index', 'chin_channels', ...
                'chin_labels', 'ekg_channels', 'ekg_labels', 'emg_channels', 'emg_labels', ...
                'surf_channels', 'surf_labels', 'micro_channels', 'micro_labels', ...
                'photodiode_channels', 'photodiode_labels', 'microphone_channels', ...
                'microphone_labels', 'annotation_channels', 'annotation_labels');
    end
else
    %create additional variables
    Stim1 = [];
    Stim1index = [];
    Stim2 = [];
    Stim2index = [];
    Events = [];

    good_channels = reordered_data;
    ref_channels = full_ref_channels;
    ekg_channels = full_ekg_channels;
    emg_channels = full_emg_channels;
    surf_channels = full_surf_channels;    
    % Save workspace
    OUTPATH = sprintf('/projects/b1134/processed/eegproc/BNI/%s/%s/%s',...
        SubjectID, SessionID, TaskID);
    mkdir(OUTPATH)

    save(sprintf('%s/downsampled_data_uV', OUTPATH),'good_channels','blank_channels','channel_IDs',...
            'inputrange','origsamplefreq','newsamplefreq', 'Events','ref_channels',...
            'ref_labels', 'Stim1', 'Stim1index', 'Stim2', 'Stim2index', 'chin_channels', ...
            'chin_labels', 'ekg_channels', 'ekg_labels', 'emg_channels', 'emg_labels', ...
            'surf_channels', 'surf_labels', 'micro_channels', 'micro_labels', ...
            'photodiode_channels', 'photodiode_labels', 'microphone_channels', ...
            'microphone_labels', 'annotation_channels', 'annotation_labels');
end

    
    
    
