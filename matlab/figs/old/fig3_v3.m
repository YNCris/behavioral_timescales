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
load([datapath,'\all_align_dynamic_cell_20230713.mat']);
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
start_y = 0.24;
box_x = 0.2;
box_y = 0.7;

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
    [0.04,0.04,0.06,0.12])
plot(sort_abs_mean_response,'-k')
hold on
plot([max_c,max_c],[0,max_response],'-r')
hold off
box off
set(gca,'TickDir','out')
axis([1,length(abs_mean_response),0,max_response])
ylabel('Sorted mean neural response')
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
    [0.11,0.04,0.06,0.12])
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
set(gca,'XTickLabel',{'Low',...
    'High'})
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
    [0.22,0.04,0.07,0.12])
bar(1:5,low_response_mice_mat,...
    'FaceColor',clow)
ylabel('Number of neurons')
box off
set(gca,'TickDir','out')
set(gca,'XTickLabel',unique_mice_name)
set(gca,'XTickLabelRotation',45)
title('Low')
axis([0.3,5.7,0,max(low_response_mice_mat)])

subplot('Position',...
    [0.31,0.04,0.07,0.12])
bar(1:5,high_response_mice_mat,...
    'FaceColor',chigh)
% ylabel('Number of neurons')
box off
set(gca,'TickDir','out')
set(gca,'XTickLabel',unique_mice_name)
set(gca,'XTickLabelRotation',45)
title('High')
axis([0.3,5.7,0,max(high_response_mice_mat)])
%% quantify response to behavior
neu2beh = mean(abs(mean_sortneu_sortbeh_mat),2);
sel_high_beh_idx = [...
    1,1,1,1,1,1,1,1,1,1,...
    0,0,0,0,0,0,0,0,0,0,...
    0,0,0,0,0,0,0,0,0,0,...
    0,0,0,0,0,0,0,0,0,1,1];
high_neu2beh = neu2beh(sel_high_beh_idx==1,:);
low_neu2beh = neu2beh(sel_high_beh_idx==0,:);

mean_high_neu2beh = mean(high_neu2beh);
mean_low_neu2beh = mean(low_neu2beh);

sd_high_neu2beh = std(high_neu2beh)/sqrt(length(high_neu2beh));
sd_low_neu2beh = std(low_neu2beh)/sqrt(length(low_neu2beh));

subplot('Position',...
    [0.44,0.86,0.06,0.12])
bar(1,mean_low_neu2beh,'FaceColor',clow,...
    'BarWidth',bar_w)
hold on
errorbar(1,mean_low_neu2beh,sd_low_neu2beh,...
    'Color','k')
hold on
plot(0.3+ones(length(low_neu2beh),1),...
    low_neu2beh,'o',...
    'MarkerFaceColor','w',...
    'MarkerEdgeColor','k',...
    'MarkerSize',2)
hold on
bar(2,mean_high_neu2beh,'FaceColor',chigh,...
    'BarWidth',bar_w)
hold on
errorbar(2,mean_high_neu2beh,sd_high_neu2beh,...
    'Color','k')
hold on
plot(0.3+2*ones(length(high_neu2beh),1),...
    high_neu2beh,'o',...
    'MarkerFaceColor','w',...
    'MarkerEdgeColor','k',...
    'MarkerSize',2)
hold off
box off
ylabel('Behavioral response')
set(gca,'TickDir','out')
set(gca,'XTick',[1,2])
set(gca,'XTickLabel',{'Low',...
    'High'})
set(gca,'XTickLabelRotation',45)
% set(gca,'YTickLabel',[])
axis([0.3,2.7,0,max_response])
%% wash and separate data
% wash 100% bad data
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

len_thres = 2;% median length>len_thres

num_thres = 2;% at least 5 frame

sel_len_idx = ((median_lenlist>=len_thres).*...
    (numlist>=num_thres))==1;

wash_all_align_dynamic_cell = all_align_dynamic_cell(...
    sel_len_idx,:);

% separate
high_beh_class = find(sel_high_beh_idx)';
low_beh_class = find(sel_high_beh_idx==0)';
sel_high_list = cell2mat(cellfun(@(x) ...
    sum(double(x==high_beh_class)),...
    wash_all_align_dynamic_cell(:,1),...
    'UniformOutput',false));

var_list = cell2mat(cellfun(@(x) sum(std(x)),...
    wash_all_align_dynamic_cell(:,4),'UniformOutput',false));

high_align_cell = wash_all_align_dynamic_cell(...
    sel_high_list==1,:);
low_align_cell = wash_all_align_dynamic_cell(...
    sel_high_list==0,:);

%% compare parameters of two groups

% peak to peak value
pp_high = cell2mat(cellfun(@(x) ...
    mean(max(x,[],2)-min(x,[],2)),...
    high_align_cell(:,4),'UniformOutput',false));
pp_low = cell2mat(cellfun(@(x) ...
    mean(max(x,[],2)-min(x,[],2)),...
    low_align_cell(:,4),'UniformOutput',false));

mean_pp_high = mean(pp_high);
sd_pp_high = std(pp_high)/sqrt(length(pp_high));
mean_pp_low = mean(pp_low);
sd_pp_low = std(pp_low)/sqrt(length(pp_low));

% high peak number
hpn_high = cell2mat(cellfun(@(x) ...
    length(findpeaks(mean(x))),...
    high_align_cell(:,4),'UniformOutput',false));
hpn_low = cell2mat(cellfun(@(x) ...
    length(findpeaks(mean(x))),...
    low_align_cell(:,4),'UniformOutput',false));

mean_hpn_high = mean(hpn_high);
sd_hpn_high = std(hpn_high)/sqrt(length(hpn_high));
mean_hpn_low = mean(hpn_low);
sd_hpn_low = std(hpn_low)/sqrt(length(hpn_low));

% low peak number
lpn_high = cell2mat(cellfun(@(x) ...
    length(findpeaks(-1*mean(x))),...
    high_align_cell(:,4),'UniformOutput',false));
lpn_low = cell2mat(cellfun(@(x) ...
    length(findpeaks(-1*mean(x))),...
    low_align_cell(:,4),'UniformOutput',false));

mean_lpn_high = mean(lpn_high);
sd_lpn_high = std(lpn_high)/sqrt(length(lpn_high));
mean_lpn_low = mean(lpn_low);
sd_lpn_low = std(lpn_low)/sqrt(length(lpn_low));

% peak to peak time
ppt_high = zeros(size(high_align_cell,1),1);
for k = 1:size(ppt_high,1)
    tempdata = high_align_cell{k,4};
    mean_x = mean(tempdata);
    [hpks,hlocs] = findpeaks(mean_x);
    [lpks,llocs] = findpeaks(-1*mean_x);
    hl_locs = sort([hlocs,llocs]);
    diff_hl_locs = diff(hl_locs);
    ppt_high(k,1) = mean(diff_hl_locs);
end
ppt_high(isnan(ppt_high)) = [];
ppt_high = ppt_high/30;

ppt_low = zeros(size(low_align_cell,1),1);
for k = 1:size(ppt_low,1)
    tempdata = low_align_cell{k,4};
    mean_x = mean(tempdata);
    [hpks,hlocs] = findpeaks(mean_x);
    [lpks,llocs] = findpeaks(-1*mean_x);
    hl_locs = sort([hlocs,llocs]);
    diff_hl_locs = diff(hl_locs);
    ppt_low(k,1) = mean(diff_hl_locs);
end
ppt_low(isnan(ppt_low)) = [];
ppt_low = ppt_low/30;

mean_ppt_high = mean(ppt_high);
sd_ppt_high = std(ppt_high)/sqrt(length(ppt_high));
mean_ppt_low = mean(ppt_low);
sd_ppt_low = std(ppt_low)/sqrt(length(ppt_low));

% variance
var_list_high = var_list(sel_high_list==1,:);
var_list_low = var_list(sel_high_list==0,:);

mean_var_list_high = mean(var_list_high);
sd_var_list_high = std(var_list_high)/sqrt(length(var_list_high));
mean_var_list_low = mean(var_list_low);
sd_var_list_low = std(var_list_low)/sqrt(length(var_list_low));

% max value

% min value

% max peak value

% min peak value

%% show
f_alpha = 0.3;
subplot('Position',...
    [0.57,0.86,0.1,0.12])
histogram(pp_low,128,'FaceColor',clow,...
    'EdgeColor','none','FaceAlpha',f_alpha,...
    'Normalization','pdf')
hold on
histogram(pp_high,128,'FaceColor',chigh,...
    'EdgeColor','none','FaceAlpha',f_alpha,...
    'Normalization','pdf')
hold off
xlabel('Peak to peak value')
ylabel('Normalized pdf')
set(gca,'TickDir','out')
axis([0,2,0,1.2])
box off

subplot('Position',...
    [0.7,0.86,0.1,0.12])
histogram(var_list_high,128,'FaceColor',clow,...
    'EdgeColor','none','FaceAlpha',f_alpha,...
    'Normalization','pdf')
hold on
histogram(var_list_low,128,'FaceColor',chigh,...
    'EdgeColor','none','FaceAlpha',f_alpha,...
    'Normalization','pdf')
hold off
xlabel('Variance')
set(gca,'TickDir','out')
axis([0,100,0,0.04])
box off



























