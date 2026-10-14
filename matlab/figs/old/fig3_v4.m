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
load([datapath,'\neu_beh_cell_20230721.mat']);
beh_class = cell2mat(neu_beh_cell(:,1));
beh_class = beh_class(:,4);
unique_beh_class = unique(beh_class);
class_name = importdata(...
    [datapath,'\cut_beh_20230301_classes.xlsx']);
load([datapath,'\all_align_dynamic_cell_20230721.mat']);
% wash data
len_thres = 15;
size_list = cell2mat(cellfun(@(x) size(x,1),...
    all_align_dynamic_cell(:,5),'UniformOutput',false));
sel_align_dynamic_cell = all_align_dynamic_cell(...
    size_list>=len_thres,:);

cmap_low = cbrewer2('Blues',256);
cmap_high = cbrewer2('Reds',256);
clow = cmap_low(128,:);
chigh = cmap_high(128,:);

clow_de = cmap_low(96,:);
clow_in = cmap_low(160,:);
%% plot canvas
hall = figure(1);
set(hall,'Position',[900,100,800,800])
set(hall,'color','white');
%% calculate distribution of variance
var_list = cell2mat(cellfun(@(x) mean(std(x)),...
    sel_align_dynamic_cell(:,6),'UniformOutput',false));
%% tempshow
figure
for k = 1:30000
    imagesc(sel_align_dynamic_cell{k,6},[-1,3])
    colormap('jet')
    colorbar
    title(k)
    pause
end
%% separate low variance and high variance
var_thres = median(var_list)/2;
%% show
subplot('Position',...
    [0.05,0.905,0.1,0.08])
histogram(var_list,256,'EdgeColor','none')
hold on
plot([var_thres,var_thres],[0,1500],'-r')
hold off
box off
set(gca,'TickDir','out')
set(gca,'YTick',[0,1500])
axis([0,2,0,1500])
xlabel('Variance')
ylabel('Counts')
%% separate low var group and high var group
low_var_idx = find(var_list<var_thres);
high_var_idx = find(var_list>=var_thres);
%% show variance demo
low_var_dynamic = sel_align_dynamic_cell(low_var_idx,:);
low_var = var_list(low_var_idx,:);
high_var_dynamic = sel_align_dynamic_cell(high_var_idx,:);
high_var = var_list(high_var_idx,:);


show_bias = 100;
row_num = 5;

[sort_low_var,sort_low_var_idx] = sort(low_var);
sort_low_var_dynamic = low_var_dynamic(...
    sort_low_var_idx,:);

sort_sel_low_var_dynamic = sort_low_var_dynamic(...
    show_bias+(1:row_num),:);

[sort_high_var,sort_high_var_idx] = sort(high_var,'descend');
sort_high_var_dynamic = high_var_dynamic(...
    sort_high_var_idx,:);

sort_sel_high_var_dynamic = sort_high_var_dynamic(...
    show_bias+(1:row_num),:);


mean_low_var_dynamic = cellfun(@(x) mean(x),...
    sort_sel_low_var_dynamic(:,6),'UniformOutput',false);
sd_low_var_dynamic = cellfun(@(x) std(x)/sqrt(size(x,1)),...
    sort_sel_low_var_dynamic(:,6),'UniformOutput',false);

mean_high_var_dynamic = cellfun(@(x) mean(x),...
    sort_sel_high_var_dynamic(:,6),'UniformOutput',false);
sd_high_var_dynamic = cellfun(@(x) std(x)/sqrt(size(x,1)),...
    sort_sel_high_var_dynamic(:,6),'UniformOutput',false);

start_x = 0.05;
start_y = 0.85;
box_x = 0.05;
box_y = 0.05;
inter_x = 0.01;
inter_y = 0.005;

line_c = [0.7*[1,1,1],0.3];

shr_par = 0.8;

for k = 1:row_num
    templowdata = sort_sel_low_var_dynamic{k,6};
    temphighdata = sort_sel_high_var_dynamic{k,6};

    subplot('Position',...
    [start_x,start_y-k*(box_y+inter_y),box_x,box_y])
    for p = 1:size(templowdata,1)
        plot(templowdata(p,:),'-',...
            'Color',line_c,'LineWidth',0.25)
        hold on
    end
    plot(mean_low_var_dynamic{k},'-',...
            'Color',clow,'LineWidth',1)
    hold off
    
%     axis([0,60,min(templowdata(:))*shr_par,shr_par*max(templowdata(:))])
    axis([0,60,-1,1])
    set(gca,'Ytick',[])
    set(gca,'TickDir','out')
    box off
    if k < row_num
        set(gca,'XTick',[])
    else
        set(gca,'XTick',[0,60])
        set(gca,'XTickLabel',[0,2])
        xlabel('Seconds')
    end
    
    if k==round(row_num/2)
        ylabel('Fluorescence intensity (Z-Score)')
    end
    
    if k==1
        title('Low')
    end

    subplot('Position',...
    [start_x+inter_x+box_x,...
    start_y-k*(box_y+inter_y),box_x,box_y])
    for p = 1:size(temphighdata,1)
        plot(temphighdata(p,:),'-',...
            'Color',line_c,'LineWidth',0.25)
        hold on
    end
    plot(mean_high_var_dynamic{k},'-',...
            'Color',chigh,'LineWidth',1)
    hold off
    
%     axis([0,60,shr_par*min(temphighdata(:)),shr_par*max(temphighdata(:))])
    axis([0,60,-2,10])
    set(gca,'Ytick',[])
    set(gca,'TickDir','out')
    box off
    if k < row_num
        set(gca,'XTick',[])
    else
        set(gca,'XTick',[0,60])
        set(gca,'XTickLabel',[0,2])
        xlabel('Seconds')
    end

    if k==1
        title('High')
    end
end

%% separate low variance into:
% 1. increase
% 2. decrease
% 3. not change
% using linear regression to fit the slope

linear_fit_list = cell2mat(...
    cellfun(@(x) polyfit(1:60,mean(x),1),...
    sort_low_var_dynamic(:,5),'UniformOutput',false));

k_list = linear_fit_list(:,1);

mean_k = mean(k_list);
std_k = std(k_list);

de_thres = mean_k-std_k;
in_thres = mean_k+std_k;
%% show distribution
subplot('Position',...
    [0.18,0.905,0.16,0.08])
histogram(k_list,128,'EdgeColor','none')
hold on
plot([de_thres,de_thres],[0,600],'-r')
hold on
plot([in_thres,in_thres],[0,600],'-r')
hold off
box off
set(gca,'TickDir','out')
axis([-0.01,0.01,0,600])
% ylabel('Counts')
xlabel('Linear fitting slope')
%% separate 3 neural classes
de_idx = k_list<de_thres;
in_idx = k_list>in_thres;
con_idx = de_idx==in_idx;

de_low_var_dynamic = sort_low_var_dynamic(de_idx,:);
in_low_var_dynamic = sort_low_var_dynamic(in_idx,:);
con_low_var_dynamic = sort_low_var_dynamic(con_idx,:);

de_k_list = k_list(de_idx,:);
in_k_list = k_list(in_idx,:);
con_k_list = k_list(con_idx,:);

show_bias = 12;
row_num = 5;

[sort_de,sort_de_idx] = sort(de_k_list);
sort_de_low_var_dynamic = de_low_var_dynamic(...
    sort_de_idx,:);

[sort_in,sort_in_idx] = sort(in_k_list,'descend');
sort_in_low_var_dynamic = in_low_var_dynamic(...
    sort_in_idx,:);

sort_con_low_var_dynamic = con_low_var_dynamic;


sel_sort_de_low_var_dynamic = sort_de_low_var_dynamic(...
    show_bias+(1:row_num),:);
sel_sort_in_low_var_dynamic = sort_in_low_var_dynamic(...
    show_bias+(1:row_num),:);
sel_sort_con_low_var_dynamic = sort_con_low_var_dynamic(...
    show_bias+(1:row_num),:);


mean_de_low_var_dynamic = cellfun(@(x) mean(x),...
    sel_sort_de_low_var_dynamic(:,5),'UniformOutput',false);
sd_de_low_var_dynamic = cellfun(@(x) std(x)/sqrt(size(x,1)),...
    sel_sort_de_low_var_dynamic(:,5),'UniformOutput',false);

mean_in_low_var_dynamic = cellfun(@(x) mean(x),...
    sel_sort_in_low_var_dynamic(:,5),'UniformOutput',false);
sd_in_low_var_dynamic = cellfun(@(x) std(x)/sqrt(size(x,1)),...
    sel_sort_in_low_var_dynamic(:,5),'UniformOutput',false);

mean_con_low_var_dynamic = cellfun(@(x) mean(x),...
    sel_sort_con_low_var_dynamic(:,5),'UniformOutput',false);
sd_con_low_var_dynamic = cellfun(@(x) std(x)/sqrt(size(x,1)),...
    sel_sort_con_low_var_dynamic(:,5),'UniformOutput',false);


% show
start_x = 0.18;
start_y = 0.85;
box_x = 0.05;
box_y = 0.05;
inter_x = 0.01;
inter_y = 0.005;

line_c = [0.7*[1,1,1],0.5];

for k = 1:row_num
    tempde = sel_sort_de_low_var_dynamic{k,5};
    tempin = sel_sort_in_low_var_dynamic{k,5};
    tempcon = sel_sort_con_low_var_dynamic{k,5};

    subplot('Position',...
    [start_x,start_y-k*(box_y+inter_y),box_x,box_y])
    for p = 1:size(tempde,1)
        plot(tempde(p,:),'-',...
            'Color',line_c,'LineWidth',0.25)
        hold on
    end
    plot(mean_de_low_var_dynamic{k},'-',...
            'Color',clow_de,'LineWidth',1)
    hold off
    
    axis([0,60,shr_par*min(tempde(:)),shr_par*max(tempde(:))])
    set(gca,'Ytick',[])
    set(gca,'TickDir','out')
    box off
    if k < row_num
        set(gca,'XTick',[])
    else
        set(gca,'XTick',[0,60])
        set(gca,'XTickLabel',[0,2])
        xlabel('Seconds')
    end
    
    if k==1
        title('Decrease')
    end

    subplot('Position',...
    [start_x+inter_x+box_x,start_y-k*(box_y+inter_y),box_x,box_y])
    for p = 1:size(tempcon,1)
        plot(tempcon(p,:),'-',...
            'Color',line_c,'LineWidth',0.25)
        hold on
    end
    plot(mean_con_low_var_dynamic{k},'-',...
            'Color',clow,'LineWidth',1)
    hold off
    
    axis([0,60,shr_par*min(tempcon(:)),shr_par*max(tempcon(:))])
    set(gca,'Ytick',[])
    set(gca,'TickDir','out')
    box off
    if k < row_num
        set(gca,'XTick',[])
    else
        set(gca,'XTick',[0,60])
        set(gca,'XTickLabel',[0,2])
        xlabel('Seconds')
    end

    if k==1
        title('Flat')
    end

    subplot('Position',...
    [start_x+2*(inter_x+box_x),start_y-k*(box_y+inter_y),box_x,box_y])
    for p = 1:size(tempin,1)
        plot(tempin(p,:),'-',...
            'Color',line_c,'LineWidth',0.25)
        hold on
    end
    plot(mean_in_low_var_dynamic{k},'-',...
            'Color',clow_in,'LineWidth',1)
    hold off
    
    axis([0,60,shr_par*min(tempin(:)),shr_par*max(tempin(:))])
    set(gca,'Ytick',[])
    set(gca,'TickDir','out')
    box off
    if k < row_num
        set(gca,'XTick',[])
    else
        set(gca,'XTick',[0,60])
        set(gca,'XTickLabel',[0,2])
        xlabel('Seconds')
    end

    if k==1
        title('Increase')
    end

end

%% response classification of neurons
high_var_label = cell(size(high_var_dynamic,1),1);
de_low_var_label = cell(size(de_low_var_dynamic,1),1);
in_low_var_label = cell(size(in_low_var_dynamic,1),1);
con_low_var_label = cell(size(con_low_var_dynamic,1),1);

for k = 1:size(high_var_label,1)
    high_var_label{k} = 'High variance';
end
for k = 1:size(de_low_var_label,1)
    de_low_var_label{k} = 'Decrease';
end
for k = 1:size(in_low_var_label,1)
    in_low_var_label{k} = 'Increase';
end
for k = 1:size(con_low_var_label,1)
    con_low_var_label{k} = 'Flat';
end

label_dynamic_cell = [...
    [high_var_dynamic,high_var_label];...
    [de_low_var_dynamic,de_low_var_label];...
    [in_low_var_dynamic,in_low_var_label];...
    [con_low_var_dynamic,con_low_var_label]];

unique_data_name = unique(neu_beh_cell(:,2));

data_neu_idx_cell = cell(size(unique_data_name,1),1);

for k = 1:size(data_neu_idx_cell,1)
    tempname = unique_data_name{k,1};
    selidx = strcmp(neu_beh_cell(:,2),tempname);
    seldata = neu_beh_cell(selidx,4);
    data_neu_idx_cell{k} = seldata{1};
end

spl_name = cellfun(@(x) split(x,'-'),unique_data_name,...
    'UniformOutput',false);
mice_name = cellfun(@(x) x{3},spl_name,...
    'UniformOutput',false);
unique_mice_name = unique(mice_name);

mice_neu_idx_cell = cell(size(unique_mice_name,1),1);

for k = 1:size(mice_neu_idx_cell,1)
    tempname = unique_mice_name{k,1};
    selidx = strcmp(mice_name,tempname);
    seldata = data_neu_idx_cell(selidx,1);
    mice_neu_idx_cell{k} = seldata{1};
end

mice_name_neuidx_cell = [];

for k = 1:size(unique_mice_name,1)
    tempname = unique_mice_name{k};
    tempidx = mice_neu_idx_cell{k};
    for m = 1:size(tempidx,1)
        mice_name_neuidx_cell = [...
            mice_name_neuidx_cell;...
            {tempname,tempidx(m)}];
    end
end

mice_name_label_cell = cell(size(label_dynamic_cell,1),1);
neu_idx_list = cell2mat(mice_name_neuidx_cell(:,2));
for k = 1:size(label_dynamic_cell,1)
    tempidx = label_dynamic_cell{k,2};
    selidx = find(neu_idx_list==tempidx);
    mice_name_label_cell{k} = mice_name_neuidx_cell{selidx};
end

label_dynamic_cell(:,7) = mice_name_label_cell;

%% statistic
unique_label_name = {...
    'Increase';...
    'Decrease';...
    'Flat';...
    'High variance'};

mice_label_mat = zeros(size(unique_mice_name,1),...
    size(unique_label_name,1));

for k = 1:size(label_dynamic_cell,1)
    tempname = label_dynamic_cell{k,7};
    templabel = label_dynamic_cell{k,6};
    nameidx = find(strcmp(tempname,unique_mice_name));
    labelidx = find(strcmp(templabel,unique_label_name));
    mice_label_mat(nameidx,labelidx) = ...
        mice_label_mat(nameidx,labelidx)+1;
end

norm_mice_label_mat = mice_label_mat./...
    (sum(mice_label_mat,2)*ones(1,size(mice_label_mat,2)));
%% show pie
tbl = tabulate(label_dynamic_cell(:,6));
temph = subplot('Position',[0.05,0.32,0.11,0.2]);
clr_list = [chigh;clow_de;clow_in;clow];
pie(cell2mat(tbl(:,3)),'%.2f%%')
colormap(temph,clr_list)
alpha(temph,0.7)
legend(tbl(:,1),'Location','NorthOutside','Box','off');

%% show statistic
mean_norm_mice_label_mat = mean(norm_mice_label_mat);
sd_norm_mice_label_mat = std(norm_mice_label_mat)./sqrt(5);
subplot('Position',[0.21,0.37,0.08,0.12]);
bar_c_list = [clow_in;clow_de;clow;chigh];
bar_w = 0.8;
for k = 1:size(mean_norm_mice_label_mat,2)
    bar(k,mean_norm_mice_label_mat(k),...
        'FaceColor',bar_c_list(k,:),'FaceAlpha',0.7,...
        'BarWidth',bar_w)
    hold on
end
errorbar(1:4,mean_norm_mice_label_mat,...
    sd_norm_mice_label_mat,'LineStyle','none','Color','k')
hold on
bias = 0.4;
for k = 1:size(norm_mice_label_mat,2)
    plot(bias+k*ones(5,1),norm_mice_label_mat(:,k),'o',...
        'MarkerFaceColor','w','MarkerEdgeColor','k',...
        'MarkerSize',2)
    hold on
end
hold off
box off
set(gca,'TickDir','out')
set(gca,'XTick',1:4)
axis([0.3,4.7,0,1])
set(gca,'XTickLabel',unique_label_name)
ylabel('Proportion')
set(gca,'FontSize',6)


%% show behavior vs increase, decrease, flat and high var
in_cell = label_dynamic_cell(...
    strcmp(label_dynamic_cell(:,6),'Increase'),:);

in_mat = zeros(size(unique_mice_name,1),...
    size(class_name,1));

for k = 1:size(in_cell,1)
    tempmice = in_cell{k,7};
    tempclass = in_cell{k,1};
    miceidx = find(strcmp(tempmice,unique_mice_name));
    labelidx = find(tempclass==unique_beh_class);
    in_mat(miceidx,labelidx) = ...
        in_mat(miceidx,labelidx)+1;
end

norm_in_mat = in_mat./...
    (sum(in_mat,2)*ones(1,size(in_mat,2)));

mean_norm_in_mat = mean(norm_in_mat);
sd_norm_in_mat = std(norm_in_mat)./sqrt(5);

de_cell = label_dynamic_cell(...
    strcmp(label_dynamic_cell(:,6),'Decrease'),:);

de_mat = zeros(size(unique_mice_name,1),...
    size(class_name,1));

for k = 1:size(de_cell,1)
    tempmice = de_cell{k,7};
    tempclass = de_cell{k,1};
    miceidx = find(strcmp(tempmice,unique_mice_name));
    labelidx = find(tempclass==unique_beh_class);
    de_mat(miceidx,labelidx) = ...
        de_mat(miceidx,labelidx)+1;
end

norm_de_mat = de_mat./...
    (sum(de_mat,2)*ones(1,size(de_mat,2)));

mean_norm_de_mat = mean(norm_de_mat);
sd_norm_de_mat = std(norm_de_mat)./sqrt(5);

flat_cell = label_dynamic_cell(...
    strcmp(label_dynamic_cell(:,6),'Flat'),:);

flat_mat = zeros(size(unique_mice_name,1),...
    size(class_name,1));

for k = 1:size(flat_cell,1)
    tempmice = flat_cell{k,7};
    tempclass = flat_cell{k,1};
    miceidx = find(strcmp(tempmice,unique_mice_name));
    labelidx = find(tempclass==unique_beh_class);
    flat_mat(miceidx,labelidx) = ...
        flat_mat(miceidx,labelidx)+1;
end

norm_flat_mat = flat_mat./...
    (sum(flat_mat,2)*ones(1,size(flat_mat,2)));

mean_norm_flat_mat = mean(norm_flat_mat);
sd_norm_flat_mat = std(norm_flat_mat)./sqrt(5);


highvar_cell = label_dynamic_cell(...
    strcmp(label_dynamic_cell(:,6),'High variance'),:);

highvar_mat = zeros(size(unique_mice_name,1),...
    size(class_name,1));

for k = 1:size(highvar_cell,1)
    tempmice = highvar_cell{k,7};
    tempclass = highvar_cell{k,1};
    miceidx = find(strcmp(tempmice,unique_mice_name));
    labelidx = find(tempclass==unique_beh_class);
    highvar_mat(miceidx,labelidx) = ...
        highvar_mat(miceidx,labelidx)+1;
end

norm_highvar_mat = highvar_mat./...
    (sum(highvar_mat,2)*ones(1,size(highvar_mat,2)));

mean_norm_highvar_mat = mean(norm_highvar_mat);
sd_norm_highvar_mat = std(norm_highvar_mat)./sqrt(5);

%% show
start_x = 0.42;
start_y = 0.89;
box_x = 0.57;
box_y = 0.09;
inter_y = 0.014;
bar_c = 0.9*ones(1,3);
cap_size = 2;
bias = 0.4;
bar_w = 0.6;
% increase
subplot('Position',[start_x,start_y,box_x,box_y]);
bar(1:41,mean_norm_in_mat,'FaceColor',clow_in,...
    'BarWidth',bar_w,'FaceAlpha',0.7)
hold on
errorbar(1:41,mean_norm_in_mat,...
    sd_norm_in_mat,'LineStyle','none','Color','k',...
    'CapSize',cap_size)
hold on
for k = 1:size(norm_in_mat,2)
    plot(bias+k*ones(5,1),norm_in_mat(:,k),'o',...
        'MarkerFaceColor','w','MarkerEdgeColor','k',...
        'MarkerSize',1)
    hold on
end
hold off
axis([0.3,41.7,0,0.2])
box off
set(gca,'TickDir','out')
set(gca,'XTick',1:41)
set(gca,'XTickLabel',[])
ylabel({'Proportion','(Increase neuron)'})
set(gca,'FontSize',6)

% decrease
subplot('Position',[start_x,start_y-inter_y-box_y,...
    box_x,box_y]);
bar(1:41,mean_norm_de_mat,'FaceColor',clow_de,...
    'BarWidth',bar_w,'FaceAlpha',0.7)
hold on
errorbar(1:41,mean_norm_de_mat,...
    sd_norm_de_mat,'LineStyle','none','Color','k',...
    'CapSize',cap_size)
hold on
for k = 1:size(norm_de_mat,2)
    plot(bias+k*ones(5,1),norm_de_mat(:,k),'o',...
        'MarkerFaceColor','w','MarkerEdgeColor','k',...
        'MarkerSize',1)
    hold on
end
hold off
axis([0.3,41.7,0,0.2])
box off
set(gca,'TickDir','out')
set(gca,'XTick',1:41)
set(gca,'XTickLabel',[])
ylabel({'Proportion','(Decrease neuron)'})
set(gca,'FontSize',6)


% flat
subplot('Position',[start_x,start_y-2*(inter_y+box_y),...
    box_x,box_y]);
bar(1:41,mean_norm_flat_mat,'FaceColor',clow,...
    'BarWidth',bar_w,'FaceAlpha',0.7)
hold on
errorbar(1:41,mean_norm_flat_mat,...
    sd_norm_flat_mat,'LineStyle','none','Color','k',...
    'CapSize',cap_size)
hold on
for k = 1:size(norm_flat_mat,2)
    plot(bias+k*ones(5,1),norm_flat_mat(:,k),'o',...
        'MarkerFaceColor','w','MarkerEdgeColor','k',...
        'MarkerSize',1)
    hold on
end
hold off
axis([0.3,41.7,0,0.2])
box off
set(gca,'TickDir','out')
set(gca,'XTick',1:41)
set(gca,'XTickLabel',[])
ylabel({'Proportion','(Flat neuron)'})
set(gca,'FontSize',6)


% high variance
subplot('Position',[start_x,start_y-3*(inter_y+box_y),...
    box_x,box_y]);
bar(1:41,mean_norm_highvar_mat,'FaceColor',chigh,...
    'BarWidth',bar_w,'FaceAlpha',0.7)
hold on
errorbar(1:41,mean_norm_highvar_mat,...
    sd_norm_highvar_mat,'LineStyle','none','Color','k',...
    'CapSize',cap_size)
hold on
for k = 1:size(norm_highvar_mat,2)
    plot(bias+k*ones(5,1),norm_highvar_mat(:,k),'o',...
        'MarkerFaceColor','w','MarkerEdgeColor','k',...
        'MarkerSize',1)
    hold on
end
hold off
axis([0.3,41.7,0,0.1])
box off
set(gca,'TickDir','out')
set(gca,'XTick',1:41)
set(gca,'XTickLabel',class_name)
set(gca,'XTickLabelRotation',45,'TickLabelInterpreter','none')
set(gca,'FontSize',6)
ylabel({'Proportion','(High variance neuron)'})
%% create type cell
neu_idx_list = cell2mat(label_dynamic_cell(:,2));
unique_neu_idx_list = unique(neu_idx_list);
neu_type_cell = cell(size(unique_neu_idx_list,1),3);

for k = 1:size(neu_type_cell,1)
    tempneuidx = unique_neu_idx_list(k,1);
    neu_type_cell{k,1} = tempneuidx;
    selidx = tempneuidx==neu_idx_list;
    sel_type = label_dynamic_cell(selidx,6);
    sel_mice = label_dynamic_cell(selidx,7);
    neu_type_cell{k,2} = sort(unique(sel_type))';
    neu_type_cell{k,3} = sel_mice{1};
end

comb_type_cell = {};
for k = 1:4
    tempcomb = nchoosek(unique_label_name,k);
    for m = 1:size(tempcomb,1)
        comb_type_cell = [comb_type_cell;...
            {sort(tempcomb(m,:))}];
    end
end

comb_num = cell2mat(cellfun(@(x) size(x,1),comb_type_cell,...
    'UniformOutput',false));
%% create type_mat
type_mat = zeros(size(unique_mice_name,1),...
    size(comb_type_cell,1));

for k = 1:size(neu_type_cell,1)
    temptype = neu_type_cell{k,2};
    tempcattype = strcat(temptype{:});
    tempname = neu_type_cell{k,3};
    type_size = size(temptype,1);
    %% compare type
    sel_comb = comb_type_cell(type_size==comb_num,:);
    for m = 1:size(sel_comb,1)
        tempcomb = sel_comb{m};
        tempcatcomb = strcat(tempcomb{:});
        tempcomp = strcmp(tempcattype,tempcatcomb);
        if tempcomp == 1
            combidx = m;
            break
        end
    end
    %% 
    miceidx = find(strcmp(tempname,unique_mice_name));
    type_mat(miceidx,combidx) = ...
        type_mat(miceidx,combidx)+1;
end

norm_type_mat = type_mat./...
    (sum(type_mat,2)*ones(1,size(type_mat,2)));

mean_norm_type_mat = mean(norm_type_mat);
sd_norm_type_mat = std(norm_type_mat)./sqrt(5);

[sort_mean_norm_type_mat,sortidx] = ...
    sort(mean_norm_type_mat,'descend');
sort_sd_norm_type_mat = sd_norm_type_mat(sortidx);
sort_norm_type_mat = norm_type_mat(:,sortidx);
%% show
show_comb_type_cell = comb_type_cell;
for k = 1:size(show_comb_type_cell,1)
    temptype = comb_type_cell{k};
    showtype = [];
    if size(temptype,2)>=2
        for m = 1:size(temptype,2)
            showtype = [showtype,temptype{m},'\newline '];
        end
        showtype((end-8):end) = [];
    else
        showtype = temptype;
    end
    show_comb_type_cell{k} = char(showtype);
end

sort_show_comb_type_cell = show_comb_type_cell(sortidx);

bar_c = 0.8*ones(1,3);
subplot('Position',[0.31,0.37,0.68,0.12]);
bar(1:length(sort_mean_norm_type_mat),...
    sort_mean_norm_type_mat,'FaceColor',bar_c)
hold on
errorbar(1:length(sort_mean_norm_type_mat),...
    sort_mean_norm_type_mat,sort_sd_norm_type_mat,...
    'LineStyle','none','Color','k')
hold on
for k = 1:size(sort_norm_type_mat,2)
    plot(bias+k*ones(5,1),sort_norm_type_mat(:,k),'o',...
        'MarkerFaceColor','w','MarkerEdgeColor','k',...
        'MarkerSize',2)
    hold on
end
hold off
box off
set(gca,'TickDir','out')
axis([0.3,15.7,0,1])
xticklabels(sort_show_comb_type_cell)
set(gca,'XTickLabelRotation',45)
set(gca,'YTickLabel',[])
set(gca,'FontSize',6)
%% create neuron-behavior-type-cell
neu_beh_type_cell = cell(...
    size(unique_neu_idx_list,1),...
    size(unique_beh_class,1));

for m = 1:size(neu_beh_type_cell,1)
    for n = 1:size(neu_beh_type_cell,2)
        neu_beh_type_cell{m,n} = 'Void';
    end
end

for k = 1:size(label_dynamic_cell,1)
    tempneu = label_dynamic_cell{k,2};
    tempbeh = label_dynamic_cell{k,1};
    temptype = label_dynamic_cell{k,6};
    neu_beh_type_cell{tempneu,tempbeh} = temptype;
end

%% statistic
tab_neu_beh_type = zeros(size(neu_beh_type_cell,1),...
    size(unique_label_name,1));

for k = 1:size(tab_neu_beh_type,1)
    temptab = tabulate(neu_beh_type_cell(k,:));
    for m = 1:size(tab_neu_beh_type,2)
        reftype = unique_label_name{m};
        for n = 1:size(temptab,1)
            temptype = temptab{n,1};
            if strcmp(reftype,temptype)
                tab_neu_beh_type(k,m) = temptab{n,2};
            end
        end
    end
end

in_neu_list = find(tab_neu_beh_type(:,1)==1&tab_neu_beh_type(:,2)==0);
de_neu_list = find(tab_neu_beh_type(:,1)==0&tab_neu_beh_type(:,2)==1);

in_neu_beh_list = zeros(size(in_neu_list,1),2);
de_neu_beh_list = zeros(size(de_neu_list,1),2);
in_neu_beh_list(:,1) = in_neu_list;
de_neu_beh_list(:,1) = de_neu_list;

for k = 1:size(in_neu_beh_list,1)
    sel_type = neu_beh_type_cell(in_neu_beh_list(k,1),:);
    in_neu_beh_list(k,2) = ...
        find(strcmp(sel_type,'Increase'));
end

for k = 1:size(de_neu_beh_list,1)
    sel_type = neu_beh_type_cell(de_neu_beh_list(k,1),:);
    de_neu_beh_list(k,2) = ...
        find(strcmp(sel_type,'Decrease'));
end
%% show specific neuron

% pie for percentage

% bar to compare the behavior representated by specific neuron

% heatmap to demonstrate the neural patterns for each behavior


































