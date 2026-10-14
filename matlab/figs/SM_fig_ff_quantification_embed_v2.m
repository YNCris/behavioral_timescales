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

%% plot canvas
hall = figure(1);
set(hall,'Position',[880,100,800,800])
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

embed_all_cell = cell(size(brain_dy_cell));

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

        embed_all_cell{m,n} = embed_cell(:,1);
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

%% 构造庞加莱截面
inter_p_cell = cell(size(brain_dy_cell));
for m = 1:size(brain_dy_cell,1)
    for n = 1:size(brain_dy_cell,2)
        %% load data
        tempembed = embed_all_cell{m,n};
        %% 交点计算
        inter_x_all = [];
        inter_y_all = [];
        for k = 1:size(tempembed,1)
            %% 
            tempxy = tempembed{k,1};
            tempx = tempembed{k,1}(:,1);
            tempy = tempembed{k,1}(:,2);

            idx_x = find(tempx(1:end-1) .* tempx(2:end) < 0);
            idx_y = find(tempy(1:end-1) .* tempy(2:end) < 0);

            %% inter
            inter_list_x = zeros(size(idx_x,1),2);

            for p = 1:size(inter_list_x,1)
                P1 = tempxy(idx_x(p),:);
                P2 = tempxy(idx_x(p)+1,:);

                P3 = [0,1];
                P4 = [0,-1];
                
                inter_list_x(p,:) = line_inter(P1,P2,P3,P4);
            end

            inter_list_y = zeros(size(idx_y,1),2);

            for p = 1:size(inter_list_y,1)
                P1 = tempxy(idx_y(p),:);
                P2 = tempxy(idx_y(p)+1,:);

                P3 = [1,0];
                P4 = [-1,0];
                
                inter_list_y(p,:) = line_inter(P1,P2,P3,P4);
            end

            inter_x_all = [inter_x_all;inter_list_x];
            inter_y_all = [inter_y_all;inter_list_y];
        end
        inter_p_cell{m,n} = {inter_x_all,inter_y_all};
    end  
end


%% 庞加莱截面分布
start_x = 0.04;
start_y = 0.46;

box_x = 0.12;
box_y = 0.045;

inter_x = 0.005;
inter_y = 0.005;

big_inter_y = 0.01;

mk_size = 2;

for m = 1:size(inter_p_cell,1)
    for n = 1:size(inter_p_cell,2)
        %% load data
        inter_p_x = inter_p_cell{m,n}{1}(:,2);
        inter_p_y = inter_p_cell{m,n}{2}(:,1);
        %% show
        % x
        subplot('Position',[...
            start_x+(m-1)*(box_x+inter_x),...
            start_y-(n-1)*2*(box_y+big_inter_y)+box_y+inter_y,...
            box_x,box_y])
        plot(sort(inter_p_x),'o',...
            'MarkerFaceColor','w',...
            'MarkerEdgeColor','k',...
            'MarkerSize',mk_size)

        min_x = min(inter_p_x);
        max_x = max(inter_p_x);

        axis([1,length(inter_p_x),min_x,max_x])

        set(gca,'XTick',[],'YTick',[])
        set(gca,'FontSize',6)
        box off

        if m == 1
            ylabel({show_title{n},'x=0'})
        end


        % y
        subplot('Position',[...
            start_x+(m-1)*(box_x+inter_x),...
            start_y-(n-1)*2*(box_y+big_inter_y),box_x,box_y])
        plot(sort(inter_p_y),'o',...
            'MarkerFaceColor','w',...
            'MarkerEdgeColor','k',...
            'MarkerSize',mk_size)

        min_y = min(inter_p_y);
        max_y = max(inter_p_y);

        axis([1,length(inter_p_y),min_y,max_y])
        
        set(gca,'XTick',[],'YTick',[])
        set(gca,'FontSize',6)
        box off

        if m == 1
            ylabel('y=0')
        end

        if n == 3
            xlabel({'Min               Max','Rank'})
        end
    end
end

%% 局部量化庞加莱截面随机程度
start_x = 0.45;
start_y = 0.46;

box_x = 0.105;
box_y = 0.045;

inter_x = 0.015;
inter_y = 0.005;

big_inter_y = 0.01;

mk_size = 2;

bw_cell = cell(size(inter_p_cell));
ent_cell = cell(size(inter_p_cell));

for m = 1:size(inter_p_cell,1)
    for n = 1:size(inter_p_cell,2)
        %% load data
        inter_p_x = inter_p_cell{m,n}{1}(:,2);
        inter_p_y = inter_p_cell{m,n}{2}(:,1);

        sort_inter_p_x = sort(inter_p_x);
        sort_inter_p_y = sort(inter_p_y);

        sort_inter_p_x = sort_inter_p_x-mean(sort_inter_p_x);
        sort_inter_p_y = sort_inter_p_y-mean(sort_inter_p_y);
        %% entropy
        norm_x = mat2gray(sort_inter_p_x);
        p_norm_x = norm_x./sum(norm_x);
        ent_x = -sum(norm_x.*log2(norm_x+eps));

        norm_y = mat2gray(sort_inter_p_y);
        p_norm_y = norm_y./sum(norm_y);
        ent_y = -sum(norm_y.*log2(norm_y+eps));

        ent_cell{m,n} = [ent_x,ent_y];
        %% psd
        Fs = 1;
        [pxx_x, f_x] = pwelch(sort_inter_p_x, [], [], [], Fs);
        [pxx_y, f_y] = pwelch(sort_inter_p_y, [], [], [], Fs);
        
        pxx_x = pxx_x / sum(pxx_x);%归一化
        spec_entropy_x = -sum(pxx_x .* log2(pxx_x + eps));  % 谱熵
        
        % 1. Spectral centroid
        f_mean_x = sum(f_x .* pxx_x) / sum(pxx_x);
        
        % 2. Spectral bandwidth (RMS)
        bandwidth_x = sqrt(sum((f_x - f_mean_x).^2 .* pxx_x)...
            / sum(pxx_x));

        % 1. Spectral centroid
        f_mean_y = sum(f_y .* pxx_y) / sum(pxx_y);
        
        % 2. Spectral bandwidth (RMS)
        bandwidth_y = sqrt(sum((f_y - f_mean_y).^2 .* pxx_y)...
            / sum(pxx_y));

        bw_cell{m,n} = [bandwidth_x,bandwidth_y];
        %% show
        % x
        pxx_x = mat2gray(pxx_x);
        pxx_y = mat2gray(pxx_y);

        subplot('Position',[...
            start_x+(m-1)*(box_x+inter_x),...
            start_y-(n-1)*2*(box_y+big_inter_y)+box_y+inter_y,...
            box_x,box_y])
        area(f_x,pxx_x, 'FaceColor', 0.9*ones(1,3))
        hold on
        plot(f_x,pxx_x,'-k')
        hold on
        plot([bandwidth_x,bandwidth_x],...
            [0,max(pxx_x)],'-r')
        hold off
        % title(ent_x)
        
        axis([0,0.5,0,1.2])

        set(gca,'FontSize',6)

        box off
        set(gca,'TickDir','out')

        set(gca,'YTick',[0,1])
        set(gca,'XTick',[0,0.5])
        set(gca,'XTickLabel',[])

        if m == 1
        else
            set(gca,'YTickLabel',[])
        end

        if n == 2 && m == 1
            ylabel('Normalized power spectral density')
        end


        % y
        subplot('Position',[...
            start_x+(m-1)*(box_x+inter_x),...
            start_y-(n-1)*2*(box_y+big_inter_y),box_x,box_y])
        area(f_y,pxx_y, 'FaceColor', 0.9*ones(1,3))
        hold on
        plot(f_y,pxx_y,'-k')
        hold on
        plot([bandwidth_y,bandwidth_y],...
            [0,max(pxx_y)],'-r')
        hold off
        % title(ent_y)

        axis([0,0.5,0,1.2])

        set(gca,'FontSize',6)

        box off
        set(gca,'TickDir','out')

        set(gca,'YTick',[0,1])
        set(gca,'XTick',[0,0.5])
        set(gca,'XTickLabel',[])

        if m == 1
        else
            set(gca,'YTickLabel',[])
        end

        if n == 3
            set(gca,'XTickLabel',{0,'Max'})
            xlabel('Normalized frequency')
        end

    end
end

%% 比较庞加莱截面的熵
start_x = 0.86;
start_y = 0.38;

box_x = 0.12;
box_y = 0.12;

x_list = 1:3;

bar_w = 0.6;

x_bias = 0.3;

mk_size = 2;

cap_size = 2;

bar_fc = 0.7*ones(1,3);

ent_mat = cell2mat(ent_cell)';

mean_ent_mat = mean(ent_mat);

std_ent_mat = std(ent_mat)./sqrt(size(ent_mat,1));

subplot('Position',[start_x,start_y,box_x,box_y])
bar(x_list,mean_ent_mat,bar_w,...
    'FaceColor',bar_fc)
hold on
errorbar(x_list,mean_ent_mat,std_ent_mat,...
    'LineStyle','none',...
    'CapSize',cap_size,...
    'Color','k')
hold on
for k = 1:size(ent_mat,2)
    plot(x_bias+k*ones(size(ent_mat,1),1),ent_mat(:,k),...
        'o','LineWidth',0.25,...
        'MarkerFaceColor','w',...
        'MarkerEdgeColor','k',...
        'MarkerSize',mk_size)
    hold on
end
hold off

ylabel('Entropy')

set(gca,'XTickLabel',[])

axis([0.3,3.7,0,800])

box off
set(gca,'FontSize',6)
set(gca,'TickDir','out')

% 比较psd带宽
start_x = 0.86;
start_y = 0.24;

box_x = 0.12;
box_y = 0.12;

x_tick_label = {...
    'Close interaction';...
    'After interaction';...
    'All'};

bw_mat = cell2mat(bw_cell)';

mean_bw_mat = mean(bw_mat);

std_bw_mat = std(bw_mat)./sqrt(size(bw_mat,1));

subplot('Position',[start_x,start_y,box_x,box_y])
bar(x_list,mean_bw_mat,bar_w,...
    'FaceColor',bar_fc)
hold on
errorbar(x_list,mean_bw_mat,std_bw_mat,...
    'LineStyle','none',...
    'CapSize',cap_size,...
    'Color','k')
hold on
for k = 1:size(bw_mat,2)
    plot(x_bias+k*ones(size(bw_mat,1),1),bw_mat(:,k),...
        'o','LineWidth',0.25,...
        'MarkerFaceColor','w',...
        'MarkerEdgeColor','k',...
        'MarkerSize',mk_size)
    hold on
end
hold off

ylabel('Band width')

axis([0.3,3.7,0,0.17])

box off
set(gca,'FontSize',6)
set(gca,'TickDir','out')

set(gca,'XTickLabel',x_tick_label)








