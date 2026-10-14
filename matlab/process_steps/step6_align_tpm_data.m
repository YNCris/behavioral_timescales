%{
    align the events of behavior data and tpm data
    create the aligned files of tpm data
%}
clear all
close all
genPath = genpath('./');
addpath(genPath)
%% set path
rootpath = ['E:\MTPM_body_language\' ...
    'raw_data'];
beh_path = [rootpath,'\behavior_all'];
tpm_path = [rootpath,'\tpm_suite2p'];
%% load names
fileFolder = fullfile(beh_path);
dirOutput = dir(fullfile(fileFolder,'*caliParas.mat'));
behNames = {dirOutput.name}';
temprootnames = split(behNames,'-caliParas');
rootnames = temprootnames(:,1);
%% process
for k = 1:size(rootnames,1)
    %% load name
    rootname = rootnames{k,1};
    beh_event_name = [rootname,'-event.txt'];
    tpm_event_beh_name = [rootname,'-event\beh.tdms'];
    tpm_event_tpm_name = [rootname,'-event\tpm.tdms'];
    %% load events
    event_sync = convertTDMS(false,...
        [tpm_path,'\sep\',tpm_event_beh_name]);
    tpm_event = convertTDMS(false,...
        [tpm_path,'\sep\',tpm_event_tpm_name]);

    behavior_event = importdata([beh_path,'\',beh_event_name]);
    %% first switch on to match later data (tpm data to match behavior data)
    event_sync_time_str = event_sync.Data.MeasuredData(5).Data;
    
    % fix the bugs of two different ways to sync
    splname = split(rootname,'-');
    splname1 = split(splname{3},'tpm');
    if strcmp(splname1{2},'ss')
        tpm_event_time_str = tpm_event.Data.MeasuredData(8).Data;
    else
        tpm_event_time_str = tpm_event.Data.MeasuredData(5).Data;
    end
    
    event_sync_time = timestr2sec(event_sync_time_str);
    tpm_event_time = timestr2sec(tpm_event_time_str);
    %% generate behavior_time
    behavior_time = zeros(size(behavior_event,1),1);
    start_time = event_sync_time;
    end_time = [event_sync_time(2:end,1);event_sync_time(end)+mean(diff(event_sync_time))];
    timelist = [start_time,end_time];
    start_pt = find(behavior_event==1);
    end_pt = [start_pt(2:end,1);size(behavior_event,1)];
    ptlist = [start_pt,end_pt];
    for m = 1:size(start_time,1)
        tempinter = interp1(ptlist(m,:),timelist(m,:),ptlist(m,1):ptlist(m,2),'linear');
        if m ~= size(start_time,1)
            behavior_time(ptlist(m,1):(ptlist(m,2)-1),1) = tempinter(1:(end-1))';
        else
            behavior_time(ptlist(m,1):ptlist(m,2),1) = tempinter(1:end)';
        end
    end
    %% idx matching
    behavior_tpm_idx = zeros(size(behavior_time,1),2);
    behavior_tpm_idx(:,1) = 1:size(behavior_time,1);
    tpm_idx = (1:size(tpm_event_time,1))';
    for m = 1:size(behavior_tpm_idx,1)
        tempdist = abs(behavior_time(m,1)-tpm_event_time);
        minidx = find(tempdist==min(tempdist),1,'first');
        behavior_tpm_idx(m,2) = tpm_idx(minidx,1);
    end
    %% check
    temp = tabulate(behavior_tpm_idx(:,2));
    %% save idx
    savepath = [tpm_path,'\sep\',rootname,'-event'];
    savename = 'beh_tpm_idx.mat';

    disp(behavior_tpm_idx)
    save([savepath,'\',savename],'behavior_tpm_idx')
    disp(k)
    disp('save finished!')
end




























































