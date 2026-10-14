%{
    分far-close-二态行为，用储池计算模拟fitting
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

all_data_cell = cell(size(neuNames,1),9);
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
    disp(k)
end
%% split far-close-far trial
fs = 30;
baseline_far_time = 5;%s
after_far_time = 60;%s
min_close_time = 1;%s
max_close_time = 30;%s

baseline_far_frame = baseline_far_time*fs;
after_far_frame = after_far_time*fs;
min_close_frame = min_close_time*fs;
max_close_frame = max_close_time*fs;

raw_trial_cell = {};

for k = 1:size(all_data_cell,1)
    %% load data
    tempdist = all_data_cell{k,9};
    
    %% select trials
    distsavelist = idx2savelist(tempdist{2});

    all_close_list = distsavelist(distsavelist(:,3)==1,:);

    all_close_list(all_close_list(:,1)<baseline_far_frame,:) = [];
    all_close_list(all_close_list(:,2)>...
        length(tempdist{2})-after_far_frame,:) = [];
    all_close_list(...
        (all_close_list(:,2)-all_close_list(:,1))<...
        min_close_frame,:) = [];
    all_close_list(...
        (all_close_list(:,2)-all_close_list(:,1))>...
        max_close_frame,:) = [];


    sel_close_list = all_close_list;
    %% append data
    for m = 1:size(sel_close_list,1)
        tempstart = sel_close_list(m,1)-baseline_far_frame;
        tempend = sel_close_list(m,2)+after_far_frame;

        newname = [all_data_cell{k,1},'-',num2str(m)];
        all_data_2 = all_data_cell{k,2}(tempstart:tempend,:);
        all_data_3 = all_data_cell{k,3}(tempstart:tempend,:);
        all_data_4 = all_data_cell{k,4}(tempstart:tempend,:);
        all_data_5 = all_data_cell{k,5}(tempstart:tempend,:);
        all_data_6 = all_data_cell{k,6}(tempstart:tempend,:);
        all_data_7 = all_data_cell{k,7}(tempstart:tempend,:);
        all_data_8 = all_data_cell{k,8}(tempstart:tempend,:);
        all_data_9 = all_data_cell{k,9}{3}(tempstart:tempend,:);

        raw_trial_cell = [raw_trial_cell;...
            {newname,all_data_2,all_data_3,all_data_4,...
            all_data_5,all_data_6,all_data_7,all_data_8,...
            all_data_9,all_data_cell{k,1}}];

        unique(all_data_5)
    end
    %%
    disp(k)
end
%% create the unique_mov and unique_seq
all_mov = [];
all_mov_name = {};
for k = 1:size(raw_trial_cell,1)
    all_mov = [all_mov;...
        cell2mat(raw_trial_cell{k,4}(:,2));...
        cell2mat(raw_trial_cell{k,7}(:,2))];
    all_mov_name = [all_mov_name;...
        raw_trial_cell{k,4}(:,1);...
        raw_trial_cell{k,7}(:,1)];
end
unique_mov = unique(all_mov);
cmap_mov = cbrewer2('BuPu',length(unique_mov));

uniuqe_mov_name = cell(size(unique_mov));
for k = 1:size(unique_mov,1)
    tempname = all_mov_name(unique_mov(k)==all_mov);
    uniuqe_mov_name{k} = tempname{1};
end

all_seq = [];
for k = 1:size(raw_trial_cell,1)
    all_seq = [all_seq;raw_trial_cell{k,5};raw_trial_cell{k,8}];
end
unique_seq = unique(all_seq);
unique_seq = unique_seq(2:end);
cmap_seq = cbrewer2('BuPu',length(unique_seq));
%% sort data by length
trial_length = cell2mat(cellfun(@(x) size(x,1),...
    raw_trial_cell(:,2),...
    'UniformOutput',false));

[~,sortidx] = sort(trial_length,'descend');

sort_trial_cell = raw_trial_cell(sortidx,:);

% %% sort data by the length of far
% far_length = cell2mat(cellfun(@(x) sum(x==0),...
%     raw_trial_cell(:,8),...
%     'UniformOutput',false));
% 
% [~,sortidx] = sort(far_length,'descend');
% 
% sort_trial_cell = raw_trial_cell(sortidx,:);

%% plot canvas
hall = figure(1);
set(hall,'Position',[680,0,800,800])
set(hall,'color','white');

%% draw demo and data
start_x = 0.04;
start_y = 0.88;

box_x = 0.3;
box_y = 0.1;

inter_y = 0.01;

x_tick = [1,150,1050,1950];
x_tick_label = [-5,0,30,60];

show_x_len = 2100;

% demo
subplot('Position',[start_x,start_y,box_x,box_y])

% self mov

% create mov mat
pad_len = 3000;
self_mov_mat = -1*ones(size(sort_trial_cell,1),pad_len);
start_list = zeros(size(self_mov_mat,1),2);
end_list = zeros(size(self_mov_mat,1),2);

for k = 1:size(self_mov_mat,1)
    tempmov = cell2mat(sort_trial_cell{k,4}(:,2))';
    self_mov_mat(k,1:length(tempmov)) = tempmov;
    start_list(k,:) = [baseline_far_frame,k];
    end_list(k,:) = [length(tempmov)-after_close_frame,k];
end

temph = subplot('Position',[start_x,...
    start_y-box_y-inter_y,box_x,box_y]);

imagesc(self_mov_mat)
colormap(temph,[1,1,1;cmap_mov])
hold on
plot(start_list(:,1),start_list(:,2),'-k')
hold on
plot(end_list(:,1),end_list(:,2),'-k')
hold off

box off
% title('Self')

axis([0,show_x_len,0,size(self_mov_mat,1)])

ylabel('Self movements')

set(gca,'XTick',x_tick)
set(gca,'XTickLabel',[])
% set(gca,'XTickLabel',x_tick_label)

set(gca,'YTick',[1,size(self_mov_mat,1)])

set(gca,'TickDir','out')
set(gca,'FontSize',6)
xlabel('Time (s)')

% colorbar, mov
cbar_box_x = 0.006;
cbar_box_y = 0.05;

cbar_inter_x = 0.01;

temph = subplot('Position',[...
    start_x+box_x+cbar_inter_x,...
    start_y-box_y-inter_y+cbar_box_y,...
    cbar_box_x,cbar_box_y]);
imagesc(flipud((1:max(unique_mov))'))
colormap(temph,cmap_mov)
set(gca,'XTick',[],'YTick',[])

text(0.5,50,'1','FontSize',6,'VerticalAlignment','middle')
text(0.5,-1,'49','FontSize',6,'VerticalAlignment','middle')

text(2.5,25,{'Movement','categories'},...
    'FontSize',6,'Rotation',90,...
    'HorizontalAlignment','center')



% partner mov

part_mov_mat = -1*ones(size(sort_trial_cell,1),pad_len);
start_list = zeros(size(part_mov_mat,1),2);
end_list = zeros(size(part_mov_mat,1),2);

for k = 1:size(part_mov_mat,1)
    tempmov = cell2mat(sort_trial_cell{k,7}(:,2))';
    part_mov_mat(k,1:length(tempmov)) = tempmov;
    start_list(k,:) = [baseline_far_frame,k];
    end_list(k,:) = [length(tempmov)-after_far_frame,k];
end

temph = subplot('Position',[start_x,...
    start_y-2*(box_y+inter_y),box_x,box_y]);

imagesc(part_mov_mat)
colormap(temph,[1,1,1;cmap_mov])
hold on
plot(start_list(:,1),start_list(:,2),'-k')
hold on
plot(end_list(:,1),end_list(:,2),'-k')
hold off

box off

axis([0,show_x_len,0,size(part_mov_mat,1)])

ylabel('Partner movements')

set(gca,'XTick',x_tick)
set(gca,'XTickLabel',[])

set(gca,'YTick',[1,size(part_mov_mat,1)])
% set(gca,'YTickLabel',[])

% title('Partner')
set(gca,'TickDir','out')
set(gca,'FontSize',6)
xlabel('Time (s)')
%% pc 1
pca_cell = cell(size(sort_trial_cell,1),5);

for k = 1:size(pca_cell,1)
    tempneu = sort_trial_cell{k,2};
    [coeff, score, ~, ~, explained] = pca(tempneu');
    pca_cell{k,1} = coeff;
    pca_cell{k,2} = score;
    pca_cell{k,3} = explained;
    pca_cell{k,4} = cumsum(explained);
    pca_cell{k,5} = explained;
    disp(k)
end

sel_pc = cellfun(@(x) mat2gray(x(:,1)'),...
        pca_cell(:,1),'UniformOutput',false);

pad_pc_mat = nan(size(sel_pc,1),pad_len);
start_list = zeros(size(pad_pc_mat,1),2);
end_list = zeros(size(pad_pc_mat,1),2);

for k = 1:size(pad_pc_mat,1)
    temppca = sel_pc{k};
    pad_pc_mat(k,1:length(temppca)) = temppca;
    start_list(k,:) = [baseline_far_frame,k];
    end_list(k,:) = [length(tempmov)-after_close_frame,k];
end

%%
temph = subplot('Position',[start_x,...
    start_y-4*(box_y+inter_y),box_x,box_y]);
imagesc(pad_pc_mat)

colormap(temph,[1,1,1;cmap_neu])

hold on
plot(start_list(:,1),start_list(:,2),'-k')
hold on
plot(end_list(:,1),end_list(:,2),'-k')
hold off

axis([0,show_x_len,0,size(pad_pc_mat,1)])

box off

ylabel('PC 1')
xlabel('Time (s)')

set(gca,'XTick',x_tick)
set(gca,'XTickLabel',x_tick_label)

set(gca,'YTick',[1,size(pad_pc_mat,1)])

set(gca,'FontSize',6)
set(gca,'TickDir','out')

% colorbar
cbar_box_x = 0.006;
cbar_box_y = 0.05;

cbar_inter_x = 0.01;

temph = subplot('Position',[...
    start_x+box_x+cbar_inter_x,...
    start_y-3*(box_y+inter_y)-inter_y-cbar_box_y,...
    cbar_box_x,cbar_box_y]);
imagesc(fliplr((1:256))')
colormap(temph,cmap_neu)
set(gca,'XTick',[],'YTick',[])

text(0.5,280,'0','FontSize',6,'VerticalAlignment','middle')
text(0.5,-30,'1','FontSize',6,'VerticalAlignment','middle')

text(2.5,128,'PC coefficient','FontSize',6,'Rotation',90,...
    'HorizontalAlignment','center')

set(gca,'FontSize',6)

%% neu (really slow)

neu_mat = [];
neu_start_list = [];
neu_end_list = [];

count = 1;

for k = 1:size(sort_trial_cell,1)
    tempneu = sort_trial_cell{k,2}';
    padneu = nan(size(tempneu,1),pad_len);

    for m = 1:size(padneu,1)
        ttneu = tempneu(m,:);
        padneu(m,1:length(ttneu)) = ttneu;
        neu_start_list = [neu_start_list;...
            [baseline_far_frame,count]];
        neu_end_list = [neu_end_list;...
            [length(ttneu)-after_far_frame,count]];

        count = count+1;
    end
    
    neu_mat = [neu_mat;padneu];
end

%% show neu
show_range = [-0.5,0.5];

cmap_neu = flipud(cbrewer2('RdBu',256));

temph = subplot('Position',[start_x,...
    start_y-3*(box_y+inter_y),box_x,box_y]);
imagesc(neu_mat,show_range)

colormap(temph,[1,1,1;cmap_neu])
hold on
plot(neu_start_list(:,1),neu_start_list(:,2),'-k')
hold on
plot(neu_end_list(:,1),neu_end_list(:,2),'-k')
hold off

box off

axis([0,show_x_len,0,size(neu_mat,1)])

set(gca,'FontSize',6)
set(gca,'TickDir','out')
set(gca,'XTick',x_tick)
set(gca,'XTickLabel',[])
% xlabel('Time (s)')
ylabel('Neural activities')

% colorbar
cbar_box_x = 0.006;
cbar_box_y = 0.05;

cbar_inter_x = 0.01;

temph = subplot('Position',[...
    start_x+box_x+cbar_inter_x,...
    start_y-2*(box_y+inter_y)-inter_y-cbar_box_y,...
    cbar_box_x,cbar_box_y]);
imagesc(flipud((1:256)'))
colormap(temph,cmap_neu)
set(gca,'XTick',[],'YTick',[])

text(0.5,280,'-0.5','FontSize',6,'VerticalAlignment','middle')
text(0.5,-30,'0.5','FontSize',6,'VerticalAlignment','middle')

text(2.5,128,'ΔF/F','FontSize',6,'Rotation',90,...
    'HorizontalAlignment','center')





































