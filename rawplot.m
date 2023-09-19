function rawplot(OUTPATH)

%%%% Created by Chris Cyr and Cathy Kim
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
    
%% find electrode shaft edges
    edges = zeros(30,1);
    j = 1;
    i = 1;
    
    while ~ (i > length(channel_IDs))
        if strcmp(channel_IDs{i, 2}, 'D') || strcmp(channel_IDs{i, 2}, 'S')%strip, depth electrodes
            if str2double(channel_IDs{i,3}) == 18 %split up 18 contact shafts
                edges(j) = i;
                j = j + 1;
                i = i + 15;
                edges(j) = i;
                j = j + 1; 
                i = i + 3;
            else    %keep all other sizes of depth/strip electrodes together
                edges(j) = i;
                j = j+1;
                i = i + str2double(channel_IDs{i, 3});
            end    
        elseif strcmp(channel_IDs{i, 2}, 'G')%grid electrodes
            for k = 0:str2double(channel_IDs{i, 4})
                edges(j) = i + k*str2double(channel_IDs{i, 3});
                j = j + 1;
            end
            i = i + k*str2double(channel_IDs{i, 3});
        elseif strcmp(channel_IDs{i, 2}, 'X')%surface electrodes
            edges(j) = i;
            edges(j+1) = i + 10;
            break %this assumed that surface electrodes are last
        end
    end    
    
    edges = nonzeros(unique(edges));
    edges = [edges;length(channel_IDs)];
    edges(end) = edges(end)+1; %allows last channel of last shaft to be plotted

%% plot 
        numRows = 31;
        numColumns = 3;
        
        fig1 = figure('visible','off');
        fig1.Units = 'inches';
        t1 = tiledlayout(fig1,numRows,numColumns,'Padding','compact',...
        'TileSpacing','compact');
    
        fig2 = figure('visible','off');    
        fig2.Units = 'inches';
        t2 = tiledlayout(fig2,numRows,numColumns,'Padding','compact',...
        'TileSpacing','compact');
    
        fig3 = figure('visible','off');    
        fig3.Units = 'inches';
        t3 = tiledlayout(fig3,numRows,numColumns,'Padding','compact',...
        'TileSpacing','compact');  
    
        fig4 = figure('visible','off');    
        fig4.Units = 'inches';
        t4 = tiledlayout(fig4,numRows,numColumns,'Padding','compact',...
        'TileSpacing','compact');  

	fig1.Position = [10.2083    4.8438    8.5  10.5];
	fig2.Position = [10.2083    4.8438    8.5  10.5];
	fig3.Position = [10.2083    4.8438    8.5  10.5];
	fig4.Position = [10.2083    4.8438    8.5  10.5];
    
        currentfig = t1;
        tile = 1;
        moveon = 0;
        firstcolumn_firsthalf = 4:+3:46;
        secondcolumn_firsthalf = 5:+3:47;
        thirdcolumn_firsthalf = 6:+3:48;
        firstcolumn_secondhalf = 49:+3:94;
        secondcolumn_secondhalf = 50:+3:95;
        thirdcolumn_secondhalf = 51:+3:96;
        
        upper_lim = 500;
        lower_lim = -500;
        time = (1:length(good_channels))/newsamplefreq;
    
        i = 1;
        while i < length(edges) %go through each electrode shaft
            for j = edges(i):edges(i+1)-1 %for each electrode
                    
                ax = nexttile(currentfig,tile);
                if ~isempty(Stim1)
                    if j == Stim1index || j == Stim2index
                        plot(time, good_channels(j,:), 'r');
                    else
                        plot(time, good_channels(j,:));
                    end
                else
                    plot(time, good_channels(j,:));
                end
                yticks(ax,[]);
                yticklabels(ax, {});
                ylim(ax, [lower_lim upper_lim]);
                xticks(ax, []);
                xticklabels(ax, {});
                xlim(ax, [0 time(end)]);
    
                % Electrode labels
                ylabel(channel_IDs{j, 1},'FontSize', 7, 'rotation', 0, ...
                'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');
                ax.XRuler.Axle.LineStyle = 'none';
                ax.YRuler.Axle.LineStyle = 'none';
        
                if j == edges(i) %only on first electrode
                    ylabel(channel_IDs{j, 1},'FontSize', 12, 'rotation', 0, ...
                    'HorizontalAlignment', 'right', 'VerticalAlignment',...
                    'middle','FontWeight','bold');
                end
        
                tile = tile + 3;
                
            end 
            i = i + 1;
            if j < length(channel_IDs) %figure out where to start plotting the next group, add time axes
                if ismember(tile, firstcolumn_firsthalf)
                    AddTimeScale(currentfig, 46, time)                    
                    tile = 94 - (edges(i+1) - edges(i))*3;
                elseif ismember(tile, secondcolumn_firsthalf)
                    AddTimeScale(currentfig, 47, time)                       %move to second 
                    tile = 95 - (edges(i+1) - edges(i))*3;                    
                elseif ismember(tile, thirdcolumn_firsthalf)  %half of column
                    AddTimeScale(currentfig, 48, time)                    
                    tile = 96 - (edges(i+1) - edges(i))*3;                    
                elseif ismember(tile, firstcolumn_secondhalf) %move to next column
                    tile = 2;
                elseif ismember(tile, secondcolumn_secondhalf)
                    tile = 3;
                elseif ismember(tile, thirdcolumn_secondhalf) %move to next page                  
                    tile = 1;                    
                    if moveon == 0
                        moveon = 1;
                        currentfig = t2;
                    elseif moveon == 1
                        currentfig = t3;
                        moveon = 2;
                    elseif moveon == 2
                        currentfig = t4;
                    end
                end
            end    

        end
        
sgtitle(fig1, 'Raw Time Series ^{ 500}_{-500} \muV')
sgtitle(fig2, 'Raw Time Series ^{ 500}_{-500} \muV')
sgtitle(fig3, 'Raw Time Series ^{ 500}_{-500} \muV')
sgtitle(fig4, 'Raw Time Series ^{ 500}_{-500} \muV')

fig1.PaperPosition = [10.2083    4.8438    8.5  10.5];
fig2.PaperPosition = [10.2083    4.8438    8.5  10.5];
fig3.PaperPosition = [10.2083    4.8438    8.5  10.5];
fig4.PaperPosition = [10.2083    4.8438    8.5  10.5];
%% save pdfs
fig1.PaperPositionMode='manual';
fig2.PaperPositionMode='manual';
fig3.PaperPositionMode ='manual';
fig4.PaperPositionMode ='manual';
print(fig1,sprintf('%s/raw1', OUTPATH),'-dpng');
print(fig2,sprintf('%s/raw2', OUTPATH),'-dpng');
print(fig3,sprintf('%s/raw3', OUTPATH),'-dpng');
print(fig4,sprintf('%s/raw4', OUTPATH),'-dpng');
end

function AddTimeScale(currentfig, tile, time)        
    ax1 = nexttile(currentfig,tile);
    ylim([-1 1])
    yticks([]);
    ax1.XAxisLocation = 'origin';
    ax1.Color = 'None';  
    xlim(ax1, [0 time(end)])
    ax1.XTick = 0:10:time(end);
    otherticks = ones(size(ax1.XTick));
    otherticks(1:+4:end) = 0;
    ax1.XTickLabel(logical(otherticks)) = {''};
    ylabel(ax1, 'Time (s)', 'Rotation', 0, 'VerticalAlignment', 'middle', 'HorizontalAlignment', 'right')
    ax1.FontSize = 6;   
end
