%{
    fig3, classical analysis of neural signal with behavior modules
%}
clear all
close all
addpath(genpath(pwd))
%% set path
rootpath = ['X:\hanyaning\multi_mice_test\Social_analysis\' ...
    'data\MTPM_social_20220228_all'];
datapath = [rootpath,'\recluster_data'];
%% load data
load([datapath,'\neu_beh_cell_20230707.mat']);
beh_class = cell2mat(neu_beh_cell(:,1));
beh_class = beh_class(:,4);
unique_beh_class = unique(beh_class);
class_name = importdata(...
    [datapath,'\cut_beh_20230301_classes.xlsx']);
load([datapath,'\all_dynamic_cell_20230712.mat']);
load([datapath,'\align_dynamic_cell_20230713.mat']);
load([datapath,'\align_quantify_dynamic_cell_20230712.mat']);
%% plot canvas
hall = figure(1);
set(hall,'Position',[900,100,800,800])
set(hall,'color','white');
%% separate mean fire rate
mean_fire_rate = cell(size(neu_beh_cell,1),1);
for k = 1:size(mean_fire_rate,1)
    %%
    tempdata = neu_beh_cell{k,3};
    tempmean = mean(tempdata,1);
    mean_fire_rate{k,1} = tempmean';
end
%% calculate all fire range
all_fire_rate = cell2mat(mean_fire_rate);
min_fr = min(all_fire_rate);
max_fr = max(all_fire_rate);

beh_fire_pattern = cell(size(unique_beh_class,1),2);
for k = 1:size(beh_fire_pattern,1)
    %%
    beh_fire_pattern{k,1} = unique_beh_class(k);
    selidx = beh_class==beh_fire_pattern{k,1};
    sel_data = cell2mat(mean_fire_rate(selidx,:));
    beh_fire_pattern{k,2} = sel_data;
end

hist_beh_fire_pattern = cell(size(beh_fire_pattern,1),2);
for k = 1:size(hist_beh_fire_pattern,1)
    [no,xo] = hist(beh_fire_pattern{k,2},128);
    hist_beh_fire_pattern{k,1} = mat2gray(no);
    hist_beh_fire_pattern{k,2} = xo;
end

maxidx_beh_fire_pattern = cell2mat(...
    cellfun(@(x,y) mean(y(x==max(x))),...
    hist_beh_fire_pattern(:,1),...
    hist_beh_fire_pattern(:,2),...
    'UniformOutput',false));
[sort_maxidx_beh_fire_pattern,I] = ...
    sort(maxidx_beh_fire_pattern,'descend');
sort_beh_fire_pattern = hist_beh_fire_pattern(I,:);
sort_class_name = class_name(I,:);
%% show fire rate patterns
% start_x = 0.10;
% start_y = 0.96;
% inter_y = 0.002;
% box_x = 0.1;
% box_y = 0.02;
% 
% bar_c = cbrewer2('Paired',1);
% 
% for k = 1:size(sort_beh_fire_pattern,1)
%     sel_mean = sort_maxidx_beh_fire_pattern(k);
%     subplot('Position',[start_x,...
%         start_y-k*(inter_y+box_y),...
%     box_x,box_y])
%     bar(sort_beh_fire_pattern{k,2},...
%         sort_beh_fire_pattern{k,1},...
%         'EdgeColor',bar_c,'FaceColor',bar_c)
%     hold on
%     plot([sel_mean,sel_mean],[0,1],'-r')
%     axis([-3,3,0,1])
%     set(gca,'TickDir','out')
%     set(gca,'YTick',[0,1])
%     set(gca,'YTickLabel',[])
%     
%     box off
%     ylabel(sort_class_name{k},'Rotation',0,...
%         'Interpreter','none','Position',[-5,0])
%     if k == size(sort_beh_fire_pattern,1)
%         xlabel({'Fluorescence intensity distribution',...
%             'Z-Score'})
%         set(gca,'XTick',[-3,0,3])
%     end
% end
%% show fire of each neuron to behavior modules
neu_id = unique(cell2mat(neu_beh_cell(:,4)));
beh_id = cell2mat(neu_beh_cell(:,1));
beh_id = unique(beh_id(:,4));
neu_beh_mat = zeros(length(beh_id),length(neu_id));
neu_beh_num_mat = ones(length(beh_id),length(neu_id));

for k = 1:size(neu_beh_cell,1)
    beh_idx = neu_beh_cell{k,1}(1,4);
    neu_idx = neu_beh_cell{k,4};
    mean_neu = mean(neu_beh_cell{k,3},1);
    neu_beh_num_mat(beh_idx,neu_idx) = ...
        neu_beh_num_mat(beh_idx,neu_idx)+1;
    neu_beh_mat(beh_idx,neu_idx) = mean_neu;
end

mean_neu_beh_mat = neu_beh_mat./(neu_beh_num_mat+eps);

%% cluster neuronal activities
D = squareform(pdist(mean_neu_beh_mat','seuclidean'));
tree_neu = linkage(D,'ward');
leafOrder_neu = optimalleaforder(tree_neu,D);
mean_sortneu_beh_mat = mean_neu_beh_mat(:,leafOrder_neu);
tree_neu(:,3) = 1:size(tree_neu,1);
%% cluster behavioral activities
D = squareform(pdist(mean_sortneu_beh_mat,'seuclidean'));
tree_beh = linkage(D,'ward');
leafOrder_beh = optimalleaforder(tree_beh,D);
mean_sortneu_sortbeh_mat = mean_sortneu_beh_mat(leafOrder_beh,:);
sort_class_name = class_name(leafOrder_beh,:);
tree_beh(:,3) = 1:size(tree_beh,1);
%% show neural behavioral clustering
start_x = 0.04;
start_y = 0.05;
box_x = 0.2;
box_y = 0.89;

inter_x = 0.001;
inter_y = inter_x;

neu_box_x = 0.02;
neu_box_y = 0.05;

clim = 0.5;
beh_neu_h = subplot('Position',...
    [start_x,start_y,box_x,box_y]);
imagesc(mean_sortneu_sortbeh_mat,[-1*clim,clim])
cmap = mat2gray(imresize(redbluecmap(11),[256,3]));
colormap(beh_neu_h,cmap)
box on
set(gca,'TickDir','out')
set(gca,'YTick',beh_id,'XTick',[])
set(gca,'YAxisLocation','right')
set(gca,'TickLength',[0,0])
set(gca,'YTickLabel',sort_class_name,...
    'TickLabelInterpreter','none')

subplot('Position',[start_x-neu_box_x-inter_x,...
    start_y,neu_box_x,box_y])
dendrogram(tree_beh,0,'Orientation','left',...
    'Reorder',leafOrder_beh)
axis([0,max(tree_beh(:,3)),0.5,size(mean_sortneu_sortbeh_mat,1)+0.5])
axis off
subplot('Position',[start_x,...
    start_y+box_y+inter_y,box_x,neu_box_y])
dendrogram(tree_neu,100,'Orientation','top',...
    'Reorder',leafOrder_neu)
axis off

temph = subplot('Position',[start_x,...
    start_y-0.01,box_x,0.005]);
imagesc(1:256)
colormap(temph,cmap)
set(gca,'XTick',[1,128,256])
set(gca,"YTick",[])
set(gca,'XTickLabel',[-1*clim,0,clim])
set(gca,'TickDir','out')
xlabel('Fluorescence intensity (Z-Score)')
%% separate strong response neurons
abs_mean_response = mean(abs(mean_neu_beh_mat));
sort_abs_mean_response = sort(abs_mean_response);
max_response = max(sort_abs_mean_response);
[IDX, C] = kmeans(sort_abs_mean_response',3);
max_c = find(diff(IDX)~=0, 1,'last');
thres_neu = max(C);
subplot('Position',...
    [0.45,0.86,0.15,0.12])
plot(sort_abs_mean_response,'-k')
hold on
plot([max_c,max_c],[0,max_response],'-r')
hold off
box off
set(gca,'TickDir','out')
axis([1,length(abs_mean_response),0,max_response])
ylabel('Sorted mean response')
xlabel('Neuron indexs')
%% compare two groups
low_r_neu_idx = find(abs_mean_response<thres_neu);
high_r_neu_idx = find(abs_mean_response>=thres_neu);

low_r_neu_data = abs_mean_response(low_r_neu_idx);
high_r_neu_data = abs_mean_response(high_r_neu_idx);

mean_low_r_neu_data = mean(low_r_neu_data);
mean_high_r_neu_data = mean(high_r_neu_data);

sd_low_r_neu_data = std(low_r_neu_data)/...
    sqrt(length(low_r_neu_data));
sd_high_r_neu_data = std(high_r_neu_data)/...
    sqrt(length(high_r_neu_data));

cmap_low = cbrewer2('Blues',256);
cmap_high = cbrewer2('Reds',256);
clow = cmap_low(128,:);
chigh = cmap_high(128,:);

bar_w = 0.6;
subplot('Position',...
    [0.62,0.86,0.08,0.12])
bar(1,mean_low_r_neu_data,'FaceColor',clow,...
    'BarWidth',bar_w)
hold on
errorbar(1,mean_low_r_neu_data,sd_low_r_neu_data,...
    'Color','k')
hold on
plot(0.3+ones(length(low_r_neu_data),1),...
    low_r_neu_data,'o',...
    'MarkerFaceColor','w',...
    'MarkerEdgeColor','k',...
    'MarkerSize',2)
hold on
bar(2,mean_high_r_neu_data,'FaceColor',chigh,...
    'BarWidth',bar_w)
hold on
errorbar(2,mean_high_r_neu_data,sd_high_r_neu_data,...
    'Color','k')
hold on
plot(0.3+2*ones(length(high_r_neu_data),1),...
    high_r_neu_data,'o',...
    'MarkerFaceColor','w',...
    'MarkerEdgeColor','k',...
    'MarkerSize',2)
hold off
% ylabel('Neural response')
box off
set(gca,'TickDir','out')
set(gca,'XTick',[1,2])
set(gca,'XTickLabel',{'Low response','High response'})
set(gca,'XTickLabelRotation',45)
set(gca,'YTickLabel',[])
axis([0.3,2.7,0,max_response])
%% check response for each mice
% low response
tempname = cellfun(@(x) split(x,'-'),...
    neu_beh_cell(:,2),'UniformOutput',false);
micenamelist = cellfun(@(x) x{3},tempname,...
    'UniformOutput',false);
unique_mice_name = unique(micenamelist);

mice_neu_idx_cell = cell(size(unique_mice_name,1),1);

low_response_mice_mat = zeros(size(unique_mice_name,1),1);
high_response_mice_mat = zeros(size(unique_mice_name,1),1);

for k = 1:size(unique_mice_name,1)
    %%
    tempname = unique_mice_name{k};
    sel_idx = strcmp(tempname,micenamelist);
    sel_data = neu_beh_cell(sel_idx,4);
    mice_neu_idx_cell{k} = sel_data{1};
end

for k = 1:size(low_response_mice_mat,1)
    %%
    tempcount = 0;
    tempneuidx = mice_neu_idx_cell{k};
    for m = 1:length(tempneuidx)
        for n = 1:length(low_r_neu_idx)
            if tempneuidx(m)==low_r_neu_idx(n)
                tempcount = tempcount+1;
            end
        end
    end
    low_response_mice_mat(k) = tempcount;
end

for k = 1:size(high_response_mice_mat,1)
    %%
    tempcount = 0;
    tempneuidx = mice_neu_idx_cell{k};
    for m = 1:length(tempneuidx)
        for n = 1:length(high_r_neu_idx)
            if tempneuidx(m)==high_r_neu_idx(n)
                tempcount = tempcount+1;
            end
        end
    end
    high_response_mice_mat(k) = tempcount;
end
%% show
subplot('Position',...
    [0.75,0.86,0.11,0.12])
bar(1:5,low_response_mice_mat,...
    'FaceColor',clow)
ylabel('Number of neurons')
box off
set(gca,'TickDir','out')
set(gca,'XTickLabel',unique_mice_name)
set(gca,'XTickLabelRotation',45)
title('Low response')
axis([0.3,5.7,0,max(low_response_mice_mat)])

subplot('Position',...
    [0.88,0.86,0.11,0.12])
bar(1:5,high_response_mice_mat,...
    'FaceColor',chigh)
% ylabel('Number of neurons')
box off
set(gca,'TickDir','out')
set(gca,'XTickLabel',unique_mice_name)
set(gca,'XTickLabelRotation',45)
title('High response')
axis([0.3,5.7,0,max(high_response_mice_mat)])
%% show low response dynamics
% use two parameters to quantify the patterns of neural dynamics
% DTW distance for varibility
neu_id = unique(cell2mat(neu_beh_cell(:,4)));
beh_id = cell2mat(neu_beh_cell(:,1));
beh_id = unique(beh_id(:,4));

all_neu_list = cell2mat(neu_beh_cell(:,4));
all_beh_list = cell2mat(...
    cellfun(@(x,y) x(1,4)*ones(length(y),1),...
    neu_beh_cell(:,1),neu_beh_cell(:,4),...
    'UniformOutput',false));

all_neu_data = cell(size(all_neu_list,1),1);
count = 1;
for k = 1:size(neu_beh_cell,1)
    tempdata = neu_beh_cell{k,3};
    for m = 1:size(tempdata,2)
        all_neu_data{count,1} = tempdata(:,m)';
        count = count+1;
    end
end

%% 
lenlist = cell(size(all_dynamic_cell,1),1);
for k = 1:size(lenlist,1)
    tempdata = all_dynamic_cell{k,3};
    templen = cell2mat(cellfun(@(x) size(x,2),tempdata,...
        'UniformOutput',false));
    lenlist{k,1} = templen;
end

median_lenlist = cell2mat(cellfun(@(x) median(x),...
    lenlist,'UniformOutput',false));

numlist = cell2mat(cellfun(@(x) size(x,1),...
    all_dynamic_cell(:,3),'UniformOutput',false));
%%
len_thres = 15;% median length>len_thres

num_thres = 5;% at least 5 frame

neu_id_list = cell2mat(all_dynamic_cell(:,2));

sel_neu_id_list = zeros(size(neu_id_list,1),1);

for k = 1:size(sel_neu_id_list,1)
    tempsel = double(low_r_neu_idx == neu_id_list(k));
    tempsumsel = sum(tempsel);
    if tempsumsel>0
        sel_neu_id_list(k,1) = 1;
    end
end


sel_len_idx = ((median_lenlist>len_thres).*...
    (numlist>num_thres).*sel_neu_id_list)==1;

sel_align_dynamic_cell = align_dynamic_cell(sel_len_idx,:);

sel_align_quantify_dynamic_cell = ...
    align_quantify_dynamic_cell(sel_len_idx,:);

sel_all_dynamic_cell = all_dynamic_cell(sel_len_idx,:);
sel_aqd = [sel_align_quantify_dynamic_cell(:,1),...
    sel_align_quantify_dynamic_cell(:,2)-...
    sel_align_quantify_dynamic_cell(:,3)];

[sort_dtw,sort_dtw_idx] = ...
    sort(sel_aqd(:,1));
pos_dtw = (1:length(sort_dtw))';

sort_dtw_sel_aqd = sel_aqd(sort_dtw_idx,:);
sort_dtw_sel_ad = sel_all_dynamic_cell(sort_dtw_idx,:);

[sort_inde,sort_inde_idx] = ...
    sort(sel_aqd(:,2));
sort_pos_inde = (1:length(sort_inde))';

sort_inde_dtw_aqd = sort_dtw_sel_aqd(sort_inde_idx,:);
sort_inde_dtw_ad = sort_dtw_sel_ad(sort_inde_idx,:);
sort_pos_dtw = pos_dtw(sort_inde_idx,:);

sort_inde_dtw_int_aqd = [sort_pos_dtw,sort_pos_inde];

one_aqd = sort_inde_dtw_int_aqd(:,1)*100000+sort_inde_dtw_int_aqd(:,2);

[sort_one_aqd,sort_one_idx] = sort(one_aqd);

sort_one_inde_dtw_int_aqd = sort_inde_dtw_int_aqd(...
    sort_one_idx,:);

sort_one_inde_dtw_ad = sort_inde_dtw_ad(sort_one_idx,:);

sort_align_dynamic_cell = ...
    sel_align_dynamic_cell(sort_one_idx,:);
% show
row_num = 10;
col_num = 10;

% select data to show
max_len = size(sort_one_inde_dtw_ad,1);
sel_list = round(1:(max_len/(row_num*col_num)):max_len);

sel_sort_one_inde_dtw_ad = sort_one_inde_dtw_ad(...
    sel_list,:);

sort_low_aqd = sort_inde_dtw_aqd(...
    sel_list,:);

sel_sort_align_dynamic_cell = sort_align_dynamic_cell(...
    sel_list,:);

mean_sel_sort_align_dynamic = ...
    cellfun(@(x) mean(x),sel_sort_align_dynamic_cell,...
    'UniformOutput',false);

start_x = 0.45;
start_y = 0.74;
box_x = 0.024;
box_y = 0.03;
inter_x = 0.002;
inter_y = 0.002;

line_c = [0.7*[1,1,1],0.05];

count = 1;
for m = 1:row_num
    for n = 1:col_num
        % find index
        tempdata = sel_sort_align_dynamic_cell{count,1};
        subplot('Position',...
    [start_x+(n-1)*(box_x+inter_x),...
    start_y-(m-1)*(box_y+inter_y),box_x,box_y])
        for p = 1:size(tempdata,1)
            plot(tempdata(p,:),'-',...
                'Color',line_c,'LineWidth',0.25)
            hold on
        end
        plot(mean_sel_sort_align_dynamic{count},'-',...
            'Color',clow,'LineWidth',1)
        hold off
        box on
        axis([0,60,-1,1])
        set(gca,'XTick',[],'YTick',[])
        count = count+1;
    end
end

%% show high response dynamics
%%
len_thres = 15;% median length>len_thres

num_thres = 5;% at least 5 frame

neu_id_list = cell2mat(all_dynamic_cell(:,2));

sel_neu_id_list = zeros(size(neu_id_list,1),1);

for k = 1:size(sel_neu_id_list,1)
    tempsel = double(high_r_neu_idx == neu_id_list(k));
    tempsumsel = sum(tempsel);
    if tempsumsel>0
        sel_neu_id_list(k,1) = 1;
    end
end


sel_len_idx = ((median_lenlist>len_thres).*...
    (numlist>num_thres).*sel_neu_id_list)==1;

sel_align_dynamic_cell = align_dynamic_cell(sel_len_idx,:);

sel_align_quantify_dynamic_cell = ...
    align_quantify_dynamic_cell(sel_len_idx,:);

sel_all_dynamic_cell = all_dynamic_cell(sel_len_idx,:);
sel_aqd = [sel_align_quantify_dynamic_cell(:,1),...
    sel_align_quantify_dynamic_cell(:,2)-...
    sel_align_quantify_dynamic_cell(:,3)];

[sort_dtw,sort_dtw_idx] = ...
    sort(sel_aqd(:,1));
pos_dtw = (1:length(sort_dtw))';

sort_dtw_sel_aqd = sel_aqd(sort_dtw_idx,:);
sort_dtw_sel_ad = sel_all_dynamic_cell(sort_dtw_idx,:);

[sort_inde,sort_inde_idx] = ...
    sort(sel_aqd(:,2));
sort_pos_inde = (1:length(sort_inde))';

sort_inde_dtw_aqd = sort_dtw_sel_aqd(sort_inde_idx,:);
sort_inde_dtw_ad = sort_dtw_sel_ad(sort_inde_idx,:);
sort_pos_dtw = pos_dtw(sort_inde_idx,:);

sort_inde_dtw_int_aqd = [sort_pos_dtw,sort_pos_inde];

one_aqd = sort_inde_dtw_int_aqd(:,1)*100000+sort_inde_dtw_int_aqd(:,2);

[sort_one_aqd,sort_one_idx] = sort(one_aqd);

sort_one_inde_dtw_int_aqd = sort_inde_dtw_int_aqd(...
    sort_one_idx,:);

sort_one_inde_dtw_ad = sort_inde_dtw_ad(sort_one_idx,:);

sort_align_dynamic_cell = ...
    sel_align_dynamic_cell(sort_one_idx,:);

% show
row_num = 10;
col_num = 10;

% select data to show
max_len = size(sort_one_inde_dtw_ad,1);
sel_list = round(1:(max_len/(row_num*col_num)):max_len);

sel_sort_one_inde_dtw_ad = sort_one_inde_dtw_ad(...
    sel_list,:);

sort_high_aqd = sort_inde_dtw_aqd(...
    sel_list,:);

sel_sort_align_dynamic_cell = sort_align_dynamic_cell(...
    sel_list,:);

mean_sel_sort_align_dynamic = ...
    cellfun(@(x) mean(x),sel_sort_align_dynamic_cell,...
    'UniformOutput',false);

start_x = 0.73;
start_y = 0.74;
box_x = 0.024;
box_y = 0.03;
inter_x = 0.002;
inter_y = 0.002;

line_c = [0.7*[1,1,1],0.05];

count = 1;
for m = 1:row_num
    for n = 1:col_num
        % find index
        tempdata = sel_sort_align_dynamic_cell{count,1};
        subplot('Position',...
    [start_x+(n-1)*(box_x+inter_x),...
    start_y-(m-1)*(box_y+inter_y),box_x,box_y])
        for p = 1:size(tempdata,1)
            plot(tempdata(p,:),'-',...
                'Color',line_c,'LineWidth',0.25)
            hold on
        end
        plot(mean_sel_sort_align_dynamic{count},'-',...
            'Color',chigh,'LineWidth',1)
        hold off
        box on
        axis([0,60,-1,1])
        set(gca,'XTick',[],'YTick',[])
        count = count+1;
    end
end























































