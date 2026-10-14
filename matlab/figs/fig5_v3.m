%{
    rslds分析dynamic
%}
clear all
close all
addpath(genpath(pwd))
%% set path
rootpath = ['E:\MTPM_body_language'];
beh_neu_path = [rootpath,'\beh_neu_20240412'];
dy_path = [rootpath,'\dynamic_model_data_20241113'];

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

    brain_dy_cell{1,k} = tempmat_all;
    brain_dy_cell{2,k} = tempmat_close;
    brain_dy_cell{3,k} = tempmat_far;
end

%% split mouse trial from the first far-close
fs = 30;
baseline_far_time = 15;%s
cut_all_time = 10*60;%s

baseline_far_frame = baseline_far_time*fs;
cut_all_frame = cut_all_time*fs;

raw_trial_cell = {};

for k = 1:size(all_data_cell,1)
    %% load data
    tempdist = all_data_cell{k,9};
    
    %% select trials
    distsavelist = idx2savelist(tempdist{2});

    diff_len = distsavelist(:,2)-distsavelist(:,1)+1;

    far_idx = distsavelist(:,3)==0;

    diff_len_idx = diff_len>=baseline_far_frame;

    selidx = (diff_len_idx.*far_idx)==1;

    find_save_list = find(selidx,1,'first');

    sel_save_list = distsavelist(find_save_list:end,:);
    
    % modify to the same lengh of baseline
    sel_save_list(1,1) = sel_save_list(1,2)-baseline_far_frame+1;
    %% append data
    tempstart = sel_save_list(1,1);
    tempend = sel_save_list(1,1)+cut_all_frame-1;

    newname = [all_data_cell{k,1},'-cut'];
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
%% sort data by brain areas
sort_brain_name_list = {...
    '1tpmss';...
    '2tpmss';...
    '3tpmss';...
    '4tpmss';...
    '5tpmss';...
    '1tpmpfc';...
    '2tpmpfc';...
    '3tpmpfc';...
    '4tpmpfc';...
    '5tpmpfc';...
    '1tpmm';...
    '2tpmm';...
    '3tpmm';...
    '4tpmm';...
    '5tpmm';...
    };

splname1 = split(raw_trial_cell(:,1),'-');


sort_trial_cell = raw_trial_cell;

for k = 1:size(sort_brain_name_list,1)
    tempname = sort_brain_name_list{k,1};
    selidx = strcmp(tempname,splname1(:,3));
    sort_trial_cell(k,:) = raw_trial_cell(selidx,:);
end



%% plot canvas
hall = figure(1);
set(hall,'Position',[680,0,800,800])
set(hall,'color','white');

%% draw demo and data
start_x = 0.04;
start_y = 0.83;

box_x = 0.36;
box_y = 0.15;

inter_y = 0.025;

x_tick = [1,450,18000];
x_tick_label = [-15,0,585];

show_x_len = 18000;

% demo
subplot('Position',[start_x,start_y,box_x,box_y])

% % self mov
% 
% % create mov mat
pad_len = 27000;
self_mov_mat = -1*ones(size(sort_trial_cell,1),pad_len);
start_list = zeros(size(self_mov_mat,1),2);
end_list = zeros(size(self_mov_mat,1),2);

for k = 1:size(self_mov_mat,1)
    tempmov = cell2mat(sort_trial_cell{k,4}(:,2))';
    self_mov_mat(k,1:length(tempmov)) = tempmov;
    start_list(k,:) = [baseline_far_frame,k];
    end_list(k,:) = [length(tempmov),k];
end
% 
% temph = subplot('Position',[start_x,...
%     start_y-box_y-inter_y,box_x,box_y]);
% 
% imagesc(self_mov_mat)
% colormap(temph,[1,1,1;cmap_mov])
% hold on
% plot(start_list(:,1),start_list(:,2),'-k')
% % hold on
% % plot(end_list(:,1),end_list(:,2),'-k')
% hold off
% 
% box off
% % title('Self')
% 
% axis([0,show_x_len,0,size(self_mov_mat,1)])
% 
% ylabel('Self movements')
% 
% set(gca,'XTick',x_tick)
% set(gca,'XTickLabel',[])
% % set(gca,'XTickLabel',x_tick_label)
% 
% set(gca,'YTick',[1,size(self_mov_mat,1)])
% 
% set(gca,'TickDir','out')
% set(gca,'FontSize',6)
% xlabel('Time (s)')
% 
% % colorbar, mov
% cbar_box_x = 0.006;
% cbar_box_y = 0.05;
% 
% cbar_inter_x = 0.01;
% 
% temph = subplot('Position',[...
%     start_x+box_x+cbar_inter_x,...
%     start_y-box_y-inter_y+cbar_box_y,...
%     cbar_box_x,cbar_box_y]);
% imagesc(flipud((1:max(unique_mov))'))
% colormap(temph,cmap_mov)
% set(gca,'XTick',[],'YTick',[])
% 
% text(0.5,50,'1','FontSize',6,'VerticalAlignment','middle')
% text(0.5,-1,'49','FontSize',6,'VerticalAlignment','middle')
% 
% text(2.5,25,{'Movement','categories'},...
%     'FontSize',6,'Rotation',90,...
%     'HorizontalAlignment','center')
% 
% 
% 
% % partner mov
% 
% part_mov_mat = -1*ones(size(sort_trial_cell,1),pad_len);
% start_list = zeros(size(part_mov_mat,1),2);
% end_list = zeros(size(part_mov_mat,1),2);
% 
% for k = 1:size(part_mov_mat,1)
%     tempmov = cell2mat(sort_trial_cell{k,7}(:,2))';
%     part_mov_mat(k,1:length(tempmov)) = tempmov;
%     start_list(k,:) = [baseline_far_frame,k];
%     end_list(k,:) = [length(tempmov),k];
% end
% 
% temph = subplot('Position',[start_x,...
%     start_y-2*(box_y+inter_y),box_x,box_y]);
% 
% imagesc(part_mov_mat)
% colormap(temph,[1,1,1;cmap_mov])
% hold on
% plot(start_list(:,1),start_list(:,2),'-k')
% % hold on
% % plot(end_list(:,1),end_list(:,2),'-k')
% hold off
% 
% box off
% 
% axis([0,show_x_len,0,size(part_mov_mat,1)])
% 
% ylabel('Partner movements')
% 
% set(gca,'XTick',x_tick)
% set(gca,'XTickLabel',[])
% 
% set(gca,'YTick',[1,size(part_mov_mat,1)])
% % set(gca,'YTickLabel',[])
% 
% % title('Partner')
% set(gca,'TickDir','out')
% set(gca,'FontSize',6)
% xlabel('Time (s)')
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
    end_list(k,:) = [length(tempmov),k];
end

raw_pc_mat = pad_pc_mat(:,1:18000);

%% distance mat
dist_mat = zeros(size(raw_pc_mat));

for k = 1:size(sort_trial_cell,1)
    %%
    tempdist_str = sort_trial_cell{k,9};

    tempdist_idx = double(strcmp(tempdist_str,'close'));
    dist_mat(k,:) = tempdist_idx;
end
%%
cmap_neu = flipud(cbrewer2('RdBu',256));

neu_cmap = cbrewer2('Paired',12);

in_c = neu_cmap(5,:);
de_c = neu_cmap(1,:);
no_c = neu_cmap(3,:);


temph = subplot('Position',[start_x,...
    start_y-2*(box_y+inter_y),box_x,box_y]);
imagesc(dist_mat)
hold on
% plot pc 1
for k = 1:size(raw_pc_mat,1)
    plot(k+mat2gray(raw_pc_mat(k,:))-0.5,'-',...
        'Color',[0, 0.4470, 0.7410])
    hold on
end

hold on
for k = 1:2
    plot([0,18000],[k*5+0.5,k*5+0.5],'-k')
    hold on
end
hold on


colormap(temph,[1,1,1;in_c])

hold on
plot(start_list(:,1),start_list(:,2)-0.5,'-k')
% hold on
% plot(end_list(:,1),end_list(:,2),'-k')
hold off

axis([0,show_x_len,0,size(pad_pc_mat,1)+0.5])

box off

ylabel('Distance & PC 1')
xlabel('Time (s)')

set(gca,'XTick',x_tick)
set(gca,'XTickLabel',x_tick_label)

set(gca,'YTick',[3,8,13])
set(gca,'YTickLabel',{'S1','dmPFC','M1'})
set(gca,'YTickLabelRotation',90)

set(gca,'FontSize',6)
set(gca,'TickDir','out')

% % colorbar
% cbar_box_x = 0.006;
% cbar_box_y = 0.05;
% 
% cbar_inter_x = 0.01;
% 
% temph = subplot('Position',[...
%     start_x+box_x+cbar_inter_x,...
%     start_y-1*(box_y+inter_y)-inter_y-cbar_box_y,...
%     cbar_box_x,cbar_box_y]);
% imagesc(fliplr((1:256))')
% colormap(temph,cmap_neu)
% set(gca,'XTick',[],'YTick',[])
% 
% text(0.5,280,'0','FontSize',6,'VerticalAlignment','middle')
% text(0.5,-30,'1','FontSize',6,'VerticalAlignment','middle')
% 
% text(2.5,128,'PC coefficient','FontSize',6,'Rotation',90,...
%     'HorizontalAlignment','center')
% 
% set(gca,'FontSize',6)

%% neu (really slow)

neu_mat = [];
neu_start_list = [];
neu_end_list = [];

neu_idx = [];

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
            [length(ttneu),count]];

        count = count+1;
    end
    
    neu_mat = [neu_mat;padneu];
    neu_idx = [neu_idx;k*ones(size(padneu,1),1)];
end

%% show neu
diff_neu_idx = [1;diff(neu_idx)];

seg1_idx = find(((neu_idx==6).*diff_neu_idx)==1);
seg2_idx = find(((neu_idx==11).*diff_neu_idx)==1);

show_range = [-0.5,0.5];

cmap_neu = flipud(cbrewer2('RdBu',256));

temph = subplot('Position',[start_x,...
    start_y-1*(box_y+inter_y),box_x,box_y]);
imagesc(neu_mat,show_range)

hold on
plot([0,18000],[seg1_idx,seg1_idx],'-k')
hold on
plot([0,18000],[seg2_idx,seg2_idx],'-k')

colormap(temph,[1,1,1;cmap_neu])
hold on
plot(neu_start_list(:,1),neu_start_list(:,2),'-k')
% hold on
% plot(neu_end_list(:,1),neu_end_list(:,2),'-k')
hold off

box off

axis([0,show_x_len,0,size(neu_mat,1)])

set(gca,'FontSize',6)
set(gca,'TickDir','out')
set(gca,'XTick',x_tick)
set(gca,'XTickLabel',[])

ytick_list = [...
    (0+seg1_idx)/2,...
    (seg1_idx+seg2_idx)/2,...
    (seg2_idx+size(neu_mat,1))/2];

set(gca,'YTick',ytick_list)
set(gca,'YTickLabel',{'S1','dmPFC','M1'})
set(gca,'YTickLabelRotation',90)
% xlabel('Time (s)')
ylabel('Neural activities')

% colorbar
cbar_box_x = 0.006;
cbar_box_y = 0.05;

cbar_inter_x = 0.01;

temph = subplot('Position',[...
    start_x+box_x+cbar_inter_x,...
    start_y-0*(box_y+inter_y)-inter_y-cbar_box_y,...
    cbar_box_x,cbar_box_y]);
imagesc(flipud((1:256)'))
colormap(temph,cmap_neu)
set(gca,'XTick',[],'YTick',[])

text(0.5,280,'-0.5','FontSize',6,'VerticalAlignment','middle')
text(0.5,-30,'0.5','FontSize',6,'VerticalAlignment','middle')

text(2.5,128,'ΔF/F','FontSize',6,'Rotation',90,...
    'HorizontalAlignment','center')

%% show 9 flow field
start_x = 0.47;
start_y = 0.83;

box_x = 0.15;
box_y = 0.15;

inter_x = 0.025;
inter_y = inter_x;
        
% xlim_range = [-1,1];
% ylim_range = [-1,1];

nxpts = 15;
nypts = 15;

dist_y_label = {...
    'All';...
    'Close';...
    'Far'};

show_brain_name = {...
    'S1';...
    'dmPFC';...
    'M1'};

quv_cmap = cbrewer2('Set2',3);

quv_cmap_list = [quv_cmap(1,:);quv_cmap(3,:)];

for m = 1:size(brain_dy_cell,1)
    for n = 1:size(brain_dy_cell,2)
        %% load variables
        % 生成网格点
        lim = max(brain_dy_cell{m,n}.xhat_dist_lem) + 1;

        xlim_range = [-1*lim(1),lim(1)];
        ylim_range = [-1*lim(2),lim(2)];

        x = linspace(xlim_range(1), xlim_range(2), nxpts);
        y = linspace(ylim_range(1), ylim_range(2), nypts);
        [X, Y] = meshgrid(x, y);
        
        % 组合网格点
        xy = [X(:), Y(:)];

        % 计算每个 (x, y) 位置的每个状态的概率，并找到最大概率对应的状态
        z = zeros(size(xy, 1), 1); % 初始化 z，用于存储每个点的状态
        
        for i = 1:size(xy, 1)
            % 对每个点计算状态得分
            scores = xy(i, :) * ...
                brain_dy_cell{m,n}.model_transitions_s_T' + ...
                brain_dy_cell{m,n}.model_transitions_r;
            % 找到得分最高的状态索引
            [~, z(i)] = max(scores);
        end
        %%
        subplot('Position',...
            [start_x+(n-1)*(box_x+inter_x),...
            start_y-(m-1)*(box_y+inter_y),...
            box_x,box_y])
        % 遍历每个动态系统的参数 (A, b)
        for k = 1:length(brain_dy_cell{m,n}.model_dynamics_As)
            A = reshape(brain_dy_cell{m,n}.model_dynamics_As(k,:,:),2,2)';
            b = brain_dy_cell{m,n}.model_dynamics_bs(k,:);
            
            % 计算每个 (x, y) 的 dx/dt 和 dy/dt
            dxydt_m = xy * A + ones(size(xy,1),1)*b - xy;

            % 找到属于状态 k 的点
            zk = (z == k);

            % 如果状态 k 中有点
            if sum(zk) > 0
                % 绘制速度场矢量
                quiver(xy(zk, 1), xy(zk, 2), ...
                       dxydt_m(zk, 1), dxydt_m(zk, 2),...
                       'Color',quv_cmap_list(k,:));
                hold on
            end
        end
        hold on

        XL = get(gca,'xlim'); XR = XL(2);
        YL = get(gca,'ylim'); YT = YL(2);

        plot(XL,YT*ones(size(XL)),...
            'color', 'k','linewidth',0.25)
        hold on
        plot(XR*ones(size(YL)),YL,...
            'color', 'k','linewidth',0.25)
        hold off

        set(gca,'FontSize',6)
        set(gca,'TickDir','out')

        box off

        if n == 1
            ylabel({dist_y_label{m},'x_2'})
        end

        if m == 3
            xlabel('x_1')
        end

        if m == 1
            title(show_brain_name{n})
        end

        % 遍历每个动态系统的参数 (A, b)
        % for k = 1:length(brain_dy_cell{m,n}.model_dynamics_As)
        %     A = reshape(brain_dy_cell{m,n}.model_dynamics_As(k,:,:),2,2)';
        %     b = brain_dy_cell{m,n}.model_dynamics_bs(k,:);
        % 
        %     % 计算每个 (x, y) 的 dx/dt 和 dy/dt
        %     dxydt_m = xy * A + ones(size(xy,1),1)*b - xy;
        % 
        %     dxydt_m_norm = sqrt(sum(dxydt_m.^2,2));
        %     % 找到属于状态 k 的点
        %     zk = (z == k);
        % 
        %     % 如果状态 k 中有点
        %     if sum(zk) > 0
        %         selx = xy(zk, 1);
        %         sely = xy(zk, 2);
        %         selz = dxydt_m_norm;
        % 
        %         [X,Y] = meshgrid(selx,sely);
        % 
        %         Z = zeros(size(X));
        % 
        %         for p = 1:size(Z,1)
        %                 ttx = selx(p);
        %                 tty = sely(p);
        % 
        %                 xidx = ttx == X;
        %                 yidx = tty == Y;
        %                 zidx = xidx&yidx;
        % 
        %                 Z(zidx) = selz(p);
        %         end
        %         % 绘制速度场平面
        %         surf(X, Y, Z);
        %         hold on
        %     end
        % end
        % hold off
    end
end






































