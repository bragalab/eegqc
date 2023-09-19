function Stanford2BIDS(INPATH, OUTPATH)
% loads mat file from /processed/eegqc directory, which were created using
% load_dataEDF., and converts this mat file into a BIDS version mat file,
% and saves it in the BIDS directory. This is currently only functional for
% Stim data.
%
% INPATH is in processed/eegqc directory, OUTPATH is in raw/bids directory
%
% created by Chris Cyr, February 2022
%% load data
load(INPATH)

%% do some converting
fileinfo = split(INPATH, '/');
subID = fileinfo{6};
subID = subID(isstrprop(subID, 'alphanum'));
sesID = fileinfo{7};
sesID = sesID(isstrprop(sesID, 'alphanum'));
taskID = fileinfo{8};
taskID = taskID(isstrprop(taskID, 'alphanum'));
acqID = fileinfo{9};
acqID = acqID(isstrprop(acqID, 'alphanum'));

Events = Stims/newsamplefreq;


%% save output file
cd(OUTPATH)

BIDSname = ['sub-', subID, '_ses-', sesID, '_task-', taskID, '_acq-', acqID, '_ieeg']; %include stim site under optional acquisition tag

save(BIDSname,'good_channels','blank_channels','channel_IDs', 'Events',...
        'inputrange','origsamplefreq','newsamplefreq','ref_channels',...
        'ref_labels', 'Stim1', 'Stim1index', 'Stim2', 'Stim2index', 'chin_channels', ...
        'chin_labels', 'ekg_channels', 'ekg_labels', 'emg_channels', 'emg_labels');
end
