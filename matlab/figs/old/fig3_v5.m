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
statpath = [rootpath,'\tpm_data_cut_dff_stat'];
%% load data
load([datapath,'\neu_beh_cell_20230721.mat']);
beh_class = cell2mat(neu_beh_cell(:,1));
beh_class = beh_class(:,4);
unique_beh_class = unique(beh_class);
class_name = importdata(...
    [datapath,'\cut_beh_20230301_classes.xlsx']);
load([datapath,'\all_align_dynamic_cell_20230721.mat']);
load([datapath,'\all_name_cell_20230721.mat']);
% wash data
len_thres = 15;
size_list = cell2mat(cellfun(@(x) size(x,1),...
    all_align_dynamic_cell(:,5),'UniformOutput',false));
void_list = cell2mat(cellfun(@(x) size(cell2mat(x),1),...
    all_align_dynamic_cell(:,4),'UniformOutput',false));
sel_align_dynamic_cell = all_align_dynamic_cell(...
    (size_list>=len_thres)&(void_list~=0),:);

sel_all_name_cell = all_name_cell(...
    (size_list>=len_thres)&(void_list~=0),:);

atlas_cmap = cbrewer2('Spectral',length(class_name));

stat_name_list = {...
    'fix-seg2-1tpm-2wt-20220226-1.mat';...
    'fix-seg3-2tpm-3wt-20220226-1.mat';...
    'fix-seg2-3tpm-3wt-20220227-1.mat';...
    'fix-seg6-4tpm-5wt-20220227-1.mat';...
    'free-seg4-5tpm-4wt-20220227-1.mat'};

stat_cell = [];
for k = 1:size(stat_name_list,1)
    tempname = stat_name_list{k};
    tempdata = load([statpath,'\',tempname]);
    stat_cell = [stat_cell;tempdata.stat];
end
%% wash baseline
pre_time = 2;
post_time = 8;
beh_time_win = 2;
fs = 30;
pre_frame = pre_time*fs;
post_frame = post_time*fs;
beh_frame_win = beh_time_win*fs;
temp_baseline_cell = [sel_align_dynamic_cell(:,1:2),...
    cellfun(@(x) cell2mat(x),sel_align_dynamic_cell(:,4),...
    'UniformOutput',false)];
baseline_cell = temp_baseline_cell;
baseline_cell(:,3) = cellfun(@(x) ...
    x(:,(round(size(x,2)/2)-pre_frame):...
    (round(size(x,2)/2)+post_frame-1)),temp_baseline_cell(:,3),...
    'UniformOutput',false);

%%
baseline_thres = 1;
wash_baseline_cell = baseline_cell;
wash_baseline_cell(:,3) = cellfun(@(x) x(...
    max(x(:,1:pre_frame),[],2)<baseline_thres,:),...
    baseline_cell(:,3),'UniformOutput',false);
wash_baseline_cell(:,3) = cellfun(@(x) ...
    x-mean(x(:,1:60),2)*ones(1,300),...
    wash_baseline_cell(:,3),'UniformOutput',false);

wash_name_cell = cellfun(@(x,y) y(...
    max(x(:,1:pre_frame),[],2)<baseline_thres,:),...
    baseline_cell(:,3),sel_all_name_cell,'UniformOutput',false);

active_thres = 2;
active_time_win = 2;
fs = 30;
active_frame_win = active_time_win*fs;

wb_active_cell = wash_baseline_cell;
wb_active_cell(:,3) = cellfun(@(x) x(...
    max(x(:,1:(pre_frame+active_frame_win)),[],2)>...
    active_thres,:),wash_baseline_cell(:,3),...
    'UniformOutput',false);

trial_thres = 1;
size_list = cell2mat(cellfun(@(x) size(x,1),...
    wb_active_cell(:,3),'UniformOutput',false));
sel_wb_active_cell = wb_active_cell(size_list>=trial_thres,:);
%% plot canvas
hall = figure(1);
set(hall,'Position',[1050,100,800,800])
set(hall,'color','white');

%% tempshow
% figure
% for k = 1:size(sel_wb_active_cell,1)
%     tempdata = sel_wb_active_cell{k,3};
%     half_tempdata = tempdata(:,pre_frame:(pre_frame+beh_frame_win-1));
%     max_data = max(half_tempdata,[],2);
%     max_idx = zeros(size(max_data));
%     for m = 1:size(max_idx,1)
%         max_idx(m) = find(...
%             max_data(m)==half_tempdata(m,:),1,'first');
%     end
%     [sort_max,sort_max_idx] = sort(max_idx);
%     subplot(211)
%     imagesc(tempdata(sort_max_idx,:),[-1,5])
%     hold on
%     plot([pre_frame,pre_frame],[0,size(tempdata,1)],'--k')
%     hold off
%     colormap('jet')
%     colorbar
%     subplot(212)
%     plot(mean(tempdata))
%     hold on
%     plot([pre_frame,pre_frame],[0,max(mean(tempdata))],'--k')
%     hold off
%     title(['beh: ',num2str(sel_wb_active_cell{k,1}),...
%         ' neu: ',num2str(sel_wb_active_cell{k,2}),...
%         ' idx: ',num2str(k)])
%     pause
% end
%% show all active trials
% prepare data
active_mat = cell2mat(sel_wb_active_cell(:,3));
beh_list = cell2mat(cellfun(@(x,y) x*ones(size(y,1),1),...
    sel_wb_active_cell(:,1),sel_wb_active_cell(:,3),...
    'UniformOutput',false));

unique_beh_list = unique(beh_list);

diff_beh_list = [0;diff(beh_list)];
sep_idx = find(diff_beh_list~=0);

unique_beh_neu_cell = cell(size(unique_beh_list,1),3);
for k = 1:size(unique_beh_list,1)
    selidx = beh_list==unique_beh_list(k);
    sel_active_mat = active_mat(selidx,:);
    unique_beh_neu_cell{k,1} = sel_active_mat;
    unique_beh_neu_cell{k,2} = mean(sel_active_mat);
    unique_beh_neu_cell{k,3} = ...
        std(sel_active_mat);
end
%%
show_min = -1;
show_max = 5;

start_x = 0.02;
box_x = 0.1;
box_y = 0.92;
inter_x = 0.005;

temph = subplot('Position',...
    [start_x,0.05,box_x,box_y]);
imagesc(active_mat,[show_min,show_max])
hold on
plot([pre_frame,pre_frame],...
    [0,size(active_mat,1)],'--k')
hold on
plot([pre_frame+active_frame_win,pre_frame+active_frame_win],...
    [0,size(active_mat,1)],'--k')
hold off
colormap(temph,flipud(cbrewer2('Spectral',256)))
box off
set(gca,'TickDir','out')
set(gca,'YTick',[])
set(gca,'XTick',[1,(fs*2):(fs*2):size(active_mat,2)])
set(gca,'XTickLabel',-2:2:8)
set(gca,'XTickLabelRotation',0)
xlabel('Time (s)')

temph = subplot('Position',...
    [start_x+box_x+inter_x,0.05,0.01,box_y]);
imagesc(beh_list)
hold on
for k = 1:size(sep_idx,1)
    plot([-2,2],[sep_idx(k),sep_idx(k)],'k-',...
        'LineWidth',0.25)
    hold on
end
hold off
colormap(temph,atlas_cmap)
box on
set(gca,'YTick',[])
set(gca,'XTick',[])

temph = subplot('Position',...
    [start_x,box_y+0.055,box_x,0.005]);
imagesc(show_min:0.01:show_max,[show_min,show_max])
colormap(temph,flipud(cbrewer2('Spectral',256)))
box on
set(gca,'TickLength',[0,0])
set(gca,'XAxisLocation','top')
set(gca,'XTick',[1,300,length(show_min:0.01:show_max)])
set(gca,'XTickLabel',{'-1','△F/F','5'})
set(gca,'XTickLabelRotation',0)


%% plot mean
start_x = 0.26;
start_y = 0.05;
box_x = 0.05;
all_box_y = 0.94;
inter_y = 0.002;

line_c = [0.85*[1,1,1],0.5];

box_y = all_box_y/size(unique_beh_list,1)-inter_y;

for k = 1:size(unique_beh_list,1)
    subplot('Position',...
    [start_x,start_y+(k-1)*(box_y+inter_y),box_x,box_y]);
    errorbar(...
        1:length(unique_beh_neu_cell{k,2}),...
        unique_beh_neu_cell{k,2},...
        unique_beh_neu_cell{k,3},...
        'CapSize',0,'LineWidth',1,...
        'Color',line_c)
    hold on
    plot(unique_beh_neu_cell{k,2},'-k')
    hold on
    plot([pre_frame,pre_frame],...
    [0,size(active_mat,1)],'--k')
    hold on
    plot([pre_frame+active_frame_win,...
        pre_frame+active_frame_win],...
    [0,size(active_mat,1)],'--k')
    hold off
    box off
    axis([0,size(active_mat,2),show_min,show_max])
    set(gca,'XTick',[1,(fs*2):(fs*2):size(active_mat,2)])
    set(gca,'YTick',[0,3])
    set(gca,'TickDir','out')
    set(gca,'FontSize',6)
    ylabel(class_name{unique_beh_list(k)},...
        'Rotation',0,'Interpreter','none',...
        'Position',[-80,0],'HorizontalAlignment','right')
    if k == 1
        set(gca,'XTickLabel',[-2,0,2,4,6,8])
        set(gca,'XTickLabelRotation',0)
    else
        set(gca,'XTickLabel',[])
    end
end
%% active number in neurons with baseline
all_neu = unique(cell2mat(baseline_cell(:,2)));
unique_wash_baseline_neu = ...
    unique(cell2mat(wash_baseline_cell(:,2)));
unique_active_neu = unique(...
    cell2mat(sel_wb_active_cell(:,2)));

active_perc = length(unique_active_neu)/...
    length(unique_wash_baseline_neu);
non_active_perc = 1-active_perc;

cmap_low = cbrewer2('Blues',256);
cmap_high = cbrewer2('Reds',256);
clow = cmap_low(64,:);
chigh = cmap_high(64,:);
clr_list = [clow;chigh];
temph = subplot('Position',[0.35,0.78,0.1,0.2]);
pie([non_active_perc,active_perc],'%.2f%%')
colormap(temph,clr_list)
legend({'No response','Active'},'Location',...
    'SouthOutside','Box','off');
title('Neurons','Position',[0,1.5])

all_wash_baseline_trial = ...
    cell2mat(cellfun(@(x) size(x,1),...
    wash_baseline_cell(:,3),...
    'UniformOutput',false));

all_active_trial = ...
    cell2mat(cellfun(@(x) size(x,1),...
    sel_wb_active_cell(:,3),...
    'UniformOutput',false));

active_perc = sum(all_active_trial)/...
    sum(all_wash_baseline_trial);
non_active_perc = 1-active_perc;

temph = subplot('Position',[0.48,0.78,0.1,0.2]);
pie([non_active_perc,active_perc],'%.2f%%')
colormap(temph,clr_list)
legend({'No response','Active'},'Location',...
    'SouthOutside','Box','off');
title('Trials','Position',[0,1.5])


%% select wash_baseline_cell
sel_wash_baseline_cell = ...
    wash_baseline_cell(size_list>=trial_thres,:);

all_sel_wash_baseline_trial = ...
    cell2mat(cellfun(@(x) size(x,1),...
    sel_wash_baseline_cell(:,3),...
    'UniformOutput',false));

trial_perc = all_active_trial./all_sel_wash_baseline_trial;

trial_perc_min_0_05 = sum(trial_perc<=0.05)/length(trial_perc);
trial_perc_max_0_1 = sum(...
    (trial_perc>0.05))/length(trial_perc);

temph = subplot('Position',[0.61,0.78,0.1,0.2]);
pie([...
    trial_perc_min_0_05,...
    trial_perc_max_0_1],'%.2f%%')
colormap(temph,clr_list)
legend({'≤0.05','>0.05'},'Location',...
    'SouthOutside','Box','off');
title('Active trials/Neuron','Position',[0,1.5])
%% show all activities of one neuron
thres_list = [0.05,0.1,0.15,1]';
thres_trial_list = cell(size(thres_list,1),4);
thres_all_list = [0;thres_list];
for k = 1:size(thres_list,1)
    sel_trial = (thres_all_list(k,1)<=trial_perc)&...
        (trial_perc<thres_all_list(k+1,1));
    thres_trial_list{k,1} = [thres_all_list(k,1),...
        thres_all_list(k+1,1)];
    thres_trial_list{k,2} = ...
        sel_wash_baseline_cell(sel_trial,:);
    thres_trial_list{k,3} = ...
        mean(cell2mat(sel_wash_baseline_cell(sel_trial,3)));
    thres_trial_list{k,4} = ...
        std(cell2mat(sel_wash_baseline_cell(sel_trial,3)))...
        ./sqrt(size(thres_trial_list{k,2},1));
end

%% show
cmap_list = ...
    flipud(cbrewer2('Spectral',size(thres_list,1)));
subplot('Position',[0.76,0.83,0.18,0.15])
show_legend_h = cell(1,size(thres_trial_list,1));
for k = fliplr(1:size(thres_trial_list,1))
    tempmean = thres_trial_list{k,3};
    tempstd = thres_trial_list{k,4};
    shadedErrorBar(1:length(tempmean),tempmean,...
        tempstd,'lineProps',{'Color',cmap_list(k,:)})
    hold on
    show_legend_h{k} = plot(tempmean,'Color',cmap_list(k,:),...
        'LineWidth',1);
    hold on
end
plot([pre_frame,pre_frame],...
    [-0.2,0.8],'--k')
hold on
plot([pre_frame+active_frame_win,pre_frame+active_frame_win],...
    [-0.2,0.8],'--k')
hold off
ylabel('△F/F')
set(gca,'XTick',[1,(fs*2):(fs*2):size(active_mat,2)])
set(gca,'XTickLabel',-2:2:8)
set(gca,'XTickLabelRotation',0)
xlabel('Time (s)')
set(gca,'TickDir','out')
set(gca,'FontSize',6)
box off
legend([show_legend_h{:}],...
    '0-0.05','0.05-0.1','0.1-0.15','0.15-1',...
    'box','off','Location','NorthWest')
%% prepare data for statistics
stat_data = cell(1,size(thres_trial_list,1));
for k = 1:size(thres_trial_list,1)
    %%
    tempdata = thres_trial_list{k,2};
    seldata = cell2mat(cellfun(@(x) mean(x(:,61:end),'all'),...
        tempdata(:,3),'UniformOutput',false));
    tempmean = mean(seldata);
    tempstd = std(seldata);
    tempN = length(seldata);
    stat_data{k} = [tempmean,tempstd,tempN];
end
stat_data = cell2mat(stat_data);
%% find specific neurons only active for some behavior
unique_active_neu = unique(cell2mat(wash_baseline_cell(:,2)));
unique_active_beh = unique(cell2mat(wash_baseline_cell(:,1)));

wb_cell_mat = cell(size(unique_active_neu,1),...
    size(unique_active_beh,1));

for m = 1:size(wb_cell_mat,1)
    for n = 1:size(wb_cell_mat,2)
        wb_cell_mat{m,n} = -10*ones(3,300);
    end
end

for k = 1:size(wash_baseline_cell,1)
    tempneu = wash_baseline_cell{k,2};
    tempbeh = wash_baseline_cell{k,1};
    selneu = find(tempneu==unique_active_neu);
    selbeh = find(tempbeh==unique_active_beh);
    wb_cell_mat{selneu,selbeh} = wash_baseline_cell{k,3};
end

active_range = 61:120;
max_wb_cell_mat = cell2mat(cellfun(@(x) ...
    max(mean(x(:,active_range))),...
    wb_cell_mat,'UniformOutput',false));

sort_max_wb_cell_mat = zeros(size(max_wb_cell_mat));
sortidx_max_wb_cell_mat = zeros(size(max_wb_cell_mat));
for k = 1:size(max_wb_cell_mat,1)
    [sort_max_wb_cell_mat(k,:),...
        sortidx_max_wb_cell_mat(k,:)] = ...
        sort(max_wb_cell_mat(k,:),'descend');
end
%%
upper_thres = 0.25;
lower_thres = 0.12;

sel_idx = find((sort_max_wb_cell_mat(:,1)>upper_thres)&...
    (sort_max_wb_cell_mat(:,2)<lower_thres));

max_list = [sel_idx,sortidx_max_wb_cell_mat(sel_idx,1),...
    sort_max_wb_cell_mat(sel_idx,1:2)];
max_list = sortrows(max_list,2);
manual_sel_idx = [1,12,5,9];
selsel_neuidx = max_list(manual_sel_idx,1);
selsel_behidx = max_list(manual_sel_idx,2);

washneu_wb_cell_mat = wb_cell_mat(selsel_neuidx,:);
washneubeh_wb_cell_mat = washneu_wb_cell_mat(:,selsel_behidx);

washneubeh_active_neu = unique_active_neu(selsel_neuidx);
washneubeh_active_beh = unique_active_beh(selsel_behidx);

sel_range = 31:150;

mean_washneubeh_wb_cell_mat = cellfun(@(x) mean(x(:,sel_range)),...
    washneubeh_wb_cell_mat,'UniformOutput',false);

sd_washneubeh_wb_cell_mat = cellfun(@(x) ...
    std(x(:,sel_range))./sqrt(size(x,1)),...
    washneubeh_wb_cell_mat,'UniformOutput',false);

washneubeh_wb_cell_mat_61120 = cellfun(@(x) x(:,sel_range),...
    washneubeh_wb_cell_mat,'UniformOutput',false);
% plot
start_x = 0.33;
start_y = 0.79;
box_x = 0.07;
box_y = 0.03;
inter_x = 0.008;
inter_y = 0.01;

for m = 1:size(mean_washneubeh_wb_cell_mat,1)
    for n = 1:size(mean_washneubeh_wb_cell_mat,2)
        tempmean = mean_washneubeh_wb_cell_mat{m,n};
        tempsd = sd_washneubeh_wb_cell_mat{m,n};
        if m == n
            cmap = cmap_list(4,:);
        else
            cmap = cmap_list(1,:);
        end
        subplot('Position',...
        [start_x+m*(box_x+inter_x),...
        start_y-n*(box_y+inter_y),box_x,box_y])
        plot([1,120],[0,0],'--k')
        hold on
        shadedErrorBar(1:length(tempmean),tempmean,tempsd,...
            'lineProps',{'Color',cmap})
        hold on
        plot(tempmean,'-',...
                'Color',cmap,'LineWidth',1)
        hold on
        plot([30,30],[-0.3,0.6],'--k')
        hold on
        plot([90,90],[-0.3,0.6],'--k')
        hold off
        axis([0,length(tempmean),-0.3,0.6])
        set(gca,'TickDir','out')
        box off
        set(gca,'XTick',[1,30,60,90,120])
        set(gca,'YTick',[-0.3,0,0.3,0.6])
        
        if n == size(mean_washneubeh_wb_cell_mat,2)
            xlabel(class_name{washneubeh_active_beh(m)},...
                'Interpreter','none',...
                'Rotation',45)
        end

        if m == 1
            ylabel({'Neuron ',...
                num2str(washneubeh_active_neu(n))},...
                'Interpreter','none',...
                'Rotation',0,'Position',[-90,0])
        end

        if n ~= size(mean_washneubeh_wb_cell_mat,2)
            set(gca,'XTickLabel',[])
        else
            set(gca,'XTickLabel',{'-1','0','1','2','3'})
            set(gca,'XTickLabelRotation',0)
        end
        if m ~= 1
            set(gca,'YTickLabel',[])
        end
        
%         if n==3 && m==1
%             ylabel('△F/F')
%         end
% 
%         if n==5 && m==3
%             xlabel('Time (s)')
%         end
        
        set(gca,'FontSize',6)
    end
end

%% create mice name
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
%% statistic the number of active neurons to behavior modules
sel_sort_idx = ~double(sort_max_wb_cell_mat<lower_thres);
active_num_list = sum(sel_sort_idx,2);

unique_active_num = unique(active_num_list);

mice_active_mat = zeros(length(unique_mice_name),...
    length(unique_active_num));

for k = 1:size(active_num_list,1)
    tempmicename = mice_name_neuidx_cell{k,1};
    tempnum = active_num_list(k);
    selmiceidx = find(strcmp(unique_mice_name,tempmicename));
    selnumidx = find(unique_active_num==tempnum);
    mice_active_mat(selmiceidx,selnumidx) = ...
        mice_active_mat(selmiceidx,selnumidx)+1;
end


norm_mice_active_mat = mice_active_mat./...
    (sum(mice_active_mat,2)*ones(1,size(mice_active_mat,2)));

mean_norm_mice_active_mat = mean(norm_mice_active_mat);
sd_norm_mice_active_mat = std(norm_mice_active_mat)./...
    sqrt(5);
%% show
bias = 0.3;
bar_c = 0.8*ones(1,3);
subplot('Position',[0.76,0.63,0.23,0.14])
bar(1:length(mean_norm_mice_active_mat),...
    mean_norm_mice_active_mat,'FaceColor',bar_c,...
    'BarWidth',0.6)
hold on
errorbar(1:length(mean_norm_mice_active_mat),...
    mean_norm_mice_active_mat,sd_norm_mice_active_mat,...
    'LineStyle','none','Color','k','CapSize',2)
hold on
for k = 1:size(norm_mice_active_mat,2)
    plot(bias+k*ones(5,1),norm_mice_active_mat(:,k),'o',...
        'MarkerFaceColor','w','MarkerEdgeColor','k',...
        'MarkerSize',2)
    hold on
end
hold off
box off
set(gca,'TickDir','out')
axis([0.3,16.5,0,0.3])
set(gca,'FontSize',6)
ylabel('Porportion')
set(gca,'XTick',1:16)
set(gca,'XTickLabel',{'0',...
    '1','2','3','4','5',...
    '6','7','8','9','10',...
    '11','12','13','14','15'})
set(gca,'XTickLabelRotation',0)
xlabel('Number of active behavior per neuron')

%% create behavior module map
mice_stat_beh_cell = cell(size(unique_mice_name,1),3);
mice_stat_beh_cell(:,1) = unique_mice_name;

for k = 1:size(mice_stat_beh_cell,1)
    tempmice = mice_stat_beh_cell{k,1};
    selmice = find(strcmp(tempmice,mice_name_neuidx_cell(:,1)));
    active_idx_mat = double(~(...
        max_wb_cell_mat(selmice,:)<lower_thres));
    one_active_idx = sum(active_idx_mat,2)==1;
    one_stat_cell = stat_cell(one_active_idx);
    one_active_idx_mat = active_idx_mat(one_active_idx,:);
    
    one_active_beh_list = zeros(size(one_stat_cell,1),1);
    for m = 1:size(one_active_idx_mat,1)
        tempdata = one_active_idx_mat(m,:);
        selidx = find(tempdata==1);
        selbehidx = unique_active_beh(selidx);
        one_active_beh_list(m,1) = selbehidx;
    end
    
    mice_stat_beh_cell{k,2} = one_stat_cell;
    mice_stat_beh_cell{k,3} = one_active_beh_list;
end
%% define restrict behavior
small_beh_cell = {...
    'Groom',[3,4,5,6,7,11,17,22,24,31,38,39,40,41]';...
    'Locomotion',[1,2,15,16,26,27,35,36]';...
    'Body movement',[8,9,10,12,13,18,25,28,30,34,21,23,29,...
    14,19,20,32,33,37]'};

small_cmap = cbrewer2('Accent',size(small_beh_cell,1));
small_cmap_41 = zeros(size(atlas_cmap));
for k = 1:size(small_beh_cell,1)
    tempsel = small_beh_cell{k,2};
    small_cmap_41(tempsel,:) = ...
        ones(size(tempsel,1),1)*small_cmap(k,:);
end
%% show
start_x = 0.33;
start_y = 0.41;
box_x = 0.1;
box_y = box_x;
inter_x = 0.005;

bias_xy = 50;
for k = 1:size(mice_stat_beh_cell,1)
    selstat = mice_stat_beh_cell{k,2};
    selbeh = mice_stat_beh_cell{k,3};
    subplot('Position',[...
        start_x+(k-1)*(box_x+inter_x),start_y,box_x,box_y])
    all_x_list = [];
    all_y_list = [];
    for m = 1:size(selstat,1)
        selmed = selstat{m}.med;
        selbehidx = selbeh(m);
        selx = double(selstat{m}.xpix);
        sely = double(selstat{m}.ypix);
        xc = double(selstat{m}.xext);
        yc = double(selstat{m}.yext);
        selcmap = small_cmap_41(selbehidx,:);

        all_x_list = [all_x_list;xc'];
        all_y_list = [all_y_list;yc'];

        plot(xc,yc,'.','Color',0.3*[1,1,1])
        hold on
        scatter(selx,sely,2*ones(size(selx)),...
            ones(size(selx,1),1)*selcmap,'filled')
        
        hold on
    end
    
    min_x = min(all_x_list);
    max_x = max(all_x_list);
    min_y = min(all_y_list);
    max_y = max(all_y_list);

    hold off

    axis([min_x-bias_xy,max_x+bias_xy,...
        min_y-bias_xy,max_y+bias_xy])
    set(gca,'XTick',[],'YTick',[])
    box on

    title(['Mouse ',num2str(k)])

    set(gca,'FontSize',6)

end

% legend
subplot('Position',[0.69,0.55,0.01,0.025])
legend_name = {'Groom-related neurons',...
    'Locomotion-related neurons',...
    'Body movement-related neurons'}';
for k = 1:size(legend_name,1)
    plot([0,1],[k,k],'-','Color',small_cmap(k,:),...
        'LineWidth',3)
    hold on
    text(1.5,k,legend_name{k},'FontSize',6)
    hold on
end
hold off
set(gca,'FontSize',6)
axis off
%% statistics of spatial correlation
small_sil_dist_mat = zeros(size(unique_mice_name,1),...
    size(small_beh_cell,1));
for k = 1:size(small_sil_dist_mat,1)
    %% load data
    selstat = mice_stat_beh_cell{k,2};
    selbeh = mice_stat_beh_cell{k,3};
    %% replace to small behavior
    smallbeh = selbeh;
    for m = 1:size(selbeh,1)
        tempbeh = selbeh(m);
        for n = 1:size(small_beh_cell,1)
            refbeh = small_beh_cell{n,2};
            tempidx = sum(refbeh==tempbeh);
            if tempidx == 1
                smallbeh(m) = n;
            end
        end
    end
    %% extract distance list
    med_list = zeros(size(smallbeh,1),2);
    for m = 1:size(med_list,1)
        med_list(m,:) = selstat{m}.med;
    end

    s = silhouette(med_list,smallbeh);

    %% calculate distance
    tempuniquebeh = unique(smallbeh);
    
    for m = 1:size(tempuniquebeh,1)
        small_sil_dist_mat(k,m) = ...
            mean(s(tempuniquebeh(m)==smallbeh));
    end
end

small_sil_dist_mat(small_sil_dist_mat==1) = 0;
%% show silhouette coef
mean_small_sil_dist_mat = mean(small_sil_dist_mat);
sd_small_sil_dist_mat = std(small_sil_dist_mat)/sqrt(5);

bar_w = 0.7;
bias_x = 0.35;
subplot('Position',[0.9,0.41,0.09,0.13])
for k = 1:size(mean_small_sil_dist_mat,2)
    tempmean = mean_small_sil_dist_mat(k);
    tempsd = sd_small_sil_dist_mat(k);
    tempdata = small_sil_dist_mat(:,k);

    bar(k,tempmean,bar_w,'FaceColor',small_cmap(k,:))
    hold on
    errorbar(k,tempmean,tempsd,'Color','k')
    hold on
    plot((k+bias_x)*ones(size(tempdata)),tempdata,'ok',...
        'MarkerFaceColor','w','MarkerSize',2)
    hold on
end
hold off

axis([0.3,3.7,-0.5,0.5])

ylabel('Silhouette coefficient')
set(gca,'FontSize',6)
box off
set(gca,'TickDir','out')
set(gca,'XTick',[])

%% statistics of differences between two groups
temp_wash_free_fix_cell = cellfun(@(x) split(x,'-'),...
    wash_name_cell,'UniformOutput',false);
wash_free_fix_cell = cellfun(@(x) x(:,1),...
    temp_wash_free_fix_cell,'UniformOutput',false);
ht_baseline_cell = [...
    wash_baseline_cell(:,1:2),...
    wash_free_fix_cell,...
    cellfun(@(x) mean(x(:,61:120),2),...
    wash_baseline_cell(:,3),...
    'UniformOutput',false)];
%% mean ht cell
group_name = {'free','fix'};
mean_ht_cell = cell(size(ht_baseline_cell,1),1);
mean_traj_ht_cell = cell(size(ht_baseline_cell,1),2);
for k = 1:size(mean_ht_cell,1)
    %% organize data
    tempname = ht_baseline_cell{k,3};
    tempdata = ht_baseline_cell{k,4};
    group_data = {...
        tempdata(strcmp(tempname,group_name{1})),...
        tempdata(strcmp(tempname,group_name{2}))};
    mean_ht_cell{k,1} = [mean(group_data{1}),mean(group_data{2})];
    %%
    temptraj = wash_baseline_cell{k,3};
    group_traj = {...
        temptraj(strcmp(tempname,group_name{1}),:),...
        temptraj(strcmp(tempname,group_name{2}),:)};
    mean_traj_ht_cell(k,:) = {...
        mean(group_traj{1}),mean(group_traj{2})};
end
%% group according to behavior
beh_ht_baseline_cell = cell(size(unique_beh_class,1),2);
ht_baseline_beh = cell2mat(ht_baseline_cell(:,1));
beh_traj_ht_baseline_cell = cell(size(unique_beh_class,1),3);
for k = 1:size(beh_ht_baseline_cell,1)
    %%
    beh_ht_baseline_cell{k,1} = unique_beh_class(k);
    beh_traj_ht_baseline_cell{k,1} = ...
        unique_beh_class(k);
    selidx = find(ht_baseline_beh==beh_ht_baseline_cell{k,1});
    beh_ht_baseline_cell{k,2} = ...
        cell2mat(mean_ht_cell(selidx,1));
    try
        beh_traj_ht_baseline_cell{k,2} = ...
            {cell2mat(mean_traj_ht_cell(selidx,1)),...
            cell2mat(mean_traj_ht_cell(selidx,2));...
            mean(cell2mat(mean_traj_ht_cell(selidx,1))),...
            mean(cell2mat(mean_traj_ht_cell(selidx,2)));...
            std(cell2mat(mean_traj_ht_cell(selidx,1)))./...
            sqrt(size(cell2mat(mean_traj_ht_cell(selidx,1)),1)),...
            std(cell2mat(mean_traj_ht_cell(selidx,2)))./...
            sqrt(size(cell2mat(mean_traj_ht_cell(selidx,1)),1))};

        beh_traj_ht_baseline_cell{k,3} = ...
            wash_free_fix_cell(selidx,:);
    
%         figure
%         plot(beh_traj_ht_baseline_cell{k,2}{2,1},'-b')
%         hold on
%         plot(beh_traj_ht_baseline_cell{k,2}{2,2},'-r')
%         hold off
%         title(p_cell{k})
    end
end
%% hypothesis testing
p_cell = cell(size(beh_ht_baseline_cell,1),3);
group_data = cell(1,2);
tic
for k = 1:size(beh_ht_baseline_cell,1)
    try
        %% organize data
        group_data{1} = beh_ht_baseline_cell{k,2}(:,1);
        group_data{2} = beh_ht_baseline_cell{k,2}(:,2);
        %% Test for Normal Distribution
        [h_norm,p_norm,lstat,cv]=lillietest(tempdata); 
        %% Two-sample F-test for equal variances
        [h_var,p_var] = vartest2(group_data{1},group_data{2});
   
        %% test
        if true%(h_norm==0)&&(h_var==0)
            % t-test
            [h_t,p_t] = ttest2(group_data{1},group_data{2});
             p_cell{k,3} = 'param';
        else
            % Mann-Whitney-Wilcoxon non parametric test
%             tempstat = mwwtest(group_data{1}',group_data{2}');
            [p_t,h_t] = ranksum(group_data{1},group_data{2});
            p_cell{k,3} = 'non param';
        end
        p_cell{k,1} = [p_t,h_t];
        p_cell{k,2} = [mean(group_data{1}),...
            mean(group_data{2})];
    catch
        p_cell{k,1} = [0,0];
        p_cell{k,2} = [0,0];
    end
end
toc
% show neural activity difference
p_mat = cell2mat(p_cell(:,1:2));
sel_p_idx = (p_mat(:,1)~=0)&(~isnan(p_mat(:,1)));
sel_ht_idx = cellfun(@(x) size(x,1)~=0,...
    beh_traj_ht_baseline_cell(:,2));
sel_p_mat = p_mat(sel_p_idx&sel_ht_idx,:);
sel_ht = beh_traj_ht_baseline_cell(sel_p_idx&sel_ht_idx,:);
sel_cmp_ht = beh_ht_baseline_cell(sel_p_idx&sel_ht_idx,:);
% sort for good show
[~,sort_i] = sort(sel_p_mat(:,1),'descend');
sort_p_mat = sel_p_mat(sort_i,:);
sort_ht = sel_ht(sort_i,:);
sort_cmp_ht = sel_cmp_ht(sort_i,:);

%% show
row_num = 3;
col_num = 7;

start_x = 0.358;
start_y = 0.05;

box_x_1 = 0.05;
box_y_1 = 0.09;

inter_x_12 = 0.002;

box_x_2 = 0.028;
box_y_2 = box_y_1;

inter_x = 0.01;
inter_y = 0.03;

cmap_tm_fix = cbrewer2('Reds',256);
cmap_tm_free = cbrewer2('Blues',256);
class_cmap_fix = cmap_tm_fix(192,:);
class_cmap_free = cmap_tm_free(192,:);

plot_range = 1:300;
cmp_range = 61:120;

bar_w = 0.6;
cap_size = 2;
bar_alpha = 0.7;

sig_y = 0.033;

star_text_list = {'n.s.';'*';'**';'***';'****'};
star_p_value = [...
    0.05,1;...
    0.01,0.05;...
    0.001,0.01;...
    0.0001,0.001;...
    0,0.0001];

count = 1;
for m = 1:row_num
    for n = 1:col_num
        %% load data
        beh_idx = sort_ht{count,1};
        beh_name = class_name{beh_idx};
        
        mean_neu_free = sort_ht{count,2}{2,1}(:,plot_range);
        mean_neu_fix = sort_ht{count,2}{2,2}(:,plot_range);
        std_neu_free = sort_ht{count,2}{3,1}(:,plot_range);
        std_neu_fix = sort_ht{count,2}{3,2}(:,plot_range);

        bar_mean_neu_free = ...
            mean(sort_cmp_ht{count,2}(:,1));
        bar_mean_neu_fix = ...
            mean(sort_cmp_ht{count,2}(:,2));
        bar_std_neu_free = ...
            std(sort_cmp_ht{count,2}(:,1))./...
            sqrt(size(sort_cmp_ht{count,2},1));
        bar_std_neu_fix = ...
            std(sort_cmp_ht{count,2}(:,2))./...
            sqrt(size(sort_cmp_ht{count,2},1));

        bar_x = 1:2;

        p_value = sort_p_mat(count,1);

        sel_p_idx = find((star_p_value(:,1)<=p_value)&...
            (p_value<star_p_value(:,2)));
        sel_p_text = star_text_list{sel_p_idx};

        %% show

        subplot('Position',[...
            start_x+(n-1)*(...
            box_x_1+box_x_2+inter_x_12+inter_x),...
            start_y+(m-1)*(box_y_1+inter_y),...
            box_x_1,box_y_1])
        plot([0,300],[0,0],'--k')
        hold on
        shadedErrorBar(1:length(mean_neu_free),...
            mean_neu_free,std_neu_free,...
            'lineProps',{'Color',class_cmap_free})
        hold on
        shadedErrorBar(1:length(mean_neu_fix),...
            mean_neu_fix,std_neu_fix,...
            'lineProps',{'Color',class_cmap_fix})
        hold on
        plot(mean_neu_free,'-',...
                'Color',class_cmap_free,'LineWidth',0.5)
        hold on
        plot(mean_neu_fix,'-',...
                'Color',class_cmap_fix,'LineWidth',0.5)
        hold on
        plot([30,30],[-0.3,0.6],'--k')
        hold on
        plot([90,90],[-0.3,0.6],'--k')
        hold off
        axis([0,300,-0.01,0.16])

        title(beh_name,...
            'Interpreter','none',...
            'FontSize',6,...
            'HorizontalAlignment','left')
        set(gca,'FontSize',6)
        box off
        set(gca,'TickDir','out')
        if n~=1
            set(gca,'YTickLabel',[])
        else
            ylabel('△F/F')
        end
        
        set(gca,'XTick',0:60:300)
        if m ~=1
            set(gca,'XTickLabel',[])
        else
            set(gca,'XTickLabel',-2:2:8)
            set(gca,'XTickLabelRotation',0)
        end
        

        subplot('Position',[...
            start_x+box_x_1+inter_x_12+(n-1)*(...
            box_x_1+box_x_2+inter_x_12+inter_x),...
            start_y+(m-1)*(box_y_1+inter_y),...
            box_x_2,box_y_2])

        bar(bar_x(1),bar_mean_neu_free,bar_w,...
            'FaceColor',class_cmap_free,...
            'FaceAlpha',bar_alpha)
        hold on
        bar(bar_x(2),bar_mean_neu_fix,bar_w,...
            'FaceColor',class_cmap_fix,...
            'FaceAlpha',bar_alpha)
        hold on
        errorbar(bar_x(1),bar_mean_neu_free,...
            bar_std_neu_free,'Color','k',...
            'CapSize',cap_size)
        hold on
        errorbar(bar_x(2),bar_mean_neu_fix,...
            bar_std_neu_fix,'Color','k',...
            'CapSize',cap_size)

        hold on
        plot(bar_x,[sig_y,sig_y],'-k')
        text(mean(bar_x),sig_y,sel_p_text,...
            'HorizontalAlignment','center',...
            'FontSize',6,'VerticalAlignment','bottom')
        hold off
        
        axis([0.3,2.7,0,0.04])
        
        box off
        set(gca,'YAxisLocation','right')
        set(gca,'FontSize',6)
        set(gca,'TickDir','out')
        set(gca,'XTick',[1,2])
        
        if n~=col_num
            set(gca,'YTickLabel',[])
        else
        end

        if m~=1
            set(gca,'XTickLabel',[])
        else
            set(gca,'XTickLabel',{'Free','Trapped'})
            set(gca,'XTickLabelRotation',90)
        end

        count = count+1;

    end
end















































































