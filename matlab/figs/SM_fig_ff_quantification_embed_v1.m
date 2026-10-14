%{
    flow field quantification

    看embedding
    
    只有日期的：far close far
    far_baseline_time = 2
    far_after_time = 2
    close_min_time = 2

    close_far: close far
    close_baseline_time = 1
    close_after_time = 0
    far_min_time = 5
    
    
    all:一万八一分，90000/5，每个脑区10分钟数据

    轮廓系数只比较最大的far close far-close和其他的显著性
%}
clear all
close all
addpath(genpath(pwd))
%% set path
rootpath = ['E:\MTPM_body_language'];
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

%% plot canvas
hall = figure(1);
set(hall,'Position',[680,0,800,800])
set(hall,'color','white');

%% show, time label
fs = 30;

time_len = 60*10;

frame_len = fs*time_len;

far_baseline_time = 2;
far_after_time = 2;
close_min_time = 2;

close_baseline_time = 1;
close_after_time = 0;
far_min_time = 5;

start_x = 0.04;
start_y = 0.84;

box_x = 0.12;
box_y = box_x;

inter_x = 0.005;
inter_y = 0.005;

quv_cmap = cbrewer2('Paired',10);

quv_cmap_list = [quv_cmap(3,:);quv_cmap(2,:)*0.8];

time_cmap = flipud(cbrewer2('Spectral',256));

% quv_cmap_list = [...
%     0,0,0.7;...
%     0.7,0,0];

show_title = {...
    'S1';...
    'dmPFC';...
    'M1'};

show_cond_title = {...
    'Far close far';...
    'Close far';...
    'All'};

dot_size = 0.5;

sh_idx = 1.1;

for m = 1:size(brain_dy_cell,1)
    for n = 1:size(brain_dy_cell,2)
        %%
        temps = brain_dy_cell{m,n};

        temp_dist = double(temps.z_dist)';
        
        temp_x = temps.xhat_dist_lem;

        min_x = min(temp_x(:,1));
        max_x = max(temp_x(:,1));
        min_y = min(temp_x(:,2));
        max_y = max(temp_x(:,2));
        
        if m == 1
            diff_dist = [0;diff(temp_dist)];
            start_idx = find(diff_dist==1)-...
                far_baseline_time*fs;
            end_idx = find(diff_dist==-1)+...
                far_baseline_time*fs-2;

            embed_cell = cell(size(start_idx,1),2);

            for k = 1:size(embed_cell,1)
                embed_cell{k,1} = temp_x(...
                    start_idx(k,1):end_idx(k,1),:);
                embed_cell{k,2} = temp_dist(...
                    start_idx(k,1):end_idx(k,1),:);
            end
        elseif m == 2
            diff_dist = [0;diff(temp_dist)];
            start_idx = find(diff_dist==1)-...
                close_baseline_time*fs;
            end_idx = [start_idx(2:end,:)-1;length(temp_dist)];

            embed_cell = cell(size(start_idx,1),2);

            for k = 1:size(embed_cell,1)
                embed_cell{k,1} = temp_x(...
                    start_idx(k,1):end_idx(k,1),:);
                embed_cell{k,2} = temp_dist(...
                    start_idx(k,1):end_idx(k,1),:);
            end

            embed_cell = embed_cell(1:5:end,:);
        elseif m == 3
            start_idx = (1:(fs*10*60):length(temp_dist))';
            end_idx = [start_idx(2:end,:)-1;length(temp_dist)];

            embed_cell = cell(size(start_idx,1),2);

            for k = 1:size(embed_cell,1)
                embed_cell{k,1} = temp_x(...
                    start_idx(k,1):end_idx(k,1),:);
                embed_cell{k,2} = temp_dist(...
                    start_idx(k,1):end_idx(k,1),:);
            end

            % embed_cell = embed_cell(1,:);
        end
        %%
        subplot('Position',[...
            start_x+(m-1)*(box_x+inter_x),...
            start_y-(n-1)*(box_y+inter_y),...
            box_x,box_y])

        for k = 1:size(embed_cell,1)
            tempembed = embed_cell{k,1};
            tempdist = embed_cell{k,2};
            plot(tempembed(:,1),tempembed(:,2),...
                '-','Color',0.7*ones(1,3),...
                'LineWidth',0.25)
            hold on
            % scatter(tempembed(:,1),tempembed(:,2),...
            %     dot_size*ones(size(tempembed,1),1),...
            %     quv_cmap_list(tempdist+1,:),...
            %     'filled')
            scatter(tempembed(:,1),tempembed(:,2),...
                dot_size*ones(size(tempembed,1),1),...
                imresize(time_cmap,[size(tempembed,1),3]),...
                'filled')
            hold on
        end
        hold off

        box on

        axis([min_x,max_x,min_y,max_y]*sh_idx)

        set(gca,'XTick',[],'YTick',[])

        if m == 1
            ylabel({show_title{n},'Latent 2'})
        end

        if n == 1
            title(show_cond_title{m})
        end

        if n == 3
            xlabel('Latent 1')
        end

        set(gca,'FontSize',6)
    end
end


%% show, z_dist label
fs = 30;

time_len = 60*10;

frame_len = fs*time_len;

far_baseline_time = 2;
far_after_time = 2;
close_min_time = 2;

close_baseline_time = 1;
close_after_time = 0;
far_min_time = 5;

start_x = 0.43;
start_y = 0.84;

box_x = 0.12;
box_y = box_x;

inter_x = 0.005;
inter_y = 0.005;

quv_cmap = cbrewer2('Paired',10);

quv_cmap_list = [quv_cmap(3,:);quv_cmap(2,:)*0.8];

time_cmap = flipud(cbrewer2('Spectral',256));

% quv_cmap_list = [...
%     0,0,0.7;...
%     0.7,0,0];

show_title = {...
    'S1';...
    'dmPFC';...
    'M1'};

show_cond_title = {...
    'Far close far';...
    'Close far';...
    'All'};

dot_size = 0.5;

sh_idx = 1.1;

for m = 1:size(brain_dy_cell,1)
    for n = 1:size(brain_dy_cell,2)
        %%
        temps = brain_dy_cell{m,n};

        temp_dist = double(temps.z_dist)';
        
        temp_x = temps.xhat_dist_lem;

        min_x = min(temp_x(:,1));
        max_x = max(temp_x(:,1));
        min_y = min(temp_x(:,2));
        max_y = max(temp_x(:,2));
        
        if m == 1
            diff_dist = [0;diff(temp_dist)];
            start_idx = find(diff_dist==1)-...
                far_baseline_time*fs;
            end_idx = find(diff_dist==-1)+...
                far_baseline_time*fs-2;

            embed_cell = cell(size(start_idx,1),2);

            for k = 1:size(embed_cell,1)
                embed_cell{k,1} = temp_x(...
                    start_idx(k,1):end_idx(k,1),:);
                embed_cell{k,2} = temp_dist(...
                    start_idx(k,1):end_idx(k,1),:);
            end
        elseif m == 2
            diff_dist = [0;diff(temp_dist)];
            start_idx = find(diff_dist==1)-...
                close_baseline_time*fs;
            end_idx = [start_idx(2:end,:)-1;length(temp_dist)];

            embed_cell = cell(size(start_idx,1),2);

            for k = 1:size(embed_cell,1)
                embed_cell{k,1} = temp_x(...
                    start_idx(k,1):end_idx(k,1),:);
                embed_cell{k,2} = temp_dist(...
                    start_idx(k,1):end_idx(k,1),:);
            end

            embed_cell = embed_cell(1:5:end,:);
        elseif m == 3
            start_idx = (1:(fs*10*60):length(temp_dist))';
            end_idx = [start_idx(2:end,:)-1;length(temp_dist)];

            embed_cell = cell(size(start_idx,1),2);

            for k = 1:size(embed_cell,1)
                embed_cell{k,1} = temp_x(...
                    start_idx(k,1):end_idx(k,1),:);
                embed_cell{k,2} = temp_dist(...
                    start_idx(k,1):end_idx(k,1),:);
            end

            % embed_cell = embed_cell(1,:);
        end
        %%
        subplot('Position',[...
            start_x+(m-1)*(box_x+inter_x),...
            start_y-(n-1)*(box_y+inter_y),...
            box_x,box_y])

        for k = 1:size(embed_cell,1)
            tempembed = embed_cell{k,1};
            tempdist = embed_cell{k,2};
            plot(tempembed(:,1),tempembed(:,2),...
                '-','Color',0.7*ones(1,3),...
                'LineWidth',0.25)
            hold on
            scatter(tempembed(:,1),tempembed(:,2),...
                dot_size*ones(size(tempembed,1),1),...
                quv_cmap_list(tempdist+1,:),...
                'filled')
            % scatter(tempembed(:,1),tempembed(:,2),...
            %     dot_size*ones(size(tempembed,1),1),...
            %     imresize(time_cmap,[size(tempembed,1),3]),...
            %     'filled')
            hold on
        end
        hold off

        box on

        axis([min_x,max_x,min_y,max_y]*sh_idx)

        set(gca,'XTick',[],'YTick',[])

        % if m == 1
        %     ylabel({show_title{n},'Latent 2'})
        % end

        if n == 1
            title(show_cond_title{m})
        end

        set(gca,'FontSize',6)

        if n == 3
            xlabel('Latent 1')
        end
    end
end

%% show silhouette coefficient  
temp_dist_cell = cellfun(@(x) double(x.z_dist)',...
    brain_dy_cell,'UniformOutput',false);

temp_x_cell = cellfun(@(x) x.xhat_dist_lem,...
    brain_dy_cell,'UniformOutput',false);

s_cell = cellfun(@(x,y) silhouette(x,y),...
    temp_x_cell,temp_dist_cell,...
    'UniformOutput',false);


%% show
start_x = 0.86;
start_y = 0.84;

box_x = 0.12;
box_y = box_x;

bar_w = 0.6;

mk_size = 2;

cap_size = 2;

x_bias = 0.3;

show_star = {...
    0.05,1.1,'ns';...
    0.01,0.05,'*';...
    0.001,0.01,'**';...
    0.0001,0.001,'***';...
    0,0.0001,'****'};

show_xtick = {...
    'Far close far-far';...
    'Far close far-close';...
    'Close far-far';...
    'Close far-close';...
    'All-close';...
    'All-far'};

stat_cell = cell(1,size(brain_dy_cell,2));

for m = 1:size(brain_dy_cell,2)
    %%
    subplot('Position',[...
        start_x,...
        start_y-(m-1)*(box_y+inter_y),...
        box_x,box_y])
    
    
    b11 = s_cell{1,m}(temp_dist_cell{1,m}==0);
    b12 = s_cell{1,m}(temp_dist_cell{1,m}==1);

    b21 = s_cell{2,m}(temp_dist_cell{2,m}==0);
    b22 = s_cell{2,m}(temp_dist_cell{2,m}==1);

    b31 = s_cell{3,m}(temp_dist_cell{3,m}==0);
    b32 = s_cell{3,m}(temp_dist_cell{3,m}==1);

    rng(1234)

    sel_num = 100;

    b11 = b11(randperm(length(b11), sel_num));
    b12 = b12(randperm(length(b12), sel_num));

    b21 = b21(randperm(length(b21), sel_num));
    b22 = b22(randperm(length(b22), sel_num));

    b31 = b31(randperm(length(b31), sel_num));
    b32 = b32(randperm(length(b32), sel_num));

    mean_b11 = mean(b11);
    mean_b12 = mean(b12);

    mean_b21 = mean(b21);
    mean_b22 = mean(b22);

    mean_b31 = mean(b31);
    mean_b32 = mean(b32);

    std_b11 = std(b11)./sqrt(size(b11,1));
    std_b12 = std(b12)./sqrt(size(b12,1));

    std_b21 = std(b21)./sqrt(size(b21,1));
    std_b22 = std(b22)./sqrt(size(b22,1));

    std_b31 = std(b31)./sqrt(size(b31,1));
    std_b32 = std(b32)./sqrt(size(b32,1));

    bar_b = [...
        mean_b11,mean_b12,...
        mean_b21,mean_b22,...
        mean_b31,mean_b32];

    err_b = [...
        std_b11,std_b12,...
        std_b21,std_b22,...
        std_b31,std_b32];

    data_b = [...
        b11,b12,...
        b21,b22,...
        b31,b32];

    %% compare
    stat_x = [...
        data_b(:,1);...
        data_b(:,2);...
        data_b(:,3);...
        data_b(:,4);...
        data_b(:,5);...
        data_b(:,6);...
        ];

    stat_y = [...
        1*ones(100,1);...
        2*ones(100,1);...
        3*ones(100,1);...
        4*ones(100,1);...
        5*ones(100,1);...
        6*ones(100,1);...
        ];

    [~,~,stats] = anova1(stat_x,stat_y,'off');
    results = multcompare(stats,'Display','off');

    stat_cell{m} = results;

    disp(results([1,6,7,8,9],[1,2,6]))
    %% show
    bar(1:6,bar_b,bar_w,...
        'FaceColor',0.7*ones(1,3))
    hold on
    errorbar(1:6,bar_b,err_b,...
        'CapSize',cap_size,...
        'LineStyle','none',...
        'Color','k')
    hold on
    for k = 1:size(data_b,1)
        plot((1:6)+x_bias,data_b(k,:),'o',...
            'MarkerFaceColor','w',...
            'MarkerEdgeColor','k',...
            'LineWidth',0.25,...
            'MarkerSize',2)
        hold on
    end
    hold off

    box off
    set(gca,'TickDir','out')
    set(gca,'FontSize',6)

    ylabel('Silhouette coefficient')

    axis([0.3,6.7,-1,1])

    if m ~= 3
        set(gca,'XTickLabel',[])
    else
        set(gca,'XTickLabel',show_xtick)
    end

    
end









