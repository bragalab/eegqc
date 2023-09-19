%%%%%%%%%%%
% Load data from CSC and Event files, downsample, and save as one large mat
% file. 
%
% The output of this function is required for other EEGQC functions in
% QCpdf.sh as well as all EEGPREPROC functions
%
% This function requires a folder INPATH with all .ncs .nev files, a folder
% txtpath with all channel labels in a txt file, and a folder OUTPATH
% where the output mat file will be saved.
%%%%%%%%%%%
function load_dataCSC(INPATH, OUTPATH)
%% add paths
addpath('/projects/b1134/tools/releaseDec2015_AMH/binaries/') %neuralynx functions
addpath('/projects/b1134/tools/fieldtrip-20220202/')
ft_defaults

%% load channel names from txt file
    %extract info from txt file of format Z15 D 15 1... aka ID Type Dimension Dimension...
    txtpath = split(INPATH, '/');
    if contains(INPATH, 'STIM')
        txtpath = join(txtpath(1:8), '/'); %for stim data
    else    
        txtpath = join(txtpath(1:9), '/'); %for all other data
    end    
    fid = fopen(sprintf('%s/channellabels.txt', txtpath{1}));
    txtinfo = textscan(fid, '%s', 'Delimiter','\n');  
    txtinfo = txtinfo{1,1};
    txtinfo(cellfun(@(x) contains(x, '#'), txtinfo)) = []; %remove file header
    channel_IDs = cell(length(txtinfo),4);
    
    for i = 1:length(channel_IDs)
        row = strsplit(txtinfo{i}, ' ');
        channel_IDs(i,:) = row(1:4); %only extract electrode ID, type, and dimensions
    end
    fclose(fid);
%% fix surface EEG labels if necessary

potential_surface_indices = find(matches(channel_IDs(:,2), 'X'));

for i = 1:length(potential_surface_indices)
    if ~strcmp(channel_IDs{potential_surface_indices(i),1}(1), 's') && ...
            ~contains(channel_IDs{potential_surface_indices(i),1}, {'REF'})
        channel_IDs{potential_surface_indices(i),1} = strcat('s', channel_IDs{potential_surface_indices(i),1}); %add an s to surface channels if need be
    end    
end    
    
%% load signals, downsample
    
    for electrode = 1:length(channel_IDs)%for each channel
         %load channel data and info
        firstfile = dir(sprintf('%s/CSC%i.ncs', INPATH, electrode)); %find first file for this electrode
        otherfiles = dir(sprintf('%s/CSC%i_*.ncs', INPATH, electrode)); %find all other files for this electrode
        cscinfo = [firstfile ; otherfiles];
        [~,idx] = max(cell2mat({cscinfo.bytes})); %use the largest file in this list
        channel = [cscinfo(idx).folder, '/', cscinfo(idx).name];

        if ~isfile(channel) %unsuccesful file search
            fprintf('WARNING: No data for channel %s.\n', channel_IDs{electrode,1})
            continue
        elseif cscinfo(idx).bytes < 20000 
            fprintf('WARNING: A file exists for channel %s but it is empty.\n', channel_IDs{electrode,1})
            continue            
        end
        
        [~, ~, ~, ~, Samples, ChannelHeader] = ...
            Nlx2MatCSC_v3(channel, [1 1 1 1 1], 1, 1, []);
        for i  = 1:length(ChannelHeader)
            if ~isempty(regexp(ChannelHeader{i}, 'SamplingFrequency'))
                origsamplefreq = str2double(ChannelHeader{i}(20:end));
            elseif ~isempty(regexp(ChannelHeader{i}, 'ADBitVolts'))    
                bits2microvolts = str2double(ChannelHeader{i}(13:end))*10^6;
            elseif ~isempty(regexp(ChannelHeader{i}, 'InputRange'))  
                inputrange = str2double(ChannelHeader{i}(13:end));
            end
        end
        
        Samples_array = Samples(:); %convert from matrix to row vector
        
        %convert data to fieldtrip format       
        cfg = [];
        cfg.label = channel_IDs(electrode, 1);
        cfg.fsample = origsamplefreq;
        cfg.trial{1} = Samples_array';
        cfg.time{1} = (1:size( cfg.trial{1}, 2))/cfg.fsample;
        [~, ft_data] = evalc('ft_datatype_raw(cfg)'); %mute output to command line
        
        if ismember(electrode, 225:256) %microwire channels
            if matches(channel_IDs(electrode,2), 'M')
                %downsample
                newsamplefreq = 10000; %hz
                cfg = [];
                cfg.resamplefs = newsamplefreq; %hz
                cfg.detrend = 'no';
                [~, ft_data] = evalc('ft_resampledata(cfg, ft_data)');

                %convert to uV and put channel in matrix
                channel_uV = ft_data.trial{1,1} * bits2microvolts;
                if ~exist('micro_channels', 'var')
                    microwirecounter = 1;
                    micro_channels = zeros(sum(matches(channel_IDs(:,2), 'M')), length(channel_uV)); %create all channel data matrix
                    micro_channels(microwirecounter,:) = channel_uV;  
                    microwirecounter = microwirecounter + 1;
                else
                    micro_channels(microwirecounter,:) = channel_uV;
                    microwirecounter = microwirecounter + 1;                
                end  
            else
                continue %skip empty microwire channels
            end    
        else    %all other channel types besides microwires
            %downsample
            newsamplefreq = 1000; %hz
            cfg = [];
            cfg.resamplefs = newsamplefreq; %hz
            cfg.detrend = 'no';
            [~, ft_data] = evalc('ft_resampledata(cfg, ft_data)');

            %convert to uV and put channel in matrix
            channel_uV = ft_data.trial{1,1} * bits2microvolts;
            if ~exist('good_channels', 'var')
                good_channels = zeros(length(channel_IDs), length(channel_uV)); %create all channel data matrix
                good_channels(electrode,:) = channel_uV;            
            else
                good_channels(electrode,:) = channel_uV;
            end
        end 
    end
    empty_indices = sum(good_channels, 2) == 0;
    good_channels(empty_indices,:) = [];
    channel_IDs(empty_indices,:) = [];
    if ~exist('micro_channels', 'var')  
        micro_channels = [];
    end
%% separate channel types

    ref_indices = contains(channel_IDs(:,1), 'REF');
    ref_labels = channel_IDs(ref_indices, :);
    ref_channels = good_channels(ref_indices,:);

    blank_indices = strcmp(channel_IDs(:, 1), '-');
    blank_channels = good_channels(blank_indices,:);
  
    chin_indices = contains(channel_IDs(:, 1), 'Chin');
    chin_labels = channel_IDs(chin_indices, :);
    chin_channels = good_channels(chin_indices,:);
    
    ekg_indices = contains(channel_IDs(:, 1), 'EKG');
    ekg_labels = channel_IDs(ekg_indices, :);
    ekg_channels = good_channels(ekg_indices,:);
    
    emg_indices = contains(channel_IDs(:, 1), 'EMG');
    emg_labels = channel_IDs(emg_indices, :);
    emg_channels = good_channels(emg_indices,:);
    
    surf_indices = contains(channel_IDs(:, 1), 's');
    surf_labels = channel_IDs(surf_indices, :);
    surf_channels = good_channels(surf_indices,:);  
    
    micro_indices = matches(channel_IDs(:,2), 'M');
    micro_labels = channel_IDs(micro_indices,:);
    
	photodiode_indices = contains(channel_IDs(:,1), 'PHOTO');
    photodiode_labels = channel_IDs(photodiode_indices,:);
    photodiode_channels = good_channels(photodiode_indices,:);
    
	microphone_indices = contains(channel_IDs(:,1), {'MIC', 'SPEAKER'});
    microphone_labels = channel_IDs(microphone_indices,:);
    microphone_channels = good_channels(microphone_indices,:);    

    good_channels(logical(blank_indices + chin_indices + ekg_indices + ...
        ref_indices + emg_indices + surf_indices + micro_indices + ...
        photodiode_indices + microphone_indices), :) = [];
    channel_IDs(logical(blank_indices + chin_indices + ekg_indices + ...
        ref_indices + emg_indices + surf_indices + micro_indices + ...
        photodiode_indices + microphone_indices), :) = [];
         
%% find stim electrodes
    if contains(OUTPATH,'STIM')
        cscinfo = split(OUTPATH,'/');
        for i = 1:length(cscinfo)
            if ~isempty(regexp(cscinfo{i}, 'STIM'))
                Stiminfo = cscinfo{i+1};
            end
        end
        
        if contains(Stiminfo,'_')
            Stiminfo(strfind(Stiminfo, '_'):end) = [];
        end
        Stiminfo = split(Stiminfo,'-');
        Stim1 = Stiminfo{1};
        Stim2 = Stiminfo{2};
        Stim1index = find(strcmp(channel_IDs(:, 1),Stim1));
        Stim2index = find(strcmp(channel_IDs(:, 1),Stim2));
    else
        Stim1 = [];
        Stim2 = [];
        Stim1index = [];
        Stim2index = [];
    end
%% load events

    if ~isempty(photodiode_channels) %favor using photodiode signal over Event files, if there is a signal
        threshold = std(photodiode_channels)*6;
        [~, Events] = findpeaks(photodiode_channels, 'MinPeakHeight', threshold,...
            'MinPeakDistance', 30, 'MinPeakProminence', threshold/2);
        if contains(OUTPATH, 'FIX')
            Events = Events(1:13);
        elseif contains(OUTPATH, 'LANG')
            Events = Events(1:365);
        elseif contains(OUTPATH, 'NBACK')
            Events = Events(1:63);  
        elseif contains(OUTPATH, 'VISCAT')
            Events = Events(1:195);
        elseif contains(OUTPATH, 'VIVID')
            Events = Events(1:122);
        end
    else
        %find largest events file, it is assumed that the rest are empty
        nev_list = dir(fullfile(INPATH,'Events*'));

        if ~size(nev_list) %if there's no events file
            fprintf('WARNING: No events for dataset %s.\n', OUTPATH)
            Events = [];
        else

            nev_size = cell2mat({nev_list.bytes});
            [~, idx] = max(nev_size);
            eventfile = {nev_list.name};
            eventfile = sprintf('%s/%s', INPATH, eventfile{idx});

            [Stamps, EventIDs, ~, ~, ~, ~]...
                = Nlx2MatEV_v3(eventfile, [1, 1, 1, 1, 1], 1, 1, [] );
            Events = (Stamps - min(Stamps))/(10^3); %time in ms from start of recording

            Events(EventIDs == 19) = 0;%remove events that aren't TTL pulses
            Events = nonzeros(Events);
            if contains(OUTPATH,'STIM')
                Events = Events(1:2:end); % there are two events for each stim, keep the earliest one
            end
        end   
    end
%% save workspace
	save(sprintf('%s/downsampled_data_uV', OUTPATH),'good_channels','blank_channels','channel_IDs',...
        'inputrange','origsamplefreq','newsamplefreq', 'Events','ref_channels',...
        'ref_labels', 'Stim1', 'Stim1index', 'Stim2', 'Stim2index', 'chin_channels', ...
        'chin_labels', 'ekg_channels', 'ekg_labels', 'emg_channels', 'emg_labels', ...
        'surf_channels', 'surf_labels', 'micro_channels', 'micro_labels', ...
        'photodiode_channels', 'photodiode_labels', 'microphone_channels', ...
        'microphone_labels');

end
