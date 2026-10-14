%{
    pca拓展到更广泛的情况
%}
clear all
close all
addpath(genpath(pwd))
%% set path
rootpath = ['E:\MTPM_body_language'];
beh_neu_path = [rootpath,'\beh_neu_20240412'];
%% load data
fileFolder = fullfile(beh_neu_path);
dirOutput = dir(fullfile(fileFolder,'free*-neu.mat'));
neuNames = {dirOutput.name}';

all_data_cell = cell(size(neuNames,1),12);
%{rootname,neudata,pose_self,mov_self,seq_self,
% pose_partner,mov_partner,seq_partner, distance,
% umap_embedding,pca_embedding}

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
        '-neu_umap.mat']);
    all_data_cell{k,10} = tempdata.umap_embedding;

    tempdata = load([beh_neu_path,'\',rootname,...
        '-neu_pca.mat']);
    all_data_cell{k,11} = tempdata.pca_embedding;

    tempdata = load([beh_neu_path,'\',rootname,...
        '-neu_linear_pred.mat']);
    all_data_cell{k,12} = tempdata.linear_pred;
    disp(k)
end

%% create the unique_mov and unique_seq
all_mov = [];
all_mov_name = {};
for k = 1:size(all_data_cell,1)
    all_mov = [all_mov;...
        cell2mat(all_data_cell{k,4}(:,2));...
        cell2mat(all_data_cell{k,7}(:,2))];
    all_mov_name = [all_mov_name;...
        all_data_cell{k,4}(:,1);...
        all_data_cell{k,7}(:,1)];
end
unique_mov = unique(all_mov);
cmap_mov = cbrewer2('BuPu',length(unique_mov));

uniuqe_mov_name = cell(size(unique_mov));
for k = 1:size(unique_mov,1)
    tempname = all_mov_name(unique_mov(k)==all_mov);
    uniuqe_mov_name{k} = tempname{1};
end

all_seq = [];
for k = 1:size(all_data_cell,1)
    all_seq = [all_seq;all_data_cell{k,5};all_data_cell{k,8}];
end
unique_seq = unique(all_seq);
unique_seq = unique_seq(2:end);
cmap_seq = cbrewer2('BuPu',length(unique_seq));
%% plot canvas
hall = figure(1);
set(hall,'Position',[680,0,800,800])
set(hall,'color','white');
%% calculate savelist
savelist_mov_cell = cell(size(all_data_cell,1),2);

for k = 1:size(savelist_mov_cell,1)
    tempmovself = cell2mat(all_data_cell{k,4}(:,2));
    tempmovpartner = cell2mat(all_data_cell{k,7}(:,2));
    savelist_mov_cell{k,1} = idx2savelist(tempmovself);
    savelist_mov_cell{k,2} = idx2savelist(tempmovpartner);
end

%% cut the edge of all mov neu
before_edge_win = 0.5;%s
after_edge_win = 0.5;%s
fs = 30;

before_edge_frame = round(before_edge_win*fs);
after_edge_frame = round(after_edge_win*fs);

cut_mov_cell = cell(size(savelist_mov_cell,1),2);
for k = 1:size(cut_mov_cell,1)
    savelist_self = savelist_mov_cell{k,1};
    savelist_self(:,1) = savelist_self(:,1)-before_edge_frame;
    savelist_self(:,2) = savelist_self(:,2)+after_edge_frame;

    savelist_self(savelist_self(:,1)<1,:) = [];
    savelist_self(savelist_self(:,2)>27000,:) = [];

    savelist_partner = savelist_mov_cell{k,2};
    savelist_partner(:,1) = ...
        savelist_partner(:,1)-before_edge_frame;
    savelist_partner(:,2) = ...
        savelist_partner(:,2)+after_edge_frame;

    savelist_partner(savelist_partner(:,1)<1,:) = [];
    savelist_partner(savelist_partner(:,2)>27000,:) = [];

    cut_mov_cell{k,1} = savelist_self;
    cut_mov_cell{k,2} = savelist_partner;
end

%% cut start edge
startedge_mov_self = {};
for k = 1:size(all_data_cell,1)
    dataname = all_data_cell{k,1};
    tempneu = all_data_cell{k,2};
    temppca = all_data_cell{k,11}{1};
    
    tempmov = cut_mov_cell{k,1};
    
    for m = 1:size(tempmov,1)
        selneu = tempneu(...
            tempmov(m,1):tempmov(m,2),:)';
        selpca = temppca(...
            tempmov(m,1):tempmov(m,2),:)';
        startedge_mov_self = [startedge_mov_self;...
            {dataname,tempmov(m,3),selneu,selpca}];
    end
    disp(k)
end

%% padding
pad_len = 200;
size_startedge_mov_self = cell2mat(cellfun(@(x) size(x,2),...
    startedge_mov_self(:,3:4),'UniformOutput',false));

selidx = (size_startedge_mov_self(:,1)<pad_len)&...
    (size_startedge_mov_self(:,2)<pad_len);

wash_startedge_mov_self = startedge_mov_self(...
    selidx,:);

pad_startedge_mov_self = wash_startedge_mov_self;
pad_startedge_mov_self(:,3:4) = cellfun(@(x) ...
    -1*ones(size(x,1),pad_len),...
    pad_startedge_mov_self(:,3:4),...
    'UniformOutput',false);

for k = 1:size(pad_startedge_mov_self,1)
    pad_mat1 = pad_startedge_mov_self{k,3};
    pad_mat2 = pad_startedge_mov_self{k,4};

    wash_mat1 = wash_startedge_mov_self{k,3};
    wash_mat2 = wash_startedge_mov_self{k,4};

    norm_wash_mat1 = zeros(size(wash_mat1));
    for m = 1:size(wash_mat1,1)
        norm_wash_mat1(m,:) = mat2gray(wash_mat1(m,:));
    end
    norm_wash_mat2 = zeros(size(wash_mat2));
    for m = 1:size(wash_mat2,1)
        norm_wash_mat2(m,:) = mat2gray(wash_mat2(m,:));
    end
end
%% temp show
all_neu = cell2mat(startedge_mov_self(:,3));

all_pca = cell2mat(startedge_mov_self(:,4));

for k = 1:20
    sel_pc_idx = 1;
    sel_mov_idx = k;
    
    pca_1 = cell2mat(cellfun(...
        @(x) mat2gray(x(sel_pc_idx,:)),...
        startedge_mov_self(:,4),...
        'UniformOutput',false));
    
    mov1_pca1 = pca_1(...
        cell2mat(startedge_mov_self(:,2))==sel_mov_idx,:);
    
    mean_mov1_pca1 = mean(mov1_pca1,2);
    
    [~,sortidx] = sort(mean_mov1_pca1);
    sort_mov1_pca1 = mov1_pca1(sortidx,:);
    
    figure
    imagesc(sort_mov1_pca1)
    title(sel_mov_idx)
end

for k = 1:20
    sel_pc_idx = 1:100;
    sel_mov_idx = k;
    
    pca_1 = cell2mat(cellfun(...
        @(x) mat2gray(mean(x(sel_pc_idx,:))),...
        startedge_mov_self(:,3),...
        'UniformOutput',false));
    
    mov1_pca1 = pca_1(...
        cell2mat(startedge_mov_self(:,2))==sel_mov_idx,:);
    
    mean_mov1_pca1 = mean(mov1_pca1,2);
    
    [~,sortidx] = sort(mean_mov1_pca1);
    sort_mov1_pca1 = mov1_pca1(sortidx,:);
    
    figure
    imagesc(sort_mov1_pca1)
    title(sel_mov_idx)
end