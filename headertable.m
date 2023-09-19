function headertable(OUTPATH)

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
 
%% create table
    
    Pt_Info = split(OUTPATH, '/');  
    SubjectID = Pt_Info(7);
    Session = Pt_Info(8);
    Task = Pt_Info(9);
    if ~isempty(Stim1)
        Stim_Site = {strjoin(Pt_Info(10:11), '_')};
    end
    
    
    %format with commas
    str_origsamplefreq = num2str(origsamplefreq);
    str_origsamplefreq(end-2:end+1) = str_origsamplefreq(end-3:end);
    str_origsamplefreq(end-3) = ',';
    str_newsamplefreq = num2str(newsamplefreq);
    str_newsamplefreq(end-2:end+1) = str_newsamplefreq(end-3:end);
    str_newsamplefreq(end-3) = ',';
    Sample_Rate_Hz = {sprintf('%s [/%s]', str_newsamplefreq, str_origsamplefreq)};
    
    if exist('annotation_channels', 'var') %stanford data
        Input_Range_uV = {' '};
    else    
        inputrange = num2str(inputrange);%format with commas
        inputrange(end-2:end+1) = inputrange(end-3:end);
        inputrange(end-3) = ',';
        Input_Range_uV = {inputrange};
    end    
    
    Num_Channels = height(good_channels);
    Duration_s = {sprintf('%.1f',length(good_channels)/newsamplefreq)};

    if ~isempty(Stim1)
        t1 = table(SubjectID, Session, Task, Stim_Site, Sample_Rate_Hz, Input_Range_uV, ...
    Num_Channels, Duration_s);
    else
        t1 = table(SubjectID, Session, Task, Sample_Rate_Hz, Input_Range_uV, ...
    Num_Channels, Duration_s);    
    end

%% Export table
    writetable(t1,sprintf('%s/header.csv',OUTPATH))
end
