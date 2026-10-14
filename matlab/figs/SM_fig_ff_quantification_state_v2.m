%{
    flow field quantification
    
    只有日期的：far close far
    far_baseline_time = 2
    far_after_time = 2
    close_min_time = 2

    close_far: close far
    close_baseline_time = 1
    close_after_time = 0
    far_min_time = 5
    
    
    all:一万八一分，90000/5，每个脑区10分钟数据
%}
clear all
close all
addpath(genpath(pwd))
%% set path
rootpath = ['H:\MTPM_body_language'];
beh_neu_path = [rootpath,'\beh_neu_20240412'];
dy_path = [rootpath,'\dynamic_model_data_20241113'];
%% load dynamics
load_brain_name = {...
    'tpmss';...
    'tpmpfc';...
    'tpmm'};

brain_dy_cell = cell(3,size(load_brain_name,1));

for k = 1:size(brain_dy_cell,1)
    %%
    all_name = [load_brain_name{k,1},'_all_20241113.mat'];
    close_name = [load_brain_name{k,1},'_20241113.mat'];
    far_name = [load_brain_name{k,1},'_close_far_20241113.mat'];

    tempmat_all = load([dy_path,'\',all_name]);
    tempmat_close = load([dy_path,'\',close_name]);
    tempmat_far = load([dy_path,'\',far_name]);

    brain_dy_cell{1,k} = tempmat_close;
    brain_dy_cell{2,k} = tempmat_far;
    brain_dy_cell{3,k} = tempmat_all;
end


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

% split far-close-far trial
fs = 30;
baseline_close_time = 1;%s
min_far_time = 10;%s
max_far_time = 180;%s

baseline_close_frame = baseline_close_time*fs;
min_far_frame = min_far_time*fs;
max_far_frame = max_far_time*fs;

cf_cell = {};

for k = 1:size(all_data_cell,1)
    %% load data
    tempdist = all_data_cell{k,9};
    
    %% select trials
    distsavelist = idx2savelist(tempdist{2});

    all_far_list = distsavelist(distsavelist(:,3)==0,:);

    all_far_list(all_far_list(:,1)<...
        baseline_close_frame,:) = [];
    all_far_list(...
        (all_far_list(:,2)-all_far_list(:,1))<...
        min_far_frame,:) = [];
    all_far_list(...
        (all_far_list(:,2)-all_far_list(:,1))>...
        max_far_frame,:) = [];

    selidx = zeros(size(all_far_list,1),1);

    for m = 1:size(all_far_list,1)
        tempstart = all_far_list(m,1);
        tempend = all_far_list(m,2);
        seldata_baseline = tempdist{2}(...
            (tempstart-baseline_close_frame):(tempstart-1));

        if sum(seldata_baseline)==baseline_close_frame
            selidx(m,1) = 1;
        end
    end

    all_far_list = all_far_list(selidx==1,:);
    %% append data
    for m = 1:size(all_far_list,1)
        tempstart = all_far_list(m,1)-baseline_close_frame;
        tempend = all_far_list(m,2);

        newname = [all_data_cell{k,1},'-',num2str(m)];
        all_data_2 = all_data_cell{k,2}(tempstart:tempend,:);
        all_data_3 = all_data_cell{k,3}(tempstart:tempend,:);
        all_data_4 = all_data_cell{k,4}(tempstart:tempend,:);
        all_data_5 = all_data_cell{k,5}(tempstart:tempend,:);
        all_data_6 = all_data_cell{k,6}(tempstart:tempend,:);
        all_data_7 = all_data_cell{k,7}(tempstart:tempend,:);
        all_data_8 = all_data_cell{k,8}(tempstart:tempend,:);
        all_data_9 = all_data_cell{k,9}{3}(tempstart:tempend,:);

        cf_cell = [cf_cell;...
            {newname,all_data_2,all_data_3,all_data_4,...
            all_data_5,all_data_6,all_data_7,all_data_8,...
            all_data_9,all_data_cell{k,1}},...
            all_data_cell{k,9}{1}(tempstart:tempend,:),...
            ];

        % unique(all_data_5)
    end
    %%
    disp(k)
end

spl_cf_name = split(cf_cell(:,1),'-');

cf_brain_name = cellfun(...
    @(x) x(2:end),spl_cf_name(:,3),...
    'UniformOutput',false);

tabulate(cf_brain_name)
%% show mov and seq of all the trials
% sort data by length
cf_length = cell2mat(cellfun(@(x) size(x,1),cf_cell(:,2),...
    'UniformOutput',false));

[~,sortidx] = sort(cf_length,'descend');

sort_cf_cell = cf_cell(sortidx,:);
%% plot canvas
hall = figure(1);
set(hall,'Position',[680,100,800,800])
set(hall,'color','white');

%% show
fs = 30;

time_len = 60*10;

frame_len = fs*time_len;

far_baseline_time = 2;
far_after_time = 2;
close_min_time = 2;

close_baseline_time = 1;
close_after_time = 0;
far_min_time = 5;

start_x = 0.08;
start_y = 0.96;

box_x = 0.9;
box_y = 0.02;

inter_y = 0.02;

small_inter_y = 0.002;

big_inter_y = 0.01;

quv_cmap = cbrewer2('Paired',10);

quv_cmap_list = [quv_cmap(3,:);quv_cmap(2,:)*0.8];

show_title = {...
    'S1';...
    'dmPFC';...
    'M1'};

x_unit_fcf = fs*10;
x_unit_cf = fs*120;
x_unit_all = fs*60*10;

for m = 1:size(brain_dy_cell,1)
    for n = 1:size(brain_dy_cell,2)
        %%
        temps = brain_dy_cell{m,n};

        temp_dist = double(temps.z_dist)';
        temp_state = double(temps.ms_state)';

        temph = subplot('Position',[...
            start_x,...
            start_y-(m-1)*(2*box_y+inter_y+small_inter_y)-...
            (n-1)*(6*box_y+3*small_inter_y+3*inter_y+big_inter_y),...
            box_x,box_y]);
        imagesc(temp_dist')
        colormap(quv_cmap_list)

        set(gca,'TickDir','out')
        set(gca,'YTick',[])
        set(gca,'FontSize',6)
        box off

        ylabel('Distance','Rotation',0)

        set(gca,'TickLength',[0.002,0.002])
        
        if m == 1
            x_unit = x_unit_fcf;
        elseif m == 2
            x_unit = x_unit_cf;
        elseif m == 3
            x_unit = x_unit_all;
        end
        set(gca,'XTick',0:x_unit:length(temp_dist))
        set(gca,'XTickLabel',[])
        
        if m == 1
            title(show_title{n});
        end

        subplot('Position',[...
            start_x,...
            start_y-(m-1)*(2*box_y+inter_y+small_inter_y)-...
            box_y-small_inter_y-...
            (n-1)*(6*box_y+3*small_inter_y+3*inter_y+big_inter_y),...
            box_x,box_y])
        plot(1.5*(1-temp_state),'Color',[0.7,0,0])
        axis([0,length(temp_state),0,1])

        set(gca,'YTick',[0,1])
        ylabel('State','Rotation',0)
        set(gca,'TickDir','out')
        set(gca,'FontSize',6)
        box off

        set(gca,'XTick',0:x_unit:length(temp_dist))

        set(gca,'TickLength',[0.002,0.002])

        if m == 1
            set(gca,'XTickLabel',(0:x_unit:length(temp_dist))/...
                (fs))
        else
            set(gca,'XTickLabel',(0:x_unit:length(temp_dist))/...
                (fs*60))
        end
    end
end

%% quantification of state change
state_change_cell = cell(size(brain_dy_cell));

for m = 1:size(brain_dy_cell,1)
    for n = 1:size(brain_dy_cell,2)
        %%
        temps = brain_dy_cell{m,n};

        temp_dist = double(temps.z_dist)';
        temp_state = double(temps.ms_state)';

        start_state_idx = find([0;diff(temp_state)]~=0);

        end_state_idx = [start_state_idx(2:end)-1;length(temp_state)];

        temp_dist_cell = cell(size(start_state_idx,1),1);

        for k = 1:size(temp_dist_cell,1)
            temp_dist_cell{k,1} = temp_dist(...
                start_state_idx(k,1):end_state_idx(k,1));
        end

        len_temp_dist = cellfun(@(x) size(x,1),...
            temp_dist_cell);
        
        if m == 2
            temp_dist_cell(...
                (len_temp_dist<=60)) = [];
        else
            temp_dist_cell(...
                (len_temp_dist<=120)) = [];
        end

        for k = 1:size(temp_dist_cell,1)
            if length(temp_dist_cell{k,1})>=600
                temp_dist_cell{k,1} = ...
                    temp_dist_cell{k,1}(1:600);
            end
        end

        state_change_cell{m,n} = temp_dist_cell;
    end
end
%% 展示状态内的一致性，分0片段和1片段，分别show，
% 展示状态的平均pattern
% state时间和trial时间的匹配程度，假设检验

start_x = 0.08;
start_y = 0.28;

box_x = 0.1;
box_y = 0.1;

inter_x = 0.035;
inter_y = 0.01;

show_cmap = [1,1,1;quv_cmap_list];

x_list = 1:600;

x_tick_13 = [0,300,600];
x_tick_label_13 = [0,10,20];

x_tick_2 = [0,60,120];
x_tick_label_2 = [0,2,4];

alpha_line = 0.2;

show_title = {...
    'Close interaction';...
    'After interaction';...
    'All'};

show_ylabel_left = {...
    'S1';...
    'dmPFC';...
    'M1'};

for m = 1:size(state_change_cell,1)
    for n = 1:size(state_change_cell,2)
        selstate = state_change_cell{m,n};

        size_list = cell2mat(cellfun(@(x) size(x,1),...
            selstate,'UniformOutput',false));

        [~,sort_i] = sort(size_list,'descend');

        sort_state = selstate(sort_i);

        pad_mat = -1*ones(size(sort_state,1),600);

        for k = 1:size(sort_state,1)
            pad_mat(k,1:length(sort_state{k})) = sort_state{k};
        end

        temph = subplot('Position',[...
            start_x+(m-1)*(box_x+inter_x),...
            start_y-(n-1)*(box_y+inter_y),...
            box_x,box_y]);
        
        yyaxis left
        imagesc(pad_mat)

        colormap(temph,show_cmap)

        set(gca,'YTick',[1,size(pad_mat,1)])
        
        if m == 1
            ylabel({show_ylabel_left{n},...
                'Trials of state 0'})
        end

       
        
        % show probability of close
        yyaxis right
        mean_pad = zeros(1,size(pad_mat,2));
        std_pad = zeros(1,size(pad_mat,2));
        for k = 1:size(pad_mat,2)
            seldata = pad_mat(:,k);
            seldata(seldata==-1) = [];
            mean_pad(k) = mean(seldata);
            std_pad(k) = std(seldata)./sqrt(length(seldata));
        end
        
        tempe = errorbar(x_list,mean_pad,std_pad,...
            'CapSize',0,'Color',0.8*ones(1,3));
        set([tempe.Bar, tempe.Line], ...
        'ColorType', 'truecoloralpha', ...
        'ColorData', [tempe.Line.ColorData(1:3); ...
        255*alpha_line])
        hold on
        
        plot(x_list,mean_pad,'-','Color',0*ones(1,3),...
            'LineWidth',1)
        hold off

        if m == 2
            axis([0,180,0,1.02])
            set(gca,'XTick',x_tick_2)
            set(gca,'XTickLabel',x_tick_label_2)
        else
            axis([0,600,0,1.02])
            set(gca,'XTick',x_tick_13)
            set(gca,'XTickLabel',x_tick_label_13)
        end

        if n ~= 3
            set(gca,'XTickLabel',[])
        end

        set(gca,'YTick',[0,1])

        set(gca,'FontSize',6)

        set(gca,'TickDir','out')

        box off

        if n == 1
            title(show_title{m})
        end

        if n == 3
            xlabel('Time (s)')
        end
        
        if m == 3
            ylabel({'Percentage of','close distance'})
        end
        
    end
end

%% close interaction比较baseline和during 2s，全局做单点检验
start_x = 0.55;
start_y = 0.28;

box_x = 0.18;
box_y = 0.1;

inter_y = 0.01; 

close_cell = state_change_cell(1,:)';
far_cell = state_change_cell(2,:)';
all_cell = state_change_cell(3,:)';

bar_w = 0.6;
cap_size = 2;

x_bias = bar_w/2;

x_list = 1:4;

show_xtick_label = {...
    'Baseline close 2s';...
    'During close 2s';...
    'Baseline all 2s';...
    'During all 2s'};

show_star = {...
    0.05,1.1,'ns';...
    0.01,0.05,'*';...
    0.001,0.01,'**';...
    0.0001,0.001,'***';...
    0,0.0001,'****'};

n_p_mat = zeros(3,6);

for m = 1:3
    %%
    sel_close = close_cell{m};
    sel_all = all_cell{m};

    baseline_data_close = zeros(size(sel_close,1),1);
    during_data_close = baseline_data_close;

    for k = 1:size(sel_close,1)
        sel_data = sel_close{k};
        baseline_data_close(k,1) = mean(sel_data(1:60));
        during_data_close(k,1) = mean(sel_data(61:120));
    end

    mean_baseline_data_close = mean(baseline_data_close);
    std_baseline_data_close = std(baseline_data_close)./...
        sqrt(length(baseline_data_close));

    mean_during_data_close = mean(during_data_close);
    std_during_data_close = std(during_data_close)./...
        sqrt(length(during_data_close));

    baseline_data_all = zeros(size(sel_all,1),1);
    during_data_all = baseline_data_all;

    for k = 1:size(sel_all,1)
        sel_data = sel_all{k};
        baseline_data_all(k,1) = mean(sel_data(1:60));
        during_data_all(k,1) = mean(sel_data(61:120));
    end

    mean_baseline_data_all = mean(baseline_data_all);
    std_baseline_data_all = std(baseline_data_all)./...
        sqrt(length(baseline_data_all));

    mean_during_data_all = mean(during_data_all);
    std_during_data_all = std(during_data_all)./...
        sqrt(length(during_data_all));

    show_bar_mean = [...
        mean_baseline_data_close,...
        mean_during_data_close,...
        mean_baseline_data_all,...
        mean_during_data_all];

    show_bar_std = [...
        std_baseline_data_close,...
        std_during_data_close,...
        std_baseline_data_all,...
        std_during_data_all];

    show_data = {...
        baseline_data_close,...
        during_data_close,...
        baseline_data_all,...
        during_data_all};

    show_close_data = [baseline_data_close,during_data_close];
    show_all_data = [baseline_data_all,during_data_all];

    %% stat
    seldata = show_close_data;
    [h_dist,p_dist] =kstest([seldata(:,1),seldata(:,2)]);
    p_var = vartestn(...
        [seldata(:,1),seldata(:,2)]','Display','off');
    if p_var>=0.05 && h_dist==0
        % normal distribution, equal variances
        [~,p_value] = ttest(seldata(:,1),seldata(:,2));
        disp('t-test')
    else
        % not normal distribution, not equal variances
        p_value = ranksum(seldata(:,1),seldata(:,2));
        disp('rank sum')
    end
    p_value_close = p_value;

    sel_star_idx = (cell2mat(show_star(:,1))<=p_value)&...
                        (p_value<cell2mat(show_star(:,2)));
            
    selstar_close = show_star{sel_star_idx,3};

    seldata = show_all_data;
    [h_dist,p_dist] =kstest([seldata(:,1),seldata(:,2)]);
    p_var = vartestn(...
        [seldata(:,1),seldata(:,2)]','Display','off');
    if p_var>=0.05 && h_dist==0
        % normal distribution, equal variances
        [~,p_value] = ttest(seldata(:,1),seldata(:,2));
        disp('t-test')
    else
        % not normal distribution, not equal variances
        p_value = ranksum(seldata(:,1),seldata(:,2));
        disp('rank sum')
    end
    p_value_all = p_value;

    sel_star_idx = (cell2mat(show_star(:,1))<=p_value)&...
                        (p_value<cell2mat(show_star(:,2)));
            
    selstar_all = show_star{sel_star_idx,3};

    n_p_mat(m,1) = p_value_close;
    n_p_mat(m,2) = p_value_all;
    n_p_mat(m,3) = size(show_close_data,1);
    n_p_mat(m,4) = size(show_close_data,1);
    n_p_mat(m,5) = size(show_all_data,1);
    n_p_mat(m,6) = size(show_all_data,1);
    %% show
    subplot('Position',[...
        start_x,...
        start_y-(m-1)*(box_y+inter_y),...
        box_x,box_y])
    bar(x_list,show_bar_mean,bar_w,...
        'FaceColor',0.7*ones(1,3))
    hold on
    errorbar(x_list,show_bar_mean,...
        show_bar_std,'CapSize',cap_size,...
        'Color','k','LineStyle','none')
    hold on
    for k = 1:size(show_close_data,1)
        plot([1,2]+x_bias,show_close_data(k,:),...
            '-k','LineWidth',0.25)
        hold on
    end
    for k = 1:size(show_all_data,1)
        plot([3,4]+x_bias,show_all_data(k,:),...
            '-k','LineWidth',0.25)
        hold on
    end
    for k = 1:size(show_data,2)
        plot(x_bias+...
            x_list(k)*ones(1,length(show_data{k})),...
            show_data{k},'o',...
            'MarkerFaceColor','w',...
            'LineWidth',0.25,...
            'MarkerEdgeColor','k',...
            'MarkerSize',2)
        hold on
    end

    % show star
    if ~strcmp(selstar_close,'ns')
        plot([1,2],[1.1,1.1],'-k')
        hold on
        text(1.5,1.1,selstar_close,...
            'VerticalAlignment','bottom',...
            'HorizontalAlignment','center')
        hold on
    end

    if ~strcmp(selstar_all,'ns')
        plot([3,4],[1.1,1.1],'-k')
        hold on
        text(3.5,1.1,selstar_all,...
            'VerticalAlignment','bottom',...
            'HorizontalAlignment','center')
        hold on
    end
    hold off

    axis([0.3,4.7,0,1.4])

    box off

    if m == 3
        set(gca,'XTickLabel',show_xtick_label)
    else
        set(gca,'XTickLabel',[])
    end

    set(gca,'YTick',[0,1])

    ylabel({'Percentage of','close distance'})

    set(gca,'FontSize',6)
    set(gca,'TickDir','out')
end

%% after interaction比较baseline和during 1s，也比较和图3的cluster比例
%% pca
rmpath(['Z:\hanyaning\multi_mice_test\Social_analysis\' ...
    'code\SBeA_Analysis\SBeA_v0.0.1\TPM\figs\function\' ...
    'gtw\lib\subspace']);
rmpath(['Z:\hanyaning\multi_mice_test\Social_analysis\' ...
    'code\SBeA_Analysis\SBeA_v0.0.1\TPM\figs\old\function\' ...
    'gtw\lib\subspace']);

pca_cell = cell(size(sort_cf_cell,1),1);

for k = 1:size(pca_cell,1)
    tempneu = sort_cf_cell{k,2};
    [coeff, score, ~, ~, explained] = pca(tempneu');
    pca_cell{k,1} = {coeff,score,...
        explained,cumsum(explained)};
    disp(k)
end

%% dtak sparate two clusters of PC
pc_dist_mat = zeros(size(pca_cell,1),size(pca_cell,1));

sel_pc_dim = 3;

for m = 1:size(pc_dist_mat,1)
    temppc1 = pca_cell{m}{1}(:,1:sel_pc_dim)';
    for n = m:size(pc_dist_mat,2)
        temppc2 = pca_cell{n}{1}(:,1:sel_pc_dim)';
        condist_mat = conDist(temppc1,temppc2);
		Kdistmat = conKnl(...
            condist_mat, 'g', 'nei');

        wFs1 = ones(1,size(Kdistmat,1));
		wFs2 = ones(1,size(Kdistmat,2));
		[T,~,~] = dtakFord(Kdistmat,0,wFs1,wFs2);

        pc_dist_mat(m,n) = T;
    end

    disp(m)
end

% fill full matrix
pc_dist_mat_all = pc_dist_mat + triu(pc_dist_mat, 1)';

% clustering
n_clus = 2;
D = pdist(pc_dist_mat_all,'seuclidean');
Z = squareform(D);
tree = linkage(Z, 'ward','euclidean');
T = cluster(tree,'maxclust',n_clus);

%%
start_x = 0.76;
start_y = 0.28;

box_x = 0.23;
box_y = 0.1;

inter_y = 0.01; 

x_list = 1:5;

show_xtick_label = {...
    'Bifurcated behavior';...
    'Baseline far 1s';...
    'During far 1s';...
    'Baseline all 1s';...
    'During all 1s'};

show_star = {...
    0.05,1.1,'ns';...
    0.01,0.05,'*';...
    0.001,0.01,'**';...
    0.0001,0.001,'***';...
    0,0.0001,'****'};

% split brain area T
spl_name = split(sort_cf_cell(:,1),'-');

brain_name_list = cellfun(@(x) x(2:end),...
    spl_name(:,3),'UniformOutput',false);

data_brain_name = {...
    'tpmss';...
    'tpmpfc';...
    'tpmm'};

brain_clus_perc = zeros(size(data_brain_name));

for k = 1:size(data_brain_name,1)
    selidx = strcmp(data_brain_name{k},brain_name_list);
    sel_clus = T(selidx);
    tab_sel_T = tabulate(sel_clus);

    brain_clus_perc(k) = max(tab_sel_T(:,3))/100;
end

n_p_far_mat = zeros(3,7);

%
for m = 1:3
    %%
    sel_far = far_cell{m};
    sel_all = all_cell{m};

    baseline_data_far = zeros(size(sel_far,1),1);
    during_data_far = baseline_data_far;

    for k = 1:size(sel_far,1)
        sel_data = sel_far{k};
        baseline_data_far(k,1) = mean(sel_data(1:30));
        during_data_far(k,1) = mean(sel_data(31:60));
    end

    mean_baseline_data_far = mean(baseline_data_far);
    std_baseline_data_far = std(baseline_data_far)./...
        sqrt(length(baseline_data_far));

    mean_during_data_far = mean(during_data_far);
    std_during_data_far = std(during_data_far)./...
        sqrt(length(during_data_far));

    baseline_data_all = zeros(size(sel_all,1),1);
    during_data_all = baseline_data_all;

    for k = 1:size(sel_all,1)
        sel_data = sel_all{k};
        baseline_data_all(k,1) = mean(sel_data(1:30));
        during_data_all(k,1) = mean(sel_data(31:60));
    end

    mean_baseline_data_all = mean(baseline_data_all);
    std_baseline_data_all = std(baseline_data_all)./...
        sqrt(length(baseline_data_all));

    mean_during_data_all = mean(during_data_all);
    std_during_data_all = std(during_data_all)./...
        sqrt(length(during_data_all));

    show_bar_mean = [...
        mean_baseline_data_far,...
        mean_during_data_far,...
        mean_baseline_data_all,...
        mean_during_data_all];

    show_bar_std = [...
        std_baseline_data_far,...
        std_during_data_far,...
        std_baseline_data_all,...
        std_during_data_all];

    show_data = {...
        baseline_data_far,...
        during_data_far,...
        baseline_data_all,...
        during_data_all};

    show_far_data = [baseline_data_far,during_data_far];
    show_all_data = [baseline_data_all,during_data_all];

    %% stat
    seldata = show_far_data;
    [h_dist,p_dist] =kstest([seldata(:,1),seldata(:,2)]);
    p_var = vartestn(...
        [seldata(:,1),seldata(:,2)]','Display','off');
    if p_var>=0.05 && h_dist==0
        % normal distribution, equal variances
        [~,p_value] = ttest(seldata(:,1),seldata(:,2));
        disp('t-test')
    else
        % not normal distribution, not equal variances
        p_value = ranksum(seldata(:,1),seldata(:,2));
        disp('rank sum')
    end
    p_value_far = p_value;

    sel_star_idx = (cell2mat(show_star(:,1))<=p_value)&...
                        (p_value<cell2mat(show_star(:,2)));
            
    selstar_far = show_star{sel_star_idx,3};

    seldata = show_all_data;
    [h_dist,p_dist] =kstest([seldata(:,1),seldata(:,2)]);
    p_var = vartestn(...
        [seldata(:,1),seldata(:,2)]','Display','off');
    if p_var>=0.05 && h_dist==0
        % normal distribution, equal variances
        [~,p_value] = ttest(seldata(:,1),seldata(:,2));
        disp('t-test')
    else
        % not normal distribution, not equal variances
        p_value = ranksum(seldata(:,1),seldata(:,2));
        disp('rank sum')
    end
    p_value_all = p_value;

    sel_star_idx = (cell2mat(show_star(:,1))<=p_value)&...
                        (p_value<cell2mat(show_star(:,2)));
            
    selstar_all = show_star{sel_star_idx,3};
    %% stat single value
    % normal distribution, equal variances
    [~,p_value] = ttest(show_far_data(:,1),brain_clus_perc(m));
    disp('t-test')

    p_value_single = p_value;

    sel_star_idx = (cell2mat(show_star(:,1))<=p_value)&...
                        (p_value<cell2mat(show_star(:,2)));
            
    selstar_single = show_star{sel_star_idx,3};

    n_p_far_mat(m,1) = p_value_single;
    n_p_far_mat(m,2) = p_value_far;
    n_p_far_mat(m,3) = p_value_all;
    n_p_far_mat(m,4) = size(show_far_data,1);
    n_p_far_mat(m,5) = size(show_far_data,1);
    n_p_far_mat(m,6) = size(show_all_data,1);
    n_p_far_mat(m,7) = size(show_all_data,1);
    %% show
    subplot('Position',[...
        start_x,...
        start_y-(m-1)*(box_y+inter_y),...
        box_x,box_y])
    bar(x_list(1),brain_clus_perc(m),bar_w,...
        'FaceColor',0.7*ones(1,3))
    hold on
    bar(x_list(2:end),show_bar_mean,bar_w,...
        'FaceColor',0.7*ones(1,3))
    hold on
    errorbar(x_list(2:end),show_bar_mean,...
        show_bar_std,'CapSize',cap_size,...
        'Color','k','LineStyle','none')
    hold on
    for k = 1:size(show_far_data,1)
        plot([2,3]+x_bias,show_far_data(k,:),...
            '-k','LineWidth',0.25)
        hold on
    end
    for k = 1:size(show_all_data,1)
        plot([4,5]+x_bias,show_all_data(k,:),...
            '-k','LineWidth',0.25)
        hold on
    end
    for k = 2:(size(show_data,2)+1)
        plot(x_bias+...
            x_list(k)*ones(1,length(show_data{k-1})),...
            show_data{k-1},'o',...
            'MarkerFaceColor','w',...
            'LineWidth',0.25,...
            'MarkerEdgeColor','k',...
            'MarkerSize',2)
        hold on
    end
    plot([0,2.3],[brain_clus_perc(m),brain_clus_perc(m)],...
        '--k')
    hold on

    % show star
    disp(p_value_single)
    if ~strcmp(selstar_single,'ns')
        plot([1,2],[1,1],'-k')
        hold on
        text(1.5,1,selstar_single,...
            'VerticalAlignment','bottom',...
            'HorizontalAlignment','center')
        hold on
    end

    if ~strcmp(selstar_far,'ns')
        plot([2,3],[1.2,1.2],'-k')
        hold on
        text(2.5,1.2,selstar_far,...
            'VerticalAlignment','bottom',...
            'HorizontalAlignment','center')
        hold on
    end

    if ~strcmp(selstar_all,'ns')
        plot([4,5],[1.2,1.2],'-k')
        hold on
        text(4.5,1.2,selstar_all,...
            'VerticalAlignment','bottom',...
            'HorizontalAlignment','center')
        hold on
    end
    hold off

    axis([0.3,5.7,0,1.4])

    box off

    if m == 3
        set(gca,'XTickLabel',show_xtick_label)
    else
        set(gca,'XTickLabel',[])
    end
    
    set(gca,'XTick',x_list)

    set(gca,'YTick',[0,brain_clus_perc(m),1])
    set(gca,'YTickLabel',{0,num2str(brain_clus_perc(m),2),1})

    set(gca,'FontSize',6)
    set(gca,'TickDir','out')
end





















