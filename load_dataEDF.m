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
function load_dataEDF(INPATH)
%% load fieldtrip tool
addpath('/projects/b1134/tools/fieldtrip-20220202')
ft_defaults

%% convert from edf to fieldtrip format

hdr = ft_read_header(INPATH, 'headerformat', 'edf');
data = ft_read_data(INPATH, 'header', hdr, 'headerformat', 'edf', 'dataformat', 'edf');
  
%% extract file info
origsamplefreq = double(string(unique(hdr.orig.SampleRate)));
fileinfo = split(INPATH, '/');
Subject_ID = fileinfo{end-1};
inputrange = [];
Session_ID = fileinfo{end}(1:4);

%% load signals and downsample if necessary

if origsamplefreq == 1000
    good_channels = data;
    newsamplefreq = 1000;
else    
        %convert data to fieldtrip format       
        cfg = [];
        cfg.label = hdr.label;
        cfg.fsample = origsamplefreq;
        cfg.trial{1} = data;
        cfg.time{1} = (1:size( cfg.trial{1}, 2))/cfg.fsample;
        [~, ft_data] = evalc('ft_datatype_raw(cfg)'); %mute output to command line
        
        %downsample
        newsamplefreq = 1000; %hz
        cfg = [];
        cfg.resamplefs = newsamplefreq; %hz
        cfg.detrend = 'no';
        [~, ft_data] = evalc('ft_resampledata(cfg, ft_data)');
        
        %convert to uV and put channel in matrix
        good_channels = ft_data.trial{1,1};
end

%% take a look
imagesc(good_channels)
colormap gray
caxis([-1000 1000])
    
%% do some clipping
good_channels(:,[end-30000:end]) = [];

%% load channel info

orig_labels = split(hdr.label, ' ');
orig_labels{end,2} = append(orig_labels{end,2}, '-');
tmp_labels = split(orig_labels(:,2), '-');
channel_IDs = cell(height(tmp_labels), 4);
channel_IDs(:,1) = tmp_labels(:,1);

%replace labels for S19140
%load(sprintf('/projects/b1134/processed/eegqc/%s/channel_mapping.mat',Subject_ID), 'channel_mapping')
%for i = 1:height(channel_IDs) 
%    if sum(strcmp(channel_IDs{i,1},channel_mapping(:,1))) == 1 %if channel ID is in list of channels that need to be renamed
%        channel_IDs{i,1} = channel_mapping{strcmp(channel_IDs{i,1}, channel_mapping(:,1)), 2}; %rename it with the appropriate label
%    end
%end

%load additional info about each channel
fid = fopen(['/projects/b1134/processed/fs/', Subject_ID, '/', Subject_ID,  '/elec_recon/', Subject_ID, '.electrodeNames']);
electrode_info = textscan(fid, '%s', 'Delimiter','\n');  
electrode_info = electrode_info{1,1};
electrode_info(1:2) = [];%remove file header
electrode_info = split(electrode_info, ' ');

% add electrode type for each channel
for i = 1:length(channel_IDs)
    if sum(strcmp(channel_IDs(i,1), electrode_info(:,1))) == 1 %search for specific electrode in the electrode type file
        channel_IDs(i,2) = electrode_info(strcmp(channel_IDs(i,1), electrode_info(:,1)), 2); % add its info to channel I
        
    %elseif sum(strcmp(channel_IDs{i,1}(isletter(channel_IDs{i,1})), regexprep(electrode_info(:,1),'\d+$',''))) > 1 %otherwise just find the electrode shaft in the electrode type file
    %    shaft_index = find(strcmp(channel_IDs{i,1}(isletter(channel_IDs{i,1})), regexprep(electrode_info(:,1),'\d+$','')), 1);
    %    channel_IDs(i,2) = electrode_info(shaft_index, 2); %add its info to channel IDs
    end    
end

%manual edits for S19139
%channel_IDs(70:133, 2) = {'G'};
%% separate channel types

    ref_indices = contains(channel_IDs(:,1), 'REF');
    ref_labels = channel_IDs(ref_indices, 1);
    ref_channels = good_channels(ref_indices,:);

    %Stanford blank channels are indicated by A,B,C,D,E etc. followed by any number
    is_letter = cellfun(@isletter, channel_IDs(:,1), 'UniformOutput', false);
    letter_count = cellfun(@sum, is_letter);
    first_char_is_letter = cellfun(@(x) x(1)==1, is_letter);
    blank_indices = (letter_count == 1 & first_char_is_letter); 
    blank_labels = channel_IDs(blank_indices,1);
    blank_channels = good_channels(blank_indices,:);
  
    chin_indices = contains(channel_IDs(:, 1), 'Chin');
    chin_labels = channel_IDs(chin_indices, 1);
    chin_channels = good_channels(chin_indices,:);
    
    ekg_indices = contains(channel_IDs(:, 1), 'EKG');
    ekg_labels = channel_IDs(ekg_indices, 1);
    ekg_channels = good_channels(ekg_indices,:);
    
    emg_indices = contains(channel_IDs(:, 1), 'EMG');
    emg_labels = channel_IDs(emg_indices, 1);
    emg_channels = good_channels(emg_indices,:);
    
    annotation_indices = contains(channel_IDs(:, 1), 'Annotations');
    annotation_labels = channel_IDs(annotation_indices, 1);
    annotation_channels = good_channels(annotation_indices,:);
    
    DC_indices = contains(channel_IDs(:, 1), 'DC');
    DC_labels = channel_IDs(DC_indices, 1);
    DC_channels = good_channels(DC_indices,:);
   

    good_channels(logical(blank_indices + chin_indices + ekg_indices + ...
        ref_indices + emg_indices + annotation_indices + DC_indices), :) = [];
    channel_IDs(logical(blank_indices + chin_indices + ekg_indices + ...
        ref_indices + emg_indices + annotation_indices + DC_indices), :) = [];
    
%% Determine electrode shaft dimensions
shaft_counter = 1;

for i = 2:height(channel_IDs)
    if strcmp(channel_IDs{i-1,1}(1:find(isletter(channel_IDs{i-1,1}), 1, 'last')),... %if still on same shaft
            channel_IDs{i,1}(1:find(isletter(channel_IDs{i-1,1}), 1, 'last')))
        shaft_counter = shaft_counter + 1; % just keep counting
    else %otherwise, reset everything and fill in info
        if strcmp(channel_IDs(i-1,2),'D') %depth electrode
            channel_IDs(i-shaft_counter:i-1, 4) = {'1'};
            channel_IDs(i-shaft_counter:i-1, 3) = {num2str(shaft_counter)};
        elseif strcmp(channel_IDs(i-1,2),'G') %grid electrode
            if shaft_counter == 32
            	channel_IDs(i-shaft_counter:i-1, 4) = {'4'};
                channel_IDs(i-shaft_counter:i-1, 3) = {'8'};
            elseif shaft_counter == 64
            	channel_IDs(i-shaft_counter:i-1, 4) = {'8'};
                channel_IDs(i-shaft_counter:i-1, 3) = {'8'};
            end
        elseif strcmp(channel_IDs(i-1,2),'S') %strip electrode
        	channel_IDs(i-shaft_counter:i-1, 4) = {'1'};
            channel_IDs(i-shaft_counter:i-1, 3) = {num2str(shaft_counter)};
        end    
        
        shaft_counter = 1;
    end        
end
i = i + 1;

if strcmp(channel_IDs(i-1,2),'D') %depth electrode
	channel_IDs(i-shaft_counter:i-1, 4) = {'1'};
	channel_IDs(i-shaft_counter:i-1, 3) = {num2str(shaft_counter)};
elseif strcmp(channel_IDs(i-1,2),'G') %grid electrode
	if shaft_counter == 32
        channel_IDs(i-shaft_counter:i-1, 4) = {'4'};
        channel_IDs(i-shaft_counter:i-1, 3) = {'8'};
	elseif shaft_counter == 64
        channel_IDs(i-shaft_counter:i-1, 4) = {'8'};
        channel_IDs(i-shaft_counter:i-1, 3) = {'8'};
	end
elseif strcmp(channel_IDs(i-1,2),'S') %strip electrode
	channel_IDs(i-shaft_counter:i-1, 4) = {'1'};
	channel_IDs(i-shaft_counter:i-1, 3) = {num2str(shaft_counter)};
end    

    
%% find Stim electrodes in file name
    
fileinfo = split(INPATH, '/');
fileinfo = split(fileinfo{end}, '_');
Stim1 = fileinfo{end-1};
Stim2 = split(fileinfo{end}, '.');
Stim2 = Stim2{1};

if ~isletter(Stim1(1))
    Stim1(1:4) = [];
end

if ~isletter(Stim2(1))
    Stim2 = append(Stim1(isletter(Stim1)),Stim2);
end    

Stim1index = find(strcmp(channel_IDs(:, 1),Stim1));
Stim2index = find(strcmp(channel_IDs(:, 1),Stim2));

%% ALTERNATIVE enter Stim electrodes manually

Stim1 = '8L14';
Stim2 = '8L15';
Stim1index = find(strcmp(channel_IDs(:, 1),Stim1));
Stim2index = find(strcmp(channel_IDs(:, 1),Stim2));

%% load Stim events
% highpass filter stim signals
cfg = [];
cfg.label = channel_IDs([Stim1index Stim2index],1);
cfg.fsample = newsamplefreq;
cfg.trial{1} = good_channels([Stim1index Stim2index], :);
cfg.time{1} = (1:size( cfg.trial{1}, 2))/cfg.fsample;
ft_data = ft_datatype_raw(cfg); %convert to fieldtrip

cfg = [];
cfg.hpfilter = 'yes';
cfg.hpfreq = 80;
ft_data = ft_preprocessing(cfg, ft_data);
filtered_Stim = ft_data.trial{1,1};

ax1 = subplot(2,1,1);
plot(good_channels(Stim1index,:) ,'b')
ylabel(channel_IDs(Stim1index,1))
hold on
plot(filtered_Stim(1,:), 'r')
ax2 = subplot(2,1,2);
plot(good_channels(Stim2index,:) ,'b')
ylabel(channel_IDs(Stim2index,1))
hold on
plot(filtered_Stim(2,:), 'r')
sgtitle(sprintf('%i Hz high pass filter', cfg.hpfreq))
linkaxes([ax1 ax2])

%% ALTERNATIVE skip the high pass filter
filtered_Stim = good_channels([Stim1index Stim2index], :);

%% find stim events
jump = 1000;

[~, maxloc1] = findpeaks(filtered_Stim(1,:), 'MinPeakDistance', 1995, 'MinPeakProminence', jump);
[~, minloc1] = findpeaks(-filtered_Stim(1,:), 'MinPeakDistance', 1995, 'MinPeakProminence', jump);
[~, maxloc2] = findpeaks(filtered_Stim(2,:), 'MinPeakDistance', 1995, 'MinPeakProminence', jump);
[~, minloc2] = findpeaks(-filtered_Stim(2,:), 'MinPeakDistance', 1995, 'MinPeakProminence', jump);
raw_Stims = sort(unique([minloc1])); %combine events across channels
%remove duplicates
j = 1;
i = 1;
Stims = [];
while i <= length(raw_Stims)
    neighbors = abs(raw_Stims(i) - raw_Stims) < 30; % check for nearby values
    if sum(neighbors) > 1
        Stims(j) = round(mean(raw_Stims(neighbors))); %average neighbors and skip to next group
        j = j+1;
        i = find(neighbors, 1, 'last') + 1;
    else
        Stims(j) = raw_Stims(i);
        j = j + 1;
        i = i + 1; %keep searching iteratively
    end    
end    

ax1 = subplot(2,1,1);
plot(filtered_Stim(1,:), 'r')
ylabel(channel_IDs(Stim1index,1))
hold on
plot(Stims, filtered_Stim(1,Stims), 'b+')
ax2 = subplot(2,1,2);
plot(filtered_Stim(2,:), 'r')
ylabel(channel_IDs(Stim2index,1))
hold on
plot(Stims, filtered_Stim(2,Stims), 'b+')
linkaxes([ax1 ax2])
sgtitle('Searching for Stim events')

%% create extra variables
surf_channels = [];
surf_labels = [];
micro_channels = [];
micro_labels = [];
photodiode_channels = [];
photodiode_labels = [];
microphone_channels = [];
microphone_labels = []; 

%% Save workspace
OUTPATH = sprintf('/projects/b1134/processed/eegqc/%s/%s/STIM/%s-%s', Subject_ID, Session_ID, Stim1, Stim2);
mkdir(OUTPATH)

save(sprintf('%s/downsampled_data_uV', OUTPATH),'good_channels','blank_channels','channel_IDs',...
        'inputrange','origsamplefreq','newsamplefreq', 'Events','ref_channels',...
        'ref_labels', 'Stim1', 'Stim1index', 'Stim2', 'Stim2index', 'chin_channels', ...
        'chin_labels', 'ekg_channels', 'ekg_labels', 'emg_channels', 'emg_labels', ...
        'surf_channels', 'surf_labels', 'micro_channels', 'micro_labels', ...
        'photodiode_channels', 'photodiode_labels', 'microphone_channels', ...
        'microphone_labels', 'annotation_channels', 'annotation_labels', 'Stims', 'DC_channels', 'DC_labels');
end


    
    
    