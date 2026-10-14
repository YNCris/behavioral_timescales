%{
    split data into far_close_far and close_far_close
%}
clear all
close all
addpath(genpath(pwd))
%% set path
rootpath = ['E:\MTPM_body_language'];

beh_video_path = [rootpath,'\raw_data\behavior_all'];

bea_path = [beh_video_path,'\BeA_path'];

process_tpm_path = [rootpath,...
    '\raw_data\tpm_suite2p\process'];

beh_neu_path = [rootpath,'\beh_neu_20240412'];
%% load data
fileFolder = fullfile(beh_neu_path);
dirOutput = dir(fullfile(fileFolder,'free*-cebra.mat'));
cebraNames = {dirOutput.name}';

cebra_cell = cell(size(cebraNames,1),13);
cebra_cell(:,1) = cebraNames;

smo_win = 60;

for k = 1:size(cebra_cell,1)
    tempdata = load([beh_neu_path,'\',cebraNames{k}]);
    cebra_cell{k,2} = tempdata.cebra;
    cebra_cell(k,3:10) = split(cebra_cell{k,1},'-');
    cebra_cell{k,11} = cebra_cell{k,5}(2:end);

    labelname = [cebra_cell{k,1}(1:(end-10)),'.mat'];

    templabel = load([beh_neu_path,'\',labelname]);

    neuname = [...
        cebra_cell{k,3},'-',...
        cebra_cell{k,4},'-',...
        cebra_cell{k,5},'-',...
        cebra_cell{k,6},'-',...
        cebra_cell{k,7},'-neu.mat',...
        ];

    tempneu = load([beh_neu_path,'\',neuname]);

    if strcmp(cebra_cell{k,8},'pose')
        temppose = templabel.coords3d;
        for m = 1:size(temppose,2)
            temppose(:,m) = smooth(...
                templabel.coords3d(:,m),smo_win);
        end
        cebra_cell{k,12} = temppose;
        cebra_cell{k,13} = tempneu.dff_smo_Fc';
    end

    if strcmp(cebra_cell{k,8},'beh_mod')
        cebra_cell{k,12} = templabel.beh_mod_list;
        cebra_cell{k,13} = tempneu.dff_smo_Fc';
    end

    if strcmp(cebra_cell{k,8},'seq')
        cebra_cell{k,12} = templabel.seq_label_list;
        cebra_cell{k,13} = tempneu.dff_smo_Fc';
    end
    disp(k)
end

dist_cell = cell(size(cebra_cell,1),3);
for k = 1:size(cebra_cell,1)
    distname = [...
        cebra_cell{k,3},'-',...
        cebra_cell{k,4},'-',...
        cebra_cell{k,5},'-',...
        cebra_cell{k,6},'-',...
        cebra_cell{k,7},'-',...
        'distance','-',...
        cebra_cell{k,9},'.mat'...
        ];
    tempdata = load([beh_neu_path,'\',distname]);

    dist_cell(k,:) = tempdata.dist_data;
    disp(k)
end

%% create data_sample_cell include the 
% far-close-far and close-far-close
fs = 30;
baseline_time = 5;%s
after_time = 20;%s

baseline_frame = baseline_time*fs;
after_frame = after_time*fs;


for k = 1:size(cebra_cell,1)
    %% load name cell
    data_sample_cell = {};
    count = 1;
    tempnamecell = {
        cebra_cell{k,1},cebra_cell{k,3:11}};
    %% load distance and transform into savelist
    tempdist = dist_cell{k,2};
    tempsavelist1 = idx2savelist(tempdist);
    %% create far-close-far savelist
    close_start = tempsavelist1(tempsavelist1(:,3)==1,1);
    pre_close_start = close_start-baseline_frame;
    pre_close_start(pre_close_start<0) = [];

    after_close_end = pre_close_start+baseline_frame+after_frame-1;
    pre_close_start(after_close_end>length(tempdist)) = [];
    after_close_end(after_close_end>length(tempdist)) = [];

    cut_distance = cell(size(pre_close_start,1),1);
    for m = 1:size(cut_distance,1)
        cut_distance{m} = ...
            tempdist(pre_close_start(m):...
            after_close_end(m));
    end
    
    % check distance
    del_idx = cell2mat(...
        cellfun(@(x) sum(x(1:baseline_frame))>0,...
        cut_distance,'UniformOutput',false));

    cut_distance(del_idx,:) = [];

    pre_close_start(del_idx,:) = [];
    after_close_end(del_idx,:) = [];
    %% append data
    for m = 1:size(pre_close_start,1)
        tempstart = pre_close_start(m);
        tempend = after_close_end(m);
        tempsavelist = [tempstart,tempend,count];

        cut_cebra = cebra_cell{k,2}(tempstart:tempend,:);
        cut_label = cebra_cell{k,12}(tempstart:tempend,:);
        cut_neu = cebra_cell{k,13}(tempstart:tempend,:);

        data_sample_cell = [data_sample_cell;...
            [tempnamecell,...
            {'far_close',...
            tempsavelist,cut_cebra,cut_label,cut_neu,cut_distance{m}}]];
        count = count+1;
    end
    %% create close_far_close savelist
    far_start = tempsavelist1(tempsavelist1(:,3)==0,1);
    pre_far_start = far_start-baseline_frame;
    pre_far_start(pre_far_start<0) = [];

    after_far_end = pre_far_start+baseline_frame+after_frame-1;
    pre_far_start(after_far_end>length(tempdist)) = [];
    after_far_end(after_far_end>length(tempdist)) = [];

    cut_distance = cell(size(pre_far_start,1),1);
    for m = 1:size(cut_distance,1)
        cut_distance{m} = ...
            tempdist(pre_far_start(m):...
            after_far_end(m));
    end
    
    % check distance
    del_idx = cell2mat(...
        cellfun(@(x) sum(x(1:baseline_frame))~=baseline_frame,...
        cut_distance,'UniformOutput',false));

    cut_distance(del_idx,:) = [];

    pre_far_start(del_idx,:) = [];
    after_far_end(del_idx,:) = [];
    %% append data
    for m = 1:size(pre_far_start,1)
        tempstart = pre_far_start(m);
        tempend = after_far_end(m);
        tempsavelist = [tempstart,tempend,count];

        cut_cebra = cebra_cell{k,2}(tempstart:tempend,:);
        cut_label = cebra_cell{k,12}(tempstart:tempend,:);
        cut_neu = cebra_cell{k,13}(tempstart:tempend,:);

        data_sample_cell = [data_sample_cell;...
            [tempnamecell,...
            {'close_far',...
            tempsavelist,cut_cebra,cut_label,cut_neu,cut_distance{m}}]];
        count = count+1;
    end
    %% save
    savename = [...
        cebra_cell{k,3},'-',...
        cebra_cell{k,4},'-',...
        cebra_cell{k,5},'-',...
        cebra_cell{k,6},'-',...
        cebra_cell{k,7},'-',...
        cebra_cell{k,8},'-',...
        'dsc_fc_cf','-',...
        cebra_cell{k,9},'.mat'...
        ];
    save([beh_neu_path,'\',...
        savename],'data_sample_cell')
    disp(k)
end






































