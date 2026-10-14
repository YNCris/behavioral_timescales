%{
    Separate data to BeA path
%}
clear all
close all
%% set path
rootpath = ['H:\MTPM_body_language\' ...
    'raw_data\behavior_op_20250915'];
savepath = [rootpath,'\BeA_path'];
mkdir(savepath)
%% load data
dataFolder = fullfile(rootpath);
dataOutput = dir(fullfile(dataFolder,...
    '*caliParas.mat'));
caliNames = {dataOutput.name}';
splname = split(caliNames,'-cali');
rootnames = splname(:,1);
%% process
for k = 1:size(rootnames,1)
    %% load data
    tempname = [rootnames{k,1},'-rot3d.mat'];
    tempdata = load([rootpath,'\',tempname]);
    %% separate data
    splname1 = split(tempname,'-');
    splname11 = splname1{1};

    if strcmp(splname11,'fix')
        disp('fix')
        newname_seg = {'tpm';'trap'};
    elseif strcmp(splname11,'free')
        disp('free')
        newname_seg = {'tpm';'free'};
    elseif strcmp(splname11,'op')
        disp('op')
        newname_seg = {'tpm';'free'};
    else
        disp('error')
    end

    tpmdata = tempdata.coords3d(:,1:48);
    otherdata = tempdata.coords3d(:,49:end);

    %% save data
    tpmdataname = [newname_seg{1},'-',rootnames{k,1},'.mat'];
    otherdataname = [newname_seg{2},'-',rootnames{k,1},'.mat'];

    coords3d = tpmdata;
    save([savepath,'\',tpmdataname],'coords3d')

    coords3d = otherdata;
    save([savepath,'\',otherdataname],'coords3d')

    disp('save data!')
    %% save video
    rawtpmvidname = [...
        rootnames{k,1},...
        '-camera-1_labeled_',...
        newname_seg{1},'.avi'];

    rawothervidname = [...
        rootnames{k,1},...
        '-camera-1_labeled_',...
        newname_seg{2},'.avi'];

    newtpmvidname = [newname_seg{1},'-',rootnames{k,1},'.avi'];
    newothervidname = [newname_seg{2},'-',rootnames{k,1},'.avi'];

    copyfile(...
        [rootpath,'\',rawtpmvidname],...
        [savepath,'\',newtpmvidname])

    copyfile(...
        [rootpath,'\',rawothervidname],...
        [savepath,'\',newothervidname])

    disp('copy video')

    disp(k)
end





































































