%{
    split close and far using distance
%}
clear all
close all
addpath(genpath(pwd))
%% set path
rootpath = ['H:\MTPM_body_language'];

beh_video_path = [rootpath,'\raw_data\behavior_op_20250915'];

bea_path = [beh_video_path,'\BeA_path'];

process_tpm_path = [rootpath,...
    '\raw_data\tpm_suite2p\process'];

beh_neu_path = [rootpath,'\beh_neu_20250918'];
%% load data
fileFolder = fullfile(beh_neu_path);
dirOutput = dir(fullfile(fileFolder,'*-neu.mat'));
neuNames = {dirOutput.name}';

splnames = split(neuNames,'-neu.mat');
rootNames = splnames(:,1);
%% separate far and close to calcualte the correlation
dist_thres = 50;%pixels
smo_win = 60;
dist_cell = cell(size(rootNames,1),3);
for k = 1:size(rootNames,1)
    %%
    free_pose_name = [rootNames{k,1},'-pose-free.mat'];
    tpm_pose_name = [rootNames{k,1},'-pose-tpm.mat'];
    
    tempdata = load([beh_neu_path,'\',free_pose_name]);
    free_pose = tempdata.coords3d;
    for m = 1:size(free_pose,2)
        free_pose(:,m) = smooth(...
            tempdata.coords3d(:,m),smo_win);
    end
    
    tempdata = load([beh_neu_path,'\',tpm_pose_name]);
    tpm_pose = tempdata.coords3d;
    for m = 1:size(tpm_pose,2)
        tpm_pose(:,m) = smooth(...
            tempdata.coords3d(:,m),smo_win);
    end
    %% calculate distance
    m1 = free_pose;
    m2 = tpm_pose;

    all_d = zeros(size(m1,1),size(m2,2)/3);
    for m = 1:size(all_d,2)
        %%
        sel_m1 = m1(:,((m-1)*3+1):(m*3));
        sel_m2 = m2(:,((m-1)*3+1):(m*3));
        tempd = sqrt(sum((sel_m1-sel_m2).^2,2));
        all_d(:,m) = tempd;
    end
    raw_min_d = min(all_d,[],2);
    %% close idx
    close_idx = raw_min_d<dist_thres;
    %% close str
    close_str = cell(size(close_idx,1),1);
    for m = 1:size(close_str,1)
        if close_idx(m) == 0
            close_str{m,1} = 'far';
        else
            close_str{m,1} = 'close';
        end
    end
    %% append data
    dist_cell{k,1} = raw_min_d;
    dist_cell{k,2} = close_idx;
    dist_cell{k,3} = close_str;
    %% save
    free_savename = [...
        rootNames{k,1},...
        '-distance-free.mat'...
        ];
    tpm_savename = [...
        rootNames{k,1},...
        '-distance-tpm.mat'...
        ];

    dist_data = dist_cell(k,:);
    save([beh_neu_path,'\',...
        free_savename],'dist_data')
    save([beh_neu_path,'\',...
        tpm_savename],'dist_data')

    disp(k)
end
