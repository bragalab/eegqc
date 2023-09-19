function statsplot(OUTPATH)
%% load data
if contains(OUTPATH, 'NWB')
	load(sprintf('%s/downsampled_data_uV', replace(OUTPATH,'eegqc','eegproc')))
else
	load(sprintf('%s/downsampled_data_uV', OUTPATH)) 
end
addpath(genpath('/projects/b1134/tools/lbcn_preproc-master/'))
fileinfo = split(OUTPATH, '/');
SubjectID = fileinfo{end-4};
if sum(isletter(SubjectID)) < length(SubjectID) %for Stanford Patients
    Events = Stims;
    surf_labels = [];
    surf_channels = [];
end  
%% combine surface and iEEG matrices
channel_IDs = [channel_IDs; surf_labels];
good_channels = [good_channels; surf_channels];

%% combine good and blank channels

all_channels = [good_channels ; blank_channels];

if height(blank_channels) > 0 %skip this if there's no blank channels
    channel_IDs{height(good_channels)+height(blank_channels), 1} = [];
    blank_labels = cell(height(blank_channels),1);
    for i = 1:length(blank_labels)
        blank_labels{i} = sprintf('blank%i',i);
    end
    channel_IDs(height(good_channels)+1:height(good_channels)+height(blank_channels), 1) = blank_labels;
end 
%% create x axis labels
    letters = cell(length(channel_IDs),1);
    
    for i = 1:length(channel_IDs) %from the list of all electrode names
        if strcmp(channel_IDs{i, 1}(1),'s') || strcmp(channel_IDs{i, 1},'M2-R')
            letters{i} = 'SURF'; %relabel all surface electrodes as SURF
        else
            letters{i} = channel_IDs{i, 1}(1:find(isletter(channel_IDs{i, 1}), 1, 'last'));
        end                     %relabel all iEEG electrodes as shaft name only
    end

    letter_IDs = unique(letters,'stable'); %boil this down to one name per shaft

    letter_mean = zeros(length(letter_IDs),1);
    letter_max = zeros(length(letter_IDs),1);

    for i = 1:length(letter_IDs)
        letter_mean(i) = mean(find(strcmp(letters,letter_IDs{i}))); %average tick
        letter_max(i) = find(strcmp(letters,letter_IDs{i}),1,'last');%max tick
    end

    letter_ticks = sort([letter_mean ; letter_max]);
    letter_ticks = [0 ;letter_ticks];
    letter_ticks = abs(letter_ticks - max(letter_ticks))+0.5; 
    letter_labels = cell(length(letter_ticks),1);
    letter_labels(2:2:end) = letter_IDs;
    letter_labels(1:2:end) = {'---'};

%% calculate stats

    channel_var = var(all_channels,0,2);

    channel_mean = mean(all_channels,2);

    channel_tSNR = abs(channel_mean./std(all_channels,0,2))/0.001;

    try
        [~ ,pathological_event] = find_paChan(all_channels',channel_IDs(:, 1)...
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
        HFOs = zeros(height(all_channels),1);
        HFOs(path_channel_indices) = path_events;
        for i = length(HFOs):-1:2 %descend through electrodes and do some smoothing
            if strcmp(letters{i}, letters{i-1}) %if on same shaft
                HFOs(i) = (HFOs(i) + HFOs(i-1))/2; %average
            end
        end
        HFO_cutoff = max(HFOs);
    catch
        warning('No HFO events found.')
        path_channel_indices = [];
        path_events = [];
        HFOs = zeros(height(all_channels),1);
        HFO_cutoff = 1;
    end    

%find spikes/jumps
    nr_jumps=zeros(size(all_channels,1),2);
    for k=1:length(nr_jumps)
        nr_jumps(k,2)=length(find(diff(all_channels(k,:))>100));
        nr_jumps(k,1)=length(find(diff(all_channels(k,:))>200));
    end
    nr_jumps(:,1) = nr_jumps(:,2) - nr_jumps(:,1);
   
    mean_scale = [-20 20];
    mean_outliers = channel_mean > mean_scale(2) | channel_mean < mean_scale(1);
    
    var_scale = [0 40000];
    var_outliers = channel_var > var_scale(2) | channel_var < var_scale(1);
    
    tSNR_scale = [0 200];
    tSNR_outliers = channel_tSNR > tSNR_scale(2);
    
    jump_cutoff = 1000;
    jump_outliers = nr_jumps(:,2) > jump_cutoff;
%% plot

    fig1 = figure('visible','off');
    fig1.Units = 'inches';
    fig1.Position = [10.2083    4.8438    8  7];
    t1 = tiledlayout(fig1, 1, 5, 'Padding', 'compact', 'TileSpacing', 'compact');

    ax1 = nexttile; 
    b = bar(flipud(channel_mean), 'k','Horizontal','on', 'BarWidth', 0.665);
    b.FaceColor = 'flat';
    if ~isempty(Stim1)
        b.CData(length(channel_mean) - Stim1index + 1,:) = [1 0 0];
        b.CData(length(channel_mean) - Stim2index + 1,:) = [1 0 0];
    end
    xlabel('Mean (\muV)')
    ax1.XAxisLocation = 'top';
    ax1.FontSize = 7.5;
	yticks((flipud(letter_ticks))+0.5)
    yticklabels(flipud(letter_labels));
    ylabel('Electrode Groups')
    ax1.TickLength = [0 0];
    ax1.YRuler.TickLabelGapOffset = 2;
    xlim(mean_scale)
    hold on
    arrayfun(@(a)yline(a,'--k', 'Color' , [0.8 0.8 0.8]),flipud(letter_ticks(1:2:end)));
    hold off
    text(sign(channel_mean(mean_outliers))*mean_scale(2) *0.8,...
        length(channel_mean) - find(mean_outliers), ...
        num2str(round(channel_mean(mean_outliers))), 'FontSize',6,...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'top')
    
    ax2 = nexttile;
    b = bar(flipud(channel_var), 'k', 'Horizontal', 'on', 'BarWidth', 0.665);
    b.FaceColor = 'flat';
    if ~isempty(Stim1)
        b.CData(length(channel_var) - Stim1index + 1,:) = [1 0 0];
        b.CData(length(channel_var) - Stim2index + 1,:) = [1 0 0];
    end
    xline(5*median(channel_var), 'r')
    xlabel('Variance')
    ax2.XAxisLocation = 'top';
    ax2.FontSize = 7.5;
    yticks([])
    yticklabels({})
    ax2.TickLength = [0 0];
    xlim(var_scale)
    hold on
    arrayfun(@(a)yline(a,'--k', 'Color', [0.8 0.8 0.8]),letter_ticks(1:2:end));
    hold off
    text(sign(channel_var(var_outliers))*var_scale(2) * 0.9,...
        length(channel_var) - find(var_outliers), ...
        num2str(round(channel_var(var_outliers))), 'FontSize',6,...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'top')
    
    ax3 = nexttile;
    b = bar(flipud(channel_tSNR),'k', 'Horizontal', 'on', 'BarWidth', 0.665);
    b.FaceColor = 'flat';
    if ~isempty(Stim1)
        b.CData(length(channel_tSNR) - Stim1index + 1,:) = [1 0 0];
        b.CData(length(channel_tSNR) - Stim2index + 1,:) = [1 0 0];
    end
    xlabel('tSNR')
    ax3.XAxisLocation = 'top';
    ax3.FontSize = 7.5;
    xlim(tSNR_scale)
    yticks([])
    yticklabels({});
    ax3.TickLength = [0 0];
    hold on
    arrayfun(@(a)yline(a,'--k', 'Color', [0.8 0.8 0.8]),letter_ticks(1:2:end));
    hold off
    text(sign(channel_tSNR(tSNR_outliers))*tSNR_scale(2) * 0.9,...
        length(channel_tSNR) - find(tSNR_outliers), ...
        num2str(round(channel_tSNR(tSNR_outliers))), 'FontSize',6,...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'top')
    
    ax4 = nexttile;
    b = bar(flipud(nr_jumps), 'stacked', 'Horizontal', 'on', 'BarWidth',...
        0.665);
    b(1).FaceColor = 'flat';
    b(2).FaceColor = 'flat';   
    b(1).CData = ones(size(b(1).CData))*0;
    b(2).CData = ones(size(b(1).CData))*0.6;
    if ~isempty(Stim1)
        b(1).CData(length(nr_jumps) - Stim1index + 1,:) = [1 0 0];
        b(2).CData(length(nr_jumps) - Stim1index + 1,:) = [1 0 0];
        b(1).CData(length(nr_jumps) - Stim2index + 1,:) = [1 0 0];
        b(2).CData(length(nr_jumps) - Stim2index + 1,:) = [1 0 0];
    end
    xlabel('Jumps')
    ax4.XAxisLocation = 'top';
    ax4.FontSize = 7.5;
    yticks([])
    yticklabels({});
    xlim([0 jump_cutoff])
    ax4.TickLength = [0 0];
    hold on
    arrayfun(@(a)yline(a,'--k', 'Color', [0.8 0.8 0.8]),letter_ticks(1:2:end));
    hold off
    l = legend('200\muV','100\muV', 'NumColumns', 1);
    l.Box = 'off';
    l.Position = [0.725 0.93 0.02 0.04];
    text(sign(nr_jumps(jump_outliers,2))*jump_cutoff * 0.9,...
        length(nr_jumps(:,2)) - find(jump_outliers), ...
        num2str(nr_jumps(jump_outliers,2)), 'FontSize',6,...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'top')
    
    ax5 = nexttile;
    b = bar(flipud(HFOs),'k', 'Horizontal', 'on', 'BarWidth', 0.665);
    b.FaceColor = 'flat';
    if ~isempty(Stim1)
        b.CData(length(HFOs) - Stim1index + 1,:) = [1 0 0];
        b.CData(length(HFOs) - Stim2index + 1,:) = [1 0 0];
    end
    yticks([])
	yticklabels({});
    xlabel('HFO Events')
    ax5.XAxisLocation = 'top';
    ax5.FontSize = 7.5;
    ax5.TickLength = [0 0];
    xlim([0 HFO_cutoff])
    hold on
    arrayfun(@(a)yline(a,'--k', 'Color', [0.8 0.8 0.8]),letter_ticks(1:2:end));
    hold off
    
    sgtitle('Channel Statistics')
    fig1.Position = [10.2083    4.8438    8  7];

%% generate pdf

    fig1.PaperPositionMode='auto';
    print(fig1, sprintf('%s/statsplot', OUTPATH),'-dpng');
    
end



        
