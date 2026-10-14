%{
    fig4, sequential analysis of neural behavioral correlation
%}
clear all
close all
addpath(genpath(pwd))
%% set path
rootpath = ['X:\hanyaning\multi_mice_test\Social_analysis\' ...
    'data\MTPM_social_20220228_all'];
datapath = [rootpath,'\recluster_data'];
%% load data
ctn = load([datapath,'\cnt_body_language_20230425.mat']);
beh_class = readcell([datapath,'\cut_beh_20230301_classes.xlsx']);
load([datapath,'\neu_beh_cell_20230721.mat']);
load([datapath,'\data_sample_cell_20230301.mat']);
load([datapath,'\sim_mat_20230905.mat']);
temp_human_label = ...
    readtable([datapath,'\labeled_help_behavior.xlsx']);

% load latent embeddings
dataFolder = fullfile(datapath);
dataOutput = dir(fullfile(dataFolder,...
    '*single_animal_embedding_dff.mat'));
leNames = {dataOutput.name}';

beh_label_num = (1:41)';

raw_le_cell = cell(size(leNames,1),2);
for k = 1:size(raw_le_cell,1)
    raw_le_cell{k,1} = leNames{k};
    raw_le_cell{k,2} = load(...
        [datapath,'\',leNames{k}]);
end

%% merge latent embedding with data_sample_cell
fix_range = [ones(27000,1);zeros(27000,1)];
free_range = [zeros(27000,1);ones(27000,1)];
range_1 = [ones(9000,1);zeros(9000,1);zeros(9000,1)];
range_2 = [zeros(9000,1);ones(9000,1);zeros(9000,1)];
range_3 = [zeros(9000,1);zeros(9000,1);ones(9000,1)];

sel_cell = {...
    'fix',fix_range;...
    'free',free_range;...
    '1',range_1;...
    '2',range_2;...
    '3',range_2};

le_sample_cell = cell(size(data_sample_cell,1),5);
for k = 1:size(le_sample_cell,1)
    tempname = data_sample_cell{k,3};
    splname1 = split(tempname,'_');
    splname = split(splname1{1},'-');

    sel_fix_free_idx = strcmp(sel_cell(:,1),splname{1});
    sel_fix_free = sel_cell{sel_fix_free_idx,2};
    sel_range_idx = strcmp(sel_cell(:,1),splname{6});
    sel_range = sel_cell{sel_range_idx,2};

    sel_mice_idx = strcmp(raw_le_cell(:,1),...
        [splname{3},'_single_animal_embedding_dff.mat']);
    sel_mice = raw_le_cell{sel_mice_idx,2};

    sel_le = sel_mice.single_animal_embedding(...
        sel_fix_free==1,:);
    sel_le_range = sel_le(sel_range==1,:);

    start_idx = data_sample_cell{k,2}(1);
    end_idx = data_sample_cell{k,2}(2);

    le_sample_cell{k,1} = sel_le_range(...
        start_idx:end_idx,:);
    le_sample_cell{k,2} = splname{1};
    le_sample_cell{k,3} = splname{3};
    le_sample_cell{k,4} = splname{6};
    le_sample_cell{k,5} = data_sample_cell{k,2}(4);
    
    if rem(k,200)==0
        disp(k)
    end
end

%% separate trapped body language and free body language
clus_diff = [diff(ctn.T_sort);0];
bk_line_pos = find(clus_diff~=0);
trap_ctn = ctn.sort_sel_show_ctn_count_mat(:,1:15);
free_ctn = ctn.sort_sel_show_ctn_count_mat(:,16:end);
mean_trap_ctn = zeros(size(ctn.mean_ctn_cell,1),1);
mean_free_ctn = zeros(size(ctn.mean_ctn_cell,1),1);

end_T = [bk_line_pos;length(ctn.T_sort)];
start_T = [0;(end_T(1:(end-1)))]+1;
for k = 1:size(mean_trap_ctn,1)
    mean_trap_ctn(k) = mean(mean(trap_ctn(start_T(k):end_T(k),:)));
    mean_free_ctn(k) = mean(mean(free_ctn(start_T(k):end_T(k),:)));
end

trap_behseq = {};
free_behseq = {};
trap_behprob = {};
free_behprob = {};
for k = 1:size(ctn.mean_ctn_cell,1)
    %%
    temp_ctn = ctn.mean_ctn_cell{k};
    temptrap = {};
    tempfree = {};
    temptrap_prob = {};
    tempfree_prob = {};
    for m = 1:size(temp_ctn,2)
        tt_ctn = temp_ctn{m};
        sel_beh = beh_class(tt_ctn(:,1));
        %%
        if mean_trap_ctn(k)>mean_free_ctn(k)
            temptrap = [temptrap,tt_ctn(:,1)];
            temptrap_prob = [temptrap_prob,tt_ctn(:,2)];
        else
            tempfree = [tempfree,tt_ctn(:,1)];
            tempfree_prob = [tempfree_prob,tt_ctn(:,2)];
        end
    end

    if mean_trap_ctn(k)>mean_free_ctn(k)
        trap_behseq = [trap_behseq;{temptrap}];
        trap_behprob = [trap_behprob;{temptrap_prob}];
    else
        free_behseq = [free_behseq;{tempfree}];
        free_behprob = [free_behprob;{tempfree_prob}];
    end
end

% enumeration of all conditions of behavior sequence
all_trap_behseq = {};
all_free_behseq = {};
all_trap_behprob = {};
all_free_behprob = {};

for k = 1:size(trap_behseq,1)
    tempseq = trap_behseq{k};
    tempprob = trap_behprob{k};
    %% full combination
    length_list = cell2mat(cellfun(@(x) size(x,1),tempseq,...
        'UniformOutput',false));
    ind = fullfact(length_list);

    fullseq = zeros(size(ind));
    fullprob = zeros(size(ind));
    for m = 1:length(tempseq)
        fullseq(:,m) = tempseq{m}(ind(:,m));
        fullprob(:,m) = tempprob{m}(ind(:,m));
    end
    %% append data
    for m = 1:size(fullseq,1)
        all_trap_behseq = [all_trap_behseq;...
            {fullseq(m,:)}];
        all_trap_behprob = [all_trap_behprob;...
            {fullprob(m,:)}];
    end
end

for k = 1:size(free_behseq,1)
    tempseq = free_behseq{k};
    tempprob = free_behprob{k};
    %% full combination
    length_list = cell2mat(cellfun(@(x) size(x,1),tempseq,...
        'UniformOutput',false));
    ind = fullfact(length_list);

    fullseq = zeros(size(ind));
    fullprob = zeros(size(ind));
    for m = 1:length(tempseq)
        fullseq(:,m) = tempseq{m}(ind(:,m));
        fullprob(:,m) = tempprob{m}(ind(:,m));
    end
    %% append data
    for m = 1:size(fullseq,1)
        all_free_behseq = [all_free_behseq;...
            {fullseq(m,:)}];
        all_free_behprob = [all_free_behprob;...
            {fullprob(m,:)}];
    end
end

%% wash data
sum_trap_behprob = cell2mat(...
    cellfun(@(x) sum(x),all_trap_behprob,...
    'UniformOutput',false));
sum_free_behprob = cell2mat(...
    cellfun(@(x) sum(x),all_free_behprob,...
    'UniformOutput',false));
%% plot canvas
hall = figure(1);
set(hall,'Position',[1050,100,800,800])
set(hall,'color','white');

%% show latent embeddings
start_x = 0.01;
start_y = 0.81;
box_x = 0.15;
box_y = 0.15;

inter_x = 0.005;

cmap_tm_fix = cbrewer2('Reds',256);
cmap_tm_free = cbrewer2('Blues',256);
class_cmap_fix = cmap_tm_fix(192,:);
class_cmap_free = cmap_tm_free(192,:);

fix_idx = (1:27000)';
free_idx = (27001:54000)';

cmap_fix_free = [ones(size(fix_idx))*class_cmap_fix;...
    ones(size(free_idx))*class_cmap_free];

for k = 1:size(raw_le_cell,1)
    temp_le = raw_le_cell{k,2}.single_animal_embedding;
    neu_num = size(raw_le_cell{k,2}.data,2);
    subplot('Position',[start_x+(k-1)*(box_x+inter_x),...
        start_y,box_x,box_y])
    plot3(...
        temp_le(free_idx,1),...
        temp_le(free_idx,2),...
        temp_le(free_idx,3),...
        '-','Color',class_cmap_free,'LineWidth',0.25)
    hold on
    plot3(...
        temp_le(fix_idx,1),...
        temp_le(fix_idx,2),...
        temp_le(fix_idx,3),...
        '-','Color',class_cmap_fix,'LineWidth',0.25)
    hold off

    title({['Mouse ',num2str(k)],...
        ['Neuron number: ',num2str(neu_num)]})

    set(gca,'XTick',[])
    set(gca,'YTick',[])
    set(gca,'ZTick',[])
end

%% compare free fix position of embedding
mice_expseq = cellfun(@(x,y) [x,'-',y],...
    le_sample_cell(:,3),le_sample_cell(:,4),...
    'UniformOutput',false);
unique_mice_expseq = unique(mice_expseq);
unique_fix_free = unique(le_sample_cell(:,2));

cmp_le = zeros(15,6);

for m = 1:size(unique_mice_expseq,1)
    for n = 1:size(unique_fix_free,1)
        sel_mice_expseq = unique_mice_expseq{m};
        sel_fix_free = unique_fix_free{n};

        sel_mice_expseq_idx = ...
            strcmp(sel_mice_expseq,mice_expseq);
        sel_fix_free_idx = ...
            strcmp(sel_fix_free,le_sample_cell(:,2));

        sel_data = cell2mat(le_sample_cell(...
            (sel_mice_expseq_idx.*sel_fix_free_idx)==1,1));

        cmp_le(m,n:2:end) = mean(sel_data);

    end
end

mean_cmp_le = mean(cmp_le);
std_cmp_le = std(cmp_le)./sqrt(size(cmp_le,1));

mean_cmp_le_fix = mean_cmp_le(1:2:end);
mean_cmp_le_free = mean_cmp_le(2:2:end);
std_cmp_le_fix = std_cmp_le(1:2:end);
std_cmp_le_free = std_cmp_le(2:2:end);

fix_xlist = [1,4,7];
free_xlist = [2,5,8];
all_xlist = [1,2,4,5,7,8];
bar_w = 0.3;
cap_size = 3;
x_bias = 0.4;

subplot('Position',[0.84,0.84,0.15,0.15])
bar(fix_xlist,mean_cmp_le_fix,bar_w,...
    'FaceColor',class_cmap_fix)
hold on
bar(free_xlist,mean_cmp_le_free,bar_w,...
    'FaceColor',class_cmap_free)
hold on
errorbar(fix_xlist,mean_cmp_le_fix,std_cmp_le_fix,...
    'LineStyle','none','Color','k','CapSize',cap_size)
hold on
errorbar(free_xlist,mean_cmp_le_free,std_cmp_le_free,...
    'LineStyle','none','Color','k','CapSize',cap_size)
hold on
for k = 1:size(cmp_le,2)
    plot(x_bias+ones(size(cmp_le,1),1)*all_xlist(k),...
        cmp_le(:,k),'o','MarkerSize',2,...
        'MarkerFaceColor','w',...
        'MarkerEdgeColor','k')
    hold on
end
hold off
axis([0.3,8.7,-0.5,0.5])
ylabel('Latent coordinates')
box off
set(gca,'TickDir','out')
set(gca,'XTick',(fix_xlist+free_xlist)/2)
set(gca,'XTickLabel',{'Latent 1','Latent 2','Latent 3'})
set(gca,'XTickLabelRotation',45)


%% show the results of SVM
start_x = 0.02;
start_y = 0.63;
box_x = 0.15;
box_y = 0.15;

heat_clr = cbrewer2('BuPu',256);
max_v = 1;
temph = subplot('Position',[start_x,start_y,box_x,box_y]);
imagesc(sim_mat,[0,max_v])
colormap(temph,heat_clr)
set(gca,'TickDir','out')
box off
set(gca,'XTick',1:size(sim_mat,1))
set(gca,'YTick',1:size(sim_mat,2))
set(gca,'XTickLabel',[])
set(gca,'YTickLabel',[])
xlabel('Prediction')
ylabel('SVM models')
set(gca,'FontSize',6)
title('Embedding trajectories')

% colorbar
temph = subplot('Position',[...
    start_x+box_x+0.005,box_y-0.05+start_y,0.005,0.05]);
imagesc((0:0.001:max_v)',[0,1])
colormap(temph,flipud(heat_clr))
set(gca,'YTick',[0,1],'XTick',[])
set(gca,'YAxisLocation','right')
ylabel('Precision','Position',[3,230])
set(gca,'FontSize',6)

%% use DTAK to measure the similarity of different neural modules
%% calculate dtak
tic
dist_mat = zeros(size(le_sample_cell,1),size(le_sample_cell,1));
for m = 1:size(le_sample_cell,1)
    for n = m:size(le_sample_cell,1)
        %% get data
        seg_data1 = le_sample_cell{m,1}';
        seg_data2 = le_sample_cell{n,1}';
        %% normalization to exclude the influence of position
%         % normalization
%         seg_data1 = zscore(seg_data1,0,2);
%         seg_data2 = zscore(seg_data2,0,2);
%         % align the start position
%         seg_data1 = ...
%             seg_data1-seg_data1(:,1)*...
%             ones(1,size(seg_data1,2));
%         seg_data2 = ...
%             seg_data2-seg_data2(:,1)*...
%             ones(1,size(seg_data2,2));
        %% calculate dtak
		condist_mat = conDist(seg_data1,seg_data2);
		Kdistmat = conKnl_DTAK(...
            condist_mat, 'g', 'nei', 1);
		wFs1 = ones(1,size(Kdistmat,1));
		wFs2 = ones(1,size(Kdistmat,2));
		[T,~,~] = dtakFord(Kdistmat,0,wFs1,wFs2);
        dist_mat(m,n) = T;
    end
    disp(m/size(le_sample_cell,1))
end
toc
%% fill full matrix
dist_mat_all = dist_mat + triu(dist_mat, 1)';
%% similarity quantification
mice_trial = cellfun(@(x,y,z) [x,'-',y,'-',z],...
    le_sample_cell(:,2),le_sample_cell(:,3),...
    le_sample_cell(:,4),'UniformOutput',false);
unique_mice_trial = unique(mice_trial);

sim_dtak_mat = zeros(...
    length(unique_mice_trial),...
    length(unique_mice_trial));

for m = 1:size(sim_dtak_mat,1)
    for n = 1:size(sim_dtak_mat,2)
        tempname1 = unique_mice_trial{m};
        tempname2 = unique_mice_trial{n};

        selidx1 = strcmp(tempname1,mice_trial);
        selidx2 = strcmp(tempname2,mice_trial);

        selmat = dist_mat_all(selidx1==1,:);
        selmat = selmat(:,selidx2==1);

        sim_dtak_mat(m,n) = mean(selmat(:));
    end
end

%% show DTAK matrix
start_x = 0.22;
start_y = 0.63;
box_x = 0.15;
box_y = 0.15;

heat_clr = cbrewer2('BuPu',256);
max_v = max(dist_mat_all(:));
temph = subplot('Position',[start_x,start_y,box_x,box_y]);
imagesc(dist_mat_all,[0,max_v])
colormap(temph,heat_clr)
set(gca,'TickDir','out')
box off
set(gca,'XTick',[1,size(dist_mat_all,1)])
set(gca,'YTick',[1,size(dist_mat_all,2)])
set(gca,'YTickLabelRotation',90)
% set(gca,'XTickLabel',[])
% set(gca,'YTickLabel',[])
xlabel('Neural modules')
ylabel('Neural modules')
set(gca,'FontSize',6)

% colorbar
temph = subplot('Position',[...
    start_x+box_x+0.005,box_y-0.05+start_y,0.005,0.05]);
imagesc((0:0.001:max_v)',[0,1])
colormap(temph,flipud(heat_clr))
set(gca,'YTick',[0,1],'XTick',[])
set(gca,'YAxisLocation','right')
ylabel('DTAK distance','Position',[3,230])
set(gca,'FontSize',6)

%% show DTAK distance
start_x = 0.42;
start_y = 0.63;
box_x = 0.15;
box_y = 0.15;

heat_clr = cbrewer2('BuPu',256);
max_v = 1;
temph = subplot('Position',[start_x,start_y,box_x,box_y]);
imagesc(sim_dtak_mat,[0,max_v])
colormap(temph,heat_clr)
set(gca,'TickDir','out')
box off
set(gca,'XTick',1:size(sim_dtak_mat,1))
set(gca,'YTick',1:size(sim_dtak_mat,2))
% set(gca,'YTickLabelRotation',90)
set(gca,'XTickLabel',[])
set(gca,'YTickLabel',[])
xlabel('Trials')
ylabel('Trials')
set(gca,'FontSize',6)
title('Embedding syntax')

% colorbar
temph = subplot('Position',[...
    start_x+box_x+0.005,box_y-0.05+start_y,0.005,0.05]);
imagesc((0:0.001:max_v)',[0,1])
colormap(temph,flipud(heat_clr))
set(gca,'YTick',[0,1],'XTick',[])
set(gca,'YAxisLocation','right')
ylabel('DTAK distance','Position',[3,230])
set(gca,'FontSize',6)

%% compare features, inner individual
spl_mice_trial = split(unique_mice_trial,'-');
unique_mice = unique(spl_mice_trial(:,2));

cmp_svm_list = cell(size(unique_mice,1),3);%{name, inner, outer}
cmp_dtak_list = cell(size(unique_mice,1),3);%{name, inner, outer}
cmp_svm_list(:,1) = unique_mice;
cmp_dtak_list(:,1) = unique_mice;

for k = 1:size(cmp_svm_list,1)
    %%
    tempname = cmp_dtak_list{k,1};
    selidx = strcmp(tempname,spl_mice_trial(:,2));
    rev_selidx = ~selidx;
    selmat = sim_mat(selidx,:);

    sel_inner_mat = selmat(:,selidx);
    sel_outer_mat = selmat(:,rev_selidx);

    cmp_svm_list{k,2} = reshape(sel_inner_mat,[],1);
    cmp_svm_list{k,3} = reshape(sel_outer_mat,[],1);
end

for k = 1:size(cmp_dtak_list,1)
    %%
    tempname = cmp_dtak_list{k,1};
    selidx = strcmp(tempname,spl_mice_trial(:,2));
    rev_selidx = ~selidx;
    selmat = sim_dtak_mat(selidx,:);

    sel_inner_mat = selmat(:,selidx);
    sel_outer_mat = selmat(:,rev_selidx);

    cmp_dtak_list{k,2} = reshape(sel_inner_mat,[],1);
    cmp_dtak_list{k,3} = reshape(sel_outer_mat,[],1);
end

cmp_svm_mat = cell2mat(...
    cellfun(@(x) mean(x),cmp_svm_list(:,2:3),...
    'UniformOutput',false));

cmp_dtak_mat = cell2mat(...
    cellfun(@(x) mean(x),cmp_dtak_list(:,2:3),...
    'UniformOutput',false));

cmp_svm_mat_mean = mean(cmp_svm_mat);
cmp_dtak_mat_mean = mean(cmp_dtak_mat);

cmp_svm_mat_sd = std(cmp_svm_mat)./sqrt(5);
cmp_dtak_mat_sd = std(cmp_dtak_mat)./sqrt(5);

xlist_svm = 1:2;
xlist_dtak = [3.5,4.5];

bar_c = 0.8*ones(1,3);
subplot('Position',[0.66,start_y,box_x,box_y]);
bar([xlist_svm,xlist_dtak],...
    [cmp_svm_mat_mean,cmp_dtak_mat_mean],...
    'FaceColor',bar_c)
hold on
errorbar(...
    [xlist_svm,xlist_dtak],...
    [cmp_svm_mat_mean,cmp_dtak_mat_mean],...
    [cmp_svm_mat_sd,cmp_dtak_mat_sd],...
    'LineStyle','none','Color','k')
hold on
all_x = [xlist_svm,xlist_dtak];
all_data = [cmp_svm_mat,cmp_dtak_mat];
for k = 1:size(all_data,2)
    plot(all_x(k)*ones(5,1)+0.4,...
        all_data(:,k),'o','MarkerFaceColor','w',...
        'MarkerEdgeColor','k','MarkerSize',2)
    hold on
end
hold off

ylabel('Feature distance of mice')
box off
set(gca,'TickDir','out')
set(gca,'XTick',all_x)
axis([0.3,5.2,0,0.6])
set(gca,'XTickLabel',{'Intra','Inter','Intra','Inter'})
xlabel('Trajectories   Modules')

%% compare features, inner trials
trials_list = cellfun(@(x,y) [x,'-',y],...
    spl_mice_trial(:,1),spl_mice_trial(:,2),...
    'UniformOutput',false);
unique_trials = unique(trials_list);

cmp_svm_list = cell(size(unique_trials,1),3);%{name, inner, outer}
cmp_dtak_list = cell(size(unique_trials,1),3);%{name, inner, outer}
cmp_svm_list(:,1) = unique_trials;
cmp_dtak_list(:,1) = unique_trials;

for k = 1:size(cmp_svm_list,1)
    %%
    tempname = cmp_dtak_list{k,1};
    selidx = strcmp(tempname,trials_list);
    rev_selidx = ~selidx;
    selmat = sim_mat(selidx,:);

    sel_inner_mat = selmat(:,selidx);
    sel_outer_mat = selmat(:,rev_selidx);

    cmp_svm_list{k,2} = reshape(sel_inner_mat,[],1);
    cmp_svm_list{k,3} = reshape(sel_outer_mat,[],1);
end

for k = 1:size(cmp_dtak_list,1)
    %%
    tempname = cmp_dtak_list{k,1};
    selidx = strcmp(tempname,trials_list);
    rev_selidx = ~selidx;
    selmat = sim_dtak_mat(selidx,:);

    sel_inner_mat = selmat(:,selidx);
    sel_outer_mat = selmat(:,rev_selidx);

    cmp_dtak_list{k,2} = reshape(sel_inner_mat,[],1);
    cmp_dtak_list{k,3} = reshape(sel_outer_mat,[],1);
end

cmp_svm_mat = cell2mat(...
    cellfun(@(x) mean(x),cmp_svm_list(:,2:3),...
    'UniformOutput',false));

cmp_dtak_mat = cell2mat(...
    cellfun(@(x) mean(x),cmp_dtak_list(:,2:3),...
    'UniformOutput',false));

cmp_svm_mat_mean = mean(cmp_svm_mat);
cmp_dtak_mat_mean = mean(cmp_dtak_mat);

cmp_svm_mat_sd = std(cmp_svm_mat)./sqrt(5);
cmp_dtak_mat_sd = std(cmp_dtak_mat)./sqrt(5);

xlist_svm = 1:2;
xlist_dtak = [3.5,4.5];

bar_c = 0.8*ones(1,3);
subplot('Position',[0.84,start_y,box_x,box_y]);
bar([xlist_svm,xlist_dtak],...
    [cmp_svm_mat_mean,cmp_dtak_mat_mean],...
    'FaceColor',bar_c)
hold on
errorbar(...
    [xlist_svm,xlist_dtak],...
    [cmp_svm_mat_mean,cmp_dtak_mat_mean],...
    [cmp_svm_mat_sd,cmp_dtak_mat_sd],...
    'LineStyle','none','Color','k')
hold on
all_x = [xlist_svm,xlist_dtak];
all_data = [cmp_svm_mat,cmp_dtak_mat];
for k = 1:size(all_data,2)
    plot(all_x(k)*ones(10,1)+0.4,...
        all_data(:,k),'o','MarkerFaceColor','w',...
        'MarkerEdgeColor','k','MarkerSize',2)
    hold on
end
hold off

ylabel('Feature distance of trials')
box off
set(gca,'TickDir','out')
set(gca,'XTick',all_x)
axis([0.3,5.2,0,0.6])
set(gca,'XTickLabel',{'Intra','Inter','Intra','Inter'})
xlabel('Trajectories   Modules')
set(gca,'YTickLabel',[])

%% compare neural syntax of two groups
% embedding
[reduction, umap, clusterIdentifiers] = ...
    run_umap(dist_mat_all,...
    'n_neighbors',199,'sgd_tasks',1,...
    'min_dist',0.08,'metric','seuclidean',...
    'n_components', 2, 'verbose', 'text',...
    'randomize',false);
embedding = umap.embedding;

all_trial_list = cellfun(...
    @(x,y,z) [x,'-',y,'-',z],...
    le_sample_cell(:,2),...
    le_sample_cell(:,3),...
    le_sample_cell(:,4),'UniformOutput',false);

unique_trial_list = unique(all_trial_list);

unique_trial_cmap = cbrewer2('Spectral',...
    length(unique_trial_list));

all_trial_cmap = zeros(size(all_trial_list,1),3);

for k = 1:size(unique_trial_cmap,1)
    selidx = strcmp(all_trial_list,unique_trial_list{k});
    all_trial_cmap(selidx,:) = ...
        ones(sum(selidx),1)*unique_trial_cmap(k,:);
end

%% show representation of all trials
start_x = 0.02;
start_y = 0.44;
box_x = 0.15;
box_y = 0.15;

xy_bias = 1;
subplot('Position',[start_x,start_y,box_x,box_y]);
scatter(embedding(:,1),embedding(:,2),...
    1*ones(size(embedding,1),1),all_trial_cmap,...
    'filled')
axis([...
    min(embedding(:,1))-xy_bias,...
    max(embedding(:,1))+xy_bias,...
    min(embedding(:,2))-xy_bias,...
    max(embedding(:,2))+xy_bias])
axis square
set(gca,'XTick',[])
set(gca,'YTick',[])
% xlabel('UMAP 1')
ylabel('UMAP 2')
set(gca,'FontSize',6)

% colorbar
temph = subplot('Position',[...
    start_x+box_x+0.005,box_y-0.05+start_y,0.005,0.05]);
imagesc((1:size(unique_trial_cmap,1))')
colormap(temph,flipud(unique_trial_cmap))
set(gca,'YTick',[0,1],'XTick',[])
set(gca,'YAxisLocation','right')
ylabel('中间分界线，区分fix(蓝) free(红)','Position',[3,15])
set(gca,'FontSize',6)
set(gca,'YTick',[])
set(gca,'XTick',[])

% %% test show neural module umap with behavior classes
% figure
% beh_idx_list = cell2mat(le_sample_cell(:,5));
% unique_beh = unique(beh_idx_list);
% 
% cmap = cbrewer2('Spectral',41);
% cmap_list = cmap(beh_idx_list,:);
% 
% scatter(embedding(:,1),embedding(:,2),...
%     1*ones(size(embedding,1),1),cmap_list,...
%     'filled')
%% clustering
% detect best cluster number
% figure
cluster_num_range = 1:100;
E2 = evalclusters(embedding,'linkage','silhouette','KList',1:100);
% plot(E2)
auto_num = E2.OptimalK;
rec_auto_num = intersect(cluster_num_range,auto_num);
%
% figure
n_clus = 77;% calculate from silhouette coef, best class
D = pdist(embedding,'seuclidean');
Z = squareform(D);
tree = linkage(Z, 'ward','euclidean');
T = cluster(tree,'maxclust',n_clus);
% cutoff = median([tree(end-2,3) tree(end-1,3)]);
% dendrogram(tree,'ColorThreshold',cutoff)
% 
label_embedding = [embedding,T];

coloridx = label_embedding(:,3);
cmap = cbrewer2('Spectral',length(unique(coloridx)));
cmaplist = cmap(coloridx,:);

% scatter(embedding(:,1),embedding(:,2),...
%     10*ones(size(embedding,1),1),cmaplist,...
%     "filled");
%% clustering of neural module umap
start_x = 0.02;
start_y = 0.28;
box_x = 0.15;
box_y = 0.15;

subplot('Position',[start_x,start_y,box_x,box_y]);
scatter(embedding(:,1),embedding(:,2),...
    1*ones(size(embedding,1),1),cmaplist,...
    'filled')
axis([...
    min(embedding(:,1))-xy_bias,...
    max(embedding(:,1))+xy_bias,...
    min(embedding(:,2))-xy_bias,...
    max(embedding(:,2))+xy_bias])
axis square
set(gca,'XTick',[])
set(gca,'YTick',[])
xlabel('UMAP 1')
ylabel('UMAP 2')
set(gca,'FontSize',6)

% colorbar
temph = subplot('Position',[...
    start_x+box_x+0.005,box_y-0.05+start_y,0.005,0.05]);
imagesc((1:size(cmap,1))')
colormap(temph,flipud(cmap))
set(gca,'YTick',[0,1],'XTick',[])
set(gca,'YAxisLocation','right')
ylabel('Classes','Position',[3,round(size(cmap,1)/2)])
set(gca,'FontSize',6)
set(gca,'YTick',[1,size(cmap,1)])
set(gca,'XTick',[])

%% compare the neural modules between free and fix group
unique_label = unique(label_embedding(:,3));

data_group_label = cell(size(unique_trial_list,1),2);
data_group_label(:,1) = unique_trial_list;

for k = 1:size(data_group_label,1)
    tempgroup = data_group_label{k,1};
    selidx = strcmp(tempgroup,all_trial_list(:,1));
    sel_label = label_embedding(selidx,3);
    tab_tabel = zeros(n_clus,2);
    tab_tabel(:,1) = 1:n_clus;

    temptab = tabulate(sel_label);

    tab_tabel(temptab(:,1),2) = ...
        temptab(:,2)./length(sel_label);

    data_group_label{k,2} = tab_tabel;
end

cmp_fix_free = zeros(n_clus,size(data_group_label,1));
for k = 1:size(cmp_fix_free,2)
    cmp_fix_free(:,k) = data_group_label{k,2}(:,2);
end

%% show compare group
start_x = 0.25;
start_y = 0.28;
box_x = 0.74;
box_y = 0.31;

mk_alpha = 0.2;
mean_alpha = 0.6;
mk_size = 4;
mean_size = 20;

cmp_fix = cmp_fix_free(:,1:15)';
cmp_free = cmp_fix_free(:,16:end)';

cmp_fix_mean = mean(cmp_fix);
cmp_free_mean = mean(cmp_free);

diff_fix_free = cmp_fix_mean-cmp_free_mean;

[sort_fix_free,sort_fix_free_I] = sort(diff_fix_free,'descend');
sort_cmp_fix = cmp_fix(:,sort_fix_free_I);
sort_cmp_free = cmp_free(:,sort_fix_free_I);
sort_cmp_fix_mean = cmp_fix_mean(:,sort_fix_free_I);
sort_cmp_free_mean = cmp_free_mean(:,sort_fix_free_I);

sort_cmap = cmap(sort_fix_free_I,:);

xlist = 1:size(cmp_fix_free,1);
subplot('Position',[start_x,start_y,box_x,box_y])
for k = 1:size(sort_cmp_free,1)
    plot(xlist,sort_cmp_free(k,:),'-',...
        'Color',[class_cmap_free,mk_alpha],...
        'LineWidth',0.25)
    hold on
    scatter(xlist,sort_cmp_free(k,:),...
        mk_size*ones(length(xlist),1),...
        ones(length(xlist),1)*class_cmap_free,...
        'filled','MarkerEdgeAlpha',mk_alpha,...
        'MarkerFaceAlpha',mk_alpha)
    hold on
end
for k = 1:size(sort_cmp_fix,1)
    plot(xlist,sort_cmp_fix(k,:),'-',...
        'Color',[class_cmap_fix,mk_alpha],...
        'LineWidth',0.25)
    hold on
    scatter(xlist,sort_cmp_fix(k,:),...
        mk_size*ones(length(xlist),1),...
        ones(length(xlist),1)*class_cmap_fix,...
        'filled','MarkerEdgeAlpha',mk_alpha,...
        'MarkerFaceAlpha',mk_alpha)
    hold on
end
plot(xlist,sort_cmp_free_mean,'-',...
    'Color',[class_cmap_free,mean_alpha],...
        'LineWidth',1.5)
hold on
scatter(xlist,sort_cmp_free_mean,...
        mean_size*ones(length(xlist),1),...
        ones(length(xlist),1)*class_cmap_free,...
        'filled','MarkerEdgeAlpha',mean_alpha,...
        'MarkerFaceAlpha',mean_alpha)
hold on
plot(xlist,sort_cmp_fix_mean,'-',...
    'Color',[class_cmap_fix,mean_alpha],...
        'LineWidth',1.5)
hold on
scatter(xlist,sort_cmp_fix_mean,...
        mean_size*ones(length(xlist),1),...
        ones(length(xlist),1)*class_cmap_fix,...
        'filled','MarkerEdgeAlpha',mean_alpha,...
        'MarkerFaceAlpha',mean_alpha)
hold off
box off
axis([0.3,77.7,0,0.2])
set(gca,'TickDir','out')
set(gca,'XTick',xlist)
set(gca,'YTick',[0,0.1,0.2])
set(gca,'FontSize',6)
ylabel('Fractions')
set(gca,'XTickLabel',[])

% show classes
box_y = 0.01;
subplot('Position', ...
    [start_x,start_y-box_y-0.005,box_x,box_y])
for k = 1:length(xlist)
    plot(xlist(k),0,'s',...
        'MarkerEdgeColor',sort_cmap(k,:),...
        'MarkerFaceColor',sort_cmap(k,:))
    hold on
end
hold off
axis([0.3,77.7,-1,1])
axis off
%% show different neural module trajectories
% use DTW to align these modules
sel_neusyn_list = [28;68];
sel_neusyn_cell = cell(length(sel_neusyn_list),2);

for k = 1:size(sel_neusyn_cell,1)
    selidx = sel_neusyn_list(k);
    sel_neusyn_cell{k,1} = selidx;
    sel_class_idx = label_embedding(:,3)==selidx;
    sel_le_cell = [le_sample_cell(sel_class_idx,:),...
        data_sample_cell(sel_class_idx,2)];
    sel_neusyn_cell{k,2} = sel_le_cell;
end

%% compare temporal features
cmp_time_cell = cell(size(sel_neusyn_cell,1),3);
fs = 30;
videotime = 5*60;
xi = 0:videotime;
bin_xi = 0:1:videotime;
for k = 1:size(sel_neusyn_cell,1)
    %%
    tempsavelist = cell2mat(sel_neusyn_cell{k,2}(:,6));
    tempstarttime = tempsavelist(:,1)/fs;
    cmp_time_cell{k,1} = tempstarttime;
    %%
    f = ksdensity(tempstarttime,xi);
    cmp_time_cell{k,2} = f;
    %% save bin data
    [N,X] = hist(tempstarttime,bin_xi);
    cmp_time_cell{k,3} = N/sum(N);
end


human_help_start_time = temp_human_label.start_time_s_;
human_help_end_time = temp_human_label.end_time_s_;

human_help_time_list = [];
for k = 1:size(human_help_start_time,1)
    human_help_time_list = [human_help_time_list,...
        human_help_start_time(k):(1/fs):human_help_end_time(k)];
end
human_help_time_list = human_help_time_list';
human_help_time_list_f = ksdensity(human_help_time_list,xi);
human_help_time_list_bin = hist(human_help_time_list,bin_xi);
human_help_time_list_bin = human_help_time_list_bin/...
    sum(human_help_time_list_bin);
%% show temporal distribution of differences
start_x = 0.02;
start_y = 0.15;
box_x = 0.15;
box_y = 0.08;

cmp_clr = cbrewer2('RdBu',size(sel_neusyn_cell,1));
subplot('Position',[start_x,start_y,box_x,box_y])
for k = 1:size(sel_neusyn_list,1)
    plot(xi,cmp_time_cell{k,2},'-','Color',cmp_clr(k,:))
    hold on
end
hold off
box off 
set(gca,'TickDir','out')
set(gca,'XTickLabel',[])
ylabel('Density')

start_x = 0.02;
start_y = 0.06;
box_x = 0.15;
box_y = 0.08;

subplot('Position',[start_x,start_y,box_x,box_y])
plot(xi,human_help_time_list_f,'-k')
box off
set(gca,'TickDir','out')
axis([0,300,0,6e-3])
xlabel('Time (s)')
ylabel('Density')

%% calculate correlations between lde with humans
dist_time_cell = cell(size(cmp_time_cell,1),3);
for k = 1:size(dist_time_cell,1)
    objtime = cmp_time_cell{k,3};
    reftime = human_help_time_list_bin;
    dist_time_cell{k,1} = abs(objtime-reftime)';
    dist_time_cell{k,2} = mean(dist_time_cell{k,1});
    dist_time_cell{k,3} = std(dist_time_cell{k,1})./...
        sqrt(length(dist_time_cell{k,1}));
end

start_x = 0.25;
start_y = 0.06;
box_x = 0.12;
box_y = 0.17;
mk_size = 2;
bias_x = 0.4;

xlist = [1,2];
subplot('Position',[start_x,start_y,box_x,box_y])
for k = 1:size(cmp_time_cell,1)
    bar(xlist(k),dist_time_cell{k,2},...
        'FaceColor',cmp_clr(k,:))
    hold on
    errorbar(xlist(k),dist_time_cell{k,2},dist_time_cell{k,3},...
        'Color','k')
    hold on
    plot(bias_x+xlist(k)*ones(length(dist_time_cell{k,1}),1),...
        dist_time_cell{k,1},'o','MarkerSize',mk_size,...
        'MarkerEdgeColor','k',...
        'MarkerFaceColor','w')
    hold on
end
hold off

box off
set(gca,'TickDir','out')
% axis([0.3,2.7,0,0.01])

%% analysis the map of neural and behavior






























