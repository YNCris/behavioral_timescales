%{
    fig1, 
    the paradigms，把cebra挪图1来
%}
clear all
close all
addpath(genpath(pwd))
%% set path
rootpath = ['X:\hanyaning\MTPM_body_language'];

beh_video_path = [rootpath,'\raw_data\behavior_all'];

bea_path = [beh_video_path,'\BeA_path'];

process_tpm_path = [rootpath,...
    '\raw_data\tpm_suite2p\process'];

beh_neu_path = [rootpath,'\beh_neu_20240412'];

dsc_free_path = [beh_video_path,'\BeA_path\recluster_data_free'];

seq_path = [bea_path,'\recluster_data_merge'];
%% plot canvas
hall = figure(1);
set(hall,'Position',[680,0,800,800])
set(hall,'color','white');
%% left space for cartoon
subplot('Position',[0.01,0.73,0.32,0.25])
box on
set(gca,'XTick',[],'YTick',[])
%% show 4 cameras behavior capture
frame_idx = 14000;
root_video_name = 'free-seg1-1tpmss-1wt-20220226-camera';
num_cam = 4;

frame_x = 640;
frame_y = 480;

start_x = 0.35;
start_y = 0.85;

box_y = 0.1;
box_x = box_y*frame_x/frame_y;


inter_x = 0.01;
inter_y = 0.02;

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

        if count == 1
            title({'Multiview video frames',...
                'Camera 1'})
            
        else
            title(['Camera ',num2str(count)])
        end
        set(gca,'FontSize',6)
        count = count+1;
    end
end


%% show 3 brain area recording
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

start_x = 0.66;

box_x = box_y;

inter_x = 0.01;

for k = 1:3
    %% raw frames
    subplot('Position',[...
        start_x+(k-1)*(box_x+inter_x),...
        start_y,...
        box_x,box_y])

    frame = imread([process_tpm_path,'\',...
        mice_name_list{k},'\social 0.tif'],...
        frame_idx_list(k));
    
    frame_tensor = zeros(...
        size(frame,1),...
        size(frame,2),...
        frame_stacks);
    for m = 1:size(frame_tensor,3)
        frame_tensor(:,:,m) = imread(...
            [process_tpm_path,'\',...
        mice_name_list{k},'\social 0.tif'],...
        frame_idx_list(k)+m);
    end

    show_frame = mat2gray(mean(frame_tensor,3));
    imshow(show_frame,[])
    
    axis square

    axis on
    box on
    set(gca,'XTick',[],'YTick',[])

    title(rec_name_list{k})
    set(gca,'FontSize',6)

    if k == 1
        ylabel('Raw frames')
    end
    %% the mask of signals
    tempdata = load([process_tpm_path,'\',...
        mice_name_list{k},...
        '\suite2p\plane0\Fall.mat']);

    iscell_idx = tempdata.iscell(:,1)==1;

    sel_stat = tempdata.stat(iscell_idx);
    
    cmap = cbrewer2('Spectral',size(sel_stat,2));
    
    mask_l = zeros(size(show_frame,1),...
        size(show_frame,2));

    for m = 1:length(sel_stat)
        tempstat = sel_stat{m};
        x_pos = tempstat.xpix;
        y_pos = tempstat.ypix;
        
        for n = 1:size(x_pos,2)
            mask_l(y_pos(n),x_pos(n)) = m;
        end
    end

    subplot('Position',[...
        start_x+(k-1)*(box_x+inter_x),...
        start_y-(box_y+inter_y),...
        box_x,box_y])
    show_label = labeloverlay(show_frame,...
        mask_l);
    imshow(show_label,[])
    axis square

    axis on
    box on
    set(gca,'XTick',[],'YTick',[])

    if k == 1
        ylabel('Suite2p detection')
    end
    set(gca,'FontSize',6)
end

%% the hierarchical behavior
start_x = 0.02;
start_y = 0.58;

box_y = 0.13;
box_x = 0.19;

inter_x = 0.02;
inter_y = 0.03;

move_box_y = 0.06;

% plot method, ADPT
m = 1;
n = 1;
subplot('Position',[...
        start_x+(m-1)*(box_x+inter_x),...
        start_y-(n-1)*(box_y+inter_y),...
        box_x,box_y])

thick_conv = 0.5;
thick_trans = 1;
shrscale = 1;
netcolorlist = cbrewer2('Pastel1',9);
cov1_c = netcolorlist(1,:);
trans_c = netcolorlist(2,:);
plotcube([thick_conv 70 70]/shrscale,[0  -35  -35]/shrscale,.8,cov1_c)
plotcube([thick_conv 70 70]/shrscale,[2  -35  -35]/shrscale,.8,cov1_c)
plotcube([thick_conv 70 70]/shrscale,[4  -35  -35]/shrscale,.8,cov1_c)

plotcube([thick_conv 70 70]/shrscale,[4  -35  -35-100]/shrscale,.8,cov1_c)

inter_z_list = (1:6)*20;
bias_z = 70;
for k = 1:length(inter_z_list)
    plotcube([thick_trans 10 10]/shrscale,...
        [6  -5  -5+inter_z_list(k)-bias_z]/shrscale,.8,trans_c)
end

inter_z_list = (1:6)*20;
bias_z = 70;
for k = 1:length(inter_z_list)
    plotcube([thick_trans 10 10]/shrscale,...
        [8  -5  -5+inter_z_list(k)-bias_z]/shrscale,.8,trans_c)
end

plotcube([thick_conv 70 70]/shrscale,[10  -35  -35]/shrscale,.8,cov1_c)
hold on
plot3([5,0],[0,0],[0,0],'-k')
hold on
plot3([2.25,2.25],[0,0],[-35,-100],'-k')
hold on
plot3([2.25,9.5],[0,0],[-100,-100],'-k')
hold on
plot3([9.5,9.5],[0,0],[-100,0],'-k')
hold on
for k = 1:length(inter_z_list)
    plot3([5,6],[0,0],[0,inter_z_list(k)-bias_z],'-k')
    hold on
end
for k = 1:length(inter_z_list)
    plot3([7,8],[0,0],...
        [inter_z_list(k)-bias_z,inter_z_list(k)-bias_z],'-k')
    hold on
end
for k = 1:length(inter_z_list)
    plot3([9,9.5],[0,0],...
        [inter_z_list(k)-bias_z,0],'-k')
    hold on
end
plot3([9.5,10],[0,0],[0,0],'-k')
hold on
plot3([4.25,4.25],[0,0],[35,100],'-k')
hold on
plot3([4.25,9.5],[0,0],[100,100],'-k')
hold on
plot3([9.5,9.5],[0,0],[100,0],'-k')
hold off
axis([0,10.5,-35,35,-150,100])
axis off
set(gca,'XTick',[],'YTick',[])
title({'Anti-Drift Pose Tracker (ADPT)'})
set(gca,'FontSize',6)
view(7,10)

% trajectories
data_rootname = 'free-seg5-4tpmss-2wt-20220227';

sel_frame_idx = 100;
smo_win = 30;

alpha_c = 0.05;
drawline = [ 1 2; 1 3;2 3; 4 5;4 6;5 7;6 8;7 14;8 14;...
    5 9;7 11;6 10; 8 12;14 15; 15 16;5,13;6,13;7,13;8,13;...
    2 4;3 4;5,6;7,8];

tempdata_pose_tpm = load(...
    [beh_neu_path,'\',data_rootname,...
    '-pose-tpm.mat']);
pose_tpm = tempdata_pose_tpm.coords3d;

tempdata_pose_free = load(...
    [beh_neu_path,'\',data_rootname,...
    '-pose-free.mat']);
pose_free = tempdata_pose_free.coords3d;

tempdata_beh_mod_tpm = load(...
    [beh_neu_path,'\',data_rootname,...
    '-beh_mod-tpm.mat']);
tempdata_beh_mod_free = load(...
    [beh_neu_path,'\',data_rootname,...
    '-beh_mod-free.mat']);

tempdata_seq_tpm = load(...
    [beh_neu_path,'\',data_rootname,...
    '-seq-tpm.mat']);
tempdata_seq_free = load(...
    [beh_neu_path,'\',data_rootname,...
    '-seq-free.mat']);
seq_tpm = tempdata_seq_tpm.seq_label_list;
seq_free = tempdata_seq_free.seq_label_list;

smo_pose_tpm = pose_tpm;
smo_pose_free = pose_free;

for k = 1:size(smo_pose_tpm,2)
    smo_pose_tpm(:,k) = smooth(pose_tpm(:,k),smo_win);
    smo_pose_free(:,k) = smooth(pose_free(:,k),smo_win);
end

setcolor = cbrewer2('Spectral',11);
mouse_tpm_c = setcolor(3,:);
mouse_free_c = setcolor(9,:);

m = 2;
n = 1;
subplot('Position',[...
        start_x+(m-1)*(box_x+inter_x),...
        start_y-(n-1)*(box_y+inter_y),...
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

view(-53,41)

set(gca,'XTickLabel',[])
set(gca,'YTickLabel',[])
set(gca,'ZTickLabel',[])
set(gca,'TickLength',[0,0])

xlabel('x')
ylabel('y')
zlabel('z')

title('3D skeletons')
set(gca,'FontSize',6)

% plot trajectories
m = 3;
n = 1;

sel_len = 1800:10:19800;
skip_dim = 1;

temph = subplot('Position',[...
        start_x+(m-1)*(box_x+inter_x),...
        start_y-(n-1)*(box_y+inter_y)+box_y-move_box_y,...
        box_x,move_box_y]);
count = 1;
for k = 1:skip_dim:size(smo_pose_tpm,2)
    temptraj = smo_pose_tpm(sel_len,k);
    show_x = 1:length(temptraj);
    show_y = mat2gray(temptraj);
    count = count+1;
    plot(show_x,show_y+count,'-','Color',mouse_tpm_c,...
        'LineWidth',0.25)
    hold on
end
hold off
box off
axis([1,length(show_x),0,count+2])
set(gca,'TickDir','out')
set(gca,'YTick',24)
set(gca,'YTickLabel','TPM',...
    'YTickLabelRotation',90)

set(gca,'XTick',[1,length(sel_len)])
set(gca,'XTickLabel',[])

title('Layer 1: trajectories')
set(gca,'FontSize',6)

temph = subplot('Position',[...
        start_x+(m-1)*(box_x+inter_x),...
        start_y-(n-1)*(box_y+inter_y)+...
        box_y-2*move_box_y-0.005,...
        box_x,move_box_y]);
count = 1;
for k = 1:skip_dim:size(smo_pose_free,2)
    temptraj = smo_pose_free(sel_len,k);
    show_x = 1:length(temptraj);
    show_y = mat2gray(temptraj);
    count = count+1;
    plot(show_x,show_y+count,'-','Color',mouse_free_c,...
        'LineWidth',0.25)
    hold on
end
hold off
box off
axis([1,length(show_x),0,count+2])
set(gca,'TickDir','out')
set(gca,'YTick',24)
set(gca,'YTickLabel','Free',...
    'YTickLabelRotation',90)

set(gca,'XTick',[1,length(sel_len)])
set(gca,'XTickLabel',[0,10])
xlabel('Time (min)')
set(gca,'FontSize',6)

% plot method, Behavior Atlas
temp_free_dsc = load([dsc_free_path,'\data_sample_cell_80.mat']);

embed3d = cell2mat(temp_free_dsc.data_sample_cell(:,6));
tempsavelist = cell2mat(temp_free_dsc.data_sample_cell(:,2));
T = tempsavelist(:,4);
%

cmap = cbrewer2('Spectral',max(T));
cmaplist = cmap(T,:);

m = 1;
n = 2;
subplot('Position',[...
        start_x+(m-1)*(box_x+inter_x),...
        start_y-(n-1)*(box_y+inter_y),...
        box_x,box_y])

ds_idx = 5;

scatter3(...
    embed3d(1:ds_idx:end,1),...
    embed3d(1:ds_idx:end,2),...
    embed3d(1:ds_idx:end,3),...
    5*ones(size(T(1:ds_idx:end))),...
    cmaplist(1:ds_idx:end,:),'filled')
box on
grid on
set(gca,...
    'XTickLabel',[],...
    'YTickLabel',[],...
    'ZTickLabel',[])
title('Behavior Atlas (BeA)')
set(gca,'FontSize',6)
set(gca,'TickLength',[0,0])
xlabel('NM 1')
ylabel('NM 2')
zlabel('Locomotion')

% movements
m = 2;
n = 2;
subplot('Position',[...
        start_x+(m-1)*(box_x+inter_x),...
        start_y-(n-1)*(box_y+inter_y),...
        box_x,box_y])

sel_len = 1800:19800;

sel_smo_pose_tpm = smo_pose_tpm(sel_len,:);
sel_smo_pose_free = smo_pose_free(sel_len,:);

beh_mod_tpm = cell2mat(tempdata_beh_mod_tpm.beh_mod_list(sel_len,2));
beh_mod_free = cell2mat(tempdata_beh_mod_free.beh_mod_list(sel_len,2));

diff_beh_mod_tpm = diff([0;beh_mod_tpm]);
start_list = find(diff_beh_mod_tpm~=0);
end_list = [(start_list(2:end)-1);length(beh_mod_tpm)];
savelist_tpm = [start_list,end_list];

diff_beh_mod_free = diff([0;beh_mod_free]);
start_list = find(diff_beh_mod_free~=0);
end_list = [(start_list(2:end)-1);length(beh_mod_free)];
savelist_free = [start_list,end_list];

savelist_all_tpm = cell(size(savelist_tpm,1),3);
for k = 1:size(savelist_all_tpm,1)
    savelist_all_tpm{k,1} = savelist_tpm(k,1);
    savelist_all_tpm{k,2} = savelist_tpm(k,2);
    savelist_all_tpm{k,3} = sel_smo_pose_tpm(...
        savelist_tpm(k,1):savelist_tpm(k,2),:);
end

savelist_all_free = cell(size(savelist_free,1),3);
for k = 1:size(savelist_all_free,1)
    savelist_all_free{k,1} = savelist_free(k,1);
    savelist_all_free{k,2} = savelist_free(k,2);
    savelist_all_free{k,3} = sel_smo_pose_free(...
        savelist_free(k,1):savelist_free(k,2),:);
end

savelist_mod_tpm = cell(size(savelist_tpm,1),3);
for k = 1:size(savelist_mod_tpm,1)
    savelist_mod_tpm{k,1} = savelist_tpm(k,1);
    savelist_mod_tpm{k,2} = savelist_tpm(k,2);
    savelist_mod_tpm{k,3} = beh_mod_tpm(...
        savelist_tpm(k,1):savelist_tpm(k,2),:);
end

savelist_mod_free = cell(size(savelist_free,1),3);
for k = 1:size(savelist_mod_free,1)
    savelist_mod_free{k,1} = savelist_free(k,1);
    savelist_mod_free{k,2} = savelist_free(k,2);
    savelist_mod_free{k,3} = beh_mod_free(...
        savelist_free(k,1):savelist_free(k,2),:);
end

% insert nan for visualization
nan_mat = nan(10,48);
nan_cell_tpm = {};
for k = 1:size(savelist_all_tpm,1)
    nan_cell_tpm = [nan_cell_tpm;...
        savelist_all_tpm{k,3};...
        nan_mat];
end
nan_mat_tpm = cell2mat(nan_cell_tpm);

nan_cell_free = {};
for k = 1:size(savelist_all_free,1)
    nan_cell_free = [nan_cell_free;...
        savelist_all_free{k,3};...
        nan_mat];
end
nan_mat_free = cell2mat(nan_cell_free);


nan_mod = nan(10,1);
nan_cell_tpm = {};
for k = 1:size(savelist_mod_tpm,1)
    nan_cell_tpm = [nan_cell_tpm;...
        savelist_mod_tpm{k,3};...
        nan_mod];
end
nan_mod_tpm = cell2mat(nan_cell_tpm);

nan_cell_free = {};
for k = 1:size(savelist_mod_free,1)
    nan_cell_free = [nan_cell_free;...
        savelist_mod_free{k,3};...
        nan_mod];
end
nan_mod_free = cell2mat(nan_cell_free);

% plot 
skip_dim = 1;
count_bias = 0.5;

temph = subplot('Position',[...
        start_x+(m-1)*(box_x+inter_x),...
        start_y-(n-1)*(box_y+inter_y)+box_y-move_box_y,...
        box_x,move_box_y]);

count = 1;
for k = 1:skip_dim:size(nan_mat_free,2)
    temptraj = nan_mat_free(:,k);
    show_x = 1:length(temptraj);
    show_y = mat2gray(temptraj);
    show_y(show_y==1) = nan;
    count = count+count_bias;
    plot(show_x,show_y+count,'-','Color',mouse_free_c,...
        'LineWidth',0.25)
    hold on
end
hold off

sel_start = 1800;
sel_end = 3600;

axis([sel_start,sel_end,0,count+2])
box off

set(gca,'TickDir','out')
set(gca,'YTick',count/2)
set(gca,'YTickLabel','TPM',...
    'YTickLabelRotation',90)

title('Trajectory decomposition')

set(gca,'XTick',[sel_start,sel_end])
set(gca,'XTickLabel',[])
xlabel('Time (min)')

set(gca,'FontSize',6)

temph = subplot('Position',[...
        start_x+(m-1)*(box_x+inter_x),...
        start_y-(n-1)*(box_y+inter_y)+...
        box_y-2*move_box_y-0.005,...
        box_x,move_box_y]);
count = 1;
for k = 1:skip_dim:size(nan_mat_tpm,2)
    temptraj = nan_mat_tpm(:,k);
    show_x = 1:length(temptraj);
    show_y = mat2gray(temptraj);
    show_y(show_y==1) = nan;
    count = count+count_bias;
    plot(show_x,show_y+count,'-','Color',mouse_tpm_c,...
        'LineWidth',0.25)
    hold on
end

hold off

sel_start = 1800;
sel_end = 3600;

axis([sel_start,sel_end,0,count+2])
box off

set(gca,'TickDir','out')
set(gca,'YTick',count/2)
set(gca,'YTickLabel','Free',...
    'YTickLabelRotation',90)

set(gca,'XTick',[sel_start,sel_end])
set(gca,'XTickLabel',[0,1])
xlabel('Time (min)')

set(gca,'FontSize',6)

% plot movements
sel_nan_mod_tpm = nan_mod_tpm(sel_start:sel_end);
sel_nan_mod_free = nan_mod_free(sel_start:sel_end);

m = 3;
n = 2;

bar_edge = 0.6;

temph = subplot('Position',[...
        start_x+(m-1)*(box_x+inter_x),...
        start_y-(n-1)*(box_y+inter_y)+box_y-move_box_y,...
        box_x,move_box_y]);

imagesc(sel_nan_mod_tpm')
axis([1,length(sel_nan_mod_tpm),1-bar_edge,1+bar_edge])
colormap(temph,[1,1,1;cmap])

title('Layer 2: movements')
set(gca,'FontSize',6)
box off
set(gca,'TickDir','out')
set(gca,'YTick',1)
set(gca,'YTickLabel','TPM')
set(gca,'YTickLabelRotation',90)
set(gca,'XTick',[1,length(sel_nan_mod_tpm)])
set(gca,'XTickLabel',[])

temph = subplot('Position',[...
        start_x+(m-1)*(box_x+inter_x),...
        start_y-(n-1)*(box_y+inter_y)+...
        box_y-2*move_box_y-0.005,...
        box_x,move_box_y]);
imagesc(sel_nan_mod_free')
axis([1,length(sel_nan_mod_free),1-bar_edge,1+bar_edge])
colormap(temph,[1,1,1;cmap])

set(gca,'FontSize',6)
box off
set(gca,'TickDir','out')
set(gca,'YTick',1)
set(gca,'YTickLabel','Free')
set(gca,'YTickLabelRotation',90)
set(gca,'XTick',[1,length(sel_nan_mod_tpm)])
set(gca,'XTickLabel',[0,1])
xlabel('Time (min)')

%
% plot method, BL-BERT
m = 1;
n = 3;
subplot('Position',[...
        start_x+(m-1)*(box_x+inter_x)-0.01,...
        start_y-(n-1)*(box_y+inter_y),...
        box_x,box_y])

% figure
inter_x_list = (1:6)*20;
bias_x = 0;
for k = 1:length(inter_x_list)
    plotcube([10 10 thick_trans]/shrscale,...
        [inter_x_list(k)-bias_x  0  0]/shrscale,.8,trans_c)
end

bias_x = 0;
for k = 1:length(inter_x_list)
    plotcube([10 10 thick_trans]/shrscale,...
        [inter_x_list(k)-bias_x  0  5]/shrscale,.8,trans_c)
end

for k = 1:length(inter_x_list)
    hold on
    plot3([inter_x_list(k)+5,inter_x_list(k)+5],...
        [5,5],[-2,8],'k-')
    hold on
end
plot3(...
    [25,125],...
    [5,5],...
    [0.5,0.5],'k-')
hold on
plot3(...
    [25,125],...
    [5,5],...
    [5.5,5.5],'k-')

hold on

input_char_cell = {...
    'A','B','C','B','C','E'};
output_char_cell = {...
    'A','<M>','<M>','<M>','<M>','E'};
pred_char_cell = {...
    '','B','C','B','C',''};

for k = 1:length(input_char_cell)
    text(inter_x_list(k)+5,5,-2,input_char_cell{k},...
        'VerticalAlignment','top',...
        'HorizontalAlignment','center',...
        'FontSize',6)
end
for k = 1:length(output_char_cell)
    text(inter_x_list(k)+5,5,8,output_char_cell{k},...
        'VerticalAlignment','bottom',...
        'HorizontalAlignment','center',...
        'FontSize',6)
end
for k = 1:length(output_char_cell)
    text(inter_x_list(k)+5,5,9,pred_char_cell{k},...
        'VerticalAlignment','bottom',...
        'HorizontalAlignment','center',...
        'FontSize',6)
end

for k = 2:(length(inter_x_list)-1)
    hold on
    plot3([inter_x_list(k)+5,inter_x_list(k)+5],...
        [12,12],[-2.5,8.5],'k-')
    hold on
    plot3([inter_x_list(k)+5,inter_x_list(k)+5],...
        [6,12],[-2.5,-2.5],'k-')
    hold on
    plot3([inter_x_list(k)+5,inter_x_list(k)+5],...
        [6,12],[8.5,8.5],'k-')
    hold on
end

hold off

axis([20,140,-4,16,-6,12])
axis off
xlabel('x')
ylabel('y')
zlabel('z')
view(-12,4)
box on
% set(gca,'XTick',[],'YTick',[])
title({'Body Language-Bidirectional Encoder',...
    'Representation from Transformers','(BL-BERT)'})
set(gca,'FontSize',6)
%
% sequences
sel_seq_tpm = seq_tpm(sel_start:sel_end);
sel_seq_free = seq_free(sel_start:sel_end);

sel_seq_tpm_savelist = idx2savelist(sel_seq_tpm);
sel_seq_tpm_savelist(...
    sel_seq_tpm_savelist(:,3)==0,:) = [];

sel_seq_free_savelist = idx2savelist(sel_seq_free);
sel_seq_free_savelist(...
    sel_seq_free_savelist(:,3)==0,:) = [];

m = 2;
n = 3;

box_bias = 0.5;

box_line_w = 2;

box_c = [1,0,0];

temph = subplot('Position',[...
        start_x+(m-1)*(box_x+inter_x),...
        start_y-(n-1)*(box_y+inter_y)+box_y-move_box_y,...
        box_x,move_box_y]);

imagesc(sel_nan_mod_tpm')
hold on
for k = 1:size(sel_seq_tpm_savelist,1)
    start_pos = sel_seq_tpm_savelist(k,1);
    end_pos = sel_seq_tpm_savelist(k,2);
    plot([start_pos,end_pos],[1+box_bias,1+box_bias],...
        '-','LineWidth',box_line_w,...
        'Color',box_c)
    hold on
    plot([start_pos,end_pos],[1-box_bias,1-box_bias],...
        '-','LineWidth',box_line_w,...
        'Color',box_c)
    hold on
    plot([start_pos,start_pos],[1-box_bias,1+box_bias],...
        '-','LineWidth',box_line_w,...
        'Color',box_c)
    hold on
    plot([end_pos,end_pos],[1-box_bias,1+box_bias],...
        '-','LineWidth',box_line_w,...
        'Color',box_c)
    hold on
end
hold off
axis([1,length(sel_nan_mod_tpm),1-bar_edge,1+bar_edge])
colormap(temph,[1,1,1;cmap])

title('Behavior sequences')
set(gca,'FontSize',6)
box off
set(gca,'TickDir','out')
set(gca,'YTick',1)
set(gca,'YTickLabel','TPM')
set(gca,'YTickLabelRotation',90)
set(gca,'XTick',[1,length(sel_nan_mod_tpm)])
set(gca,'XTickLabel',[])

temph = subplot('Position',[...
        start_x+(m-1)*(box_x+inter_x),...
        start_y-(n-1)*(box_y+inter_y)+...
        box_y-2*move_box_y-0.005,...
        box_x,move_box_y]);
imagesc(sel_nan_mod_free')
hold on
for k = 1:size(sel_seq_free_savelist,1)
    start_pos = sel_seq_free_savelist(k,1);
    end_pos = sel_seq_free_savelist(k,2);
    plot([start_pos,end_pos],[1+box_bias,1+box_bias],...
        '-','LineWidth',box_line_w,...
        'Color',box_c)
    hold on
    plot([start_pos,end_pos],[1-box_bias,1-box_bias],...
        '-','LineWidth',box_line_w,...
        'Color',box_c)
    hold on
    plot([start_pos,start_pos],[1-box_bias,1+box_bias],...
        '-','LineWidth',box_line_w,...
        'Color',box_c)
    hold on
    plot([end_pos,end_pos],[1-box_bias,1+box_bias],...
        '-','LineWidth',box_line_w,...
        'Color',box_c)
    hold on
end
hold off
axis([1,length(sel_nan_mod_free),1-bar_edge,1+bar_edge])
colormap(temph,[1,1,1;cmap])

set(gca,'FontSize',6)
box off
set(gca,'TickDir','out')
set(gca,'YTick',1)
set(gca,'YTickLabel','Free')
set(gca,'YTickLabelRotation',90)
set(gca,'XTick',[1,length(sel_nan_mod_tpm)])
set(gca,'XTickLabel',[0,1])
xlabel('Time (min)')

% plot sequences
m = 3;
n = 3;


temph = subplot('Position',[...
        start_x+(m-1)*(box_x+inter_x),...
        start_y-(n-1)*(box_y+inter_y)+box_y-move_box_y,...
        box_x,move_box_y]);

imagesc(sel_seq_tpm')
axis([1,length(sel_seq_tpm),1-bar_edge,1+bar_edge])
colormap(temph,[1,1,1;cmap])

title('Layer 3: sequential ethogram')
set(gca,'FontSize',6)
box off
set(gca,'TickDir','out')
set(gca,'YTick',1)
set(gca,'YTickLabel','TPM')
set(gca,'YTickLabelRotation',90)
set(gca,'XTick',[1,length(sel_nan_mod_tpm)])
set(gca,'XTickLabel',[])

temph = subplot('Position',[...
        start_x+(m-1)*(box_x+inter_x),...
        start_y-(n-1)*(box_y+inter_y)+...
        box_y-2*move_box_y-0.005,...
        box_x,move_box_y]);
imagesc(sel_seq_free')
axis([1,length(sel_seq_free),1-bar_edge,1+bar_edge])
colormap(temph,[1,1,1;cmap])

set(gca,'FontSize',6)
box off
set(gca,'TickDir','out')
set(gca,'YTick',1)
set(gca,'YTickLabel','Free')
set(gca,'YTickLabelRotation',90)
set(gca,'XTick',[1,length(sel_nan_mod_tpm)])
set(gca,'XTickLabel',[0,1])
xlabel('Time (min)')

%% the neural signals
beh_neu_Folder = fullfile(beh_neu_path);
neuOutput = dir(fullfile(beh_neu_Folder,'*neu.mat'));
neuNames = {neuOutput.name}';
splname1 = split(neuNames,'-');

sel_free_idx = strcmp(splname1(:,1),'free');

free_neuNames = neuNames(sel_free_idx);

splname2 = split(splname1(sel_free_idx,3),'tpm');

sort_seq = {...
    3,'ss';...
    2,'pfc';...
    1,'m'};

sort_idx_list = zeros(size(splname2,1),1);

for k = 1:size(sort_idx_list,1)
    tempname = splname2{k,2};
    sel_idx = strcmp(tempname,sort_seq(:,2));
    sort_idx_list(k,:) = sort_seq{sel_idx,1};
end

[~,sort_I] = sort(sort_idx_list);

sort_name = free_neuNames(sort_I);

% load neu data
neu_dsc = cell(size(sort_name,1),2);
neu_dsc(:,1) = sort_name;

for k = 1:size(neu_dsc,1)
     tempdata = load([beh_neu_path,'\',...
        neu_dsc{k,1}]);
     neu_dsc{k,2} = tempdata.dff_smo_Fc;
    disp(k)
end

tpmm_mat = cell2mat(neu_dsc(1:5,2));
tpmpfc_mat = cell2mat(neu_dsc(6:10,2));
tpmss_mat = cell2mat(neu_dsc(11:15,2));

%% sort 
zscore_tpmm_mat = tpmm_mat;
for k = 1:size(zscore_tpmm_mat,1)
    zscore_tpmm_mat(k,:) = zscore(zscore_tpmm_mat(k,:));
end

zscore_tpmpfc_mat = tpmpfc_mat;
for k = 1:size(zscore_tpmpfc_mat,1)
    zscore_tpmpfc_mat(k,:) = zscore(zscore_tpmpfc_mat(k,:));
end

zscore_tpmss_mat = tpmss_mat;
for k = 1:size(zscore_tpmss_mat,1)
    zscore_tpmss_mat(k,:) = zscore(zscore_tpmss_mat(k,:));
end

% sort tpmm
D = pdist(zscore_tpmm_mat,'seuclidean');
Z = squareform(D);

max_Z = max(Z(:));
L = tril(ones(size(Z)));

mask_Z = L*max_Z+(~L).*Z;
mask_Z_pool = mask_Z;

sort_list_tpmm = zeros(size(zscore_tpmm_mat,1),1);
sort_list_tpmm(1,:) = 1;

for k = 1:(size(sort_list_tpmm,1)-1)
    ref_neu_idx = sort_list_tpmm(k,1);
    ref_Z = mask_Z_pool(k,:);
    sel_idx = find(ref_Z==min(ref_Z));
    sort_list_tpmm(k+1,:) = sel_idx;
    mask_Z_pool(k,:) = max_Z;
    mask_Z_pool(:,k) = max_Z;
end

sort_tpmm_mat = zscore_tpmm_mat(sort_list_tpmm,:);

% sort tpmpfc
D = pdist(zscore_tpmpfc_mat,'seuclidean');
Z = squareform(D);

max_Z = max(Z(:));
L = tril(ones(size(Z)));

mask_Z = L*max_Z+(~L).*Z;
mask_Z_pool = mask_Z;

sort_list_tpmpfc = zeros(size(zscore_tpmpfc_mat,1),1);
sort_list_tpmpfc(1,:) = 1;

for k = 1:(size(sort_list_tpmpfc,1)-1)
    ref_neu_idx = sort_list_tpmpfc(k,1);
    ref_Z = mask_Z_pool(k,:);
    sel_idx = find(ref_Z==min(ref_Z));
    sort_list_tpmpfc(k+1,:) = sel_idx;
    mask_Z_pool(k,:) = max_Z;
    mask_Z_pool(:,k) = max_Z;
end

sort_tpmpfc_mat = zscore_tpmpfc_mat(sort_list_tpmpfc,:);

% sort tpmss
D = pdist(zscore_tpmss_mat,'seuclidean');
Z = squareform(D);

max_Z = max(Z(:));
L = tril(ones(size(Z)));

mask_Z = L*max_Z+(~L).*Z;
mask_Z_pool = mask_Z;

sort_list_tpmss = zeros(size(zscore_tpmss_mat,1),1);
sort_list_tpmss(1,:) = 1;

for k = 1:(size(sort_list_tpmss,1)-1)
    ref_neu_idx = sort_list_tpmss(k,1);
    ref_Z = mask_Z_pool(k,:);
    sel_idx = find(ref_Z==min(ref_Z));
    sort_list_tpmss(k+1,:) = sel_idx;
    mask_Z_pool(k,:) = max_Z;
    mask_Z_pool(:,k) = max_Z;
end

sort_tpmss_mat = zscore_tpmss_mat(sort_list_tpmss,:);

all_sort_neu_mat = [...
    sort_tpmss_mat;...
    sort_tpmpfc_mat;
    sort_tpmm_mat...
    ];

seg_lines = [...
    size(sort_tpmss_mat,1);...
    size(sort_tpmss_mat,1)+size(sort_tpmpfc_mat,1);...
    ];
%% show
sel_len = 1800:19800;
clim_min = 0;
clim_max = 1;

start_x = 0.66;
start_y = 0.265;
box_y = 0.44;
box_x = 0.32;

y_list = [...
    1;...
    size(sort_tpmss_mat,1)/2;...
    size(sort_tpmss_mat,1);
    size(sort_tpmss_mat,1)+size(sort_tpmpfc_mat,1)/2;...
    size(sort_tpmss_mat,1)+size(sort_tpmpfc_mat,1);...
    size(sort_tpmss_mat,1)+size(sort_tpmpfc_mat,1)+...
    size(sort_tpmm_mat,1)/2;...
    size(all_sort_neu_mat,1)
    ];

y_tick_list = {...
    1;...
    'S1 (N = 1804)';...
    size(sort_tpmss_mat,1);
    'dmPFC (N = 1340)';...
    size(sort_tpmss_mat,1)+size(sort_tpmpfc_mat,1);...
    'M1 (N = 2981)';...
    size(all_sort_neu_mat,1)
    };

temph = subplot('Position',[start_x,start_y,box_x,box_y]);
imagesc(all_sort_neu_mat(:,sel_len),[clim_min,clim_max])
hold on
for k = 1:size(seg_lines,1)
    plot([0,sel_len(end)],...
        [seg_lines(k),seg_lines(k)],'-k')
    hold on
end
hold off

colormap(temph,cbrewer2('Blues',256))

box off
set(gca,'TickDir','out')
set(gca,'FontSize',6)
set(gca,'YTick',y_list)
set(gca,'YTickLabel',y_tick_list)
set(gca,'YTickLabelRotation',90)
set(gca,'XTick',[1,size(all_sort_neu_mat(:,sel_len),2)])
set(gca,'XTickLabel',{0,10})
xlabel('Time (min)')

% color bar
bar_box_x = 0.1;
temph = subplot('Position',...
    [start_x-bar_box_x+box_x,start_y+box_y+0.002,...
    bar_box_x,0.006]);
imagesc(1:256)
colormap(temph,cbrewer2('Blues',256))
set(gca,'XTick',[],'YTick',[])
title('Z-Score')
set(gca,'FontSize',6)


%% plot canvas 2
hall = figure(2);
set(hall,'Position',[480,0,800,800])
set(hall,'color','white');
%% load data
fileFolder = fullfile(beh_neu_path);
dirOutput = dir(fullfile(fileFolder,'*-cebra.mat'));
cebraNames = {dirOutput.name}';

cebra_cell = cell(size(cebraNames,1),11);
cebra_cell(:,1) = cebraNames;

for k = 1:size(cebra_cell,1)
    tempdata = load([beh_neu_path,'\',cebraNames{k}]);
    cebra_cell{k,2} = tempdata.cebra;
    cebra_cell(k,3:10) = split(cebra_cell{k,1},'-');
    cebra_cell{k,5} = cebra_cell{k,5}(2:end);

    labelname = [cebra_cell{k,1}(1:(end-10)),'.mat'];

    templabel = load([beh_neu_path,'\',labelname]);

    if strcmp(cebra_cell{k,8},'pose')
        cebra_cell{k,11} = templabel.coords3d;
    elseif strcmp(cebra_cell{k,8},'beh_mod')
        cebra_cell{k,11} = templabel.beh_mod_list;
        elseif strcmp(cebra_cell{k,8},'seq')
        cebra_cell{k,11} = templabel.seq_label_list;
    end
    disp(k)
end

%% generate a general list of behavior labels
dsc_name_list = {'tpm';'free';'trap'};
all_class_label = {};
for k = 1:size(dsc_name_list,1)
    %% load
    dsc_path_name = ['recluster_data_',dsc_name_list{k}];
    temp_label = readtable([bea_path,'\', ...
        dsc_path_name,...
        '\cut_beh_80\beh_label.xlsx']);
    %% reorganize
    class_label = temp_label.Behavior;

    all_class_label = [all_class_label;class_label];

    disp(k)
end
%
unique_class_label = unique(all_class_label);
unique_class_idx = (1:length(unique_class_label))';

beh_mod_cmap = cbrewer2('Spectral',length(unique_class_label));
%% generate a general list of sequence labels
sel_seq_cebra = cebra_cell(strcmp('seq',cebra_cell(:,8)),:);
unique_seq_label = unique(cell2mat(sel_seq_cebra(:,11)));

seq_cmap = [...
    0.9*ones(1,3);...
    cbrewer2('Spectral',length(unique_seq_label)-1)];
%% show cebra
exp_cond = 'free';
brain_area = {'tpmss';'tpmpfc';'tpmm'};
beh_type = {'pose';'beh_mod';'seq'};
% beh_type = {'pose';'beh_mod'};
mouse_type = {'tpm';'free'};

show_mouse_type_label = {'Self';'Parter'};
show_brain_area_label = {'S1';'dmPFC';'M1'};
show_beh_type_label = {'Trajectories';'Movements';'Ethogram'};

start_x = 0.02;
start_y = 0.81;

box_x = 0.15;
box_y = box_x;

inter_x = 0.005;
inter_y = 0.005;

big_inter_x = 0.012;

down_sample_idx = 20;

dot_size = 1.5;

for m = 1:length(mouse_type)
    for p = 1:length(brain_area)
        for q = 1:length(beh_type)
            %% select data
            temp_mouse_type = mouse_type{m};
            temp_brain_area = brain_area{p};
            temp_beh_type = beh_type{q};

            sel_mouse_type = strcmp(temp_mouse_type,...
                cebra_cell(:,9));
            sel_brain_area = strcmp(temp_brain_area,...
                cebra_cell(:,5));
            sel_beh_type = strcmp(temp_beh_type,...
                cebra_cell(:,8));

            sel_idx = sel_mouse_type.*...
                sel_brain_area.*...
                sel_beh_type==1;

            sel_cebra_cell = cebra_cell(sel_idx,:);
            %%  show
            subplot('Position',...
                [start_x+(p-1)*(box_x+inter_x)+...
                (m-1)*(3*((box_x+inter_x))+big_inter_x),...
                start_y-(q-1)*(box_y+inter_y),...
                box_x,box_y])

            if strcmp('pose',temp_beh_type)
                cmap = cbrewer2('Spectral',256);

                for k = 1:size(sel_cebra_cell,1)
                    tempcebra = sel_cebra_cell{k,2};
                    temp_show_label = mean(sel_cebra_cell{k,11},2);
                    % temp_show_label = sel_cebra_cell{k,11}(:,19);
    
                    show_label = round(...
                        255*mat2gray(temp_show_label))+1;
    
                    cmaplist = cmap(show_label,:);
    
                    scatter3(...
                        tempcebra(1:down_sample_idx:end,1),...
                        tempcebra(1:down_sample_idx:end,2),...
                        tempcebra(1:down_sample_idx:end,3),...
                        dot_size*ones(size(...
                        tempcebra(1:down_sample_idx:end,:),1),1),...
                        cmaplist(1:down_sample_idx:end,:),'filled')
                    hold on
                end
                hold off
            elseif strcmp('beh_mod',temp_beh_type)
               for k = 1:size(sel_cebra_cell,1)
                     tempcebra = sel_cebra_cell{k,2};
                    temp_show_label = cell2mat(...
                        sel_cebra_cell{k,11}(:,2));

                    cmaplist = beh_mod_cmap(temp_show_label,:);
    
                    scatter3(...
                        tempcebra(1:down_sample_idx:end,1),...
                        tempcebra(1:down_sample_idx:end,2),...
                        tempcebra(1:down_sample_idx:end,3),...
                        dot_size*ones(size(...
                        tempcebra(1:down_sample_idx:end,:),1),1),...
                        cmaplist(1:down_sample_idx:end,:),'filled')
                    hold on
                end
                hold off
            elseif strcmp('seq',temp_beh_type)
               for k = 1:size(sel_cebra_cell,1)
                     tempcebra = sel_cebra_cell{k,2};
                    temp_show_label = ...
                        sel_cebra_cell{k,11};

                    tempcebra(...
                        temp_show_label==0,:) = [];

                    temp_show_label(...
                        temp_show_label==0) = [];
                    
    

                    cmaplist = zeros(...
                        size(temp_show_label,1),3);

                    for a = 1:size(cmaplist,1)
                        cmaplist(a,:) = seq_cmap(...
                            unique_seq_label==...
                            temp_show_label(a),:);
                    end
    
                    scatter3(...
                        tempcebra(1:down_sample_idx:end,1),...
                        tempcebra(1:down_sample_idx:end,2),...
                        tempcebra(1:down_sample_idx:end,3),...
                        dot_size*ones(size(...
                        tempcebra(1:down_sample_idx:end,:),1),1),...
                        cmaplist(1:down_sample_idx:end,:),'filled')
                    hold on
                end
                hold off
            end
            
            set(gca,...
                'XTickLabel',[],...
                'YTickLabel',[],...
                'ZTickLabel',[])

            set(gca,'TickLength',[0;0])

            set(gca,'FontSize',6)
            if q == 1
                if p == 2
                    title({...
                        show_mouse_type_label{m},...
                        show_brain_area_label{p}})
                else
                    title(show_brain_area_label{p})
                end
            end

            if p == 1 && m == 1
                zlabel(show_beh_type_label{q})
            end
            %% show colorbar
            box_x_cbar = 0.005;
            box_y_cbar = 0.08;
            if m == 2 && p == 3
                temph = subplot('Position',...
                [start_x+(p-1)*(box_x+inter_x)+box_x+...
                (m-1)*(3*((box_x+inter_x))+big_inter_x)+...
                0.003,...
                start_y-(q-1)*(box_y+inter_y)+box_y-box_y_cbar,...
                box_x_cbar,box_y_cbar]);
                if strcmp('pose',temp_beh_type)
                    cmap = cbrewer2('Spectral',256);
                    imagesc((1:256)')
                    colormap(temph,cmap)
                    set(gca,'XTick',[],'YTick',[])
                    axis off
                elseif strcmp('beh_mod',temp_beh_type)
                    imagesc((1:size(beh_mod_cmap,1))')
                    hold on
                    for a = 1:size(beh_mod_cmap,1)
                        plot([1-0.5,1+0.5],[a+0.5,a+0.5],...
                            '-w','LineWidth',0.25)
                        hold on
                    end
                    hold off
                    colormap(temph,beh_mod_cmap)
                    set(gca,'XTick',[],'YTick',[])
                    axis off
                elseif strcmp('seq',temp_beh_type)
                    imagesc((1:(size(seq_cmap,1)-1))')
                    hold on
                    for a = (1:(size(seq_cmap,1)-1))
                        plot([1-0.5,1+0.5],[a+0.5,a+0.5],...
                            '-w','LineWidth',0.25)
                        hold on
                    end
                    hold off
                    colormap(temph,seq_cmap(2:end,:))
                    set(gca,'XTick',[],'YTick',[])
                    axis off
                end
                box on
            end
        end
    end
end















