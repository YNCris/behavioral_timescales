%{
    reservoir network demo
%}
clear all
close all
addpath(genpath(pwd))
%% set path
rootpath = ['E:\MTPM_body_language'];
beh_neu_path = [rootpath,'\beh_neu_20240412'];

%% load data
fileFolder = fullfile(beh_neu_path);
dirOutput = dir(fullfile(fileFolder,'free*-neu.mat'));
neuNames = {dirOutput.name}';

all_data_cell = cell(size(neuNames,1),11);
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

    tempdata = load([beh_neu_path,'\',rootname,...
        '-cut-rnn_ed_train_2layers.mat']);
    all_data_cell{k,10} = tempdata;

    tempdata = load([beh_neu_path,'\',rootname,...
        '-cut-rnn_ed_train_control_2layers.mat']);
    all_data_cell{k,11} = tempdata;

    
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
        all_data_9,all_data_cell{k,1}}];

    unique(all_data_5)
    %%
    disp(k)
end
%% plot canvas
hall = figure(1);
set(hall,'Position',[680,0,800,800])
set(hall,'color','white');

%% set cmap
setcolor = cbrewer2('Spectral',11);
subject_pose_c = setcolor(3,:);
object_pose_c = setcolor(9,:);

pred_base_color = setcolor(11,:);

%% show the space of network structures
sel_data_idx = 5;
Train_pca = all_data_cell{sel_data_idx,10}.Train_pca;

overlap_perc = 1.1;

start_x = 0.4;
start_y = 0.85;

box_x = 0.1;
box_y = 0.15;
show_x_list = 1:900;
subplot('Position',...
    [start_x,start_y,box_x,box_y])
for k = 1:6
    plot(show_x_list,...
        mat2gray(Train_pca(show_x_list,k))+overlap_perc*(k-1),'-',...
        'LineWidth',0.25,'Color',subject_pose_c)
    hold on
end
hold off
set(gca,'XTick',[],'YTick',[])
box on

%% show demo data
start_x = 0.05;
start_y = 0.74;

box_x = 0.365;
box_y = 0.1;

inter_y = 0.005;

sel_data_idx = 5;

overlap_perc = 0.2;

show_x_list = 1:18000;

show_x_tick = [0,9000,18000];

XTrain = all_data_cell{sel_data_idx,10}.XTrain;
Train_pca = all_data_cell{sel_data_idx,10}.Train_pca;
pca_predict = all_data_cell{sel_data_idx,10}.pca_predict;
YTrain = all_data_cell{sel_data_idx,10}.YTrain;
ys_predict = all_data_cell{sel_data_idx,10}.ys_predict;
ys_pca_predict = all_data_cell{sel_data_idx,10}.ys_pca_predict;

% XTrain = all_data_cell{sel_data_idx,11}.XTrain_rand;
% Train_pca = all_data_cell{sel_data_idx,11}.Train_pca_rand;
% pca_predict = all_data_cell{sel_data_idx,11}.pca_predict;
% YTrain = all_data_cell{sel_data_idx,11}.YTrain;
% ys_predict = all_data_cell{sel_data_idx,11}.ys_predict_rand;
ys_pca_predict_rand = all_data_cell{sel_data_idx,11}.ys_pca_predict_rand;

% XTrain
subplot('Position',[...
    start_x,start_y,box_x,box_y])
for k = 1:size(XTrain,2)
    plot(show_x_list,...
        mat2gray(XTrain(:,k))+overlap_perc*(k-1),'-',...
        'LineWidth',0.25,'Color',object_pose_c)
    hold on
end
hold off

box off
set(gca,'TickDir','out')
set(gca,'FontSize',6)
set(gca,'XTick',show_x_tick,'XTickLabel',[])
set(gca,'YTick',[1:16]*3*overlap_perc)
set(gca,'YTickLabel',[])

ylabel('Object poses')

axis([0,max(show_x_list),0,overlap_perc*size(XTrain,2)+1])

% PCA train
subplot('Position',[...
    start_x,start_y-box_y-inter_y,box_x,box_y])
for k = 1:50
    plot(show_x_list,...
        mat2gray(Train_pca(:,k))+overlap_perc*(k-1),'-',...
        'LineWidth',0.25,'Color',subject_pose_c)
    hold on
end
hold off

box off
set(gca,'TickDir','out')
set(gca,'FontSize',6)
set(gca,'XTick',show_x_tick,'XTickLabel',[])
set(gca,'YTick',[1,50]*overlap_perc)
set(gca,'YTickLabel',[1,50])

ylabel('Neural PCs')

axis([0,max(show_x_list),0,overlap_perc*50+1])

% PCA predict
subplot('Position',[...
    start_x,start_y-2*(box_y+inter_y),box_x,box_y])
for k = 1:50
    plot(show_x_list,...
        mat2gray(pca_predict(:,k))+overlap_perc*(k-1),'-',...
        'LineWidth',0.25,'Color',(pred_base_color+subject_pose_c)/2)
    hold on
end
hold off

box off
set(gca,'TickDir','out')
set(gca,'FontSize',6)
set(gca,'XTick',show_x_tick,'XTickLabel',[])
set(gca,'YTick',[1,50]*overlap_perc)
set(gca,'YTickLabel',[1,50])

ylabel('Predicted PCs')

axis([0,max(show_x_list),0,overlap_perc*50+1])


% YTrain
subplot('Position',[...
    start_x,start_y-3*(box_y+inter_y),box_x,box_y])
for k = 1:size(YTrain,2)
    plot(show_x_list,...
        mat2gray(YTrain(:,k))+overlap_perc*(k-1),'-',...
        'LineWidth',0.25,'Color',subject_pose_c)
    hold on
end
hold off

box off
set(gca,'TickDir','out')
set(gca,'FontSize',6)
set(gca,'XTick',show_x_tick,'XTickLabel',[])
set(gca,'YTick',[1:16]*3*overlap_perc)
set(gca,'YTickLabel',[])

ylabel('Subject poses')

axis([0,max(show_x_list),0,overlap_perc*size(YTrain,2)+1])

% Y predict
subplot('Position',[...
    start_x,start_y-4*(box_y+inter_y),box_x,box_y])
for k = 1:size(ys_predict,2)
    plot(show_x_list,...
        mat2gray(ys_predict(:,k))+overlap_perc*(k-1),'-',...
        'LineWidth',0.25,'Color',(pred_base_color+subject_pose_c)/2)
    hold on
end
hold off

box off
set(gca,'TickDir','out')
set(gca,'FontSize',6)
set(gca,'XTick',show_x_tick,'XTickLabel',[])
set(gca,'YTick',[1:16]*3*overlap_perc)
set(gca,'YTickLabel',[])

ylabel({'Predicted subject poses',...
    'from neural PCs'})

axis([0,max(show_x_list),0,overlap_perc*size(ys_predict,2)+1])

% Y predict from XTrain (ys_pca_predict)
subplot('Position',[...
    start_x,start_y-5*(box_y+inter_y),box_x,box_y])
for k = 1:size(ys_pca_predict,2)
    plot(show_x_list,...
        mat2gray(ys_pca_predict(:,k))+overlap_perc*(k-1),'-',...
        'LineWidth',0.25,'Color',(pred_base_color+object_pose_c)/2)
    hold on
end
hold off

box off
set(gca,'TickDir','out')
set(gca,'FontSize',6)
set(gca,'XTick',show_x_tick,'XTickLabel',[])
set(gca,'YTick',[1:16]*3*overlap_perc)
set(gca,'YTickLabel',[])

ylabel('from predicted PCs')

axis([0,max(show_x_list),0,overlap_perc*size(ys_pca_predict,2)+1])

% control group
subplot('Position',[...
    start_x,start_y-6*(box_y+inter_y),box_x,box_y])
for k = 1:size(ys_pca_predict_rand,2)
    plot(show_x_list,...
        mat2gray(ys_pca_predict_rand(:,k))+overlap_perc*(k-1),'-',...
        'LineWidth',0.25,'Color',0.7*ones(1,3))
    hold on
end
hold off

box off
set(gca,'TickDir','out')
set(gca,'FontSize',6)
set(gca,'XTick',show_x_tick,'XTickLabel',[0,5,10])
set(gca,'YTick',[1:16]*3*overlap_perc)
set(gca,'YTickLabel',[])

ylabel({'from random','object poses'})
xlabel('Time (min)')

axis([0,max(show_x_list),0,overlap_perc*size(ys_pca_predict_rand,2)+1])

%% show skeletons
start_x = 0.46;
start_y = 0.74;

box_x = 0.1;
box_y = box_x;

inter_x = 0.005;
inter_y = inter_x;

col_num = 5;
row_num = 6;

drawline = [ 1 2; 1 3;2 3; 4 5;4 6;5 7;...
        6 8;7 14;8 14;5 13;6 13;7 13;8 13;...
    5 9;7 11;6 10; 8 12;14 15; 15 16];

xy_bias = 20;

show_brain_name = {'S1','dmPFC','M1'};
count = 1;

for m = 1:col_num
    for n = 1:row_num
        %
        subplot('Position',[...
            start_x+(m-1)*(box_x+inter_x),...
            start_y-(n-1)*(box_y+inter_y),...
            box_x,box_y])
        % tpmss
        if n == 1 || n == 2
            selname = 'free-seg1-1tpmss-1wt-20220226';
            sel_far_idx = [6;13];
            sel_close_idx = [15;13;14];
        end
        % tpmpfc
        if n == 3 || n == 4
            selname = 'free-seg2-1tpmpfc-rwt-20240103';
            sel_far_idx = [3;4];
            sel_close_idx = [6;5;3];
        end
        % tpmm
        if n == 5 || n == 6
            selname = 'free-seg2-1tpmm-rwt-20231107';
            sel_far_idx = [3;2];
            sel_close_idx = [4;10;3];
        end

        selidx = strcmp(selname,all_data_cell(:,1));
        seldata = all_data_cell(selidx,:);

        XTrain = seldata{10}.XTrain;
        YTrain = seldata{10}.YTrain;
        ys_predict = seldata{10}.ys_predict;
        ys_pca_predict = seldata{10}.ys_pca_predict;
        ys_pca_predict_rand = seldata{11}.ys_pca_predict_rand;

        dist_list = raw_trial_cell{selidx,9};
        distsavelist = idx2savelist(dist_list);

        far_savelist = distsavelist(distsavelist(:,3)==0,2:3);
        close_savelist = distsavelist(distsavelist(:,3)==1,2:3);

        far_savelist(:,1) = round(mean(...
            distsavelist(distsavelist(:,3)==0,1:2),2));

        close_savelist(:,1) = round(mean(...
            distsavelist(distsavelist(:,3)==1,1:2),2));
        
        sel_show_far = far_savelist(sel_far_idx,1);
        sel_show_close = close_savelist(sel_close_idx,1);

        sel_show_idx = [sel_show_far;sel_show_close];

        sel_show_idx = sel_show_idx(m);
        
        
        % show
        plot_skl_dl(...
            XTrain(sel_show_idx,1:3:end)',...
            XTrain(sel_show_idx,2:3:end)',...
            XTrain(sel_show_idx,3:3:end)',...
            object_pose_c,object_pose_c,drawline)
        hold on
        plot_skl_dl(...
            YTrain(sel_show_idx,1:3:end)',...
            YTrain(sel_show_idx,2:3:end)',...
            YTrain(sel_show_idx,3:3:end)',...
            subject_pose_c,subject_pose_c,drawline)
        hold on
        plot_skl_dl(...
            ys_predict(sel_show_idx,1:3:end)',...
            ys_predict(sel_show_idx,2:3:end)',...
            ys_predict(sel_show_idx,3:3:end)',...
            (pred_base_color+subject_pose_c)/2,...
            (pred_base_color+subject_pose_c)/2,drawline)
        hold on
        plot_skl_dl(...
            ys_pca_predict(sel_show_idx,1:3:end)',...
            ys_pca_predict(sel_show_idx,2:3:end)',...
            ys_pca_predict(sel_show_idx,3:3:end)',...
            (pred_base_color+object_pose_c)/2,...
            (pred_base_color+object_pose_c)/2,drawline)
        hold on
        plot_skl_dl(...
            ys_pca_predict_rand(sel_show_idx,1:3:end)',...
            ys_pca_predict_rand(sel_show_idx,2:3:end)',...
            ys_pca_predict_rand(sel_show_idx,3:3:end)',...
            0.7*ones(1,3),0.7*ones(1,3),drawline)
        hold off

        % panel control
        box on
        
        all_x = ...
            [XTrain(sel_show_idx,1:3:end)';...
            YTrain(sel_show_idx,1:3:end)';...
            ys_predict(sel_show_idx,1:3:end)';...
            ys_pca_predict(sel_show_idx,1:3:end)'];
        all_y = ...
            [XTrain(sel_show_idx,2:3:end)';...
            YTrain(sel_show_idx,2:3:end)';...
            ys_predict(sel_show_idx,2:3:end)';...
            ys_pca_predict(sel_show_idx,2:3:end)'];
        all_z = ...
            [XTrain(sel_show_idx,3:3:end)';...
            YTrain(sel_show_idx,3:3:end)';...
            ys_predict(sel_show_idx,3:3:end)';...
            ys_pca_predict(sel_show_idx,3:3:end)'];

        min_x = min(all_x);
        max_x = max(all_x);
        min_y = min(all_y);
        max_y = max(all_y);
        min_z = min(all_z);
        max_z = max(all_z);

        if rem(n,2) == 1
            % xy
            view(90,90)
            axis([...
                min_x-xy_bias,...
                max_x+xy_bias,...
                min_y-xy_bias,...
                max_y+xy_bias])
        else
            % xz
            view(90,0)
            axis([...
                min_x-xy_bias,...
                max_x+xy_bias,...
                min_y-xy_bias,...
                max_y+xy_bias,...
                -10,...
                100])
        end

        set(gca,'TickLength',[0,0])
        set(gca,'FontSize',6)
        set(gca,'XTickLabel',[],'YTickLabel',[],'ZTickLabel',[])

        if m == 1
            if rem(n,2) == 1
                xlabel({show_brain_name{count},'y'})
                count = count+1;
            else
                zlabel('z')
            end
        end

        if n == 6
            ylabel('x')
        end
    end
end

%% compare error
error_mat = zeros(size(all_data_cell,1),5);
for k = 1:size(all_data_cell,1)
    %
    tempgood = all_data_cell{k,10};
    tempcontrol = all_data_cell{k,11};
    
    Train_pca = tempgood.Train_pca;
    YTrain = tempgood.YTrain;

    good_pca_predict = tempgood.pca_predict;
    good_ys_predict = tempgood.ys_predict;
    good_ys_pca_predict = tempgood.ys_pca_predict;
    control_pca_predict = tempcontrol.pca_predict;
    control_ys_pca_predict_rand = tempcontrol.ys_pca_predict_rand;

    err_good_pca_predict = ...
        mean(sqrt((good_pca_predict-Train_pca).^2),'all');
    err_good_ys_predict = ...
        mean(sqrt((good_ys_predict-YTrain).^2),'all');
    err_good_ys_pca_predict = ...
        mean(sqrt((good_ys_pca_predict-YTrain).^2),'all');
    err_control_pca_predict = ...
        mean(sqrt((control_pca_predict-Train_pca).^2),'all');
    err_control_ys_pca_predict_rand = ...
        mean(sqrt((control_ys_pca_predict_rand-YTrain).^2),'all');

    error_mat(k,:) = [...
        err_good_pca_predict,err_control_pca_predict,...
        err_good_ys_predict,err_good_ys_pca_predict,...
        err_control_ys_pca_predict_rand];
end

% sort error by brain areas
sort_brain_name_list = {...
    '1tpmss','tpmss';...
    '2tpmss','tpmss';...
    '3tpmss','tpmss';...
    '4tpmss','tpmss';...
    '5tpmss','tpmss';...
    '1tpmpfc','tpmpfc';...
    '2tpmpfc','tpmpfc';...
    '3tpmpfc','tpmpfc';...
    '4tpmpfc','tpmpfc';...
    '5tpmpfc','tpmpfc';...
    '1tpmm','tpmm';...
    '2tpmm','tpmm';...
    '3tpmm','tpmm';...
    '4tpmm','tpmm';...
    '5tpmm','tpmm';...
    };

splname1 = split(all_data_cell(:,1),'-');


sort_error_mat = error_mat;

for k = 1:size(sort_brain_name_list,1)
    tempname = sort_brain_name_list{k,1};
    selidx = strcmp(tempname,splname1(:,3));
    sort_error_mat(k,:) = error_mat(selidx,:);
end


%% show pc error
start_x = 0.46;
start_y = 0.11;

box_x = 0.2;
box_y = 0.08;

show_brain_seq = {...
    'tpmss';...
    'tpmpfc';...
    'tpmm'};

show_x_list = [...
    1,2;...
    4,5;...
    7,8];

show_c_list = [...
    (pred_base_color+subject_pose_c)/2;...
    0.7*ones(1,3)];

show_star_list = {...
    0.01,0.05,'*';...
    0.001,0.01,'**';...
    0.0001,0.001,'***';...
    0,0.0001,'****';...
    };

bar_w = 0.6;
x_bias = bar_w/2;
mk_size = 3;
cap_size = 2;

subplot('Position',[start_x,start_y,box_x,box_y])
for k = 1:size(show_brain_seq,1)
    %%
    selname = show_brain_seq{k,1};
    selidx = strcmp(selname,sort_brain_name_list(:,2));

    sel_err = sort_error_mat(selidx,1:2);

    sel_x = show_x_list(k,:);

    mean_err = mean(sel_err);

    std_err = std(sel_err)./sqrt(size(sel_err,1));

    for m = 1:size(mean_err,2)
        bar(sel_x(m),mean_err(m),bar_w,...
            'FaceColor',show_c_list(m,:))
        hold on
        for n = 1:size(sel_err,1)
            plot(x_bias+sel_x,sel_err(n,:),'-k','LineWidth',0.25)
            hold on
            plot(x_bias+sel_x,sel_err(n,:),'o',...
                'LineWidth',0.25,...
                'MarkerFaceColor','w',...
                'MarkerEdgeColor','k',...
                'MarkerSize',mk_size)
            hold on
            
        end

        errorbar(sel_x(m),mean_err(m),std_err(m),...
            'Color','k','CapSize',cap_size)
        hold on    
    end
    plot(sel_x,[0.08,0.08],'-k',...
                'LineWidth',0.25)
    hold on
    %% stat
        % test
        [h_dist_1,p_dist_1] =kstest(sel_err(:,1));
        [h_dist_2,p_dist_2] =kstest(sel_err(:,2));
        [h_var,p_var] = vartest2(...
            sel_err(:,1),...
            sel_err(:,2));
        if h_dist_1==0 && h_var==0 && h_dist_2==0
            % normal distribution
            [~,p_value] = ttest(...
                        sel_err(:,1),...
                        sel_err(:,2));
            disp('normal')
        else
            % not normal distribution
            p_value = ranksum(...
                        sel_err(:,1),...
                        sel_err(:,2));
        end

        disp(p_value)

        %% show stat
        for p = 1:size(show_star_list,1)
            if show_star_list{p,1}<=p_value &&...
                    p_value<show_star_list{p,2}
                selstar = show_star_list{p,3};
                text(mean(sel_x),0.09,...
                    selstar,...
                    'HorizontalAlignment','center',...
                    'VerticalAlignment','middle',...
                    'Rotation',0)
            end
        end
    
end
hold off

box off
set(gca,'TickDir','out')
set(gca,'FontSize',6)
set(gca,'XTick',mean(show_x_list,2))
set(gca,'XTickLabel',show_brain_name)

axis([0.3,8.7,0,0.1])

set(gca,'YTick',[0,0.1])

ylabel('MSE (PC values)')

%% show ys error
start_x = 0.7;
% start_y = 0.1;

box_x = 0.28;
% box_y = 0.08;

disp('')

show_x_list = [...
    1,2,3;...
    5,6,7;...
    9,10,11];

show_c_list = [...
    (pred_base_color+subject_pose_c)/2;...
    (pred_base_color+object_pose_c)/2;...
    0.7*ones(1,3)];

subplot('Position',[start_x,start_y,box_x,box_y])
for k = 1:size(show_brain_seq,1)
    %%
    selname = show_brain_seq{k,1};
    selidx = strcmp(selname,sort_brain_name_list(:,2));

    sel_err = sort_error_mat(selidx,3:5);

    sel_x = show_x_list(k,:);

    mean_err = mean(sel_err);

    std_err = std(sel_err)./sqrt(size(sel_err,1));

    for m = 1:size(mean_err,2)
        bar(sel_x(m),mean_err(m),bar_w,...
            'FaceColor',show_c_list(m,:))
        hold on
        for n = 1:size(sel_err,1)
            plot(x_bias+sel_x,sel_err(n,:),'-k','LineWidth',0.25)
            hold on
            plot(x_bias+sel_x,sel_err(n,:),'o',...
                'LineWidth',0.25,...
                'MarkerFaceColor','w',...
                'MarkerEdgeColor','k',...
                'MarkerSize',mk_size)
            hold on
            
        end

        errorbar(sel_x(m),mean_err(m),std_err(m),...
            'Color','k','CapSize',cap_size)
        hold on

         
    end
    
    % plot(sel_x([1,2]),[40,40],'-k',...
    %             'LineWidth',0.25)
    % hold on
    % plot(sel_x([2,3]),[55,55],'-k',...
    %         'LineWidth',0.25)
    % hold on   
    % 
    % plot(sel_x([1,3]),[70,70],'-k',...
    %             'LineWidth',0.25)
    % hold on

    %% stat
    reo_sel_err = [...
        sel_err(:,1);...
        sel_err(:,2);...
        sel_err(:,3)];
    reo_group = [...
        ones(5,1);...
        2*ones(5,1);...
        3*ones(5,1);...
        ];
    % test
    [~,anovatab,stats] = anova1(sel_err,[],'off');
    cmp = multcompare(stats,'Display','off');
    %% show star
    show_y_list = [...
        40;...
        55;...
        70];

    for p = 1:size(cmp,1)
        p_value = cmp(p,end);
        disp(p_value)
        for q = 1:size(show_star_list,1)
            if show_star_list{q,1}<=p_value &&...
                    p_value<show_star_list{q,2}
                selstar = show_star_list{q,3};
                plot(sel_x([cmp(p,1),cmp(p,2)]),...
                    [show_y_list(p),show_y_list(p)],'-k',...
                'LineWidth',0.25)
                hold on
                text(mean(sel_x([cmp(p,1),cmp(p,2)])),...
                    show_y_list(p),...
                    selstar,...
                    'HorizontalAlignment','center',...
                    'VerticalAlignment','bottom',...
                    'Rotation',0)
            end
        end
    end
    
end
hold off

box off
set(gca,'TickDir','out')
set(gca,'FontSize',6)
set(gca,'XTick',mean(show_x_list,2))
set(gca,'XTickLabel',show_brain_name)

axis([0.3,11.7,0,80])

ylabel('MSE (pixels)')






