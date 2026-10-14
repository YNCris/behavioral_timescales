%{
    fig1, show behavior differences
%}
clear all
close all
addpath(genpath(pwd))
%% plot canvas
hall = figure(1);
set(hall,'Position',[900,100,800,800])
set(hall,'color','white');
%% set path
rootpath = ['Z:\hanyaning\multi_mice_test\Social_analysis\' ...
    'data\MTPM_social_20220228_all'];
trajpath = [rootpath,'\behavior_data_cut'];
datapath = [rootpath,'\recluster_data'];
%% load data
trajFolder = fullfile(trajpath);
trajOutput = dir(fullfile(trajFolder,'*.mat'));
trajNames = {trajOutput.name}';
trajNames = trajNames(1:30,:);
traj_cell = cell(size(trajNames));
for k = 1:size(traj_cell,1)
    tempdata = load([trajpath,'\',trajNames{k,1}]);
    traj_cell{k,1} = tempdata.coords3d;
end

fix_trajNames = trajNames(1:15,:);
free_trajNames = trajNames(16:30,:);
naive_trajNames = cell(15,1);
for k = 1:size(naive_trajNames,1)
    naive_trajNames{k} = ['naive',trajNames{k+15}(5:end)];
end

naive_traj_cell = cell(size(naive_trajNames));
for k = 1:size(naive_traj_cell,1)
    tempdata = load([trajpath,'\',naive_trajNames{k,1}]);
    naive_traj_cell{k,1} = tempdata.coords3d;
end
fix_vidobj = VideoReader([trajpath,'\fix-seg2-1tpm-2wt-20220226-1.avi']);
free_vidobj = VideoReader([trajpath,'\free-seg1-1tpm-1wt-20220226-1.avi']);

mean_tpm_frame = zeros(512,512);
for k = 1:5
    tpm_img = imread([datapath,'\free_fix_3 1.tif'],...
        'Index',k);
    mean_tpm_frame = mean_tpm_frame+double(tpm_img);
end
all_mean_tpm_frame = round(mat2gray(mean_tpm_frame)*255);

tpm_data = load([datapath,'\fix-seg2-3tpm-3wt-20220227-1.mat']);

load([datapath,'\embedding_20230301.mat']);
load([datapath,'\data_sample_cell_20230301.mat']);
load([datapath,'\group_compare_20230301.mat']);

% load center aligned data
fix_align_traj = cell(size(fix_trajNames,1),2);
for k = 1:size(fix_trajNames,1)
    struct_name = ...
        [fix_trajNames{k,1}(1:(end-4)),'_struct.mat'];
    fix_align_traj{k,1} = struct_name;
    tempdata = load([trajpath,'\struct\',struct_name]);
    fix_align_traj{k,2} = tempdata.BeA.BeA_DecData.XY;
end

free_align_traj = cell(size(free_trajNames,1),2);
for k = 1:size(free_trajNames,1)
    struct_name = ...
        [free_trajNames{k,1}(1:(end-4)),'_struct.mat'];
    free_align_traj{k,1} = struct_name;
    tempdata = load([trajpath,'\struct\',struct_name]);
    free_align_traj{k,2} = tempdata.BeA.BeA_DecData.XY;
end

all_align_traj = [fix_align_traj;free_align_traj];

% hist_mean_tpm_frame = adapthisteq(all_mean_tpm_frame);
%% plot panels
%% experimental time lines
subplot('Position',[0.05,0.34,0.301,0.1])
box on
set(gca,'XTick',[],'YTick',[])
xlabel('Experimental time line')
%% experimental paradigms
sel_fix_frame = 1800;
sel_free_frame = 4200;

fix_case_frame = read(fix_vidobj,sel_fix_frame);
free_case_frame = read(free_vidobj,sel_free_frame);

frame_height = 480;
frame_width = 640;

start_x = 0.05;
start_y = 0.85;
box_x = 0.15;
box_y = box_x*frame_height/frame_width;
inter_x = 0.005;
inter_y = 0.005;

subplot('Position',[start_x,start_y,box_x,box_y])
imshow(fix_case_frame)
title('Trapped partner')
ylabel('Frames')

subplot('Position',[start_x+box_x+inter_x,start_y,box_x,box_y])
imshow(free_case_frame)
title('Free partner')

fix_c = [0.5,0,0];
free_c = [0,0,0.3];
naive_c = [0,0.3,0];

edge_bias = 10;

% 2D trajectories
smo_win = 30;
fix_case_traj = traj_cell{1,1};
for k = 1:size(fix_case_traj,2)
    fix_case_traj(:,k) = smooth(fix_case_traj(:,k),smo_win);
end
free_case_traj = traj_cell{16,1};
for k = 1:size(free_case_traj,2)
    free_case_traj(:,k) = smooth(free_case_traj(:,k),smo_win);
end
naive_case_traj = naive_traj_cell{1,1};
for k = 1:size(naive_case_traj,2)
    naive_case_traj(:,k) = smooth(naive_case_traj(:,k),smo_win);
end

subplot('Position',[start_x,start_y-box_x-inter_y,box_x,box_x])
plot(fix_case_traj(:,1),fix_case_traj(:,2),'-','Color',fix_c)
min_x = min(fix_case_traj(:,1));
max_x = max(fix_case_traj(:,1));
min_y = min(fix_case_traj(:,2));
max_y = max(fix_case_traj(:,2));
axis([min_x-edge_bias,max_x+edge_bias,min_y-edge_bias,max_y+edge_bias])
ylabel('Trajectories')
set(gca,'XTick',[],'YTick',[])
subplot('Position',[start_x+box_x+inter_x,start_y-box_x-inter_y,box_x,box_x])
plot(free_case_traj(:,1),free_case_traj(:,2),'-','Color',free_c)
min_x = min(free_case_traj(:,1));
max_x = max(free_case_traj(:,1));
min_y = min(free_case_traj(:,2));
max_y = max(free_case_traj(:,2));
axis([min_x-edge_bias,max_x+edge_bias,min_y-edge_bias,max_y+edge_bias])
set(gca,'XTick',[],'YTick',[])

% 3D poses
pos_bias = 0.075;
temp_alpha = 0.05;
drawline = [ 1 2; 1 3;2 3; 4 5;4 6;5 7;6 8;7 14;8 14;...
    5 9;7 11;6 10; 8 12;14 15; 15 16;5,13;6,13;7,13;8,13;...
    2 4;3 4;5,6;7,8];
max_z = 30;
subplot('Position',[start_x, ...
    start_y-box_y-box_x-2*inter_y+pos_bias, ...
    box_x,box_y-pos_bias])
coords3d = fix_case_traj(sel_fix_frame,:);
new_mesh_mouse(coords3d, temp_alpha, fix_c)
hold on
plot_skl_dl(coords3d(1:3:end)', ...
            coords3d(2:3:end)', ...
            coords3d(3:3:end)',...
    'k','k',drawline)
hold off
view(-90,0)
box on
xy_bias = 10;
min_x = min(coords3d(1:3:end));
max_x = max(coords3d(1:3:end));
min_y = min(coords3d(2:3:end));
max_y = max(coords3d(2:3:end));
% min_z = min([coords3d(3:3:end),coords3d_naive(3:3:end)]);
% max_z = max([coords3d(3:3:end),coords3d_naive(3:3:end)]);
axis([min_x-xy_bias,max_x+xy_bias,min_y-xy_bias,max_y+xy_bias, ...
    0,max_z])
set(gca,'XTick',[],'YTick',[],'ZTick',[])
ylabel('x')
zlabel({'3D poses','z'})

max_z = 50;
subplot('Position', ...
    [start_x+box_x+inter_x, ...
    start_y-box_y-box_x-2*inter_y+pos_bias, ...
    box_x,box_y-pos_bias])
coords3d = free_case_traj(sel_free_frame,:);
coords3d(3:3:end) = coords3d(3:3:end)*1.8-5;
new_mesh_mouse(coords3d, temp_alpha, free_c)
hold on
coords3d_naive = naive_case_traj(sel_free_frame,:);
coords3d_naive(3:3:end) = coords3d_naive(3:3:end)*1.8-10;
new_mesh_mouse(coords3d_naive, temp_alpha, naive_c)
hold on
plot_skl_dl(coords3d(1:3:end)', ...
            coords3d(2:3:end)', ...
            coords3d(3:3:end)',...
    'k','k',drawline)
hold on
plot_skl_dl(coords3d_naive(1:3:end)', ...
            coords3d_naive(2:3:end)', ...
            coords3d_naive(3:3:end)',...
    'k','k',drawline)
hold off
view(0,0)
box on
xy_bias = 10;
min_x = min([coords3d(1:3:end),coords3d_naive(1:3:end)]);
max_x = max([coords3d(1:3:end),coords3d_naive(1:3:end)]);
min_y = min([coords3d(2:3:end),coords3d_naive(2:3:end)]);
max_y = max([coords3d(2:3:end),coords3d_naive(2:3:end)]);
% min_z = min([coords3d(3:3:end),coords3d_naive(3:3:end)]);
% max_z = max([coords3d(3:3:end),coords3d_naive(3:3:end)]);
axis([min_x-xy_bias,max_x+xy_bias,min_y-xy_bias,max_y+xy_bias, ...
    0,max_z])
set(gca,'XTick',[],'YTick',[],'ZTick',[])
xlabel('x')

% tpm
pos_bias = pos_bias-0.02;
subplot('Position',[start_x, ...
    start_y-box_y-2*box_x-3*inter_y+pos_bias, ...
    box_x,box_x])
imshow(all_mean_tpm_frame,[])
ylabel('TPM')
box on
xlabel('Raw frame')

xy_bias =0;
xy_k = 1;
neu_stat = tpm_data.stat;
neu_stat = neu_stat(tpm_data.iscell(:,1)==1);
temph = subplot('Position', ...
    [start_x+box_x+inter_x, ...
    start_y-box_y-2*box_x-3*inter_y+pos_bias,...
    box_x,box_x]);
% imshow(all_mean_tpm_frame,[])
% hold on
pad_frame = zeros(size(all_mean_tpm_frame));
for k = 1:length(neu_stat)
    x_loc = round(xy_k*double(neu_stat{k}.xpix)'+xy_bias);
    y_loc = round(xy_k*double(neu_stat{k}.ypix)'+xy_bias);
    for m = 1:length(x_loc)
        pad_frame(x_loc(m),y_loc(m)) = k;
    end
end
temp_show_frame = zeros(512,512,3);
temp_show_frame(:,:,1) = all_mean_tpm_frame;
temp_show_frame(:,:,2) = all_mean_tpm_frame;
temp_show_frame(:,:,3) = all_mean_tpm_frame;
temp_show_frame = uint8(temp_show_frame);
show_frame = labeloverlay(temp_show_frame,pad_frame);
imshow(show_frame,[])
box on
xlabel('Neuron extraction')

%% compare classical parameters
% distance to ref
fix_traj_cell = traj_cell(1:15,:);
free_traj_cell = traj_cell(16:30,:);

center_pos = [-50,550];

dpi = 500/550;%mm/pixel

fix_dist = zeros(size(fix_traj_cell));
for k = 1:length(fix_traj_cell)
    temptraj = fix_traj_cell{k,1};
    temptrajcenter = temptraj(:,34:35);
    all_dist = sqrt(sum((temptrajcenter-...
    ones(size(temptrajcenter,1),1)* ...
    center_pos).^2,2))*dpi;
    fix_dist(k,1) = mean(all_dist);
end

free_dist = zeros(size(free_traj_cell));
for k = 1:length(free_traj_cell)
    tempfreetraj = free_traj_cell{k,1};
    tempnaivetraj = naive_traj_cell{k,1};
    temp_free_center = tempfreetraj(:,34:35);
    temp_naive_center = tempnaivetraj(:,34:35);
    all_dist = sqrt(sum( ...
        (temp_free_center-temp_naive_center).^2,2))*dpi;
    free_dist(k,1) = mean(all_dist);
end

bar_w = 0.6;
xlist = [1,2];
mk_size = 2;
xlabel_list = {'Trapped','Free'};

fix_dist = fix_dist/10;% to cm
free_dist = free_dist/10;% to cm
mean_fix_dist = mean(fix_dist);
mean_free_dist = mean(free_dist);
std_fix_dist = std(fix_dist);
std_free_dist = std(free_dist);
subplot('Position',[0.41,0.76,0.1,0.2]);
bar(xlist(1),mean_fix_dist,bar_w,'FaceColor','none','EdgeColor',fix_c)
hold on
bar(xlist(2),mean_free_dist,bar_w,'FaceColor','none','EdgeColor',free_c)
hold on
errorbar(xlist(1),mean_fix_dist,std_fix_dist,'Color',fix_c)
hold on
errorbar(xlist(2),mean_free_dist,std_free_dist,'Color',free_c)
hold on
plot(xlist(1)*ones(size(fix_dist))+bar_w/2,fix_dist,'o', ...
    'MarkerFaceColor','w','MarkerEdgeColor',fix_c,...
    'MarkerSize',mk_size)
hold on
plot(xlist(2)*ones(size(free_dist))+bar_w/2,free_dist,'o', ...
    'MarkerFaceColor','w','MarkerEdgeColor',free_c,...
    'MarkerSize',mk_size)
hold off
box off
set(gca,'TickDir','out')
set(gca,'XTick',xlist)
set(gca,'XTickLabel',xlabel_list)
ylabel('Body distance (cm)')
axis([0.2,2.8,0,max([fix_dist;free_dist])])


% locomotion
fix_loco = zeros(size(fix_traj_cell));
for k = 1:size(fix_loco,1)
    temptraj = fix_traj_cell{k,1}(:,34:35);
    loco_dist = sqrt(sum(([0,0;diff(temptraj)]).^2,2))*dpi;
    fix_loco(k,1) = sum(loco_dist);
end

free_loco = zeros(size(free_traj_cell));
for k = 1:size(free_loco,1)
    temptraj = free_traj_cell{k,1}(:,34:35);
    loco_dist = sqrt(sum(([0,0;diff(temptraj)]).^2,2))*dpi;
    free_loco(k,1) = sum(loco_dist);
end

fix_loco = fix_loco/10/1000;%to cm
free_loco = free_loco/10/1000;%to cm

mean_fix_loco = mean(fix_loco);
mean_free_loco = mean(free_loco);
std_fix_loco = std(fix_loco);
std_free_loco = std(free_loco);

subplot('Position',[0.56,0.76,0.1,0.2]);
bar(xlist(1),mean_fix_loco,bar_w,'FaceColor','none','EdgeColor',fix_c)
hold on
bar(xlist(2),mean_free_loco,bar_w,'FaceColor','none','EdgeColor',free_c)
hold on
errorbar(xlist(1),mean_fix_loco,std_fix_loco,'Color',fix_c)
hold on
errorbar(xlist(2),mean_free_loco,std_free_loco,'Color',free_c)
hold on
plot(xlist(1)*ones(size(fix_loco))+bar_w/2,fix_loco,'o', ...
    'MarkerFaceColor','w','MarkerEdgeColor',fix_c,...
    'MarkerSize',mk_size)
hold on
plot(xlist(2)*ones(size(free_loco))+bar_w/2,free_loco,'o', ...
    'MarkerFaceColor','w','MarkerEdgeColor',free_c,...
    'MarkerSize',mk_size)
hold off
box off
set(gca,'TickDir','out')
set(gca,'XTick',xlist)
set(gca,'XTickLabel',xlabel_list)
% ytickformat('%.1e');
ylabel('Locomotion distance ( x 10^3 cm)')
axis([0.2,2.8,0,max([fix_loco;free_loco])])


% position preference
center_pos = [-50,550];
field_r = 500/dpi/2;

fix_pp = zeros(size(fix_traj_cell));
for k = 1:size(fix_pp,1)
    temptraj = fix_traj_cell{k,1}(:,34:35);
    all_dist = sqrt(sum((temptraj-...
    ones(size(temptraj,1),1)* ...
    center_pos).^2,2))*dpi;
    fix_pp(k,1) = mean(all_dist/field_r);
end

free_pp = zeros(size(free_traj_cell));
for k = 1:size(free_pp,1)
    temptraj = free_traj_cell{k,1}(:,34:35);
    all_dist = sqrt(sum((temptraj-...
    ones(size(temptraj,1),1)* ...
    center_pos).^2,2))*dpi;
    free_pp(k,1) = mean(all_dist/field_r);
end

mean_fix_pp = mean(fix_pp);
std_fix_pp = std(fix_pp);
mean_free_pp = mean(free_pp);
std_free_pp = std(free_pp);

subplot('Position',[0.71,0.76,0.1,0.2]);
bar(xlist(1),mean_fix_pp,bar_w,'FaceColor','none','EdgeColor',fix_c)
hold on
bar(xlist(2),mean_free_pp,bar_w,'FaceColor','none','EdgeColor',free_c)
hold on
errorbar(xlist(1),mean_fix_pp,std_fix_pp,'Color',fix_c)
hold on
errorbar(xlist(2),mean_free_pp,std_free_pp,'Color',free_c)
hold on
plot(xlist(1)*ones(size(fix_pp))+bar_w/2,fix_pp,'o', ...
    'MarkerFaceColor','w','MarkerEdgeColor',fix_c,...
    'MarkerSize',mk_size)
hold on
plot(xlist(2)*ones(size(free_pp))+bar_w/2,free_pp,'o', ...
    'MarkerFaceColor','w','MarkerEdgeColor',free_c,...
    'MarkerSize',mk_size)
hold off
box off
set(gca,'TickDir','out')
set(gca,'XTick',xlist)
set(gca,'XTickLabel',xlabel_list)
% ytickformat('%.1e');
ylabel('Peripheral region preference')
axis([0.2,2.8,0,max([fix_pp;free_pp])])


% Vertical locomotion
fix_ver_loco = zeros(size(fix_traj_cell));
free_ver_loco = zeros(size(free_traj_cell));

for k = 1:size(fix_ver_loco,1)
    temptraj = fix_traj_cell{k,1}(:,3);
    ver_dist = sqrt(diff(temptraj).^2)*dpi;
    fix_ver_loco(k,1) = sum(ver_dist);
end

for k = 1:size(free_ver_loco,1)
    temptraj = free_traj_cell{k,1}(:,3);
    ver_dist = sqrt(diff(temptraj).^2)*dpi;
    free_ver_loco(k,1) = sum(ver_dist);
end

fix_ver_loco = fix_ver_loco/10/1000;
free_ver_loco = free_ver_loco/10/1000;

mean_fix_ver_loco = mean(fix_ver_loco);
mean_free_ver_loco = mean(free_ver_loco);
std_fix_ver_loco = std(fix_ver_loco);
std_free_ver_loco = std(free_ver_loco);

subplot('Position',[0.86,0.76,0.1,0.2]);
bar(xlist(1),mean_fix_ver_loco,bar_w,'FaceColor','none','EdgeColor',fix_c)
hold on
bar(xlist(2),mean_free_ver_loco,bar_w,'FaceColor','none','EdgeColor',free_c)
hold on
errorbar(xlist(1),mean_fix_ver_loco,std_fix_ver_loco,'Color',fix_c)
hold on
errorbar(xlist(2),mean_free_ver_loco,std_free_ver_loco,'Color',free_c)
hold on
plot(xlist(1)*ones(size(fix_ver_loco))+bar_w/2,fix_ver_loco,'o', ...
    'MarkerFaceColor','w','MarkerEdgeColor',fix_c,...
    'MarkerSize',mk_size)
hold on
plot(xlist(2)*ones(size(free_ver_loco))+bar_w/2,free_ver_loco,'o', ...
    'MarkerFaceColor','w','MarkerEdgeColor',free_c,...
    'MarkerSize',mk_size)
hold off
box off
set(gca,'TickDir','out')
set(gca,'XTick',xlist)
set(gca,'XTickLabel',xlabel_list)
% ytickformat('%.1e');
ylabel('Vertical locomotion ( x 10^3 cm)')
axis([0.2,2.8,0,max([fix_ver_loco;free_ver_loco])])


%% subtle behavior comparison
%% all data
mk_size = 4;

T = unique(best_label_embedding(:,4));
atlas_cmap = cbrewer2('Spectral',length(T));
atlas_cmap_list = atlas_cmap(best_label_embedding(:,4),:);
% atlas
% subplot('Position',[0.41,0.54,0.15,0.15]);
% scatter3(best_label_embedding(:,1),...
%          best_label_embedding(:,2),...
%          best_label_embedding(:,3),...
%          5*ones(size(best_label_embedding,1),1),...
%          atlas_cmap_list,'filled');
% xlabel('UMAP 1')
% ylabel('UMAP 2')
% zlabel('Normalized speed')
% set(gca,'XTickLabel',[],'YTickLabel',[])

% fractions
all_group_compare = cell2mat(cellfun(@(x) x(:,2), ...
    group_compare(:,3),...
    'UniformOutput',false)');

fix_frac = all_group_compare(:,1:15)';
free_frac = all_group_compare(:,16:30)';

mean_fix_frac = mean(fix_frac);
mean_free_frac = mean(free_frac);
std_fix_frac = std(fix_frac)/sqrt(size(fix_frac,1));
std_free_frac = std(free_frac)/sqrt(size(free_frac,1));

alpha_fix_free = 0.2;

subplot('Position',[0.41,0.54,0.56,0.15]);
for k = 1:size(fix_frac,1)
    plot(T,fix_frac(k,:),'o','Color',[fix_c,alpha_fix_free], ...
        'MarkerSize',2)
    hold on
    plot(T,free_frac(k,:),'o','Color',[free_c,alpha_fix_free], ...
        'MarkerSize',2)
    hold on
end
errorbar(T,mean_fix_frac,std_fix_frac, ...
    'Color',fix_c,'LineStyle','none')
hold on
errorbar(T,mean_free_frac,std_free_frac, ...
    'Color',free_c,'LineStyle','none')
hold on
plot(T,mean_fix_frac,'o-','Color',fix_c, ...
    'MarkerFaceColor',fix_c,...
    'MarkerSize',mk_size)
hold on
plot(T,mean_free_frac,'o-','Color',free_c,...
    'MarkerFaceColor',free_c,...
    'MarkerSize',mk_size)
hold off
box off
axis([0,max(T)+1,0,0.12])
set(gca,'TickDir','out')
set(gca,'XTick',T)
set(gca,'YTick',[0,0.12])
ylabel('Fractions')
set(gca,'XTickLabel',[])


%% close distance
% atlas
% subplot('Position',[0.41,0.32,0.15,0.15]);


% fractions
dist_thres = 50/dpi;% mm

close_fix_frac = zeros(size(fix_frac));
for k = 1:size(close_fix_frac,1)
    tempname = fix_trajNames{k,1};
    sel_name = [tempname(1:(end-4)),'_struct.mat'];
    sel_data_sample_cell = data_sample_cell( ...
        strcmp(data_sample_cell(:,3),sel_name),:);
    
    temptraj = fix_traj_cell{k,1}(:,1:2);
    all_dist = sqrt(sum((temptraj-...
    ones(size(temptraj,1),1)* ...
    center_pos).^2,2))*dpi;
    
    dist_idx = double(dist_thres>all_dist);
    move_dist_list = zeros(size(sel_data_sample_cell,1),1);
    for m = 1:size(sel_data_sample_cell,1)
        start_idx = sel_data_sample_cell{m,2}(1);
        end_idx = sel_data_sample_cell{m,2}(2);
        tempmode = mode(dist_idx(start_idx:end_idx));
        move_dist_list(m,1) = tempmode;
    end
    
    savelist = cell2mat(sel_data_sample_cell(:,2));
    classlist = savelist(:,4);
    tempfraclist = zeros(1,size(close_fix_frac,2));
    for m = 1:length(classlist)
        tempfraclist(classlist(m)) = ...
            tempfraclist(classlist(m))+move_dist_list(m);
    end
    close_fix_frac(k,:) = tempfraclist/length(classlist);
end


close_free_frac = zeros(size(free_frac));
for k = 1:size(close_free_frac,1)
    tempname = free_trajNames{k,1};
    sel_name = [tempname(1:(end-4)),'_struct.mat'];
    sel_data_sample_cell = data_sample_cell( ...
        strcmp(data_sample_cell(:,3),sel_name),:);

    tempfreetraj = free_traj_cell{k,1};
    tempnaivetraj = naive_traj_cell{k,1};
    temp_free_center = tempfreetraj(:,1:2);
    temp_naive_center = tempnaivetraj(:,34:35);
    all_dist = sqrt(sum( ...
        (temp_free_center-temp_naive_center).^2,2))*dpi;

    dist_idx = double(dist_thres>all_dist);
    move_dist_list = zeros(size(sel_data_sample_cell,1),1);
    for m = 1:size(sel_data_sample_cell,1)
        start_idx = sel_data_sample_cell{m,2}(1);
        end_idx = sel_data_sample_cell{m,2}(2);
        tempmode = mode(dist_idx(start_idx:end_idx));
        move_dist_list(m,1) = tempmode;
    end
    
    savelist = cell2mat(sel_data_sample_cell(:,2));
    classlist = savelist(:,4);
    tempfraclist = zeros(1,size(close_free_frac,2));
    for m = 1:length(classlist)
        tempfraclist(classlist(m)) = ...
            tempfraclist(classlist(m))+move_dist_list(m);
    end
    close_free_frac(k,:) = tempfraclist/length(classlist);
end



mean_close_fix_frac = mean(close_fix_frac);
mean_close_free_frac = mean(close_free_frac);
std_close_fix_frac = std(close_fix_frac)/sqrt(size(close_fix_frac,1));
std_close_free_frac = std(close_free_frac)/sqrt(size(close_free_frac,1));

stat_close_fix_free_frac = [close_fix_frac;close_free_frac]';

subplot('Position',[0.41,0.34,0.56,0.15]);
for k = 1:size(close_fix_frac,1)
    plot(T,close_fix_frac(k,:),'o','Color',[fix_c,alpha_fix_free], ...
        'MarkerSize',2)
    hold on
    plot(T,close_free_frac(k,:),'o','Color',[free_c,alpha_fix_free], ...
        'MarkerSize',2)
    hold on
end
errorbar(T,mean_close_fix_frac,std_close_fix_frac, ...
    'Color',fix_c,'LineStyle','none')
hold on
errorbar(T,mean_close_free_frac,std_close_free_frac, ...
    'Color',free_c,'LineStyle','none')
hold on
plot(T,mean_close_fix_frac,'o-','Color',fix_c, ...
    'MarkerFaceColor',fix_c,...
    'MarkerSize',mk_size)
hold on
plot(T,mean_close_free_frac,'o-','Color',free_c,...
    'MarkerFaceColor',free_c,...
    'MarkerSize',mk_size)
hold off
box off
axis([0,max(T)+1,0,0.025])
set(gca,'TickDir','out')
set(gca,'XTick',T)
set(gca,'XTickLabel',[])
set(gca,'YTick',[0,0.025])
ylabel('Close fractions')
xlabel('Behavior module indexes')

subplot('Position',[0.41,0.323,0.56,0.01]);
x_bias = 0.3;
for k = 1:length(T)
    plot([T(k)-x_bias,T(k)+x_bias],[1,1],'-',...
        'Color',atlas_cmap(k,:),'LineWidth',5)
    hold on
end
hold off
axis([0,max(T)+1,0,2])
% set(gca,'XTick',T)
axis off
%% behavior phenotypes
% all: 29
% close: 23, 30, 34, 35, 36

% all
start_x = 0.06;
start_y = 0.15;
inter_y = 0.005;
box_x = 0.12;
box_y = 0.06;

body_edge_x = 5;
body_edge_y = 5;

temp_save_list = cell2mat(data_sample_cell(:,2));
all_savelist = temp_save_list(:,4);

sel_beh_idx = 29;
sel_idx_list = all_savelist==sel_beh_idx;
sel_data_sample_cell = data_sample_cell(sel_idx_list,:);
sel_fix_frame_cell = cell(size(all_align_traj,1),1);
for k = 1:size(sel_fix_frame_cell,1)
    %
    tempname = all_align_traj{k,1};
    temp_align_xy = all_align_traj{k,2};
    sel_idx_list = strcmp(tempname,sel_data_sample_cell(:,3));
    temp_data_sample_cell = ...
    sel_data_sample_cell(sel_idx_list,:);
    temp_xy = cell(size(temp_data_sample_cell,1),1);
    %
    for m = 1:size(temp_data_sample_cell,1)
        start_idx = temp_data_sample_cell{m,2}(1);
        end_idx = temp_data_sample_cell{m,2}(2);
        temp_xy{m,1} = temp_align_xy(:,start_idx:end_idx)';
    end
    temp_xy = cell2mat(temp_xy);
    sel_fix_frame_cell{k,1} = temp_xy;
end

sel_frame_mat = cell2mat(sel_fix_frame_cell);
mean_fix_frame = mean(sel_frame_mat);

axis_min_x = min(mean_fix_frame(1:3:end));
axis_max_x = max(mean_fix_frame(1:3:end));
axis_min_y = min(mean_fix_frame(2:3:end));
axis_max_y = max(mean_fix_frame(2:3:end));
axis_min_z = min(mean_fix_frame(3:3:end));
axis_max_z = max(mean_fix_frame(3:3:end));

% calculate xy and xz locomtion heatmap
sel_frame_xy = sel_frame_mat;
sel_frame_xy(:,3:3:end) = [];
[XX_xy,YY_xy,conv_bk_xy] = loco_heatmap(sel_frame_xy);
sel_frame_xz = sel_frame_mat;
sel_frame_xz(:,2:3:end) = [];
[XX_xz,YY_xz,conv_bk_xz] = loco_heatmap(sel_frame_xz);

loco_cmap = [ones(8,3);cbrewer2('OrRd',16)];
loco_cmap = mat2gray(imresize(loco_cmap,[256,3]));
% loco_cmap(1:128,:) = imresize(loco_cmap(1:16,:),[128,3]);
% loco_cmap = mat2gray(loco_cmap);

%
temph = subplot('Position',[start_x,start_y,box_x,box_y]);
imagesc([min(XX_xz(:)),max(XX_xz(:))],...
        [min(YY_xz(:)),max(YY_xz(:))],...
        conv_bk_xz)
hold on
plot_skl_dl_2d(mean_fix_frame(1:3:end)', ...
            mean_fix_frame(3:3:end)',...
    'k','k',drawline)
hold off
box on
xlabel('x')
ylabel('z')
set(gca,'XTickLabel',[],'YTickLabel',[],'ZTickLabel',[])
view(0,-90)
grid on
colormap(temph,loco_cmap)
axis([axis_min_x-body_edge_x,axis_max_x+body_edge_x, ...
    axis_min_z-body_edge_y,axis_max_z+body_edge_y])
temph = subplot('Position', ...
    [start_x,start_y+box_y+inter_y,box_x,box_y]);
imagesc([min(XX_xy(:)),max(XX_xy(:))], ...
    [min(YY_xy(:)),max(YY_xy(:))],conv_bk_xy);

colormap(temph,loco_cmap)
hold on
plot_skl_dl_2d(mean_fix_frame(1:3:end)', ...
            mean_fix_frame(2:3:end)',...
    'k','k',drawline)
hold off
box on
view(0,90)
set(gca,'XTickLabel',[],'YTickLabel',[])
title('Rising')
ylabel({'Behavior difference','of all data','y'})
grid on
axis([axis_min_x-body_edge_x,axis_max_x+body_edge_x, ...
      axis_min_y-body_edge_y,axis_max_y+body_edge_y])

% close
start_x = 0.28;
inter_x = 0.02;
close_list = [23, 30, 34, 35, 36]';
% close_title_list = ...
%     {'Rearing','Stepping','Walking',...
%     'Approaching','Walking sniffing'}';

close_title_list = ...
    {'Rearing','Left turning','Right turning',...
    'Approaching','Walking sniffing'}';

mean_free_frame_cell = cell(length(close_list),1);
sel_frame_cell = cell(size(mean_free_frame_cell));
for k = 1:length(close_list)
    sel_beh_idx = close_list(k);
    sel_idx_list = all_savelist==sel_beh_idx;
    sel_data_sample_cell = data_sample_cell(sel_idx_list,:);
    sel_fix_frame_cell = cell(size(all_align_traj,1),1);
    for n = 1:size(sel_fix_frame_cell,1)
        %
        tempname = all_align_traj{n,1};
        temp_align_xy = all_align_traj{n,2};
        sel_idx_list = strcmp(tempname,sel_data_sample_cell(:,3));
        temp_data_sample_cell = ...
        sel_data_sample_cell(sel_idx_list,:);
        temp_xy = cell(size(temp_data_sample_cell,1),1);
        %
        for m = 1:size(temp_data_sample_cell,1)
            start_idx = temp_data_sample_cell{m,2}(1);
            end_idx = temp_data_sample_cell{m,2}(2);
            temp_xy{m,1} = temp_align_xy(:,start_idx:end_idx)';
        end
        temp_xy = cell2mat(temp_xy);
        sel_fix_frame_cell{n,1} = temp_xy;
    end
    
    sel_frame_mat = cell2mat(sel_fix_frame_cell);

    sel_frame_cell{k,1} = sel_frame_mat;

    mean_free_frame = mean(sel_frame_mat);
    mean_free_frame_cell{k,1} = mean_free_frame;
end

% calculate heatmamp for close distance
axis_cell = cell(size(mean_free_frame_cell,1),6);
XX_xy_cell = cell(size(mean_free_frame_cell,1),1);
YY_xy_cell = cell(size(XX_xy_cell));
XX_xz_cell = cell(size(XX_xy_cell));
YY_xz_cell = cell(size(XX_xy_cell));
conv_bk_xy_cell = cell(size(XX_xy_cell));
conv_bk_xz_cell = cell(size(XX_xy_cell));

for k = 1:size(mean_free_frame_cell,1)
    temp_mean = mean_free_frame_cell{k,1};
    temp_sel_frame = sel_frame_cell{k,1};
    axis_cell{k,1} = min(temp_mean(1:3:end));
    axis_cell{k,2} = max(temp_mean(1:3:end));
    axis_cell{k,3} = min(temp_mean(2:3:end));
    axis_cell{k,4} = max(temp_mean(2:3:end));
    axis_cell{k,5} = min(temp_mean(3:3:end));
    axis_cell{k,6} = max(temp_mean(3:3:end));
    
    % calculate xy and xz locomtion heatmap
    sel_frame_xy = temp_sel_frame;
    sel_frame_xy(:,3:3:end) = [];
    [XX_xy,YY_xy,conv_bk_xy] = loco_heatmap(sel_frame_xy);
    XX_xy_cell{k,1} = XX_xy;
    YY_xy_cell{k,1} = YY_xy;
    conv_bk_xy_cell{k,1} = conv_bk_xy;

    sel_frame_xz = temp_sel_frame;
    sel_frame_xz(:,2:3:end) = [];
    [XX_xz,YY_xz,conv_bk_xz] = loco_heatmap(sel_frame_xz);
    XX_xz_cell{k,1} = XX_xz;
    YY_xz_cell{k,1} = YY_xz;
    conv_bk_xz_cell{k,1} = conv_bk_xz;

end

for k = 1:length(close_list)
    temph = subplot('Position', ...
        [start_x+(k-1)*(inter_x+box_x), ...
        start_y, ...
        box_x,box_y]);

    imagesc( ...
    [min(XX_xz_cell{k,1}(:)),max(XX_xz_cell{k,1}(:))], ...
    [min(YY_xz_cell{k,1}(:)),max(YY_xz_cell{k,1}(:))], ...
    conv_bk_xz_cell{k,1});

    colormap(temph,loco_cmap)
    
    hold on

    plot_skl_dl_2d( ...
            mean_free_frame_cell{k,1}(1:3:end)', ...
            mean_free_frame_cell{k,1}(3:3:end)',...
    'k','k',drawline)
    view(0,-90)
    hold off
    box on
    if k == 1
        ylabel('z')
    end
    xlabel('x')
    set(gca,'XTickLabel',[],'YTickLabel',[],'ZTickLabel',[])
    axis([axis_cell{k,1}-body_edge_x,axis_cell{k,2}+body_edge_x, ...
      axis_cell{k,5}-body_edge_y,axis_cell{k,6}+body_edge_y])

    grid on

    
    temph = subplot('Position', ...
        [start_x+(k-1)*(inter_x+box_x), ...
        start_y+box_y+inter_y, ...
        box_x,box_y]);
    
    imagesc( ...
    [min(XX_xy_cell{k,1}(:)),max(XX_xy_cell{k,1}(:))], ...
    [min(YY_xy_cell{k,1}(:)),max(YY_xy_cell{k,1}(:))], ...
    conv_bk_xy_cell{k,1});

    colormap(temph,loco_cmap)
    
    hold on

    plot_skl_dl_2d( ...
            mean_free_frame_cell{k,1}(1:3:end)', ...
            mean_free_frame_cell{k,1}(2:3:end)', ...
    'k','k',drawline)

    hold off
    
    axis([axis_cell{k,1}-body_edge_x,axis_cell{k,2}+body_edge_x, ...
      axis_cell{k,3}-body_edge_y,axis_cell{k,4}+body_edge_y])

    view(0,90)
    box on
    grid on
    title(close_title_list{k})
    if k == 1
        ylabel({'Behavior difference','of close interactions','y'})
    end
    set(gca,'XTickLabel',[],'YTickLabel',[],'ZTickLabel',[])
end

temph = subplot('Position',[0.965,0.225,0.005,0.05]);
imagesc(flipud((1:100)'))
colormap(temph,loco_cmap)
set(gca,'XTick',[],'YTick',[])






























































