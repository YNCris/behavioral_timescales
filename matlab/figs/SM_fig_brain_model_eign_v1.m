%{
    reservoir network demo
%}
clear all
close all
addpath(genpath(pwd))

rmpath(['Z:\hanyaning\multi_mice_test\Social_analysis\' ...
    'code\SBeA_Analysis\SBeA_v0.0.1\TPM\figs\function\' ...
    'gtw\lib\subspace']);
rmpath(['Z:\hanyaning\multi_mice_test\Social_analysis\' ...
    'code\SBeA_Analysis\SBeA_v0.0.1\TPM\figs\old\function\' ...
    'gtw\lib\subspace']);
%% set path
rootpath = ['X:\hanyaning\MTPM_body_language'];
beh_neu_path = [rootpath,'\beh_neu_20240412'];

%% load data
fileFolder = fullfile(beh_neu_path);
dirOutput = dir(fullfile(fileFolder,'free*-neu.mat'));
neuNames = {dirOutput.name}';

all_data_cell = cell(size(neuNames,1),12);
%{rootname,neudata,pose_self,mov_self,seq_self,
% pose_partner,mov_partner,seq_partner, distance}

for k = 1:size(all_data_cell,1)
    rootname = neuNames{k}(1:(end-8));
    all_data_cell{k,1} = rootname;
    
    tempdata = load([beh_neu_path,'\',neuNames{k}]);
    all_data_cell{k,2} = tempdata.dff_smo_Fc';

    tempdata = load([beh_neu_path,'\',rootname,...
        '-pose-tpm.mat']);
    all_data_cell{k,3} = tempdata.coords3d;

    tempdata = load([beh_neu_path,'\',rootname,...
        '-beh_mod-tpm.mat']);
    all_data_cell{k,4} = tempdata.beh_mod_list;

    tempdata = load([beh_neu_path,'\',rootname,...
        '-seq-tpm.mat']);
    all_data_cell{k,5} = tempdata.seq_label_list;

    tempdata = load([beh_neu_path,'\',rootname,...
        '-pose-free.mat']);
    all_data_cell{k,6} = tempdata.coords3d;

    tempdata = load([beh_neu_path,'\',rootname,...
        '-beh_mod-free.mat']);
    all_data_cell{k,7} = tempdata.beh_mod_list;

    tempdata = load([beh_neu_path,'\',rootname,...
        '-seq-free.mat']);
    all_data_cell{k,8} = tempdata.seq_label_list;

    tempdata = load([beh_neu_path,'\',rootname,...
        '-distance-free.mat']);
    all_data_cell{k,9} = tempdata.dist_data;

    tempdata = load([beh_neu_path,'\',rootname,...
        '-cut-rnn_ed_train_2layers.mat']);
    all_data_cell{k,10} = tempdata;

    tempdata = load([beh_neu_path,'\',rootname,...
        '-cut-rnn_ed_train_control_2layers.mat']);
    all_data_cell{k,11} = tempdata;

    tempdata = load([beh_neu_path,'\',rootname,...
        '-cut-rnn_states_ed_train_2layers.mat']);
    all_data_cell{k,12} = tempdata;
    
    disp(k)
end

load([beh_neu_path,'\l_mat_norm_20250205.mat']);

stat_tbl = ...
    readtable([beh_neu_path,'\fig6_stat_20250205.xlsx']);
%% split mouse trial from the first far-close
fs = 30;
baseline_far_time = 15;%s
cut_all_time = 10*60;%s

baseline_far_frame = baseline_far_time*fs;
cut_all_frame = cut_all_time*fs;

raw_trial_cell = {};

for k = 1:size(all_data_cell,1)
    %% load data
    tempdist = all_data_cell{k,9};
    
    %% select trials
    distsavelist = idx2savelist(tempdist{2});

    diff_len = distsavelist(:,2)-distsavelist(:,1)+1;

    far_idx = distsavelist(:,3)==0;

    diff_len_idx = diff_len>=baseline_far_frame;

    selidx = (diff_len_idx.*far_idx)==1;

    find_save_list = find(selidx,1,'first');

    sel_save_list = distsavelist(find_save_list:end,:);
    
    % modify to the same lengh of baseline
    sel_save_list(1,1) = sel_save_list(1,2)-baseline_far_frame+1;
    %% append data
    tempstart = sel_save_list(1,1);
    tempend = sel_save_list(1,1)+cut_all_frame-1;

    newname = [all_data_cell{k,1},'-cut'];
    all_data_2 = all_data_cell{k,2}(tempstart:tempend,:);
    all_data_3 = all_data_cell{k,3}(tempstart:tempend,:);
    all_data_4 = all_data_cell{k,4}(tempstart:tempend,:);
    all_data_5 = all_data_cell{k,5}(tempstart:tempend,:);
    all_data_6 = all_data_cell{k,6}(tempstart:tempend,:);
    all_data_7 = all_data_cell{k,7}(tempstart:tempend,:);
    all_data_8 = all_data_cell{k,8}(tempstart:tempend,:);
    all_data_9 = all_data_cell{k,9}{2}(tempstart:tempend,:);

    raw_trial_cell = [raw_trial_cell;...
        {newname,all_data_2,all_data_3,all_data_4,...
        all_data_5,all_data_6,all_data_7,all_data_8,...
        all_data_9,all_data_cell{k,1}}];

    unique(all_data_5)
    %%
    disp(k)
end

%% pca of all raw data
raw_pca_cell = cell(size(all_data_cell,1),7);
raw_eign_cell = cell(size(all_data_cell,1),7);

for k = 1:size(raw_pca_cell,1)
    %% select data
    sel_idx = k;
    
    selpartnerpose = all_data_cell{sel_idx,10}.XTrain;
    
    sel_e1 = all_data_cell{sel_idx,12}.states_encoder_r1;
    sel_e1 = reshape(sel_e1,[size(sel_e1,2),size(sel_e1,3)]);
    
    sel_e2 = all_data_cell{sel_idx,12}.states_encoder_r2;
    sel_e2 = reshape(sel_e2,[size(sel_e2,2),size(sel_e2,3)]);
    
    sel_d1 = all_data_cell{sel_idx,12}.states_decoder_r1;
    sel_d1 = reshape(sel_d1,[size(sel_d1,2),size(sel_d1,3)]);
    
    sel_d2 = all_data_cell{sel_idx,12}.states_decoder_r2;
    sel_d2 = reshape(sel_d2,[size(sel_d2,2),size(sel_d2,3)]);

    selselfpose = all_data_cell{sel_idx,10}.YTrain;
    %% pca
    [coeff,score,~,~,explained] = ...
        pca(selpartnerpose');
    raw_pca_cell{k,1} = {coeff,score,explained};
    [coeff,score,~,~,explained] = ...
        pca(sel_e1');
    raw_pca_cell{k,2} = {coeff,score,explained};
    [coeff,score,~,~,explained] = ...
        pca(sel_e2');
    raw_pca_cell{k,3} = {coeff,score,explained};

    raw_pca_cell{k,4} = {all_data_cell{sel_idx,10}.Train_pca,[],[]};

    [coeff,score,~,~,explained] = ...
        pca(sel_d1');
    raw_pca_cell{k,5} = {coeff,score,explained};
    [coeff,score,~,~,explained] = ...
        pca(sel_d2');
    raw_pca_cell{k,6} = {coeff,score,explained};
    [coeff,score,~,~,explained] = ...
        pca(selselfpose');
    raw_pca_cell{k,7} = {coeff,score,explained};


    disp(k)
end

%% separate far close far
%% split far-close-far trial include neural networks
fs = 30;
baseline_far_time = 5;%s
after_far_time = 5;%s
min_close_time = 2;%s
max_close_time = 10;%s

baseline_far_frame = baseline_far_time*fs;
after_far_frame = after_far_time*fs;
min_close_frame = min_close_time*fs;
max_close_frame = max_close_time*fs;

fcf_cell = {};

for k = 1:size(raw_trial_cell,1)
    %% load data
    tempdist = raw_trial_cell{k,9};
    
    temp_XTrain = all_data_cell{k,10}.XTrain;
    temp_Train_pca = all_data_cell{k,10}.Train_pca;
    temp_YTrain = all_data_cell{k,10}.YTrain;
    temp_states_encoder_r1 = ...
        all_data_cell{k,12}.states_encoder_r1;
    temp_states_encoder_r1 = reshape(...
        temp_states_encoder_r1,[...
        size(temp_states_encoder_r1,2),...
        size(temp_states_encoder_r1,3)]);
    temp_states_encoder_r2 = ...
        all_data_cell{k,12}.states_encoder_r2;
    temp_states_encoder_r2 = reshape(...
        temp_states_encoder_r2,[...
        size(temp_states_encoder_r2,2),...
        size(temp_states_encoder_r2,3)]);
    temp_states_decoder_r1 = ...
        all_data_cell{k,12}.states_decoder_r1;
    temp_states_decoder_r1 = reshape(...
        temp_states_decoder_r1,[...
        size(temp_states_decoder_r1,2),...
        size(temp_states_decoder_r1,3)]);
    temp_states_decoder_r2 = ...
        all_data_cell{k,12}.states_decoder_r2;
    temp_states_decoder_r2 = reshape(...
        temp_states_decoder_r2,[...
        size(temp_states_decoder_r2,2),...
        size(temp_states_decoder_r2,3)]);
    %% select trials
    distsavelist = idx2savelist(tempdist);

    all_close_list = distsavelist(distsavelist(:,3)==1,:);

    all_close_list(all_close_list(:,1)<baseline_far_frame,:) = [];
    all_close_list(all_close_list(:,2)>...
        length(tempdist)-after_far_frame,:) = [];
    all_close_list(...
        (all_close_list(:,2)-all_close_list(:,1))<...
        min_close_frame,:) = [];
    all_close_list(...
        (all_close_list(:,2)-all_close_list(:,1))>...
        max_close_frame,:) = [];

    selidx = zeros(size(all_close_list,1),1);

    for m = 1:size(all_close_list,1)
        tempstart = all_close_list(m,1);
        tempend = all_close_list(m,2);
        seldata_baseline = tempdist(...
            (tempstart-baseline_far_frame):(tempstart-1));
        seldata_after = tempdist(...
            (tempend+1):(tempend+after_far_frame));

        if sum(seldata_baseline)==0 && sum(seldata_after)==0
            selidx(m,1) = 1;
        end
    end

    sel_close_list = all_close_list(selidx==1,:);
    %% append data
    for m = 1:size(sel_close_list,1)
        tempstart = sel_close_list(m,1)-baseline_far_frame;
        tempend = sel_close_list(m,2)+after_far_frame;

        newname = [raw_trial_cell{k,1},'-',num2str(m)];
        all_data_2 = raw_trial_cell{k,2}(tempstart:tempend,:);
        all_data_3 = raw_trial_cell{k,3}(tempstart:tempend,:);
        all_data_4 = raw_trial_cell{k,4}(tempstart:tempend,:);
        all_data_5 = raw_trial_cell{k,5}(tempstart:tempend,:);
        all_data_6 = raw_trial_cell{k,6}(tempstart:tempend,:);
        all_data_7 = raw_trial_cell{k,7}(tempstart:tempend,:);
        all_data_8 = raw_trial_cell{k,8}(tempstart:tempend,:);
        all_data_9 = raw_trial_cell{k,9}(tempstart:tempend,:);
        
        net_XTrain = temp_XTrain(tempstart:tempend,:);
        net_YTrain = temp_YTrain(tempstart:tempend,:);
        net_e1 = temp_states_encoder_r1(tempstart:tempend,:);
        net_e2 = temp_states_encoder_r2(tempstart:tempend,:);
        net_d1 = temp_states_decoder_r1(tempstart:tempend,:);
        net_d2 = temp_states_decoder_r2(tempstart:tempend,:);

        fcf_cell = [fcf_cell;...
            {newname,all_data_2,all_data_3,all_data_4,...
            all_data_5,all_data_6,all_data_7,all_data_8,...
            all_data_9,raw_trial_cell{k,1}},...
            net_XTrain,net_YTrain,...
            net_e1,net_e2,net_d1,net_d2];

        unique(all_data_5)
    end
    %%
    disp(k)
end

fcf_length = cell2mat(cellfun(@(x) size(x,1),fcf_cell(:,2),...
    'UniformOutput',false));

[~,sortidx] = sort(fcf_length,'descend');

sort_fcf_cell = fcf_cell(sortidx,:);
%% pca
sort_pca_cell = cell(size(sort_fcf_cell,1),7);

for k = 1:size(sort_pca_cell,1)
    %% load data
    tempneu = sort_fcf_cell{k,2};
    tempXTrain = sort_fcf_cell{k,11};
    tempYTrain = sort_fcf_cell{k,12};
    tempe1 = sort_fcf_cell{k,13};
    tempe2 = sort_fcf_cell{k,14};
    tempd1 = sort_fcf_cell{k,15};
    tempd2 = sort_fcf_cell{k,16};
    %% pca
    [coeff_neu, score_neu, ~, ~, explained_neu] = ...
        pca(tempneu');
    [coeff_XTrain, score_XTrain, ~, ~, explained_XTrain] = ...
        pca(tempXTrain');
    [coeff_YTrain, score_YTrain, ~, ~, explained_YTrain] = ...
        pca(tempYTrain');
    [coeff_e1, score_e1, ~, ~, explained_e1] = ...
        pca(tempe1');
    [coeff_e2, score_e2, ~, ~, explained_e2] = ...
        pca(tempe2');
    [coeff_d1, score_d1, ~, ~, explained_d1] = ...
        pca(tempd1');
    [coeff_d2, score_d2, ~, ~, explained_d2] = ...
        pca(tempd2');
    %% append data
    sort_pca_cell{k,1} = ...
        {coeff_XTrain,score_XTrain,explained_XTrain};
    sort_pca_cell{k,2} = ...
        {coeff_e1,score_e1,explained_e1};
    sort_pca_cell{k,3} = ...
        {coeff_e2,score_e2,explained_e2};
    sort_pca_cell{k,4} = ...
        {coeff_neu,score_neu,explained_neu};
    sort_pca_cell{k,5} = ...
        {coeff_d1,score_d1,explained_d1};
    sort_pca_cell{k,6} = ...
        {coeff_d2,score_d2,explained_d2};
    sort_pca_cell{k,7} = ...
        {coeff_YTrain,score_YTrain,explained_YTrain};

    disp(k)
end

%% plot canvas
hall = figure(1);
set(hall,'Position',[680,0,800,800])
set(hall,'color','white');

















