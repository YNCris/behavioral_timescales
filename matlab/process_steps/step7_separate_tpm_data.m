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
    splname = split(rootname,'-');
    animal_name = splname{3};
    %% load data from process
    raw_suite2p_path = [tpm_path,'\process\',...
        animal_name,'\suite2p\plane0'];

    rawtpmdata = load([raw_suite2p_path,'\Fall.mat']);

    all_tif_path = [tpm_path,'\process\',...
        animal_name];

    tifFolder = fullfile(all_tif_path);
    dirOutput = dir(fullfile(tifFolder,'*.tif'));
    all_tifNames = {dirOutput.name}';
    
    all_tif_len_list = zeros(size(all_tifNames,1),1);
    for m = 1:size(all_tifNames,1)
        tifname = all_tifNames{m,1};
        tifinfo = imfinfo([all_tif_path,'\',tifname]);
        all_tif_len_list(m,1) = length(tifinfo);
    end

    tif_name_idx_cell = {};
    
    count = 1;
    for m = 1:size(all_tif_len_list,1)
        tempname = all_tifNames{m,1};
        tempidx = all_tif_len_list(m,1);
        for n = 1:tempidx
            tif_name_idx_cell = [...
                tif_name_idx_cell;{tempname,count}];
            count = count+1;
        end
    end
    %% load sep
    sep_tpm_path = [tpm_path,'\sep\',...
        rootname,'-tpm'];

    tifFolder = fullfile(sep_tpm_path);
    dirOutput = dir(fullfile(tifFolder,'*.tif'));
    sep_tifNames = {dirOutput.name}';
    
    sep_idx_cell = cell(size(sep_tifNames,1),2);
    for m = 1:size(sep_tifNames,1)
        tempname = sep_tifNames{m,1};
        cmpidx = strcmp(tempname,tif_name_idx_cell(:,1));
        selidxlist = cell2mat(tif_name_idx_cell(cmpidx==1,2));
        sep_idx_cell{m,1} = tempname;
        sep_idx_cell{m,2} = selidxlist;
    end

    sep_idx_all = [sep_idx_cell{1,2};sep_idx_cell{2,2}];
    
    %% sep data
    newtpmdata.stat = rawtpmdata.stat;
    newtpmdata.ops = rawtpmdata.ops;
    newtpmdata.F = rawtpmdata.F(:,sep_idx_all);
    newtpmdata.Fneu = rawtpmdata.Fneu(:,sep_idx_all);
    newtpmdata.spks = rawtpmdata.spks(:,sep_idx_all);
    newtpmdata.iscell = rawtpmdata.iscell;
    newtpmdata.redcell = rawtpmdata.redcell;
    newtpmdata.sep_idx_all = sep_idx_all;
    newtpmdata.sep_idx_all_norm = sep_idx_all-sep_idx_all(1)+1;
    %% save data
    save([sep_tpm_path,'\raw_sep_suite2p.mat'],'newtpmdata');
    disp(k)
end
disp('save!')























































