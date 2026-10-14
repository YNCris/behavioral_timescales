%{
    find stereotyped sequences
%}
clear all
close all
genPath = genpath('./');
addpath(genPath)
%% set path
rootpath = 'E:\MTPM_body_language\';
beh_path = [rootpath,'\raw_data\behavior_all'];
bea_path = [beh_path,'\BeA_path'];
seq_path = [bea_path,'\recluster_data_merge'];

beh_neu_path = [rootpath,'\beh_neu_20240412'];
%% load names
fileFolder = fullfile(seq_path);
dirOutput = dir(fullfile(fileFolder,'*seqpred.mat'));
seqNames = {dirOutput.name}';

msk_token = '<msk>';

rep_time = 100;

rootNames = split(seqNames,'-seq');
rootNames = rootNames(:,1);
%% load raw data
dataname_list = {'tpm';'free';'trap'};

all_label_dsc = {};

for k = 1:size(dataname_list,1)
    temp_behname = readtable([bea_path,...
        '\recluster_data_',dataname_list{k},...
        '\cut_beh_80\beh_label.xlsx']);
    templabelname = temp_behname.Behavior;
    temp_dsc_io = load([bea_path,...
        '\recluster_data_',dataname_list{k},...
        '\py_dsc_80.mat']);
    temp_dsc = temp_dsc_io.py_dsc;

    splname = split(temp_dsc(:,2),'_');
    splname = splname(:,1);

    for m = 1:size(temp_dsc,1)
        templabel = temp_dsc{m,1}(4);
        all_label_dsc = [all_label_dsc;...
            {temp_dsc{m,1},splname{m,1},...
            templabelname{templabel}}];
    end
end
%% process
prec_cell = cell(size(seqNames,1),1);
for k = 1:size(seqNames,1)
    %% load name
    tempname = seqNames{k,1};
    %% load data
    tempdata = load([seq_path,'\',tempname]);
    temp_raw = tempdata.sel_raw;
    temp_msk = tempdata.sel_msk;
    temp_pred = tempdata.sel_pred;
    %% data re-organization
    raw_cell = cell(size(temp_raw,1),size(temp_raw,2));
    msk_cell = cell(size(temp_msk,1),size(temp_msk,2));
    pred_cell = cell(size(temp_pred,1),size(temp_raw,2));
    for m = 1:size(temp_raw,1)
        %%
        tt_raw = reshape(temp_raw(m,:,:),...
            size(temp_raw(m,:,:),2),size(temp_raw(m,:,:),3));
        tt_msk = reshape(temp_msk(m,:,:),...
            size(temp_msk(m,:,:),2),size(temp_msk(m,:,:),3));
        tt_pred = reshape(temp_pred(m,:,:),...
            size(temp_pred(m,:,:),2),size(temp_pred(m,:,:),3));
        %% delete space
        temp_str_raw = cellstr(strip(string(tt_raw)));
        temp_str_msk = cellstr(strip(string(tt_msk)));
        temp_str_pred = cellstr(strip(string(tt_pred)));
        %% append data
        raw_cell(m,:) = temp_str_raw;
        msk_cell(m,:) = temp_str_msk;
        pred_cell(m,:) = temp_str_pred(1:size(temp_raw,2));
    end
    %% compare
    cmp_mat = cell2mat(cellfun(@(x,y) strcmp(x,y),...
        raw_cell,pred_cell,'UniformOutput',false));
    msk_idx_mat = strcmp(msk_cell,msk_token);
    %% calculate the cumulate precision
    data_len = size(cmp_mat,1)/rep_time;
    cm_mean_list = zeros(data_len,size(cmp_mat,2));
    for m = 1:data_len
        temp_cmp = cmp_mat(((m-1)*rep_time+1):(m*rep_time),:);
        cm_mean_list(m,:) = mean(temp_cmp);
    end

    full_len = data_len-1+size(cm_mean_list,2);

    all_cm_mat = nan(data_len,full_len);

    for m = 1:size(all_cm_mat,1)
        all_cm_mat(m,m:(m+size(cmp_mat,2)-1)) = cm_mean_list(m,:);
    end

    all_cm_mean_list = zeros(size(all_cm_mat,2),1);

    for m = 1:size(all_cm_mat,2)
        tempcm = all_cm_mat(:,m);
        tempcm(isnan(tempcm)) = [];
        all_cm_mean_list(m,:) = mean(tempcm);
    end

    prec_cell{k,1} = all_cm_mean_list;

    disp(k)
end
%% precision spectral clustering for segmentation
clus_num = 20;
hard_thres = 0.6;
smo_win = 3;

savelist_cell = cell(size(prec_cell,1),1);

for k = 1:size(prec_cell,1)
    %%
    tempprec = prec_cell{k,1};
    %% calculate DTAK
    D = pdist(tempprec,'seuclidean');
    Z = squareform(D);
    tree = linkage(Z, 'ward','euclidean');
    T = cluster(tree,'maxclust',clus_num);
    %% thresholding
    thres_T = T;
    thres_T(tempprec<hard_thres) = 0;
    %% check contineous
    % cont_T = thres_T;
    % for m = 1:(size(thres_T,1)-smo_win+1)
    %     tempT = thres_T(m:(m+smo_win-1));
    %     if tempT(1)==tempT(3) && tempT(2)~=0
    %         cont_T(m+1) = tempT(1);
    %     end
    % end
    cont_cont_T = thres_T;
    for m = 1:(size(thres_T,1)-smo_win+1)
        tempT = thres_T(m:(m+smo_win-1));
        if tempT(1)~=tempT(2) && tempT(2)~=tempT(3)
            cont_cont_T(m+1) = 0;
        end
    end
    cont_cont_T(1) = cont_cont_T(2);
    cont_cont_T(end) = cont_cont_T(end-1);
    %% transform to savelist
    savelist = idx2savelist([cont_cont_T;cont_cont_T(end)]);
    savelist_cell{k,1} = savelist;
    %%
    % subplot(311)
    % plot(tempprec)
    % axis([0,length(tempprec),0,1])
    % title(seqNames{k})
    % subplot(312)
    % imagesc(Z)
    % subplot(313)
    % imagesc(cont_cont_T')
    % pause
end
%% reclustering
%% create data_sample_cell
data_sample_cell = {};
for k = 1:size(rootNames,1)
    %% load data
    tempname = rootNames{k,1};
    selidx = strcmp(tempname,all_label_dsc(:,2));
    sel_dsc = all_label_dsc(selidx,:);

    sel_savelist = savelist_cell{k,1}(...
        savelist_cell{k,1}(:,3)~=0,:);

    %% extract non zero part for reclustering
    for m = 1:size(sel_savelist,1)
        start_idx = sel_savelist(m,1);
        end_idx = sel_savelist(m,2);
        sel_label = sel_dsc(start_idx:end_idx,3)';
        data_sample_cell = [data_sample_cell;...
            {sel_label,[start_idx,end_idx],tempname}];
    end
end

%% calculate hamming distance mat
ham_dist_mat = zeros(...
    size(data_sample_cell,1),...
    size(data_sample_cell,1));
tic
for m = 1:size(ham_dist_mat,1)
    for n = (m+1):size(ham_dist_mat,1)
        seq1 = data_sample_cell{m,1};
        seq2 = data_sample_cell{n,1};

        temp_ham_mat = zeros(size(seq1,1),size(seq2,2));
        for p = 1:size(temp_ham_mat,1)
            for q = 1:size(temp_ham_mat,2)
                if strcmp(seq1{p},seq2{q})
                    temp_ham_mat(p,q) = 1;
                end
            end
        end

        ham_dist_mat(m,n) = mean(temp_ham_mat(:));
    end
    if rem(m,200) == 0
        disp(m)
        toc
    end
end
toc
%% fill full matrix
dist_mat_all = ham_dist_mat + triu(ham_dist_mat, 1)';
%% embedding
% [reduction, umap, clusterIdentifiers] = run_umap(dist_mat_all,...
%     'n_neighbors',199,'sgd_tasks',1,...
%     'min_dist',0.05,'metric','seuclidean','n_components', 2, 'verbose', 'text');
[reduction, umap, clusterIdentifiers] = run_umap(...
    dist_mat_all,...
    'n_neighbors',199,'sgd_tasks',1,...
    'min_dist',0.05,'metric','seuclidean',...
    'n_components', 2, 'verbose', 'text',...
     'randomize',false);
embedding = umap.embedding;

plot(embedding(:,1),embedding(:,2),'o')
axis square

%% detect clustering number
% E1 = evalclusters(embedding,'linkage',...
%     'silhouette','KList',1:100);
n_clus = 35; % from E1
D = pdist(embedding,'seuclidean');
Z = squareform(D);
tree = linkage(Z, 'ward','euclidean');
T_class = cluster(tree,'maxclust',n_clus);
%% save variables
save([seq_path,'\find_stereotyped_sequences.mat'],...
    'T_class','embedding','data_sample_cell','savelist_cell',...
    'rootNames','dist_mat_all','prec_cell')
disp('save!')
%% save to beh neu path
for k = 1:size(rootNames,1)
    %% load data
    tempname = rootNames{k,1};
    selallidx = strcmp(tempname,all_label_dsc(:,2));
    sel_all_dsc = all_label_dsc(selallidx,:);

    seldscidx = strcmp(tempname,data_sample_cell(:,3));
    sel_dsc = data_sample_cell(seldscidx,:);
    sel_label = T_class(seldscidx);
    %% append labels
    seq_label_list = zeros(sel_all_dsc{end,1}(1,2),1);

    for m = 1:size(sel_dsc,1)
        tempsavelist1 = sel_dsc{m,2};
        templabel = sel_label(m);

        selrange = ...
            sel_all_dsc{tempsavelist1(1),1}(1,1):...
            sel_all_dsc{tempsavelist1(2),1}(1,2);

        seq_label_list(selrange,1) = templabel;
    end
    %% save sequence label
    rawsplname = split(tempname,'-');

    savename = [rawsplname{2},'-',...
                rawsplname{3},'-',...
                rawsplname{4},'-',...
                rawsplname{5},'-',...
                rawsplname{6},'-seq-',...
                rawsplname{1},'.mat'];

    save([beh_neu_path,'\',savename],...
            'seq_label_list')
    disp(k)
end
disp('save!')





































