function powerspectrum(OUTPATH)

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

%% calculate power spectrum

    set_ov=0; % overlap
    f = 0:250; %
    data_pxx=zeros(size(good_channels,1),length(f)); 
    
    for k = 1:size(good_channels,1) 
        [Pxx,f] = pwelch(good_channels(k, :),floor(newsamplefreq),set_ov,f,floor(newsamplefreq));
        data_pxx(k,:)=Pxx;
    end
%% plot    
    fig1 = figure('visible','off');
    fig1.Units = 'inches';
    fig1.Position = [10.2083    4.8438    8.5  3.5];
    ax1 = axes(fig1);
    ax1.Units = 'inches';
    ax1.Position = [0.85 0.385 4 2.7525];

    ax3 = axes(fig1);
    ax3.Units = 'inches';
    ax3.Position = [5.25 0.385 3 2.7525];
    
    if sum(contains(channel_IDs(:,1),'s')) > 0
        ax2 = axes(fig1); %only create this plot if theres surface channels
        ax2.Units = 'inches';
        ax2.Position = [6.95 2.15 1.25 1];
        hold(ax2, 'on')
    end
  
    hold([ax1 ax3], 'on')
 
    plotthis=log(data_pxx);
    
    for fi = 1:size(plotthis,1)
        if ~strcmp(channel_IDs{fi, 1}(1),'s') %only plot iEEG channels
            plot(ax1, f,plotthis(fi,:))
            text(ax1, 0:100:size(plotthis,2), plotthis(fi, 1:100:size(plotthis,2)), channel_IDs{fi, 1}, ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle','FontSize',8)            
        end
    end
    xlim(ax1,[ 1 size(plotthis,2)])
    ylim(ax1, [min(plotthis(:)) max(plotthis(:))])
    ax1.YRuler.TickLabelGapOffset = 15;
    x = xlabel(ax1, 'Frequency');
    x.Position(2) = x.Position(2) + 0.25;
    ylabel(ax1, 'log(Power)')

    plotthis=log(data_pxx(:, 1:50));
    
    if sum(contains(channel_IDs(:,1),'s')) > 0
        xlim(ax2,[ 1 size(plotthis,2)])
        ylim(ax2, [min(plotthis(:)) max(plotthis(:))]) 
        y2 = ylabel(ax2, 'Surface');
        y2.Position(1) = -5;
        yticks(ax2, [])
        yticklabels(ax2, {})
    end
    
    for fi = 1:size(plotthis,1)
        if ~strcmp(channel_IDs{fi, 1}(1),'s') %only plot non surface channels     
            plot(ax3, f(1:50),plotthis(fi,:))
            text(ax3, 50, plotthis(fi, 50), channel_IDs{fi, 1}, ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle','FontSize',8)
        else
            plot(ax2, f(1:50),plotthis(fi,:))
            text(ax2, 50, plotthis(fi, 50), channel_IDs{fi, 1}, ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle','FontSize',8)            
        end
    end
    xlim(ax3, [1 size(plotthis,2)])
    ylim(ax3, [min(plotthis(:)) max(plotthis(:))])
    %ylabel(ax3, 'iEEG Only', 'VerticalAlignment', 'middle')
    sgtitle('Power Spectral Densities');
    fig1.Position = [10.2083    4.8438    8.5  3.5];

%% generate pdf

    fig1.PaperPositionMode='auto';
    print(fig1,sprintf('%s/powerspectrum', OUTPATH),'-dpng');
   
end
