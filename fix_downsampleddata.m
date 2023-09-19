files = dir(fullfile('/projects/b1134/processed/ieeg_stim/BNI', 'DVYZVK', 'EMU*', '**', '**', 'sub*.mat'));

FolderList = cell(height(files),1);
for i = 1:height(files) %convert from structure to cell array of folder names
    FolderList{i} = files(i).folder;
end
FolderList = unique(FolderList); %remove duplicates

%%
for i = 1:length(FolderList)
    pathinfo = strsplit(FolderList{i}, '/');
    ProjectID = pathinfo{end-5};
    SubjectID = pathinfo{end-4};
    SessionID = pathinfo{end-3};
    TaskID = pathinfo{end-2};
    StimSite = pathinfo{end-1};
    CurrentID = pathinfo{end};
    
    filename = sprintf('%s/sub-%s_ses-%s_task-%s_acq-%s-%s_ds_qcx_epoch_trialsx_bpref_z_flip.mat',...
        FolderList{i}, SubjectID, SessionID, TaskID, StimSite, CurrentID);
    load(filename)
    path_channels = {'C1';'C8';'C9';'C10';'D1';'S3';'S4'};
    for j = 1:height(channel_IDs)
        if sum(matches(split(channel_IDs{j,1},'-'), path_channels)) > 0
            Z_flip(j,:,:) = NaN;
        end
    end
    
    save(filename, 'channel_IDs', 'bad_channels', ...
        'path_channels', 'exclusion_channels', 'out_channels', 'bad_segments',...
        'white_channels', 'power_spectrum_deviant_channels', 'bad_epochs',...
        'Stim1', 'Stim2', 'Z_flip', 'flip_indicator', 'loud_channels')

    
    filename = sprintf('%s/sub-%s_ses-%s_task-%s_acq-%s-%s_ds_qcx_epoch_trialsx_bpref_z_flip_avg.mat',...
        FolderList{i}, SubjectID, SessionID, TaskID, StimSite, CurrentID);
    load(filename)
    path_channels = {'C1';'C8';'C9';'C10';'D1';'S3';'S4'};
    for j = 1:height(channel_IDs)
        if sum(matches(split(channel_IDs{j,1},'-'), path_channels)) > 0
            Z_avg_flip(j,:,:) = NaN;
        end
    end
    save(filename , 'channel_IDs', 'bad_channels', ...
        'path_channels', 'exclusion_channels', 'out_channels', 'bad_segments',...
        'white_channels', 'power_spectrum_deviant_channels', 'bad_epochs',...
        'Stim1', 'Stim2', 'Z_avg_flip', 'Z_SE', 'flip_indicator', 'loud_channels')


end
    
