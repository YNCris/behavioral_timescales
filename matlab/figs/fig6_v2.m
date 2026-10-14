%{
    reservoir network demo
%}
clear all
close all
addpath(genpath(pwd))
%% set path
rootpath = ['H:\MTPM_body_language'];
beh_neu_path = [rootpath,'\beh_neu_20240412'];

%% load data
fileFolder = fullfile(beh_neu_path);
dirOutput = dir(fullfile(fileFolder,'free*-neu.mat'));
neuNames = {dirOutput.name}';

all_data_cell = cell(size(neuNames,1),12);
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

    tempdata = load([beh_neu_path,'\',rootname,...
        '-cut-rnn_states_ed_train_2layers.mat']);
    all_data_cell{k,12} = tempdata;
    
    disp(k)
end

load([beh_neu_path,'\l_mat_norm_20250205.mat']);

stat_tbl = ...
    readtable([beh_neu_path,'\fig6_stat_20250205.xlsx']);
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
% subplot('Position',[...
%     start_x,start_y,box_x,box_y])
% for k = 1:size(XTrain,2)
%     plot(show_x_list,...
%         mat2gray(XTrain(:,k))+overlap_perc*(k-1),'-',...
%         'LineWidth',0.25,'Color',object_pose_c)
%     hold on
% end
% hold off
% 
% box off
% set(gca,'TickDir','out')
% set(gca,'FontSize',6)
% set(gca,'XTick',show_x_tick,'XTickLabel',[])
% set(gca,'YTick',[1:16]*3*overlap_perc)
% set(gca,'YTickLabel',[])
% 
% ylabel('Object poses')
% 
% axis([0,max(show_x_list),0,overlap_perc*size(XTrain,2)+1])
% 
% % PCA train
% subplot('Position',[...
%     start_x,start_y-box_y-inter_y,box_x,box_y])
% for k = 1:50
%     plot(show_x_list,...
%         mat2gray(Train_pca(:,k))+overlap_perc*(k-1),'-',...
%         'LineWidth',0.25,'Color',subject_pose_c)
%     hold on
% end
% hold off
% 
% box off
% set(gca,'TickDir','out')
% set(gca,'FontSize',6)
% set(gca,'XTick',show_x_tick,'XTickLabel',[])
% set(gca,'YTick',[1,50]*overlap_perc)
% set(gca,'YTickLabel',[1,50])
% 
% ylabel('Neural PCs')
% 
% axis([0,max(show_x_list),0,overlap_perc*50+1])
% 
% % PCA predict
% subplot('Position',[...
%     start_x,start_y-2*(box_y+inter_y),box_x,box_y])
% for k = 1:50
%     plot(show_x_list,...
%         mat2gray(pca_predict(:,k))+overlap_perc*(k-1),'-',...
%         'LineWidth',0.25,'Color',(pred_base_color+subject_pose_c)/2)
%     hold on
% end
% hold off
% 
% box off
% set(gca,'TickDir','out')
% set(gca,'FontSize',6)
% set(gca,'XTick',show_x_tick,'XTickLabel',[])
% set(gca,'YTick',[1,50]*overlap_perc)
% set(gca,'YTickLabel',[1,50])
% 
% ylabel('Predicted PCs')
% 
% axis([0,max(show_x_list),0,overlap_perc*50+1])
% 
% 
% % YTrain
% subplot('Position',[...
%     start_x,start_y-3*(box_y+inter_y),box_x,box_y])
% for k = 1:size(YTrain,2)
%     plot(show_x_list,...
%         mat2gray(YTrain(:,k))+overlap_perc*(k-1),'-',...
%         'LineWidth',0.25,'Color',subject_pose_c)
%     hold on
% end
% hold off
% 
% box off
% set(gca,'TickDir','out')
% set(gca,'FontSize',6)
% set(gca,'XTick',show_x_tick,'XTickLabel',[])
% set(gca,'YTick',[1:16]*3*overlap_perc)
% set(gca,'YTickLabel',[])
% 
% ylabel('Subject poses')
% 
% axis([0,max(show_x_list),0,overlap_perc*size(YTrain,2)+1])
% 
% % Y predict
% subplot('Position',[...
%     start_x,start_y-4*(box_y+inter_y),box_x,box_y])
% for k = 1:size(ys_predict,2)
%     plot(show_x_list,...
%         mat2gray(ys_predict(:,k))+overlap_perc*(k-1),'-',...
%         'LineWidth',0.25,'Color',(pred_base_color+subject_pose_c)/2)
%     hold on
% end
% hold off
% 
% box off
% set(gca,'TickDir','out')
% set(gca,'FontSize',6)
% set(gca,'XTick',show_x_tick,'XTickLabel',[])
% set(gca,'YTick',[1:16]*3*overlap_perc)
% set(gca,'YTickLabel',[])
% 
% ylabel({'Predicted subject poses',...
%     'from neural PCs'})
% 
% axis([0,max(show_x_list),0,overlap_perc*size(ys_predict,2)+1])
% 
% % Y predict from XTrain (ys_pca_predict)
% subplot('Position',[...
%     start_x,start_y-5*(box_y+inter_y),box_x,box_y])
% for k = 1:size(ys_pca_predict,2)
%     plot(show_x_list,...
%         mat2gray(ys_pca_predict(:,k))+overlap_perc*(k-1),'-',...
%         'LineWidth',0.25,'Color',(pred_base_color+object_pose_c)/2)
%     hold on
% end
% hold off
% 
% box off
% set(gca,'TickDir','out')
% set(gca,'FontSize',6)
% set(gca,'XTick',show_x_tick,'XTickLabel',[])
% set(gca,'YTick',[1:16]*3*overlap_perc)
% set(gca,'YTickLabel',[])
% 
% ylabel('from predicted PCs')
% 
% axis([0,max(show_x_list),0,overlap_perc*size(ys_pca_predict,2)+1])
% 
% % control group
% subplot('Position',[...
%     start_x,start_y-6*(box_y+inter_y),box_x,box_y])
% for k = 1:size(ys_pca_predict_rand,2)
%     plot(show_x_list,...
%         mat2gray(ys_pca_predict_rand(:,k))+overlap_perc*(k-1),'-',...
%         'LineWidth',0.25,'Color',0.7*ones(1,3))
%     hold on
% end
% hold off
% 
% box off
% set(gca,'TickDir','out')
% set(gca,'FontSize',6)
% set(gca,'XTick',show_x_tick,'XTickLabel',[0,5,10])
% set(gca,'YTick',[1:16]*3*overlap_perc)
% set(gca,'YTickLabel',[])
% 
% ylabel({'from random','object poses'})
% xlabel('Time (min)')
% 
% axis([0,max(show_x_list),0,overlap_perc*size(ys_pca_predict_rand,2)+1])

%% show skeletons
start_x = 0.03;
start_y = 0.74;

box_x = 0.1;
box_y = box_x;

inter_x = 0.005;
inter_y = inter_x;

col_num = 1;
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
            sel_far_idx = [13;6];
            sel_close_idx = [15;13;14];
        end
        % tpmpfc
        if n == 3 || n == 4
            selname = 'free-seg2-1tpmpfc-rwt-20240103';
            sel_far_idx = [4;3];
            sel_close_idx = [6;5;3];
        end
        % tpmm
        if n == 5 || n == 6
            selname = 'free-seg2-1tpmm-rwt-20231107';
            sel_far_idx = [2;3];
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
start_x = 0.18;
start_y = 0.75;

box_x = 0.22;
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
set(gca,'XTickLabel',[])

axis([0.3,8.7,0,0.1])

set(gca,'YTick',[0,0.1])

ylabel('MSE (PC values)')

%% show ys error
% start_x = 0.7;
start_y = 0.65;

% box_x = 0.28;
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

%% the analysis using Lyapnov index
% l_mat = zeros(size(all_data_cell,1),7);
% 
% for k = 1:size(l_mat,1)
%     %% load data
%     temp_XTrain = all_data_cell{k,10}.XTrain;
%     temp_Train_pca = all_data_cell{k,10}.Train_pca;
%     temp_YTrain = all_data_cell{k,10}.YTrain;
%     temp_states_encoder_r1 = ...
%         all_data_cell{k,12}.states_encoder_r1;
%     temp_states_encoder_r1 = reshape(...
%         temp_states_encoder_r1,[...
%         size(temp_states_encoder_r1,2),...
%         size(temp_states_encoder_r1,3)]);
%     temp_states_encoder_r2 = ...
%         all_data_cell{k,12}.states_encoder_r2;
%     temp_states_encoder_r2 = reshape(...
%         temp_states_encoder_r2,[...
%         size(temp_states_encoder_r2,2),...
%         size(temp_states_encoder_r2,3)]);
%     temp_states_decoder_r1 = ...
%         all_data_cell{k,12}.states_decoder_r1;
%     temp_states_decoder_r1 = reshape(...
%         temp_states_decoder_r1,[...
%         size(temp_states_decoder_r1,2),...
%         size(temp_states_decoder_r1,3)]);
%     temp_states_decoder_r2 = ...
%         all_data_cell{k,12}.states_decoder_r2;
%     temp_states_decoder_r2 = reshape(...
%         temp_states_decoder_r2,[...
%         size(temp_states_decoder_r2,2),...
%         size(temp_states_decoder_r2,3)]);
%     %% calculate
%     fs = 30;
%     L_XTrain = lyapunovExponent(temp_XTrain,fs);
%     L_Train_pca = lyapunovExponent(temp_Train_pca,fs);
%     L_YTrain = lyapunovExponent(temp_YTrain,fs);
%     L_states_encoder_r1 = ...
%         lyapunovExponent(temp_states_encoder_r1,fs);
%     L_states_encoder_r2 = ...
%         lyapunovExponent(temp_states_encoder_r2,fs);
%     L_states_decoder_r1 = ...
%         lyapunovExponent(temp_states_decoder_r1,fs);
%     L_states_decoder_r2 = ...
%         lyapunovExponent(temp_states_decoder_r2,fs);
% 
%     l_mat(k,1:7) = [L_XTrain,L_Train_pca,L_YTrain,...
%         L_states_encoder_r1,...
%         L_states_encoder_r2,...
%         L_states_decoder_r1,...
%         L_states_decoder_r2];
% 
%     disp(k)
% end
% 
% save([beh_neu_path,'\l_mat_20250204.mat'],...
%     'l_mat','-v7.3')
% disp('save!')

%% show comparison
show_name_brain = {...
    'S1','tpmss';...
    'dmPFC','tpmpfc';...
    'M1','tpmm'};

show_name_net = {...
    'Object poses';...
    'Neural PCs';...
    'Subject poses';...
    'Encoder L1';...
    'Encoder L2';...
    'Decoder L1';...
    'Decoder L2'};

show_cell = cell(...
    size(show_name_brain,1)*size(show_name_net,1),...
    4);

splname1 = split(all_data_cell(:,1),'-');
raw_brain_name = cellfun(@(x) x(2:end),...
    splname1(:,3),'UniformOutput',false);


count = 1;
for m = 1:size(show_name_brain,1)
        temprawname = show_name_brain{m,2};
        selbrainidx = strcmp(raw_brain_name,temprawname);
    for n = 1:size(show_name_net,1)
        sel_l = l_mat(selbrainidx,:);

        mean_sel_l = mean(sel_l);

        std_sel_l = std(sel_l)./sqrt(size(sel_l,1));

        show_cell{count,1} = [show_name_brain{m,1},'-',...
            show_name_net{n,1}];
        show_cell{count,2} = sel_l(:,n)';
        show_cell{count,3} = mean_sel_l(n);
        show_cell{count,4} = std_sel_l(n);

        count = count+1;
    end
    
end

[~,sort_idx] = sort(cell2mat(show_cell(:,3)),'descend');

sort_show_cell = show_cell(sort_idx,:);

start_x = 0.45;
start_y = 0.72;

box_x = 0.53;
box_y = 0.11;

bar_w = 0.6;
cap_size = 2;

mk_size = 2;

xbias = 0.3;

neu_cmap = cbrewer2('Paired',12);

in_c = neu_cmap(5,:);
de_c = neu_cmap(1,:);
no_c = neu_cmap(3,:);

brain_c = [...
    de_c;...
    in_c;...
    no_c];

xlist = 1:size(sort_show_cell,1);

stat_mat = cell2mat(sort_show_cell(:,2))';

legend_h_cell = cell(size(show_name_brain,1),1);

subplot('Position',[...
    start_x,start_y,box_x,box_y])
for k = 1:size(sort_show_cell,1)
    splname = split(sort_show_cell{k,1},'-');
    selc_idx = strcmp(splname{1},show_name_brain(:,1));

    selc = brain_c(selc_idx,:);

    % % test
    % [h_dist,p_dist] =kstest(sort_show_cell{k,2});
    % if h_dist==0
    %     % normal distribution
    %     [~,p_value] = ttest(sort_show_cell{k,2});
    %     disp('t-test')
    % else
    %     % not normal distribution
    %     p_value = signrank(sort_show_cell{k,2});
    %     disp('rank sum')
    % end
    % disp(p_value)

    temph = bar(k,sort_show_cell{k,3},bar_w,...
        'FaceColor',selc);

    if find(selc_idx) == 1
        legend_h_cell{1} = temph;
    end

    if find(selc_idx) == 2
        legend_h_cell{2} = temph;
    end

    if find(selc_idx) == 3
        legend_h_cell{3} = temph;
    end

    hold on
    errorbar(k,sort_show_cell{k,3},...
        sort_show_cell{k,4},'CapSize',cap_size,...
        'Color','k')
    hold on
    plot(xbias+k*ones(5,1),sort_show_cell{k,2},...
        'o','MarkerFaceColor','w',...
        'MarkerEdgeColor','k',...
        'LineWidth',0.25,...
        'MarkerSize',mk_size)
    hold on
end

hold off

axis([0.3,21.7,0,3])

ylabel('Lyapunov exponents')

legend([legend_h_cell{1},legend_h_cell{2},legend_h_cell{3}],...
    'Box','off','Location','northeast',...
    'String',show_name_brain(:,1))

set(gca,'XTick',xlist)
set(gca,'XTickLabel',sort_show_cell(:,1))
set(gca,'FontSize',6)
set(gca,'TickDir','out')
box off

%% evaluate the similarity using L exp
show_p_mat = zeros(size(sort_show_cell,1),...
    size(sort_show_cell,1));

raw_title = stat_tbl.Var1;

raw_p = stat_tbl.Var6;

spltitle = split(raw_title,'''');
spltitle = strrep(spltitle,char(160),' ');
spltitle1 = spltitle(:,2);
spltitle2 = spltitle(:,4);

for m = 1:size(sort_show_cell,1)
    tempname_row = sort_show_cell{m,1};
    for n = (m+1):size(sort_show_cell,1)
        tempname_col = sort_show_cell{n,1};
        
        selidx11 = strcmp(tempname_row,spltitle1);
        selidx12 = strcmp(tempname_col,spltitle2);

        selidx1 = selidx11&selidx12;

        selidx21 = strcmp(tempname_col,spltitle1);
        selidx22 = strcmp(tempname_row,spltitle2);

        selidx2 = selidx21&selidx22;

        selidx = selidx1|selidx2;

        selp = raw_p(selidx);

        show_p_mat(m,n) = selp;

    end
end

show_p_mat_all = show_p_mat + triu(show_p_mat,1)';
show_p_mat_all(isnan(show_p_mat_all)) = 0.99999;

show_p_mat_all = show_p_mat_all+eye(size(show_p_mat_all));
%% show similarity
start_x = 0.25;
start_y = 0.32;

box_x = 0.27;
box_y = box_x;

heat_cmap_red = flipud(cbrewer2('Reds',50));
heat_cmap_blue = cbrewer2('Blues',2000);

heat_cmap = [...
    heat_cmap_red;...
    [1,1,1];...
    heat_cmap_blue(1000:end,:)];

temph = subplot('Position',[start_x,start_y,box_x,box_y]);
imagesc(show_p_mat_all)

colormap(temph,heat_cmap)

box off

set(gca,'XTick',xlist)
set(gca,'YTick',xlist)

set(gca,'XTickLabel',sort_show_cell(:,1))
set(gca,'YTickLabel',sort_show_cell(:,1))

set(gca,'TickDir','out')

set(gca,'FontSize',6)

% show colorbar
inter_y = 0.005;

cbar_x = 0.1;
cbar_y = 0.006;

temph = subplot('Position',[...
    start_x,...
    start_y+box_y+inter_y,...
    cbar_x,cbar_y]);

imagesc(1:2000)

colormap(temph,[...
    heat_cmap_red;...
    [1,1,1];...
    heat_cmap_blue(1:40:end,:)])

box on

title({'P value','0          0.05          1'})
set(gca,'FontSize',6)

set(gca,'XTick',[],'YTick',[])
%% separate far close far
%% split far-close-far trial include neural networks
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

for k = 1:size(raw_trial_cell,1)
    %% load data
    tempdist = raw_trial_cell{k,9};
    
    temp_XTrain = all_data_cell{k,10}.XTrain;
    temp_Train_pca = all_data_cell{k,10}.Train_pca;
    temp_YTrain = all_data_cell{k,10}.YTrain;
    temp_states_encoder_r1 = ...
        all_data_cell{k,12}.states_encoder_r1;
    temp_states_encoder_r1 = reshape(...
        temp_states_encoder_r1,[...
        size(temp_states_encoder_r1,2),...
        size(temp_states_encoder_r1,3)]);
    temp_states_encoder_r2 = ...
        all_data_cell{k,12}.states_encoder_r2;
    temp_states_encoder_r2 = reshape(...
        temp_states_encoder_r2,[...
        size(temp_states_encoder_r2,2),...
        size(temp_states_encoder_r2,3)]);
    temp_states_decoder_r1 = ...
        all_data_cell{k,12}.states_decoder_r1;
    temp_states_decoder_r1 = reshape(...
        temp_states_decoder_r1,[...
        size(temp_states_decoder_r1,2),...
        size(temp_states_decoder_r1,3)]);
    temp_states_decoder_r2 = ...
        all_data_cell{k,12}.states_decoder_r2;
    temp_states_decoder_r2 = reshape(...
        temp_states_decoder_r2,[...
        size(temp_states_decoder_r2,2),...
        size(temp_states_decoder_r2,3)]);
    %% select trials
    distsavelist = idx2savelist(tempdist);

    all_close_list = distsavelist(distsavelist(:,3)==1,:);

    all_close_list(all_close_list(:,1)<baseline_far_frame,:) = [];
    all_close_list(all_close_list(:,2)>...
        length(tempdist)-after_far_frame,:) = [];
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
        seldata_baseline = tempdist(...
            (tempstart-baseline_far_frame):(tempstart-1));
        seldata_after = tempdist(...
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

        newname = [raw_trial_cell{k,1},'-',num2str(m)];
        all_data_2 = raw_trial_cell{k,2}(tempstart:tempend,:);
        all_data_3 = raw_trial_cell{k,3}(tempstart:tempend,:);
        all_data_4 = raw_trial_cell{k,4}(tempstart:tempend,:);
        all_data_5 = raw_trial_cell{k,5}(tempstart:tempend,:);
        all_data_6 = raw_trial_cell{k,6}(tempstart:tempend,:);
        all_data_7 = raw_trial_cell{k,7}(tempstart:tempend,:);
        all_data_8 = raw_trial_cell{k,8}(tempstart:tempend,:);
        all_data_9 = raw_trial_cell{k,9}(tempstart:tempend,:);
        
        net_XTrain = temp_XTrain(tempstart:tempend,:);
        net_YTrain = temp_YTrain(tempstart:tempend,:);
        net_e1 = temp_states_encoder_r1(tempstart:tempend,:);
        net_e2 = temp_states_encoder_r2(tempstart:tempend,:);
        net_d1 = temp_states_decoder_r1(tempstart:tempend,:);
        net_d2 = temp_states_decoder_r2(tempstart:tempend,:);

        fcf_cell = [fcf_cell;...
            {newname,all_data_2,all_data_3,all_data_4,...
            all_data_5,all_data_6,all_data_7,all_data_8,...
            all_data_9,raw_trial_cell{k,1}},...
            net_XTrain,net_YTrain,...
            net_e1,net_e2,net_d1,net_d2];

        unique(all_data_5)
    end
    %%
    disp(k)
end

fcf_length = cell2mat(cellfun(@(x) size(x,1),fcf_cell(:,2),...
    'UniformOutput',false));

[~,sortidx] = sort(fcf_length,'descend');

sort_fcf_cell = fcf_cell(sortidx,:);
%% pca
sort_pca_cell = cell(size(sort_fcf_cell,1),7);

for k = 1:size(sort_pca_cell,1)
    %% load data
    tempneu = sort_fcf_cell{k,2};
    tempXTrain = sort_fcf_cell{k,11};
    tempYTrain = sort_fcf_cell{k,12};
    tempe1 = sort_fcf_cell{k,13};
    tempe2 = sort_fcf_cell{k,14};
    tempd1 = sort_fcf_cell{k,15};
    tempd2 = sort_fcf_cell{k,16};
    %% pca
    [coeff_neu, score_neu, ~, ~, explained_neu] = ...
        pca(tempneu');
    [coeff_XTrain, score_XTrain, ~, ~, explained_XTrain] = ...
        pca(tempXTrain');
    [coeff_YTrain, score_YTrain, ~, ~, explained_YTrain] = ...
        pca(tempYTrain');
    [coeff_e1, score_e1, ~, ~, explained_e1] = ...
        pca(tempe1');
    [coeff_e2, score_e2, ~, ~, explained_e2] = ...
        pca(tempe2');
    [coeff_d1, score_d1, ~, ~, explained_d1] = ...
        pca(tempd1');
    [coeff_d2, score_d2, ~, ~, explained_d2] = ...
        pca(tempd2');
    %% append data
    sort_pca_cell{k,1} = ...
        {coeff_neu,score_neu,explained_neu};
    sort_pca_cell{k,2} = ...
        {coeff_XTrain,score_XTrain,explained_XTrain};
    sort_pca_cell{k,3} = ...
        {coeff_YTrain,score_YTrain,explained_YTrain};
    sort_pca_cell{k,4} = ...
        {coeff_e1,score_e1,explained_e1};
    sort_pca_cell{k,5} = ...
        {coeff_e2,score_e2,explained_e2};
    sort_pca_cell{k,6} = ...
        {coeff_d1,score_d1,explained_d1};
    sort_pca_cell{k,7} = ...
        {coeff_d2,score_d2,explained_d2};
end

%% calculate l exp
norm_sort_pca_cell = cellfun(@(x) mat2gray(x{1}),...
    sort_pca_cell,'UniformOutput',false);

sort_pca_l_mat = ...
    cellfun(@(x) lyapunovExponent(x,30),...
    norm_sort_pca_cell);

%% normalize data to show
norm_coeff_sort_pca_cell = cellfun(@(x) ...
    (x{1}-ones(size(x{1},1),1)*min(x{1},[],1))./...
    (ones(size(x{1},1),1)*max(x{1},[],1)-...
    ones(size(x{1},1),1)*min(x{1},[],1)),...
    sort_pca_cell,'UniformOutput',false);
%% show pcs
row_num = 7;
col_num = 4;

start_x = 0.61;
start_y = 0.59;

box_x = 0.09;
box_y = 0.03;

inter_x = 0.005;
inter_y = 0.005;

pad_len = 600;

x_tick = [150,300,450];
x_tick_label = [0,5,10];

start_list = zeros(size(norm_coeff_sort_pca_cell,1),2);
end_list = start_list;

for k = 1:size(norm_coeff_sort_pca_cell,1)
    start_list(k,1) = baseline_far_frame;
    start_list(k,2) = k;

    end_list(k,1) = ...
        size(norm_coeff_sort_pca_cell{k,1},1)-...
        after_far_frame;
    end_list(k,2) = k;
end

cmap_neu = flipud(cbrewer2('RdBu',1000));

show_seq_list = {...
    'Object poses',2;...
    'Encoder L1',4;...
    'Encoder L2',5;...
    'Neural PCs',1;...
    'Decoder L1',6;...
    'Decoder L2',7;...
    'Subject poses',3;...
    };

for m = 1:row_num
    temppc = norm_coeff_sort_pca_cell(:,show_seq_list{m,2});
    for n = 1:col_num
        %%
        selpc = cellfun(@(x) x(:,n),...
            temppc,'UniformOutput',false);

        pad_pc = -1*ones(size(selpc,1),pad_len);
        
        for k = 1:size(selpc,1)
            pad_pc(k,1:length(selpc{k})) = selpc{k};
        end

        pad_pc(pad_pc==-1) = NaN;

        temph = subplot('Position',[...
            start_x+(n-1)*(box_x+inter_x),...
            start_y-(m-1)*(box_y+inter_y),box_x,box_y]);
        imagesc(pad_pc)
        hold on
        plot(start_list(:,1),start_list(:,2),'-k')
        hold on
        plot(end_list(:,1),end_list(:,2),'-k')
        hold off
        
        if m == 1
            title(['PC ',num2str(n)])
        end
        
        colormap(temph,[1,1,1;cmap_neu])
        
        box off
        set(gca,'FontSize',6)

        if n == 1
            ylabel(show_seq_list{m,1},'Rotation',0)
        end

        set(gca,'YTick',[1,size(selpc,1)])

        if n~=1
            set(gca,'YTickLabel',[])
        end

        set(gca,'TickDir','out')

        set(gca,'XTick',x_tick)

        if m ~= row_num
            set(gca,'XTickLabel',[])
        else
            set(gca,'XTickLabel',x_tick_label)
            xlabel('Time (s)')
        end

    end
end

%% show behaivor bar
start_x = 0.58;
start_y = 0.25;

enh_idx = 1.4;

box_x = enh_idx*0.05;
box_y = 0.08;

inter_x = 0.04;

bar_w = 0.6;

mk_size = 2;

cap_size = 2;

x_bias = 0.3;


obj_beh_l = sort_pca_l_mat(:,2);
sub_beh_l = sort_pca_l_mat(:,3);

mean_obj_beh_l = mean(obj_beh_l);
mean_sub_beh_l = mean(sub_beh_l);

std_obj_beh_l = std(obj_beh_l)./sqrt(length(obj_beh_l));
std_sub_beh_l = std(sub_beh_l)./sqrt(length(sub_beh_l));

[h_dist_1,p_dist_1] =kstest(obj_beh_l);
[h_dist_2,p_dist_2] =kstest(sub_beh_l);
[h_var,p_var] = vartest2(...
    obj_beh_l,...
    sub_beh_l);
if h_dist_1==0 && h_var==0 && h_dist_2==0
    % normal distribution
    [~,p_value] = ttest(...
                obj_beh_l,...
                sub_beh_l);
    disp('normal')
else
    % not normal distribution
    p_value = ranksum(...
                obj_beh_l,...
                sub_beh_l);
end
%%

subplot('Position',[start_x,start_y,box_x,box_y])
bar(1,mean_obj_beh_l,bar_w,'FaceColor',...
   object_pose_c)
hold on
bar(2,mean_sub_beh_l,'FaceColor',...
   subject_pose_c)
hold on
errorbar(1,mean_obj_beh_l,std_obj_beh_l,...
    'CapSize',cap_size,'Color','k')
hold on
errorbar(2,mean_sub_beh_l,std_sub_beh_l,...
    'CapSize',cap_size,'Color','k')
hold on
plot(x_bias+ones(length(obj_beh_l),1),obj_beh_l,...
    'ok','MarkerFaceColor','w',...
    'LineWidth',0.25,...
    'MarkerSize',mk_size)
hold on
plot(x_bias+2*ones(length(sub_beh_l),1),sub_beh_l,...
    'ok','MarkerFaceColor','w',...
    'LineWidth',0.25,...
    'MarkerSize',mk_size)
hold off

axis([0.3,2.7,-0.1,1])

box off
set(gca,'TickDir','out')
set(gca,'FontSize',6)

set(gca,'XTick',[1,2])
set(gca,'XTickLabel',{'Object','Subject'})
xlabel('Poses')
ylabel('Lyapunov exponents')

% show network bar
start_x = start_x+inter_x+box_x;
start_y = 0.25;

box_x = enh_idx*0.1;
box_y = 0.08;

l_e1 = sort_pca_l_mat(:,4);
l_e2 = sort_pca_l_mat(:,5);
l_d1 = sort_pca_l_mat(:,6);
l_d2 = sort_pca_l_mat(:,7);

mean_l_e1 = mean(l_e1);
mean_l_e2 = mean(l_e2);
mean_l_d1 = mean(l_d1);
mean_l_d2 = mean(l_d2);

std_l_e1 = std(l_e1)./sqrt(length(l_e1));
std_l_e2 = std(l_e2)./sqrt(length(l_e2));
std_l_d1 = std(l_d1)./sqrt(length(l_d1));
std_l_d2 = std(l_d2)./sqrt(length(l_d2));

net_cmap = 0.7*ones(1,3);

subplot('Position',[start_x,start_y,box_x,box_y])
bar(1,mean_l_e1,bar_w,'FaceColor',...
   net_cmap)
hold on
bar(2,mean_l_e2,'FaceColor',...
   net_cmap)
hold on
bar(3,mean_l_d1,bar_w,'FaceColor',...
   net_cmap)
hold on
bar(4,mean_l_d2,'FaceColor',...
   net_cmap)
hold on
errorbar(1,mean_l_e1,std_l_e1,...
    'CapSize',cap_size,'Color','k')
hold on
errorbar(2,mean_l_e2,std_l_e2,...
    'CapSize',cap_size,'Color','k')
hold on
errorbar(3,mean_l_d1,std_l_d1,...
    'CapSize',cap_size,'Color','k')
hold on
errorbar(4,mean_l_d2,std_l_d2,...
    'CapSize',cap_size,'Color','k')
hold on
plot(x_bias+ones(length(l_e1),1),l_e1,...
    'ok','MarkerFaceColor','w',...
    'LineWidth',0.25,...
    'MarkerSize',mk_size)
hold on
plot(x_bias+2*ones(length(l_e2),1),l_e1,...
    'ok','MarkerFaceColor','w',...
    'LineWidth',0.25,...
    'MarkerSize',mk_size)
hold on
plot(x_bias+3*ones(length(l_d1),1),l_d1,...
    'ok','MarkerFaceColor','w',...
    'LineWidth',0.25,...
    'MarkerSize',mk_size)
hold on
plot(x_bias+4*ones(length(l_d2),1),l_d2,...
    'ok','MarkerFaceColor','w',...
    'LineWidth',0.25,...
    'MarkerSize',mk_size)
hold off

box off

axis([0.3,4.7,min(min(sort_pca_l_mat(:,4:7))),...
    max(max(sort_pca_l_mat(:,4:7)))])

set(gca,'TickDir','out')
set(gca,'FontSize',6)

set(gca,'XTick',1:4)

set(gca,'XTickLabel',{...
    'Decoder L1',...
    'Decoder L2',...
    'Encoder L1',...
    'Encoder L2'})
% show far close far l exp
splname1 = split(sort_fcf_cell(:,1),'-');

trial_brain_name = cellfun(@(x) x(2:end),...
    splname1(:,3),'UniformOutput',false);

start_x = start_x+inter_x+box_x;
start_y = 0.25;

box_x = enh_idx*0.075;
box_y = 0.08;

stat_cell = cell(size(show_name_brain,1),1);

subplot('Position',[start_x,start_y,box_x,box_y])
for k = 1:size(show_name_brain,1)
    tempbrainname = show_name_brain{k,2};
    selidx = strcmp(tempbrainname,trial_brain_name);
    sel_l = sort_pca_l_mat(selidx,1);

    stat_cell{k,1} = sel_l;

    mean_l = mean(sel_l);
    std_l = std(sel_l)./sqrt(length(sel_l));
    bar(k,mean_l,bar_w,'FaceColor',...
        brain_c(k,:))
    hold on
    errorbar(k,mean_l,std_l,...
    'CapSize',cap_size,'Color','k')
    hold on
    plot(x_bias+k*ones(length(sel_l),1),sel_l,...
        'ok','MarkerFaceColor','w',...
        'LineWidth',0.25,...
        'MarkerSize',mk_size)
    hold on
end

plot([1,2],[0.4,0.4],'-k')
hold on
text(1.5,0.4,'*','VerticalAlignment','bottom',...
    'HorizontalAlignment','center')
hold on
plot([2,3],[0.5,0.5],'-k')
hold on
text(2.5,0.5,'***','VerticalAlignment','bottom',...
    'HorizontalAlignment','center')

hold off

box off

axis([0.3,3.7,0,0.6])

set(gca,'TickDir','out')
set(gca,'FontSize',6)

set(gca,'XTick',1:3)

set(gca,'XTickLabel',show_name_brain(:,1))

























