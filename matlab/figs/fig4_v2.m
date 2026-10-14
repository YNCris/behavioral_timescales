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
%% plot canvas
hall = figure(1);
set(hall,'Position',[680,0,800,800])
set(hall,'color','white');
%% split name
splname = split(all_data_cell(:,1),'-');
all_mouse_idx = cellfun(@(x) x(1),...
    splname(:,3),'UniformOutput',false);

all_brain_name = cellfun(@(x) x(2:end),...
    splname(:,3),'UniformOutput',false);
%% show variance explained
start_x = 0.04;
start_y = 0.87;

box_x = 0.12;
box_y = box_x;

show_brain_list = {...
    'tpmss';...
    'tpmpfc';...
    'tpmm'};

neu_cmap = cbrewer2('Paired',12);

in_c = neu_cmap(5,:);
de_c = neu_cmap(1,:);
no_c = neu_cmap(3,:);

brain_c = [...
    de_c;...
    in_c;...
    no_c];

show_exp_len = 150;

error_bar_width = 2;

alpha_line = 0.2;

subplot('Position',...
    [start_x,start_y,box_x,box_y])

temph_cell = cell(size(show_brain_list,1),1);
for k = 1:size(show_brain_list,1)
    selidx = strcmp(show_brain_list{k},all_brain_name);
    seldata = cell2mat(...
        cellfun(@(x) x{7}(1:show_exp_len)',...
        all_data_cell(selidx,11),...
        'UniformOutput',false));

    mean_seldata = mean(seldata);
    std_seldata = std(seldata)./sqrt(size(seldata,1));

    tempe = errorbar(1:length(mean_seldata),...
        mean_seldata,std_seldata,...
        'CapSize',0,'LineWidth',error_bar_width,...
        'Color',brain_c(k,:));
    set([tempe.Bar, tempe.Line], ...
        'ColorType', 'truecoloralpha', ...
        'ColorData', [tempe.Line.ColorData(1:3); ...
        255*alpha_line])
    hold on
    temph_cell{k} = plot(mean_seldata,'Color',brain_c(k,:),...
        'LineWidth',1.5);
    hold on
end
hold on
plot([0,150],[90,90],'-k')
hold off

box off

legend([temph_cell{1},temph_cell{2},temph_cell{3}],...
    {'S1','dmPFC','M1'},'box','off',...
    'Location','northwest')

ylabel('Variance explained (%)')
xlabel('Principal components')

set(gca,'TickDir','out')

set(gca,'FontSize',6)

%% show pca accuracy
brain_beh_prec_cell = cell(...
    size(show_brain_list,1)*...
    size(all_data_cell{1,12},2),1);

sel_cell = {...
    'tpmss',1;...
    'tpmss',2;...
    'tpmss',3;...
    'tpmss',4;...
    'tpmss',5;...
    'tpmss',6;...
    'tpmpfc',1;...
    'tpmpfc',2;...
    'tpmpfc',3;...
    'tpmpfc',4;...
    'tpmpfc',5;...
    'tpmpfc',6;...
    'tpmm',1;...
    'tpmm',2;...
    'tpmm',3;...
    'tpmm',4;...
    'tpmm',5;...
    'tpmm',6;...
    };

show_tick = {...
    'S1-Self-Pose';...
    'S1-Partner-Pose';...
    'S1-Self-Movement';...
    'S1-Self-Movement';...
    'S1-Partner-Sequence';...
    'S1-Self-Sequence';...
    'dmPFC-Self-Pose';...
    'dmPFC-Partner-Pose';...
    'dmPFC-Self-Movement';...
    'dmPFC-Self-Movement';...
    'dmPFC-Partner-Sequence';...
    'dmPFC-Self-Sequence';...
    'M1-Self-Pose';...
    'M1-Partner-Pose';...
    'M1-Self-Movement';...
    'M1-Self-Movement';...
    'M1-Partner-Sequence';...
    'M1-Self-Sequence';...
    };

for k = 1:size(brain_beh_prec_cell,1)
    selbrainidx = strcmp(...
        sel_cell{k,1},...
        all_brain_name);
    selbehidx = sel_cell{k,2};

    seldata = cell2mat(...
        cellfun(@(x) mean(x{selbehidx}),...
        all_data_cell(selbrainidx,12),...
        'UniformOutput',false));

    brain_beh_prec_cell{k,1} = seldata;
end

mean_brain_beh_prec = cellfun(@(x) mean(x),...
    brain_beh_prec_cell);

[~,sortidx] = sort(mean_brain_beh_prec,'descend');

sort_brain_beh_prec_cell = ...
    brain_beh_prec_cell(sortidx,:);
sort_show_tick = show_tick(sortidx,:);
%% show
start_x = 0.19;
start_y = 0.87;

box_x = 0.3;
box_y = 0.12;


star_first_3 = {...
    'ns';...%self
    'ns';...
    'ns';...
    'ns';...
    'ns';...
    'ns';...
    'ns';...
    'ns';...
    'ns';...
    '*';...
    '**';...
    '**';...
    '**';...
    '**';...
    '**';...
    '***';...
    '****';...
    '****';...
    };

bar_w = 0.6;

cap_size = 2;

x_bias = 0.3;

max_y = 1.2;

sel_show = sort_brain_beh_prec_cell;
x_list = 1:size(sel_show,1);
mean_show = cell2mat(cellfun(@(x) mean(x),...
    sel_show(:,1),'UniformOutput',false));
std_show = cell2mat(cellfun(@(x) std(x)./sqrt(length(x)),...
    sel_show(:,1),'UniformOutput',false));

subplot('Position',[...
    start_x,start_y,box_x,box_y])
for k = 1:size(sel_show,1)
    tempname = sort_show_tick{k,1};
    splname = split(tempname,'-');
    if strcmp(splname{1},'S1')
        bar_c = brain_c(1,:);
    end
    if strcmp(splname{1},'dmPFC')
        bar_c = brain_c(2,:);
    end
    if strcmp(splname{1},'M1')
        bar_c = brain_c(3,:);
    end
    bar(x_list(k),mean_show(k),bar_w,...
        'FaceColor',bar_c)
    hold on
    errorbar(x_list(k),mean_show(k),std_show(k),...
        'CapSize',cap_size,'Color','k')
    hold on
    for m = 1:size(sel_show,1)
        tempy = sel_show{m,1};
        tempx = m*ones(size(tempy));
        plot(x_bias+tempx,tempy,'o','MarkerSize',2,...
            'MarkerFaceColor','w','MarkerEdgeColor','k',...
            'LineWidth',0.25)
        hold on
    end   
    
    if ~strcmp(star_first_3{k},'ns')
        text(x_list(k),1.05,star_first_3{k},...
            'Rotation',90,...
            'VerticalAlignment','top')
    end
end
plot([0,20],[mean(sel_show{1,1}),mean(sel_show{1,1})],...
        '--k','LineWidth',0.25)
hold off

box off

axis([0.3,18.7,0,max_y])

set(gca,'TickDir','Out')
set(gca,'XTick',x_list)
set(gca,'YTick',[0,1])
set(gca,'XTickLabel',sort_show_tick)
set(gca,'FontSize',6)
set(gca,'XTickLabelRotation',60)
ylabel('Accuracy')

%% movement level alignment, the PC fingerprints
pc_len = 150;

mov_pc_cell = cell(size(all_data_cell,1),2);
tic
for k = 1:size(all_data_cell,1)
    %% get data
    mov_self = cell2mat(all_data_cell{k,4}(:,2));
    mov_partner = cell2mat(all_data_cell{k,7}(:,2));

    neupc = all_data_cell{k,11}{1};

    %% compare correlation
    mov_self_weight_mat = zeros(length(unique_mov),pc_len);
    for m = 1:length(unique_mov)
        selidx = mov_self==m;

        if sum(selidx)>0
            mdl = fitcdiscr(neupc,selidx);    
            mov_weight = mdl.Coeffs(1,2).Linear;
        else
            mov_weight = nan(size(neupc,2),1);
        end

        mov_self_weight_mat(m,:) = mov_weight(1:pc_len)';
    end


    mov_partner_weight_mat = zeros(length(unique_mov),pc_len);
    for m = 1:length(unique_mov)
        selidx = mov_self==m;

        if sum(selidx)>0
            mdl = fitcdiscr(neupc,selidx);    
            mov_weight = mdl.Coeffs(1,2).Linear;
        else
            mov_weight = nan(size(neupc,2),1);
        end

        mov_partner_weight_mat(m,:) = mov_weight(1:pc_len)';
    end

    mov_pc_cell{k,1} = mov_self_weight_mat;
    mov_pc_cell{k,2} = mov_partner_weight_mat;
    toc
end

%% sort to trials
mov_pc_trial_cell = {};
for k = 1:size(mov_pc_cell,1)
    mov_self = mov_pc_cell{k,1};
    mov_partner = mov_pc_cell{k,2};

    tempname = all_data_cell{k,1};

    splname = split(tempname,'-');

    for m = 1:size(mov_self,1)
        if ~isnan(mov_self(m,1))
            mov_pc_trial_cell = [mov_pc_trial_cell;...
                {tempname,splname{3}(2:end),'self',...
                uniuqe_mov_name{m},...
                mov_self(m,:),mat2gray(mov_self(m,:))}];
        end
    end

    for m = 1:size(mov_partner,1)
        if ~isnan(mov_partner(m,1))
            mov_pc_trial_cell = [mov_pc_trial_cell;...
                {tempname,splname{3}(2:end),'partner',...
                uniuqe_mov_name{m},...
                mov_partner(m,:),mat2gray(mov_partner(m,:))}];
        end
    end
end

%% 
mov_pc_mat = cell2mat(mov_pc_trial_cell(:,6));

%% embedding
n_nei = 10;
min_dist = 0.1;
[~, umap, clusterIdentifiers] = run_umap(...
        mov_pc_mat,'n_neighbors',n_nei,...
    'min_dist',min_dist,'metric','euclidean',...
    'n_components', 2, 'verbose', 'text',...
    'randomize',false,'cluster_method_2D','dbscan');
    embedding = umap.embedding;

all_labels = clusterIdentifiers;

unique_labels = unique(all_labels);

cmap = cbrewer2('Spectral',size(unique_labels,1));

cmaplist = zeros(size(all_labels,1),3);
for k = 1:size(unique_labels,1)
    cmaplist(unique_labels(k)==all_labels,:) = ...
        ones(sum(unique_labels(k)==all_labels),1)*...
        cmap(k,:);
end

figure
scatter(embedding(:,1),embedding(:,2),...
    10*ones(size(embedding,1),1),cmaplist,...
    'filled')
title({n_nei,min_dist})  



%% show labels of mice
all_labels = mov_pc_trial_cell(:,1);

unique_labels = unique(all_labels);

cmap = cbrewer2('Spectral',size(unique_labels,1));

cmaplist = zeros(size(all_labels,1),3);
for k = 1:size(unique_labels,1)
    cmaplist(strcmp(unique_labels{k},all_labels),:) = ...
        ones(sum(strcmp(unique_labels{k},all_labels)),1)*...
        cmap(k,:);
end

figure
scatter(embedding(:,1),embedding(:,2),...
    10*ones(size(embedding,1),1),cmaplist,...
    'filled')
title({n_nei,min_dist})

%% show labels of brain areas
all_labels = mov_pc_trial_cell(:,2);

unique_labels = unique(all_labels);

cmap = cbrewer2('Spectral',size(unique_labels,1));

cmaplist = zeros(size(all_labels,1),3);
for k = 1:size(unique_labels,1)
    cmaplist(strcmp(unique_labels{k},all_labels),:) = ...
        ones(sum(strcmp(unique_labels{k},all_labels)),1)*...
        cmap(k,:);
end

figure
scatter(embedding(:,1),embedding(:,2),...
    10*ones(size(embedding,1),1),cmaplist,...
    'filled')
title({n_nei,min_dist})

%% show labels of self partner
all_labels = mov_pc_trial_cell(:,3);

unique_labels = unique(all_labels);

cmap = cbrewer2('Spectral',size(unique_labels,1));

cmaplist = zeros(size(all_labels,1),3);
for k = 1:size(unique_labels,1)
    cmaplist(strcmp(unique_labels{k},all_labels),:) = ...
        ones(sum(strcmp(unique_labels{k},all_labels)),1)*...
        cmap(k,:);
end

figure
scatter(embedding(:,1),embedding(:,2),...
    5*ones(size(embedding,1),1),cmaplist,...
    'filled')
title({n_nei,min_dist})

%% show labels of mov 
all_labels = mov_pc_trial_cell(:,4);

unique_labels = unique(all_labels);

cmap = cbrewer2('Spectral',size(unique_labels,1));

cmaplist = zeros(size(all_labels,1),3);
for k = 1:size(unique_labels,1)
    cmaplist(strcmp(unique_labels{k},all_labels),:) = ...
        ones(sum(strcmp(unique_labels{k},all_labels)),1)*...
        cmap(k,:);
end

figure
scatter(embedding(:,1),embedding(:,2),...
    10*ones(size(embedding,1),1),cmaplist,...
    'filled')
title({n_nei,min_dist})

%% calculate cluster matched behavior
unique_cluster = unique(clusterIdentifiers);
match_mov_cell = cell(size(unique_cluster,1),2);

for k = 1:size(unique_cluster,1)
    tempidx = unique_cluster(k);
    selidx = tempidx==clusterIdentifiers;
    selmov = mov_pc_trial_cell(selidx,4);

    match_mov_cell{k,1} = selmov;
    match_mov_cell{k,2} = tabulate(selmov);
end




























