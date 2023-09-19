function carpetplot(OUTPATH)
%% load data
if contains(OUTPATH, 'NWB')
	load(sprintf('%s/downsampled_data_uV', replace(OUTPATH,'eegqc','eegproc')))
else
	load(sprintf('%s/downsampled_data_uV', OUTPATH)) 
end 
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

%% reduce blank channel matrix size
if height(blank_channels)>25
    blank_channels = blank_channels(1:25,:);
end

%% create y axis labels
    letters = cell(length(channel_IDs),1);

    for i = 1:length(channel_IDs) %from the list of all electrode names
        if strcmp(channel_IDs{i, 1}(1),'s')
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
    letter_ticks = [1 ;letter_ticks];
    letter_labels = cell(length(letter_ticks),1);
    letter_labels(2:2:end) = letter_IDs;
    letter_labels(1:2:end) = {'---'};

%% plot
    paperwidth = 8.5;

    fig1 = figure('visible','off');
    fig1.Units = 'inches';
    fig1.Position = [10.2083    4.8438    paperwidth  1];
    if ~isempty(Stim1) %if there's stim channels, plot them
        ax1 = axes(fig1);
        plot(good_channels(Stim1index,:),'Color', [1 0 0 1])
        hold on
        plot(good_channels(Stim2index,:),'Color', [0 0 1 0.15])
        hold off
        xlim([1 length(good_channels)])
        title('Stimulating Electrodes')
        ylabel('\muV')
        xticks([]);
        xticklabels({});
        [~, icons, ~, ~] = legend(Stim1, Stim2);
        icons(3).XData = [0.5 0.6];
        icons(5).XData = [0.5 0.6];
        icons(1).Position = [0.15 0.7 0];
        icons(2).Position = [0.15 0.25 0];
        ax1.Legend.Box = 'off';
        ax1.Position = [0.1300    0.05    0.7750    0.7115];
        ax1.Legend.Position = [.84 .43 0.094 0.3];
    end

    fig2 = figure('visible','off'); %carpet plot of good channels
    fig2.Units = 'inches';
    fig2.Position = [10.2083    4.8438    paperwidth   6.75];
    ax2 = axes(fig2);
    ax2.Units = 'inches';
    ax2.Position(2) = 0.1;
    x_scale = [0 width(good_channels)]/newsamplefreq;
    y_scale = [0 height(good_channels)];
    imagesc(ax2, x_scale, y_scale, good_channels)
    colormap gray
    yticks(letter_ticks)
    yticklabels(letter_labels)
    ax2.YAxis.TickLength = [0 0];
    ylabel('Electrode Groups') 
    ax2.XAxisLocation = 'top';
	set(ax2,'TickDir','out')
    xticks(Events/newsamplefreq)
    xticklabels({})
    xlabel(ax2, 'Stims','Position',[10000 -1 0])    
    t = title('iEEG Channels');
    t.Position(2) = -1;
    ax2.Box = 'off';
    colorbaraxis = [-200 200];
    caxis(colorbaraxis)
    fig2.Position = [10.2083    4.8438    paperwidth   6];

    fig3 = figure('visible','off'); %carpet plot of blank channels
    fig3.Units = 'inches';
    fig3.Position = [10.2083    4.8438    paperwidth  2];
    ax4 = axes(fig3);
    ax4.Units = 'inches'; 
    imagesc(ax4, x_scale, y_scale, blank_channels) %normalize axes size so that blank channels are same size as good channels
    ax4.XTick = 0:10:x_scale(2);
    otherticks = ones(size(ax4.XTick));
    otherticks(1:+4:end) = 0;
    ax4.XTickLabel(logical(otherticks)) = {''};
    ax4.Position(4) = ax2.Position(4)*(height(blank_channels)/height(good_channels));
    ax4.Position(2) = fig3.Position(4) - ax4.Position(4) - 0.2; %minimize white space at top of figure
    colormap gray
    yticks([])
    yticklabels({})
    xlabel('Time (s)','FontSize', 7)
    if ~isempty(blank_channels)
        title('Blank Channels')
    end    
    ax4.Box = 'off';
    caxis(colorbaraxis)
    ax4.TickDir = 'out';
    
    fig4 = figure('visible','off'); %colorbar for both carpet plots
    fig4.Units = 'inches';
    fig4.Position = [10.2083    4.8438    4  0.5];
    ax5 = axes(fig4);
    colormap gray
    c = colorbar;
    c.Location = 'north';
    c.Units = 'inches';
    caxis(colorbaraxis)
    ax5.Visible = 'off';
    y = ylabel(c, '\muV');
    y.Position = [230 1 0];
    c.Position = [0.6253    0.175   2.8862    0.0556];
    
    fig1.Position = [10.2083    4.8438    paperwidth  1];
    fig2.Position = [10.2083    4.8438    paperwidth   6];
    fig3.Position = [10.2083    4.8438    paperwidth  2];
    fig4.Position = [10.2083    4.8438    4  0.5];
%% generate png

    fig1.PaperPositionMode='auto';
    fig2.PaperPositionMode='auto';
    fig3.PaperPositionMode='auto';
    fig4.PaperPositionMode='auto';
    print(fig1,sprintf('%s/carpetplot_stim', OUTPATH),'-dpng');
    print(fig2,sprintf('%s/carpetplot_good', OUTPATH),'-dpng');
    print(fig3,sprintf('%s/carpetplot_blank', OUTPATH),'-dpng');
    print(fig4,sprintf('%s/colorbar', OUTPATH),'-dpng');
end

