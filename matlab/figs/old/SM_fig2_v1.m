%{
    用自然语言作为对照去看看BERT能不能提取有效语义
%}
clear all
close all
%% set path
rootpath = ['X:\hanyaning\multi_mice_test\Social_analysis\' ...
    'data\MTPM_social_20220228_all'];
datapath = [rootpath,'\recluster_data'];
%% load data
load([datapath,'\hl_cnt_count_cell_20230531.mat']);
load([datapath,'\hl_mask_token_20230531.mat']);
load([datapath,'\hl_mask_ctn_list_20230531.mat']);

ctn_body = load([datapath,'\mask_ctn_list_20230425.mat']);

%% seperate raw data and random data
raw_idx = 1:(size(cnt_count_cell,1)/2);
rand_idx = (1+(size(cnt_count_cell,1)/2)):size(cnt_count_cell,1);

raw_mask_ctn_list = mask_ctn_list(raw_idx,:);
rand_mask_ctn_list = mask_ctn_list(rand_idx,:);

%% sort by length
raw_mask_ctn_mat = cell2mat(raw_mask_ctn_list);
rand_mask_ctn_mat = cell2mat(rand_mask_ctn_list);

one_idx_raw_list = sum(raw_mask_ctn_mat~=0,2);
one_idx_rand_list = sum(rand_mask_ctn_mat~=0,2);

raw_perc_cell = cell(12,1);
for k = 1:size(raw_perc_cell,1)
    %%
    selmask = raw_mask_ctn_mat(one_idx_raw_list==k,1:k);
    if size(selmask,1) == 0
        break
    end
    all_tab_cell = cell(1,size(selmask,2));
    for m = 1:size(selmask,2)
        temptab = tabulate(selmask(:,m));
        temptab(temptab(:,2)==0,:) = [];
        all_tab_cell{m} = [temptab(:,1),temptab(:,3)/100];
    end
    raw_perc_cell{k,1} = all_tab_cell;
end

rand_perc_cell = cell(12,1);
for k = 1:size(rand_perc_cell,1)
    %%
    selmask = rand_mask_ctn_mat(one_idx_rand_list==k,1:k);
    if size(selmask,1) == 0
        break
    end
    all_tab_cell = cell(1,size(selmask,2));
    for m = 1:size(selmask,2)
        temptab = tabulate(selmask(:,m));
        temptab(temptab(:,2)==0,:) = [];
        all_tab_cell{m} = [temptab(:,1),temptab(:,3)/100];
    end
    rand_perc_cell{k,1} = all_tab_cell;
end

mask_len_thres = 3;
sel_raw_mask_ctn_mat = raw_mask_ctn_mat(...
    one_idx_raw_list>=mask_len_thres,:);
sel_rand_mask_ctn_mat = rand_mask_ctn_mat(...
    one_idx_rand_list>=mask_len_thres,:);
%% count unique mask
unique_raw_mask = unique(sel_raw_mask_ctn_mat,'rows');
unique_rand_mask = unique(sel_rand_mask_ctn_mat,'rows');

count_raw_mask = zeros(size(unique_raw_mask,1),1);
count_rand_mask = zeros(size(unique_rand_mask,1),1);

tic
for k = 1:size(unique_raw_mask,1)
    tempmask = unique_raw_mask(k,:);
    tempmaskmat = ones(size(sel_raw_mask_ctn_mat,1),1)*tempmask;
    count_raw_mask(k,1) = ...
        sum(sum(abs(tempmaskmat-sel_raw_mask_ctn_mat),2)==0);

    if rem(k,1000) == 0
        disp(k)
        toc
    end
end

tic
for k = 1:size(unique_rand_mask,1)
    tempmask = unique_rand_mask(k,:);
    tempmaskmat = ones(size(sel_rand_mask_ctn_mat,1),1)*tempmask;
    count_rand_mask(k,1) = ...
        sum(sum(abs(tempmaskmat-sel_rand_mask_ctn_mat),2)==0);

    if rem(k,1000) == 0
        disp(k)
        toc
    end
end

cut_thres = 3;
sel_unique_raw_mask = ...
    unique_raw_mask(count_raw_mask>=cut_thres,:);
sel_unique_rand_mask = ...
    unique_rand_mask(count_rand_mask>=cut_thres,:);

cmap_tm_raw = cbrewer2('Reds',256);
cmap_tm_rand = cbrewer2('Blues',256);

cmap_raw = ones(size(sel_unique_raw_mask,1),1)...
    *cmap_tm_raw(end,:);
cmap_rand = ones(size(sel_unique_rand_mask,1),1)...
    *cmap_tm_rand(end,:);

cmap_all = [cmap_raw;cmap_rand];

%% plot canvas
hall = figure(1);
set(hall,'Position',[900,100,800,800])
set(hall,'color','white');

%% show
start_x = 0.12;
start_y = 0.97;
box_x = 0.15;
box_y = 0.02;
inter_x = 0.01;
inter_y = 0.002;

col_num = 5;
show_unique_mask = [sel_unique_raw_mask;sel_unique_rand_mask];

row_num = ceil(size(show_unique_mask,1)/col_num);

count = 1;
for m = 1:col_num
    for n = 1:row_num
        subplot('Position',[...
            start_x+(m-1)*(box_x+inter_x),...
            start_y-(n-1)*(box_y+inter_y),...
            box_x,...
            box_y])
        tempmask = show_unique_mask(count,:);
        tempmask(tempmask==0) = [];
        maskword = mask_token(tempmask);
        maskword(1:(end-1)) = ...
            cellfun(@(x) [x,' '],maskword(1:(end-1)),...
            'UniformOutput',false);
        maskword = maskword';
        maskword = cell2mat(maskword);

        text(0,1,maskword,'FontSize',6,...
            'Color',cmap_all(count,:))
        
        axis([-0.5,length(maskword)+0.5,-1,2])
        axis off

        if size(show_unique_mask,1)==count
            break;
        end
        count = count+1;

    end
end

%% distribution statistics
start_x = 0.15;
start_y = 0.12;
all_x = 0.65;
inter_x = 0.05;
box_y = 0.15;

bar_c_raw = cmap_tm_raw(round(size(cmap_tm_raw,1)/6*5),:);
bar_c_rand = cmap_tm_rand(round(size(cmap_tm_raw,1)/6*5),:);
bar_c_fix = cmap_tm_raw(size(cmap_tm_raw,1)/2,:);
bar_c_free = cmap_tm_rand(size(cmap_tm_rand,1)/2,:);

trap_mask_list = ctn_body.mask_ctn_list(1:15,:);
free_mask_list = ctn_body.mask_ctn_list(16:end,:);

raw_len_list = zeros(size(raw_mask_ctn_list,1),12);
rand_len_list = zeros(size(rand_mask_ctn_list,1),12);
trap_len_list = zeros(size(trap_mask_list,1),12);
free_len_list = zeros(size(free_mask_list,1),12);

raw_unique_num_list = cell(size(raw_mask_ctn_list));
rand_unique_num_list = cell(size(rand_mask_ctn_list));

for k = 1:size(raw_mask_ctn_list,1)
    tempmask = raw_mask_ctn_list{k};
    numlist = sum(tempmask~=0,2);
    for m = 1:size(raw_len_list,2)
        raw_len_list(k,m) = sum(numlist==m)/length(numlist);
    end
end

for k = 1:size(rand_mask_ctn_list,1)
    tempmask = rand_mask_ctn_list{k};
    numlist = sum(tempmask~=0,2);
    for m = 1:size(rand_len_list,2)
        rand_len_list(k,m) = sum(numlist==m)/length(numlist);
    end
end

for k = 1:size(trap_mask_list,1)
    tempmask = trap_mask_list{k};
    numlist = sum(tempmask~=0,2);
    for m = 1:size(rand_len_list,2)
        trap_len_list(k,m) = sum(numlist==m)/length(numlist);
    end
end

for k = 1:size(free_mask_list,1)
    tempmask = free_mask_list{k};
    numlist = sum(tempmask~=0,2);
    for m = 1:size(rand_len_list,2)
        free_len_list(k,m) = sum(numlist==m)/length(numlist);
    end
end

mean_raw = mean(raw_len_list);
mean_rand = mean(rand_len_list);
mean_trap = mean(trap_len_list);
mean_free = mean(free_len_list);
std_raw = std(raw_len_list);
std_rand = std(rand_len_list);
std_trap = std(trap_len_list);
std_free = std(free_len_list);

bar_w = 0.6;
cap_size = 3;
subplot('Position',[start_x,start_y,...
    (all_x-inter_x)/3,box_y])
for k = 1:length(mean_raw)
    bar(3*k-2,mean_raw(k),'FaceColor',bar_c_raw,...
        'BarWidth',bar_w)
    hold on
    errorbar(3*k-2,mean_raw(k),std_raw(k),...
        'CapSize',cap_size,'Color','k')
    hold on
    plot((3*k-2+mk_bias)*ones(size(raw_len_list,1),1),...
        raw_len_list(:,k),'o',...
        'MarkerFaceColor','w','MarkerEdgeColor','k',...
        'MarkerSize',mk_size)
    hold on
    bar(3*k-1,mean_rand(k),'FaceColor',bar_c_rand,...
        'BarWidth',bar_w)
    hold on
    errorbar(3*k-1,mean_rand(k),std_rand(k),...
        'CapSize',cap_size,'Color','k')
    hold on
    plot((3*k-1+mk_bias)*ones(size(rand_len_list,1),1),...
        rand_len_list(:,k),'o',...
        'MarkerFaceColor','w','MarkerEdgeColor','k',...
        'MarkerSize',mk_size)
    hold on
end
hold off

set(gca,'XTick',(1:3:36)+0.5)
set(gca,'XTickLabel',1:12)
ylabel('Length ratio')
set(gca,'TickDir','out')
xlabel('Sequence length')
box off
axis([0,18,0,0.5])

cap_size = 3;
mk_size = 2;
mk_bias = 0.3;
% compare human language with animal body language
subplot('Position',[start_x+(all_x-inter_x)/3+inter_x,...
    start_y,...
    (all_x-inter_x)/3*2,box_y])
for k = 1:length(mean_raw)
    bar(4*k-3,mean_raw(k),'FaceColor',bar_c_raw,...
        'BarWidth',bar_w)
    hold on
    errorbar(4*k-3,mean_raw(k),std_raw(k),...
        'CapSize',cap_size,'Color','k')
    hold on
    plot((4*k-3+mk_bias)*ones(size(raw_len_list,1),1),...
        raw_len_list(:,k),'o',...
        'MarkerFaceColor','w','MarkerEdgeColor','k',...
        'MarkerSize',mk_size)
    hold on
    bar(4*k-2,mean_trap(k),'FaceColor',bar_c_fix,...
        'BarWidth',bar_w)
    hold on
    errorbar(4*k-2,mean_trap(k),std_trap(k),...
        'CapSize',cap_size,'Color','k')
    hold on
    plot((4*k-2+mk_bias)*ones(size(trap_len_list,1),1),...
        trap_len_list(:,k),'o',...
        'MarkerFaceColor','w','MarkerEdgeColor','k',...
        'MarkerSize',mk_size)
    hold on
    bar(4*k-1,mean_free(k),'FaceColor',bar_c_free,...
        'BarWidth',bar_w)
    hold on
    errorbar(4*k-1,mean_free(k),std_free(k),...
        'CapSize',cap_size,'Color','k')
    hold on
    plot((4*k-1+mk_bias)*ones(size(free_len_list,1),1),...
        free_len_list(:,k),'o',...
        'MarkerFaceColor','w','MarkerEdgeColor','k',...
        'MarkerSize',mk_size)
    hold on
end
hold off
set(gca,'XTick',(1:4:48)+1)
set(gca,'XTickLabel',1:12)
set(gca,'TickDir','out')
xlabel('Sequence length')
box off
axis([0,24,0,0.5])

% cmap list
lw = 5;
bias_x = 1.2;
bias_y = 0.2;
subplot('Position',[start_x+all_x+0.01,start_y+0.1,...
    0.02,0.05])
plot([0,1],[7,7],'-','Color',bar_c_raw,'LineWidth',lw)
text(bias_x,7+bias_y,'ASAP','FontSize',6)
hold on
plot([0,1],[5,5],'-','Color',bar_c_rand,'LineWidth',lw)
text(bias_x,5+bias_y,'Shuffle ASAP','FontSize',6)
hold on
plot([0,1],[3,3],'-','Color',bar_c_fix,'LineWidth',lw)
text(bias_x,3+bias_y,'Trapped','FontSize',6)
hold on
plot([0,1],[1,1],'-','Color',bar_c_free,'LineWidth',lw)
text(bias_x,1+bias_y,'Free','FontSize',6)
hold off

axis off




























