%{
    re-organize data into new path

    create the hierachical data of behavior
    transform behavior and neural data into the 
    format of CEBRA
%}
clear all
close all
%% set path
rootpath = 'H:\MTPM_body_language';
beh_path = [rootpath,'\raw_data\behavior_op_20250915'];

bea_path = [beh_path,'\BeA_path'];

neu_path = [rootpath,'\raw_data\tpm_suite2p\sep'];

savepath = [rootpath,'\beh_neu_20250918'];

seq_path = [bea_path,'\recluster_data_merge'];

mkdir(savepath)
%% load names
fileFolder = fullfile(beh_path);
dirOutput = dir(fullfile(fileFolder,'*caliParas.mat'));
behNames = {dirOutput.name}';
temprootnames = split(behNames,'-caliParas');
rootnames = temprootnames(:,1);

%% load data_sample_cell
dsc_name_list = {'tpm';'free'};
dsc_class_cell = cell(size(dsc_name_list,1),2);
all_class_label = {};
for k = 1:size(dsc_name_list,1)
    %% load
    dsc_path_name = ['recluster_data_',dsc_name_list{k}];
    temp_dsc = load([bea_path,'\', ...
        dsc_path_name, ...
        '\data_sample_cell_80.mat']);

    temp_label = readtable([bea_path,'\', ...
        dsc_path_name,...
        '\cut_beh_80\beh_label.xlsx']);
    %% reorganize
    filenamelist = temp_dsc.data_sample_cell(:,3);
    filenamelist = split(filenamelist,'_struct.mat');
    filenamelist = filenamelist(:,1);

    tempsavelist = cell2mat(temp_dsc.data_sample_cell(:,2));

    tempidxlist = tempsavelist(:,4);

    class_label = temp_label.Behavior;

    all_class_label = [all_class_label;class_label];

    tempclasslist = class_label(tempidxlist);
    %% append data
    dsc_class_cell{k,1} = dsc_name_list{k,1};
    dsc_class_cell{k,2} = [tempclasslist,...
        temp_dsc.data_sample_cell(:,2),...
        filenamelist];

    disp(k)
end

%% generate a general list of behavior labels
unique_class_label = unique(all_class_label);
unique_class_idx = 1:length(unique_class_label);
%% process
for k = 1:size(rootnames,1)
    %% load name
    rootname = rootnames{k,1};

    splname = split(rootname,'-');

    if strcmp(splname{1},'free')
        behnamelist = {'tpm';'free'};
    elseif strcmp(splname{1},'fix')
        behnamelist = {'tpm';'trap'};
    elseif strcmp(splname{1},'op')
        behnamelist = {'tpm';'free'};
    else
        error('error')
    end
    %% load behavior data, include recording and social
    for m = 1:length(behnamelist)
        %% new name
        new_beh_name = [behnamelist{m},'-',rootname];
        %% pose
        temp_pose = load([bea_path,'\',new_beh_name]);
        coords3d = temp_pose.coords3d;
        save([savepath,'\',rootname,'-pose-',...
            behnamelist{m},'.mat'],...
            'coords3d')
        disp('save pose!')
        %% behavior modules
        sel_dsc_idx = strcmp(...
            dsc_class_cell(:,1),behnamelist{m});

        sel_dsc_name = dsc_class_cell{sel_dsc_idx,2};

        selidx = strcmp(sel_dsc_name(:,3),new_beh_name);

        sel_dsc = sel_dsc_name(selidx,:);

        beh_mod_list = cell(sel_dsc{end,2}(1,2),2);
        
        for n = 1:size(sel_dsc,1)
            tempdsc = sel_dsc(n,:);
            for p = tempdsc{2}(1):tempdsc{2}(2)
                beh_mod_list{p,1} = tempdsc{1};
                beh_mod_list{p,2} = ...
                    unique_class_idx(...
                    strcmp(unique_class_label,...
                    beh_mod_list{p,1}));
            end
        end

        save([savepath,'\',rootname,'-beh_mod-',...
            behnamelist{m},'.mat'],...
            'beh_mod_list')

        disp('save behavior modules')
        %% behavior sequences
        % should be done in python, too big
    end
    %% load neural data
    temp_neu = load([neu_path,'\',rootname,...
        '-tpm\final_filter_tpm.mat']);

    dff_smo_Fc = temp_neu.dff_smo_Fc;

    save([savepath,'\',rootname,'-neu.mat'],...
            'dff_smo_Fc')

    disp('save neural data')

    disp(k)

    figure
    imagesc(dff_smo_Fc,[0,2])
    colorbar
    title(rootname)
    pause(0.00000001)
end
disp('save all!')





































