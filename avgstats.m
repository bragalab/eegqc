%%%%%%%%%
% Calculate average mean, std, tSNR, jumps, and HFO events across channels that
% are plugged in
%
%%%%%%%%%%%%%%%%
function [output] = avgstats(OUTPATH)
%% load data
    cd(OUTPATH)
    load('downsampled_data_uV.mat')
    addpath(genpath('/projects/b1134/tools/lbcn_preproc-master/'))
    
%% combine surface and iEEG matrices
channel_IDs = [channel_IDs; surf_labels];
good_channels = [good_channels; surf_channels];
    
%% use mat file to extract dataset info
    load(sprintf('%s/downsampled_data_uV', OUTPATH), 'good_channels', 'newsamplefreq', 'origsamplefreq', 'inputrange')
    num_channels = sprintf('%i/%i', sum(good_channels(:,1) ~= 0), height(good_channels)); %channels may be labeled as good but actually are all zeros
    samplerate = sprintf('%i/%i', newsamplefreq, origsamplefreq);
    duration = sprintf('%.1f',length(good_channels)/newsamplefreq);  
    fileinfo = split(OUTPATH,'/');
    if contains(OUTPATH, 'STIM')
        SUB = fileinfo{end-4};
        SESS = fileinfo{end-3};
        TASK = sprintf('%s/%s/%s', fileinfo{end-2}, fileinfo{end-1}, fileinfo{end});
    else    
        SUB = fileinfo{end-2};
        SESS = fileinfo{end-1};
        TASK = fileinfo{end};
    end
    
%% remove unplugged good channels as well as stim channels
unplugged_channels = good_channels(:,1) == 0;
unplugged_channels(Stim1index) = 1;
unplugged_channels(Stim2index) = 1;
good_channels(unplugged_channels,:) = [];

%% calculate stats for individual channels
    channel_corr = mean(corrcoef(good_channels'),2);%average correlation of each channel with all other channels, including itself
    channel_std = std(good_channels,0,2);
    channel_mean = mean(good_channels,2);
    channel_tSNR = abs(channel_mean./std(good_channels,0,2))/0.001;

    try
        [~ ,pathological_event] = find_paChan(good_channels',channel_IDs(:, 1)...
            ,newsamplefreq, 1.5); %find pathological events
        [path_events, path_channels] = groupcounts(pathological_event.channel'); %find names of path channels
                                         %and number of events per channel

        for i = 1:length(path_channels) %convert from bipolar to unipolar
            path_channels{i} = path_channels{i}(1:find(isstrprop(path_channels{i},'punct'))-1);
        end

        path_channel_indices = zeros(length(path_channels),1);
        for i = 1:length(path_channel_indices)
            path_channel_indices(i) = find(strcmp(path_channels{i},channel_IDs(:,1)));
        end
        HFOs = zeros(height(good_channels),1);
        HFOs(path_channel_indices) = path_events;
        
        letters = cell(length(channel_IDs),1); %create list of electrode shaft names only
    
        for i = 1:length(channel_IDs) %from the list of all electrode names
            if strcmp(channel_IDs{i, 1}(1),'s') || strcmp(channel_IDs{i, 1},'M2-R')
                letters{i} = 'SURF'; %relabel all surface electrodes as SURF
            else
                letters{i} = channel_IDs{i, 1}(isletter(channel_IDs{i, 1}));
            end                     %relabel all iEEG electrodes as shaft name only
        end
        
        for i = length(HFOs):-1:2 %descend through electrodes and do some smoothing
            if strcmp(letters{i}, letters{i-1}) %if on same shaft
                HFOs(i) = (HFOs(i) + HFOs(i-1))/2; %average
            end
        end

    catch
        warning('No HFO events found.')
        path_channel_indices = [];
        path_events = [];
        HFOs = zeros(height(good_channels),1);
    end    

%find spikes/jumps
    nr_jumps=zeros(size(good_channels,1),2);
    for k=1:length(nr_jumps)
        nr_jumps(k,2)=length(find(diff(good_channels(k,:))>100));%column 2, jumps greater than 100uV
        nr_jumps(k,1)=length(find(diff(good_channels(k,:))>200));%column 1, jumps greater than 200uV
    end
    nr_jumps(:,1) = nr_jumps(:,2) - nr_jumps(:,1); %remove double counted jumps
    
%% average across channels    
avg_corr = mean(channel_corr);
avg_mean = mean(channel_mean);
avg_std = mean(channel_std);
avg_tSNR = mean(channel_tSNR);
avg_jumps_100 = mean(nr_jumps(:,2));
avg_jumps_200 = mean(nr_jumps(:,1));
avg_HFOs = mean(HFOs); 

%% combine all info
output = sprintf('%s %s %s  %s %i %s %s %0.4f %3.2f %.1f %.1f %.0f %.0f %.1f', ...
        SUB, SESS, TASK, samplerate, inputrange, num_channels, duration, ...
        avg_corr, avg_mean, avg_std, avg_tSNR, avg_jumps_100, avg_jumps_200, avg_HFOs);

fprintf('\nDataset Metrics:\n')
fprintf('Subject ID, SessionID, TaskID, Sample Rate, Input Range, Num Channels, Duration, Correlation, Mean, STD, tSNR, 100uV Jumps, 200uV Jumps, HFOs\n')
fprintf('%s\n',output)

end
        
