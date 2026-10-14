%{
    separate the tpm data from the animals
%}
clear all
close all
genPath = genpath('./');
addpath(genPath)
%% set path
rootpath = ['H:\MTPM_body_language\' ...
    'raw_data'];
beh_path = [rootpath,'\behavior_op_20250915'];
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

    idx_name = [rootname,'-event\beh_tpm_idx.mat'];

    raw_tpm_name = [rootname,'-tpm\raw_sep_suite2p.mat'];

    idx_mat = load([tpm_path,'\sep\',idx_name]);

    raw_tpm_mat = load([tpm_path,'\sep\',raw_tpm_name]);
    %% resample
    idx_list = idx_mat.behavior_tpm_idx(:,2);

    resample_tpm_data.stat = raw_tpm_mat.newtpmdata.stat;
    resample_tpm_data.ops = raw_tpm_mat.newtpmdata.ops;
    resample_tpm_data.F = raw_tpm_mat.newtpmdata.F(:,idx_list);
    resample_tpm_data.Fneu = raw_tpm_mat.newtpmdata.Fneu(:,idx_list);
    resample_tpm_data.spks = raw_tpm_mat.newtpmdata.spks(:,idx_list);
    resample_tpm_data.iscell = raw_tpm_mat.newtpmdata.iscell;
    resample_tpm_data.redcell = raw_tpm_mat.newtpmdata.redcell;
    resample_tpm_data.sep_idx_all = raw_tpm_mat.newtpmdata.sep_idx_all;
    resample_tpm_data.sep_idx_all_norm = raw_tpm_mat.newtpmdata.sep_idx_all_norm;
    resample_tpm_data.idx_resample = raw_tpm_mat.newtpmdata.sep_idx_all(idx_list);
    resample_tpm_data.beh_tpm_idx = idx_mat.behavior_tpm_idx;

    %% save data
    sep_tpm_path = [tpm_path,'\sep\',...
        rootname,'-tpm'];

    save([sep_tpm_path,'\resample_sep_suite2p.mat'],'resample_tpm_data')

    disp(k)
end
disp('save!')





































