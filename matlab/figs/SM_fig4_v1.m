%{
    画所有的neural syntax在一个图
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

load([beh_neu_path,'\dist_mat_all_20240822.mat'])
load([beh_neu_path,'\embedding_20240822.mat'])
load([beh_neu_path,'\data_sample_cell_20240822.mat'])
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
%% cluster number calculate
T = cell2mat(data_sample_cell(:,4));

n_clus = length(unique(T));

neu_clus_cmap = cbrewer2('Paired',n_clus);

neu_clus_cmaplist = neu_clus_cmap(T,:);


%% create mov_dsc
mov_dsc = cell(size(data_sample_cell,1),2);

for k = 1:size(data_sample_cell,1)
    tempname = data_sample_cell{k,3};
    selmouseidx = strcmp(tempname,all_data_cell(:,1));
    tempsavelist = data_sample_cell{k,2};


    selmov_self = cell2mat(all_data_cell{selmouseidx,4}(...
        tempsavelist(1):tempsavelist(2),2));
    selmov_partner = cell2mat(all_data_cell{selmouseidx,7}(...
        tempsavelist(1):tempsavelist(2),2));

    mov_dsc{k,1} = selmov_self';
    mov_dsc{k,2} = selmov_partner';
end
%% plot canvas
hall = figure(1);
set(hall,'Position',[680,0,800,800])
set(hall,'color','white');
%% show all of the neural syntax
start_x = 0.09;
start_y = 0.73;

box_x = 0.85;
box_y = 0.25;

unique_dsc_name = unique(data_sample_cell(:,3));

brain_name = {...
    'tpmss';...
    'tpmpfc';...
    'tpmm'};

spl_unique_name = split(unique_dsc_name,'-');

spl_unique_brain_name = cellfun(@(x) x(2:end),...
    spl_unique_name(:,3),'UniformOutput',false);

sort_unique_name = {};
for k = 1:size(brain_name,1)
    tempname = brain_name{k,1};
    selidx = strcmp(tempname,spl_unique_brain_name);
    selname = unique_dsc_name(selidx,:);
    sort_unique_name = [sort_unique_name;selname];
end

show_mouse_name = {...
    'S1 mouse 1';...
    'S1 mouse 2';...
    'S1 mouse 3';...
    'S1 mouse 4';...
    'S1 mouse 5';...
    'dmPFC mouse 1';...
    'dmPFC mouse 2';...
    'dmPFC mouse 3';...
    'dmPFC mouse 4';...
    'dmPFC mouse 5';...
    'M1 mouse 1';...
    'M1 mouse 2';...
    'M1 mouse 3';...
    'M1 mouse 4';...
    'M1 mouse 5';...
    };

show_mat = zeros(size(sort_unique_name,1),27000);
for k = 1:size(show_mat,1)
    tempname = sort_unique_name{k,1};
    selidx = strcmp(data_sample_cell(:,3),tempname);
    sel_T = T(selidx);
    sel_savelist = data_sample_cell(selidx,2);

    show_list = zeros(1,size(show_mat,2));
    for m = 1:size(sel_savelist,1)
        show_list(1,...
            sel_savelist{m}(1):...
            sel_savelist{m}(2)) = sel_T(m);
    end

    show_mat(k,:) = show_list;
end

temph = subplot('Position',[start_x,start_y,box_x,box_y]);
imagesc(show_mat)
colormap(temph,neu_clus_cmap)
set(gca,'XTick',[1,27000])
set(gca,'XTickLabel',[])
set(gca,'YTick',1:size(sort_unique_name,1))
set(gca,'YTickLabel',show_mouse_name)
set(gca,'TickDir','out')
set(gca,'FontSize',6)
box off

% colorbar
cbar_box_x = 0.01;
cbar_box_y = 0.08;

cbar_inter_x = 0.005;

temph = subplot('Position',[...
    start_x+box_x+cbar_inter_x,...
    start_y+box_y-cbar_box_y,...
    cbar_box_x,cbar_box_y]);
imagesc((1:size(neu_clus_cmap,1))')
colormap(temph,neu_clus_cmap)
set(gca,'XTick',[],'YTick',[])
text(2.5,4,'Neural motifs','Rotation',90,...
    'FontSize',6,...
    'HorizontalAlignment','center')

% show movement motifs, self
inter_y = 0.02;

show_mat_self = zeros(size(sort_unique_name,1),27000);
for k = 1:size(show_mat_self,1)
    tempname = sort_unique_name{k,1};
    selidx = strcmp(data_sample_cell(:,3),tempname);
    sel_mov = mov_dsc(selidx,1);
    sel_savelist = data_sample_cell(selidx,2);

    show_list = zeros(1,size(show_mat_self,2));
    for m = 1:size(sel_savelist,1)
        show_list(1,...
            sel_savelist{m}(1):...
            sel_savelist{m}(2)) = sel_mov{m};
    end

    show_mat_self(k,:) = show_list;
end

temph = subplot('Position',[start_x,...
    start_y-inter_y-box_y,...
    box_x,box_y]);
imagesc(show_mat_self)
colormap(temph,cmap_mov)
set(gca,'XTick',[1,27000])
set(gca,'XTickLabel',[])
set(gca,'YTick',1:size(sort_unique_name,1))
set(gca,'YTickLabel',show_mouse_name)
set(gca,'TickDir','out')
set(gca,'FontSize',6)
box off

% colorbar
cbar_box_x = 0.01;
cbar_box_y = 0.08;

cbar_inter_x = 0.005;

temph = subplot('Position',[...
    start_x+box_x+cbar_inter_x,...
    start_y+box_y-cbar_box_y-inter_y-box_y,...
    cbar_box_x,cbar_box_y]);
imagesc((1:size(cmap_mov,1))')
colormap(temph,cmap_mov)
set(gca,'XTick',[],'YTick',[])
text(2.5,size(cmap_mov,1)/2,'Movements','Rotation',90,...
    'FontSize',6,...
    'HorizontalAlignment','center')

% show movement motifs, partner
inter_y = 0.02;

show_mat_self = zeros(size(sort_unique_name,1),27000);
for k = 1:size(show_mat_self,1)
    tempname = sort_unique_name{k,1};
    selidx = strcmp(data_sample_cell(:,3),tempname);
    sel_mov = mov_dsc(selidx,2);
    sel_savelist = data_sample_cell(selidx,2);

    show_list = zeros(1,size(show_mat_self,2));
    for m = 1:size(sel_savelist,1)
        show_list(1,...
            sel_savelist{m}(1):...
            sel_savelist{m}(2)) = sel_mov{m};
    end

    show_mat_self(k,:) = show_list;
end

temph = subplot('Position',[start_x,...
    start_y-inter_y-box_y-inter_y-box_y,...
    box_x,box_y]);
imagesc(show_mat_self)
colormap(temph,cmap_mov)
set(gca,'XTick',[1,27000])
set(gca,'XTickLabel',[0,15])
set(gca,'YTick',1:size(sort_unique_name,1))
set(gca,'YTickLabel',show_mouse_name)
set(gca,'TickDir','out')
set(gca,'FontSize',6)
box off

xlabel('Time (min)')

% colorbar
cbar_box_x = 0.01;
cbar_box_y = 0.08;

cbar_inter_x = 0.005;

temph = subplot('Position',[...
    start_x+box_x+cbar_inter_x,...
    start_y+box_y-cbar_box_y-inter_y-box_y-inter_y-box_y,...
    cbar_box_x,cbar_box_y]);
imagesc((1:size(cmap_mov,1))')
colormap(temph,cmap_mov)
set(gca,'XTick',[],'YTick',[])
text(2.5,size(cmap_mov,1)/2,'Movements','Rotation',90,...
    'FontSize',6,...
    'HorizontalAlignment','center')















