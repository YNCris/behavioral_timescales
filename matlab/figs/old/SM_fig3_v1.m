%{
    看看人工标注的序列是否与机器一致
%}
clear all
close all
%% set path
rootpath = ['X:\hanyaning\multi_mice_test\Social_analysis\' ...
    'data\MTPM_social_20220228_all'];
datapath = [rootpath,'\recluster_data'];
%% load data
temp_label = readtable([datapath,'\labeled_help_behavior.xlsx']);
load([datapath,'\data_sample_cell_20230301.mat']);
beh_class = readcell([datapath,'\cut_beh_20230301_classes.xlsx']);
ctn = load([datapath,'\cnt_body_language_20230425.mat']);
%% align human label with movement sequence
human_label_cell = cell(size(temp_label,1),6);
fs = 30;
rootnamelist = cellfun(@(x) x(1,1:(end-11)),...
        data_sample_cell(:,3),'UniformOutput',false);
for k = 1:size(human_label_cell,1)
    human_label_cell{k,1} = temp_label{k,1}{1}(1,1:(end-4));
    human_label_cell{k,2} = temp_label{k,2}*fs+1;
    human_label_cell{k,3} = temp_label{k,3}*fs;
    human_label_cell{k,4} = temp_label{k,4};

    %%
    sel_idx = strcmp(rootnamelist,human_label_cell{k,1});
    sel_labels = data_sample_cell(sel_idx,2);
    for m = 1:size(sel_labels,1)
        start_idx = sel_labels{m}(1);
        end_idx = sel_labels{m}(2);
        if start_idx<=human_label_cell{k,2} && ...
                end_idx>=human_label_cell{k,2}
            seq_start = m;
        end
        if start_idx<=human_label_cell{k,3} && ...
                end_idx>=human_label_cell{k,3}
            seq_end = m;
        end
    end
    sel_labels_mat = cell2mat(sel_labels);
    human_label_cell{k,5} = ...
        sel_labels_mat(seq_start:seq_end,4);
    human_label_cell{k,6} = beh_class(human_label_cell{k,5});

    disp(k)
end
%% sort data
% help_move_cell = human_label_cell(125:127,:);
% help_inv_cell = human_label_cell([1:124,128:153],:);
help_inv_cell = human_label_cell;

inv_distmat = zeros(size(help_inv_cell,1),size(help_inv_cell,1));

for m = 1:size(help_inv_cell,1)
    for n = 1:size(help_inv_cell,1)
        %% 
        seq_1 = help_inv_cell{m,5};
        seq_2 = help_inv_cell{n,5};
        
        seq_distmat = zeros(length(seq_1),length(seq_2));
        for p = 1:length(seq_1)
            for q = 1:length(seq_2)
                if seq_1(p) ~= seq_2(q)
                    seq_distmat(p,q) = 1;
                end
            end
        end
        Kdistmat = conKnl(seq_distmat,1);
		wFs1 = ones(1,size(Kdistmat,1));
		wFs2 = ones(1,size(Kdistmat,2));
		[T,~,~] = dtakFord(Kdistmat,0,wFs1,wFs2);
        inv_distmat(m,n) = T;
    end
end
%%
D = pdist(inv_distmat,'seuclidean');
Z = squareform(D);
tree = linkage(Z, 'ward','euclidean');
[~,~,P_sort] = dendrogram(tree,0);

sort_inv_cell = help_inv_cell(P_sort,:);

pad_max_len = max(cell2mat(cellfun(@(x) size(x,1),...
    sort_inv_cell(:,6),'UniformOutput',false)));
pad_sort_inv_cell = cell(size(sort_inv_cell,1),1);

for k = 1:size(pad_sort_inv_cell,1)
    tempclass = sort_inv_cell{k,5};
    padclass = [tempclass;...
        zeros(pad_max_len-length(tempclass),1)]';
    pad_sort_inv_cell{k,1} = padclass;
end

pad_sort_inv_mat = cell2mat(pad_sort_inv_cell);

class_seq_cell = cell(1,size(pad_sort_inv_mat,2));

for k = 1:size(pad_sort_inv_mat,2)
    templist = pad_sort_inv_mat(:,k);
    class_seq_cell{k} = tabulate(templist);
    class_seq_cell{k}(class_seq_cell{k}(:,3)==0,:) = [];
end

unique_class_idx = unique(pad_sort_inv_mat(:));
unique_class_idx = unique_class_idx(2:end);


all_tab_class = tabulate(cell2mat(sort_inv_cell(:,5)));
all_tab_class(all_tab_class(:,2)==0,:) = [];

sort_all_tab_class = sortrows(all_tab_class,2,'descend');

count_mat = zeros(size(sort_all_tab_class,1),...
    size(pad_sort_inv_mat,2)+1);
count_mat(:,1) = sort_all_tab_class(:,2);
for k = 2:size(count_mat,2)
    for m = 1:length(sort_all_tab_class(:,1))
        tempclass = sort_all_tab_class(m,1);
        count_mat(m,k) = sum(pad_sort_inv_mat(:,k-1)==tempclass);
    end
end

shu_perc = 0.01;%缩小系数，用于方便显示
norm_count_mat = zeros(size(count_mat));
for k = 1:size(count_mat,2)
    norm_count = mat2gray(count_mat(:,k))+...
        flipud(((1:size(count_mat,1))*shu_perc)');
    norm_count_mat(:,k) = norm_count;
end
%% plot canvas
hall = figure(1);
set(hall,'Position',[900,100,800,800])
set(hall,'color','white');

%% plot raw data
start_x = 0.06;

all_cmap = cbrewer2('Spectral',256);
all_cmap(65:192,:) = [];
beh_class_cmap = mat2gray(imresize(all_cmap,...
    [length(unique_class_idx),3]));
beh_class_cmap_zero = [1*ones(1,3);beh_class_cmap];
temph = subplot('Position',[start_x,0.73,0.9,0.2]);
imagesc(pad_sort_inv_mat)
colormap(temph,beh_class_cmap_zero)
box off
set(gca,'TickDir','out')
set(gca,'XTick',1:size(pad_sort_inv_mat,2))
set(gca,'YTick',[1,size(pad_sort_inv_mat,1)])
ylabel('Prosocial behavior sequences')
xlabel('Time steps','Position',[32,180])

sel_beh_class = beh_class(unique_class_idx);

% plot classes
box_xy = 0.05;
subplot('Position',[start_x,0.94,0.9,0.05]);
count = 1;
for m = 1:8
    for n = 1:3
        plot([m-box_xy,m+box_xy],[n,n],'-',...
            'Color',beh_class_cmap(count,:),'LineWidth',6)
        hold on
        text(m+box_xy+0.02,n,sel_beh_class{count},'Interpreter','none',...
            'FontSize',6)
        count = count+1;
    end
end
hold off
axis([1-box_xy,8.7,0.5,3.5])
axis off

%% plot 前几个概率，字符点云
show_num = 5;

start_x = 0.06;
start_y = 0.51;
box_y = 0.12;
inter_x = 0.002;
box_x = 0.75/show_num-inter_x;


cmap_tm_fix = cbrewer2('Reds',256);
for k = 1:show_num
    show_beh = beh_class(class_seq_cell{k}(2:end,1));
    size_beh = class_seq_cell{k}(2:end,2);
    subplot('Position',...
        [start_x+(k-1)*(box_x+inter_x),...
        start_y,box_x,box_y])
    wordcloud(show_beh,size_beh,'Shape','rectangle',...
            'LayoutNum',3,'HighlightColor',cmap_tm_fix(end,:))
end

%% 量化trapped和free与手工的异同
cut_len = 12;
cut_pad_sort_inv_mat = pad_sort_inv_mat(:,1:cut_len);
cut_sort_sel_mask_ctn_mat = ...
    ctn.sort_sel_mask_ctn_mat(:,1:cut_len);

trap_ctn = ctn.sort_sel_show_ctn_count_mat(:,1:15);
free_ctn = ctn.sort_sel_show_ctn_count_mat(:,16:end);
mean_trap_ctn = mean(trap_ctn,2);
mean_free_ctn = mean(free_ctn,2);

ctn_inv_distmat = zeros(size(cut_sort_sel_mask_ctn_mat,1),...
    size(cut_pad_sort_inv_mat,1));

for m = 1:size(ctn_inv_distmat,1)
    for n = 1:size(ctn_inv_distmat,2)
        sel_ctn = cut_sort_sel_mask_ctn_mat(m,:);
        sel_inv = cut_pad_sort_inv_mat(n,:);
        dot_ctn_inv = sel_ctn.*sel_inv;
        sel_ctn = sel_ctn(dot_ctn_inv~=0);
        sel_inv = sel_inv(dot_ctn_inv~=0);
        distlist = ones(size(sel_ctn));
        %% compare hamming distances
        for p = 1:length(sel_ctn)
            if (sel_ctn(p)==sel_inv(p))&&...
                (sel_ctn(p)~=0)&&(sel_ctn(p)~=0)
                distlist(p) = 0;
            end
        end

        ctn_inv_distmat(m,n) = mean(distlist);
    end
end

ctn_inv_mindist = min(ctn_inv_distmat,[],2);

trap1_free0_idx = mean_trap_ctn>mean_free_ctn;

trap_dist = ctn_inv_mindist(trap1_free0_idx==1);
free_dist = ctn_inv_mindist(trap1_free0_idx==0);

mean_trap_dist = mean(trap_dist);
mean_free_dist = mean(free_dist);
std_trap_dist = std(trap_dist);
std_free_dist = std(free_dist);

cmap_tm_free = cbrewer2('Blues',256);
mk_clr = cmap_tm_free(128,:);
subplot('Position',[0.86,start_y,0.1,box_y])
bar([1,2],[mean_trap_dist,mean_free_dist],...
    'FaceColor',mk_clr)
hold on
errorbar(1,mean_trap_dist,std_trap_dist,'Color','k')
hold on
errorbar(2,mean_free_dist,std_free_dist,'Color','k')
hold on
rng('default')
for k = 1:length(trap_dist)
    plot(1+(rand(1)-0.5)/3,trap_dist(k,1),...
        'ko','MarkerSize',2,...
        'MarkerFaceColor','w','LineWidth',0.25)
end
hold on
rng('default')
for k = 1:length(free_dist)
    plot(2+(rand(1)-0.5)/3,free_dist(k,1),...
        'ko','MarkerSize',2,...
        'MarkerFaceColor','w','LineWidth',0.25)
end
hold off
box off
ylabel('Mean hamming distances')
set(gca,'TickDir','out')
set(gca,'XTick',[1,2])
set(gca,'XTickLabel',{'Trapped','Free'},...
    'XTickLabelRotation',0)
axis([0.3,2.7,0,1.1])











































