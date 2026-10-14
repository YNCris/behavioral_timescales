%{
    fig1,一图流，简化
%}
clear all
close all
addpath(genpath(pwd))

rmpath(['D:\SBeA_Analysis\SBeA_v0.0.1\TPM\figs\function\' ...
    'gtw\lib\subspace']);
rmpath(['D:\SBeA_Analysis\SBeA_v0.0.1\TPM\figs\old\function\' ...
    'gtw\lib\subspace']);
%% set path
rootpath = ['D:\MTPM_body_language'];
beh_neu_path = [rootpath,'\beh_neu_20240412'];

beh_video_path = [rootpath,'\raw_data\behavior_all'];

bea_path = [beh_video_path,'\BeA_path'];

process_tpm_path = [rootpath,...
    '\raw_data\tpm_suite2p\process'];
%% load data
fileFolder = fullfile(beh_neu_path);
dirOutput = dir(fullfile(fileFolder,'free*-neu.mat'));
neuNames = {dirOutput.name}';

all_data_cell = cell(size(neuNames,1),13);

for k = 1:size(all_data_cell,1)
    % 名字
    rootname = neuNames{k}(1:(end-8));
    all_data_cell{k,1} = rootname;
    
    % subject 神经活动
    tempdata = load([beh_neu_path,'\',neuNames{k}]);
    all_data_cell{k,2} = tempdata.dff_smo_Fc';

    % subject 姿态
    tempdata = load([beh_neu_path,'\',rootname,...
        '-pose-tpm.mat']);
    all_data_cell{k,3} = tempdata.coords3d;
    
    % subject 动作
    tempdata = load([beh_neu_path,'\',rootname,...
        '-beh_mod-tpm.mat']);
    all_data_cell{k,4} = tempdata.beh_mod_list;
    
    % subject 序列
    tempdata = load([beh_neu_path,'\',rootname,...
        '-seq-tpm.mat']);
    all_data_cell{k,5} = tempdata.seq_label_list;
    
    % object 姿态
    tempdata = load([beh_neu_path,'\',rootname,...
        '-pose-free.mat']);
    all_data_cell{k,6} = tempdata.coords3d;

    % object 动作
    tempdata = load([beh_neu_path,'\',rootname,...
        '-beh_mod-free.mat']);
    all_data_cell{k,7} = tempdata.beh_mod_list;
    
    % object 序列
    tempdata = load([beh_neu_path,'\',rootname,...
        '-seq-free.mat']);
    all_data_cell{k,8} = tempdata.seq_label_list;
    
    % subject 和 object 的距离
    tempdata = load([beh_neu_path,'\',rootname,...
        '-distance-free.mat']);
    all_data_cell{k,9} = tempdata.dist_data;

    % neu umap
    tempdata = load([beh_neu_path,'\',rootname,...
        '-neu_umap.mat']);
    all_data_cell{k,10} = tempdata.umap_embedding;

    tempdata = load([beh_neu_path,'\',rootname,...
        '-cut-rnn_ed_train_2layers.mat']);
    all_data_cell{k,11} = tempdata;

    tempdata = load([beh_neu_path,'\',rootname,...
        '-cut-rnn_ed_train_control_2layers.mat']);
    all_data_cell{k,12} = tempdata;

    tempdata = load([beh_neu_path,'\',rootname,...
        '-cut-rnn_states_ed_train_2layers.mat']);
    all_data_cell{k,13} = tempdata;
    disp(k)
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
    all_data_9 = all_data_cell{k,9}{2}(tempstart:tempend,:);

    raw_trial_cell = [raw_trial_cell;...
        {newname,all_data_2,all_data_3,all_data_4,...
        all_data_5,all_data_6,all_data_7,all_data_8,...
        all_data_9,all_data_cell{k,1}},...
        [tempstart,tempend]];

    unique(all_data_5)
    %%
    disp(k)
end
%% split far-close-far trial，按照时间条件分离社交trial
fs = 30;
baseline_far_time = 5;%s
after_far_time = 5;%s
min_close_time = 2;%s
max_close_time = 10;%s

baseline_far_frame = baseline_far_time*fs;
after_far_frame = after_far_time*fs;
min_close_frame = min_close_time*fs;
max_close_frame = max_close_time*fs;

fcf_cell = {};

for k = 1:size(all_data_cell,1)
    %% load data
    tempdist = all_data_cell{k,9};
    
    %% select trials
    distsavelist = idx2savelist(tempdist{2});

    all_close_list = distsavelist(distsavelist(:,3)==1,:);

    all_close_list(all_close_list(:,1)<baseline_far_frame,:) = [];
    all_close_list(all_close_list(:,2)>...
        length(tempdist{2})-after_far_frame,:) = [];
    all_close_list(...
        (all_close_list(:,2)-all_close_list(:,1))<...
        min_close_frame,:) = [];
    all_close_list(...
        (all_close_list(:,2)-all_close_list(:,1))>...
        max_close_frame,:) = [];

    selidx = zeros(size(all_close_list,1),1);

    for m = 1:size(all_close_list,1)
        tempstart = all_close_list(m,1);
        tempend = all_close_list(m,2);
        seldata_baseline = tempdist{2}(...
            (tempstart-baseline_far_frame):(tempstart-1));
        seldata_after = tempdist{2}(...
            (tempend+1):(tempend+after_far_frame));

        if sum(seldata_baseline)==0 && sum(seldata_after)==0
            selidx(m,1) = 1;
        end
    end

    sel_close_list = all_close_list(selidx==1,:);
    %% append data
    for m = 1:size(sel_close_list,1)
        tempstart = sel_close_list(m,1)-baseline_far_frame;
        tempend = sel_close_list(m,2)+after_far_frame;

        newname = [all_data_cell{k,1},'-',num2str(m)];
        all_data_2 = all_data_cell{k,2}(tempstart:tempend,:);
        all_data_3 = all_data_cell{k,3}(tempstart:tempend,:);
        all_data_4 = all_data_cell{k,4}(tempstart:tempend,:);
        all_data_5 = all_data_cell{k,5}(tempstart:tempend,:);
        all_data_6 = all_data_cell{k,6}(tempstart:tempend,:);
        all_data_7 = all_data_cell{k,7}(tempstart:tempend,:);
        all_data_8 = all_data_cell{k,8}(tempstart:tempend,:);
        all_data_9 = all_data_cell{k,9}{3}(tempstart:tempend,:);

        fcf_cell = [fcf_cell;...
            {newname,all_data_2,all_data_3,all_data_4,...
            all_data_5,all_data_6,all_data_7,all_data_8,...
            all_data_9,all_data_cell{k,1},...
            [tempstart,tempend]}];

        unique(all_data_5)
    end
    %%
    disp(k)
end
%% create the unique_mov and unique_seq，分离动作和序列
all_mov = [];
all_mov_name = {};
for k = 1:size(fcf_cell,1)
    all_mov = [all_mov;...
        cell2mat(fcf_cell{k,4}(:,2));...
        cell2mat(fcf_cell{k,7}(:,2))];
    all_mov_name = [all_mov_name;...
        fcf_cell{k,4}(:,1);...
        fcf_cell{k,7}(:,1)];
end
unique_mov = unique(all_mov);
cmap_mov = cbrewer2('BuPu',length(unique_mov));

uniuqe_mov_name = cell(size(unique_mov));
for k = 1:size(unique_mov,1)
    tempname = all_mov_name(unique_mov(k)==all_mov);
    uniuqe_mov_name{k} = tempname{1};
end

all_seq = [];
for k = 1:size(fcf_cell,1)
    all_seq = [all_seq;fcf_cell{k,5};fcf_cell{k,8}];
end
unique_seq = unique(all_seq);
unique_seq = unique_seq(2:end);
cmap_seq = cbrewer2('BuPu',length(unique_seq));

%% show mov and seq of all the trials
% sort data by length
fcf_length = cell2mat(cellfun(@(x) size(x,1),fcf_cell(:,2),...
    'UniformOutput',false));

[~,sortidx] = sort(fcf_length,'descend');

sort_fcf_cell = fcf_cell(sortidx,:);

%% extract seq
seq_cell = cell(size(unique_seq,1),1);
for k = 1:size(unique_seq,1)
    tempseq = unique_seq(k,1);
    saveseqlist = {};
    for m = 1:size(sort_fcf_cell,1)
        seqlist_1 = sort_fcf_cell{m,5};
        seqlist_2 = sort_fcf_cell{m,8};
        movlist_1 = sort_fcf_cell{m,4}(:,1);
        movlist_2 = sort_fcf_cell{m,7}(:,1);
        movidxlist_1 = cell2mat(...
            sort_fcf_cell{m,4}(:,2));
        movidxlist_2 = cell2mat(...
            sort_fcf_cell{m,7}(:,2));

        savelist1 = idx2savelist(seqlist_1);
        savelist2 = idx2savelist(seqlist_2);

        selidx1 = savelist1(:,3)==tempseq;
        selidx2 = savelist2(:,3)==tempseq;
        
        if sum(selidx1) > 0
            selsavelist1 = savelist1(selidx1,:);
            for n = 1:size(selsavelist1,1)
                sel_movidxlist_1 = movidxlist_1(...
                    selsavelist1(1):selsavelist1(2));
                diffidx = [1;diff(sel_movidxlist_1)~=0];
                saveseqlist = [saveseqlist;...
                    {movlist_1(diffidx==1)'}];
            end    
        end

        if sum(selidx2) > 0
            selsavelist2 = savelist2(selidx2,:);
            for n = 1:size(selsavelist2,1)
                sel_movidxlist_2 = movidxlist_2(...
                    selsavelist2(1):selsavelist2(2));
                diffidx = [1;diff(sel_movidxlist_2)~=0];
                saveseqlist = [saveseqlist;...
                    {movlist_2(diffidx==1)'}];
            end    
        end   
    end
    seq_cell{k,1} = saveseqlist;
end


% create seq mat
pad_len = 600;
self_seq_mat = -1*ones(size(sort_fcf_cell,1),pad_len);
start_list = zeros(size(self_seq_mat,1),2);
end_list = zeros(size(self_seq_mat,1),2);

for k = 1:size(self_seq_mat,1)
    tempseq = sort_fcf_cell{k,5}';
    self_seq_mat(k,1:length(tempseq)) = tempseq;
    start_list(k,:) = [baseline_far_frame,k];
    end_list(k,:) = [length(tempseq)-after_far_frame,k];
end


% show mov and seq of partner
% create mov mat
pad_len = 600;
part_mov_mat = -1*ones(size(sort_fcf_cell,1),pad_len);
start_list = zeros(size(part_mov_mat,1),2);
end_list = zeros(size(part_mov_mat,1),2);

for k = 1:size(part_mov_mat,1)
    tempmov = cell2mat(sort_fcf_cell{k,7}(:,2))';
    part_mov_mat(k,1:length(tempmov)) = tempmov;
    start_list(k,:) = [baseline_far_frame,k];
    end_list(k,:) = [length(tempmov)-after_far_frame,k];
end

% create seq mat
pad_len = 600;
part_seq_mat = -1*ones(size(sort_fcf_cell,1),pad_len);
start_list = zeros(size(part_seq_mat,1),2);
end_list = zeros(size(part_seq_mat,1),2);

for k = 1:size(part_seq_mat,1)
    tempseq = sort_fcf_cell{k,8}';
    part_seq_mat(k,1:length(tempseq)) = tempseq;
    start_list(k,:) = [baseline_far_frame,k];
    end_list(k,:) = [length(tempseq)-after_far_frame,k];
end

%% use pca to do the linear component analysis
pca_cell = cell(size(sort_fcf_cell,1),5);

for k = 1:size(pca_cell,1)
    tempneu = sort_fcf_cell{k,2};
    [coeff, score, ~, ~, explained] = pca(tempneu');
    pca_cell{k,1} = coeff;
    pca_cell{k,2} = score;
    pca_cell{k,3} = explained;
    pca_cell{k,4} = cumsum(explained);

    norm_coeff = zeros(size(coeff));
    for m = 1:size(coeff,2)
        norm_coeff(:,m) = mat2gray(coeff(:,m));
    end
    pca_cell{k,5} = norm_coeff;
end

%% plot canvas
hall = figure(1);
set(hall,'Position',[1080,60,800,800])
set(hall,'color','white');
%% 1. naturalistic social data collection


% two carton mice
start_x = 0.03;
start_y = 0.65;

box_x = 0.2;
box_y = 0.1;

subplot('Position',[start_x,start_y,box_x,box_y])

%% neu frame
start_x = 0.03;
start_y = 0.8;

box_x = 0.07;
box_y = 0.07;

inter_x = 0.02;

frame_idx_list = [...
    1100;...
    100;...
    100];

frame_stacks = 200;

mice_name_list = {...
    '4tpmss';...
    '4tpmpfc';...
    '1tpmm'};

rec_name_list = {...
    {'Primary','somatosensory','cortex (S1)'};...
    {'Dorsomedial','prefrontal','cortex (dmPFC)'};...
    {'Primary','Motor','Cortex (M1)'}};

title_name_list = {...
    'Somatosensory';...
    {'Hierarchical Pathway of Social Cognitive Processing',...
    'Cognition'};...
    'Motor'};

x_name_list = {...
    'S1';...
    'dmPFC';...
    'M1'};

for k = 1:3
    % raw frames
    subplot('Position',[...
        start_x+(k-1)*(box_x+inter_x),...
        start_y,...
        box_x,box_y])
    axis square

    axis on
    box on
    set(gca,'XTick',[],'YTick',[])

    title(title_name_list{k})

    set(gca,'FontSize',6)

    xlabel(x_name_list{k})
end

%% behavior recording
frame_idx = 14052;
root_video_name = 'free-seg1-1tpmss-1wt-20220226-camera';
num_cam = 4;

frame_x = 640;
frame_y = 480;

start_x = 0.03;
start_y = 0.55;

box_y = 0.06;
box_x = box_y*frame_x/frame_y;


inter_x = 0.003;
inter_y = 0.003;

count = 1;
for m = 1:2
    for n = 1:2
        subplot('Position',[...
            start_x+(m-1)*(box_x+inter_x),...
            start_y-(n-1)*(box_y+inter_y),...
            box_x,box_y])
        vidobj = VideoReader([beh_video_path,...
            '\',root_video_name,'-',...
            num2str(count),'.avi']);
        frame = read(vidobj,frame_idx);
        imshow(frame,[0,255])
        axis on
        box on
        set(gca,'XTick',[],'YTick',[])

        set(gca,'FontSize',6)
        count = count+1;

        if m == 1 && n == 1
            title('                          Camera array')
        end
    end
end

%% 3d poses
start_x = 0.195;
start_y = 0.49;

box_x = 0.12;
box_y = box_x;

data_rootname = 'free-seg1-1tpmss-1wt-20220226';

sel_frame_idx = 14052;
smo_win = 30;

alpha_c = 0.05;
drawline = [ 1 2; 1 3;2 3; 4 5;4 6;5 7;6 8;7 14;8 14;...
    5 9;7 11;6 10; 8 12;14 15; 15 16;5,13;6,13;7,13;8,13;...
    2 4;3 4;5,6;7,8];

sel_data_idx = strcmp(data_rootname,all_data_cell(:,1));

sel_data = all_data_cell(sel_data_idx,:);

pose_tpm = sel_data{3};
pose_free = sel_data{6};

smo_pose_tpm = pose_tpm;
smo_pose_free = pose_free;

for k = 1:size(smo_pose_tpm,2)
    smo_pose_tpm(:,k) = smooth(pose_tpm(:,k),smo_win);
    smo_pose_free(:,k) = smooth(pose_free(:,k),smo_win);
end

setcolor = cbrewer2('Spectral',11);
mouse_tpm_c = setcolor(3,:);
mouse_free_c = setcolor(9,:);

subplot('Position',[...
        start_x,...
        start_y,...
        box_x,box_y])

traj_tpm_frame = smo_pose_tpm(sel_frame_idx,:);
traj_free_frame = smo_pose_free(sel_frame_idx,:);

tempx_tpm = traj_tpm_frame(1:3:end)';
tempy_tpm = traj_tpm_frame(2:3:end)';
tempz_tpm = traj_tpm_frame(3:3:end)';

tempx_free = traj_free_frame(1:3:end)';
tempy_free = traj_free_frame(2:3:end)';
tempz_free = traj_free_frame(3:3:end)';

min_axis_x = min([tempx_tpm;tempx_free]);
min_axis_y = min([tempy_tpm;tempy_free]);
min_axis_z = min([tempz_tpm;tempz_free]);
max_axis_x = max([tempx_tpm;tempx_free]);
max_axis_y = max([tempy_tpm;tempy_free]);
max_axis_z = max([tempz_tpm;tempz_free]);

new_mesh_mouse(traj_tpm_frame,alpha_c,mouse_tpm_c)
hold on
plot_skl_dl(tempx_tpm(:,1),tempy_tpm(:,1),tempz_tpm(:,1),...
    'k','k',drawline)
hold on
new_mesh_mouse(traj_free_frame,alpha_c,mouse_free_c)
hold on
plot_skl_dl(tempx_free(:,1),tempy_free(:,1),tempz_free(:,1),...
    'k','k',drawline)
hold off

grid on

view(8,32)

set(gca,'XTickLabel',[])
set(gca,'YTickLabel',[])
set(gca,'ZTickLabel',[])
set(gca,'TickLength',[0,0])

xlabel('x')
ylabel('y')
zlabel('z')

title('3D skeletons')
set(gca,'FontSize',6)
%% 2. localized mesostasis theory
%% show umap lde
start_x = 0.33;
start_y = 0.59;

box_x = 0.15;
box_y = 0.15;

data_rootname = 'free-seg2-1tpmpfc-rwt-20240103';

pre_umap = 300;%frames
post_umap = 300;%frames

sel_data_idx = strcmp(data_rootname,all_data_cell(:,1));

sel_data = all_data_cell(sel_data_idx,:);

sel_fcf_idx = strcmp(data_rootname,sort_fcf_cell(:,10));

sel_fcf = sort_fcf_cell(sel_fcf_idx,:);

sel_umap = sel_data{1,10};

raw_sel_savelist = cell2mat(sel_fcf(:,11));

raw_sel_pca = pca_cell(sel_fcf_idx,:);

%注意这里排序了
[sel_savelist,sort_i] = sortrows(raw_sel_savelist,1);

sel_pca = raw_sel_pca(sort_i,:);

show_savelist = sel_savelist(1:2,:);

show_pca = sel_pca(1:2,:);

sel_umap_savelist = [...
    show_savelist(1,1)-pre_umap,...
    show_savelist(2,2)+post_umap];

cut_umap = sel_umap(...
    sel_umap_savelist(1):sel_umap_savelist(2),:);

social_1 = sel_umap(show_savelist(1,:),:);
social_2 = sel_umap(show_savelist(2,:),:);

social_all = [social_1;social_2];

time_cmap = flipud(cbrewer2('Spectral',256));

subplot('Position',[start_x,start_y,box_x,box_y])

score = cut_umap;
show_cmap = mat2gray(...
imresize(time_cmap,[size(score,1),3]));

plot3(score(:,1),score(:,2),score(:,3),'-k')
hold on
scatter3(score(:,1),score(:,2),score(:,3),...
    3*ones(size(score,1),1),show_cmap,'filled')
hold on

for k = 1:4
    if rem(k,2) == 0
        clr = 'k';
    else
        clr = 'r';
    end
    plot3(social_all(k,1),...
        social_all(k,2),...
        social_all(k,3),...
        '*','MarkerSize',10,...
        'Color',clr)
    hold on
end

raw_list = [];

show_cmap_2 = show_cmap(...
    pre_umap:(size(show_cmap,1)-post_umap+1),:);
show_cmap_2 = show_cmap_2(...
    (show_savelist(2,1)-show_savelist(1,1)+2):(end-1),:);


hold off



xlabel('UMAP 1')
ylabel('UMAP 2')
zlabel('UMAP 3')

title('Neural embedding')

set(gca,'FontSize',6)

set(gca,'XTickLabel',[],'YTickLabel',[],'ZTickLabel',[])

grid on

view(139,10)

% colorbar
cbar_box_x = 0.006;
cbar_box_y = 0.05;

cbar_inter_x = 0.01;

temph = subplot('Position',[...
    start_x+1*(box_x+inter_x)+cbar_inter_x,...
    start_y+box_y-cbar_box_y,...
    cbar_box_x,cbar_box_y]);
imagesc(flipud((1:256)'))
colormap(temph,time_cmap)
set(gca,'XTick',[],'YTick',[])

max_time = round(length(cut_umap)/30);

text(0.5,280,'0','FontSize',6,'VerticalAlignment',...
    'middle')
text(0.0,-30,num2str(max_time),'FontSize',6,'VerticalAlignment',...
    'middle')

text(2.5,128,'Time (s)','FontSize',6,'Rotation',90,...
    'HorizontalAlignment','center')

% show corresponding PCA
pca_box_x = 0.15;
pca_box_y = 0.15;

inter_x_pca1 = 0.05;
inter_y_pca2 = -0.02;

y_bias = 0.00;

show_pc_list = 1:2:12;

cmap_pc = flipud(cbrewer2('RdBu',256));

% pca1
subplot('Position',[...
    start_x+inter_x_pca1+box_x,...
    start_y+y_bias,...
    pca_box_x,pca_box_y])

tempshow_pca = show_pca{1,5};

social_ep_list = ones(size(tempshow_pca,1),1);

social_ep_list(1:baseline_far_frame) = 0;
social_ep_list((end-baseline_far_frame+1):end) = 0;

% 用scatter3画

quv_cmap_list = [cmap_pc(32,:);cmap_pc(240,:)];

show_cmap_list = quv_cmap_list(social_ep_list+1,:);

tempshow_pca = show_pca{2,5};

social_ep_list = ones(size(tempshow_pca,1),1);

social_ep_list(1:baseline_far_frame) = 0;
social_ep_list((end-baseline_far_frame+1):end) = 0;

show_cmap_list = quv_cmap_list(social_ep_list+1,:);

plot3(...
        1:size(tempshow_pca,1),...
        -1*ones(1,size(tempshow_pca,1)),...
        social_ep_list,'Color',quv_cmap_list(2,:),...
        'LineWidth',1.5)
hold on

scatter3(...
        1:size(tempshow_pca,1),...
        -1*ones(1,size(tempshow_pca,1)),...
        social_ep_list,...
        1*ones(1,length(social_ep_list)),...
        show_cmap_list)

hold on

for k = show_pc_list
    % sel data
    show_temp_pca = tempshow_pca(:,k);

    show_temp_idx = round(show_temp_pca*255)+1;
    %
    plot3(...
        1:size(tempshow_pca,1),...
        k*ones(1,size(tempshow_pca,1)),...
        tempshow_pca(:,k),...
        '-',...
        'Color',0.7*ones(1,3))
    hold on 
    scatter3(...
        1:size(tempshow_pca,1),...
        k*ones(1,size(tempshow_pca,1)),...
        tempshow_pca(:,k),...
        3*ones(1,length(social_ep_list)),...
        cmap_pc(show_temp_idx,:),...
        'filled')
    hold on 
end
hold off

view(68,72)

axis([0,size(tempshow_pca,1),-1,11,...
    0,1])

xlabel('Time (s)')
ylabel('Neural PCs')
% ylabel('Neural PCs')
% zlabel('Coefficients')

set(gca,'FontSize',6)

show_xtick = [0,baseline_far_frame,...
    size(tempshow_pca,1)-after_far_frame,...
    size(tempshow_pca,1)];

set(gca,'XTick',show_xtick)
set(gca,'YTick',show_pc_list)
set(gca,'ZTick',[0,1])

set(gca,'XTickLabel',round((show_xtick-150)/30))
set(gca,'YTickLabel',[])
set(gca,'ZTickLabel',[])

grid on

title('Social interaction episode')

% title('Social interaction episode 2')

% colorbar
cbar_box_x = 0.006;
cbar_box_y = 0.05;

cbar_inter_x = 0.01;

temph = subplot('Position',[...
    start_x+1*(box_x+inter_x)+cbar_inter_x+...
    pca_box_x+inter_x_pca1,...
    start_y+box_y-cbar_box_y,...
    cbar_box_x,cbar_box_y]);
imagesc(flipud((1:256)'))
colormap(temph,cmap_pc)
set(gca,'XTick',[],'YTick',[])

max_time = round(length(cut_umap)/30);

text(0.5,280,'0','FontSize',6,'VerticalAlignment',...
    'middle')
text(0.5,-30,'1','FontSize',6,'VerticalAlignment',...
    'middle')

text(2.5,128,'PC coefficients','FontSize',6,'Rotation',90,...
    'HorizontalAlignment','center')

%% show neu
% neu frame
start_x = 0.36;
start_y = 0.8;

box_x = 0.08;
box_y = 0.07;

inter_x = 0.02;


frame_idx_list = [...
    1100;...
    100;...
    100];

frame_stacks = 200;

mice_name_list = {...
    '4tpmss';...
    '4tpmpfc';...
    '1tpmm'};

rec_name_list = {...
    {'Primary','somatosensory','cortex (S1)'};...
    {'Dorsomedial','prefrontal','cortex (dmPFC)'};...
    {'Primary','Motor','Cortex (M1)'}};

title_name_list = {...
    'Somatosensory';...
    {'Hierarchical Pathway of Social Cognitive Processing',...
    'Cognition'};...
    'Motor'};

x_name_list = {...
    'S1';...
    'dmPFC';...
    'M1'};

% select data，搞两个trial连一起的
data_rootname_cell = {...
    'free-seg5-4tpmss-2wt-20220227';...
    'free-seg2-1tpmpfc-rwt-20240103';...
    'free-seg2-1tpmm-rwt-20231107'};

sel_trial_cell = {...
    [8,9];...
    [1,2];...
    [6,7]};


% 选范围
cut_range_cell = cell(size(data_rootname_cell,1),6);
pre_frame = 300;%frames
post_frame = 300;%frames

corr_len = 1901;

for k = 1:size(data_rootname_cell,1)
    %
    tempname = data_rootname_cell{k};
    selidx = strcmp(tempname,sort_fcf_cell(:,10));
    
    selsavelist = cell2mat(sort_fcf_cell(selidx,11));

    sel_fcf = sort_fcf_cell(selidx,:);

    [sort_b,sort_i] = sort(selsavelist(:,1));

    sel_trial_idx = sel_trial_cell{k,1};

    sort_sel_fcf = sel_fcf(sort_i(sel_trial_idx),:);

    cut_range_cell{k,1} = [...
        sort_sel_fcf{1,11}(1)-pre_frame;...
        sort_sel_fcf{2,11}(2)+post_frame];

    cut_range_cell{k,2} = ...
        sort_sel_fcf{2,11}(2)-...
        sort_sel_fcf{1,11}(1);

    % correct range
    cut_range_cell{k,3} = [...
        cut_range_cell{k,1}(1);...
        cut_range_cell{k,1}(1)+corr_len+pre_frame+post_frame];

    cut_range_cell{k,4} = cut_range_cell{k,3}(2)-...
        cut_range_cell{k,3}(1);

    % save raw value
    cut_range_cell{k,5} = cell2mat(sort_sel_fcf(:,11));

    % show far close far
    new_idxlist = [...
        cut_range_cell{k,3}(1);...
        cut_range_cell{k,5}(1,:)';...
        cut_range_cell{k,5}(2,:)';...
        cut_range_cell{k,3}(2)]-cut_range_cell{k,3}(1)+1;
    
    new_start = new_idxlist(1:(end-1));
    new_end = [new_idxlist(2:(end-1))-1;new_idxlist(end)];

    new_savelist = [new_start,new_end];

    cut_range_cell{k,6} = new_savelist;
end

% 选神经元
sel_neu_cell = cell(size(cut_range_cell,1),4);

filt_min = -0.5;
filt_max = 4;

filt_fire_max = 1;

sel_num = 20;

for k = 1:size(sel_neu_cell,1)
    % cut neu
    tempname = data_rootname_cell{k,1};
    temprange = cut_range_cell{k,3};
    sel_neu = all_data_cell{...
        strcmp(tempname,all_data_cell(:,1)),...
        2};

    cut_neu = sel_neu(temprange(1):temprange(2),:)';

    sel_neu_cell{k,1} = cut_neu;

    % filt neu
    min_mat = min(cut_neu,[],2);
    max_mat = max(cut_neu,[],2);

    selneuidx = (min_mat>filt_min)&(max_mat<filt_max)&...
        (max_mat>filt_fire_max);
    
    sel_cut_neu = cut_neu(selneuidx,:);

    sel_neu_cell{k,2} = sel_cut_neu;

    % sort neu by max value
    max_neu = max(sel_cut_neu,[],2);
    
    [sort_b,sort_i] = sort(max_neu,'descend');
    
    sel_neu_cell{k,3} = sel_cut_neu(sort_i,:);

    % resample neu
    res_neu = sel_cut_neu(1:25,:);

    sel_neu_cell{k,4} = res_neu;
end

% show 结果

srk_param = 0.9;

for k = 1:3
    % sel data
    tempneu = sel_neu_cell{k,4};
    % show
    subplot('Position',[...
        start_x+(k-1)*(box_x+inter_x),...
        start_y,...
        box_x,box_y])

    % plot show

    % for m = 1:size(tempneu,1)
    %     plot(1:size(tempneu,2),...
    %         m+0.8*mat2gray(tempneu(m,:)),'-k')
    %     hold on
    % end
    % hold off

    % scatter show
    for m = 1:size(tempneu,1)
        show_x = 1:size(tempneu,2);
        show_y = mat2gray(tempneu(m,:));
        show_cmap = cmap_pc(round((show_y*255)+1),:);

        plot(show_x,m+srk_param*show_y,'-',...
            'Color',0.4*ones(1,3),...
            'LineWidth',0.25)
        hold on
    
        % scatter(show_x,...
        %         m+srk_param*show_y,...
        %         0.25*ones(size(show_x)),...
        %         show_cmap,...
        %         'filled');
        % hold on
    end
    hold on

    % show mask
    temp_savelist = cut_range_cell{k,6};
    for m = 1:size(temp_savelist,1)
        p_x = [...
            temp_savelist(m,1),...
            temp_savelist(m,2),...
            temp_savelist(m,2),...
            temp_savelist(m,1)];%[左，右，右，左]
        p_y = [0,0,...
            size(tempneu,1)+1.5,...
            size(tempneu,1)+1.5];%[下，下，上，上]

        if rem(m,2)==0
            show_clr = quv_cmap_list(2,:);
        else
            show_clr = quv_cmap_list(1,:);
        end
        patch(p_x,p_y,...
            show_clr,'FaceAlpha',0.15,...
            'EdgeColor','none')
        hold on
    end
    hold off
    

    box off

    set(gca,'XTick',[],'YTick',[])

    title(title_name_list{k})

    set(gca,'FontSize',6)

    xlabel(x_name_list{k})
end



