%{
    reservoir network demo
%}
clear all
close all
addpath(genpath(pwd))
rmpath(['D:\SBeA_Analysis\SBeA_v0.0.1\TPM\figs\function\' ...
    'gtw\lib\subspace']);
rmpath(['D:\SBeA_Analysis\SBeA_v0.0.1\TPM\figs\old\function\' ...
    'gtw\lib\subspace']);
rmpath(['D:\SBeA_Analysis\SBeA_v0.0.1\TPM\function\' ...
    'gtw\lib\subspace']);
%% set path
rootpath = ['H:\MTPM_body_language'];
beh_neu_path = [rootpath,'\beh_neu_20240412'];

%% load data
fileFolder = fullfile(beh_neu_path);
dirOutput = dir(fullfile(fileFolder,'free*-neu.mat'));
neuNames = {dirOutput.name}';

all_data_cell = cell(size(neuNames,1),13);
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

    % tempdata = load([beh_neu_path,'\',rootname,...
    %     '-cut-rnn_states_ed_train_2layers_op_big_clip.mat']);
    % tempdata = load([beh_neu_path,'\',rootname,...
    %     '-cut-rnn_states_ed_train_2layers_op_class.mat']);%0.8 light
    %     strength
    tempdata = load([beh_neu_path,'\',rootname,...
        '-cut-rnn_states_ed_train_2layers_op_class05part_rep.mat']);
    all_data_cell{k,13} = tempdata;
    
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
set(hall,'Position',[1080,100,800,800])
set(hall,'color','white');

%% set cmap
setcolor = cbrewer2('Spectral',11);
subject_pose_c = setcolor(3,:);
object_pose_c = setcolor(9,:);

pred_base_color = setcolor(11,:);

neu_cmap = cbrewer2('Paired',12);

in_c = neu_cmap(5,:);
de_c = neu_cmap(1,:);
no_c = neu_cmap(3,:);

brain_c = [...
    de_c;...
    in_c;...
    no_c];

neu_cmap = cbrewer2('Paired',12);

in_c = neu_cmap(5,:);
de_c = neu_cmap(1,:);
no_c = neu_cmap(3,:);

two_state_c = [...
    de_c;in_c;];

op_c = two_state_c(2,:);
free_c = two_state_c(1,:);

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

%% show skeletons
start_x = 0.04;
start_y = 0.74;

box_x = 0.1;
box_y = box_x;

inter_x = 0.02;
inter_y = 0.005;

col_num = 2;
row_num = 3;

drawline = [ 1 2; 1 3;2 3; 4 5;4 6;5 7;...
        6 8;7 14;8 14;5 13;6 13;7 13;8 13;...
    5 9;7 11;6 10; 8 12;14 15; 15 16];

xy_bias = 20;

show_brain_name = {'S1','dmPFC','M1'};
count = 1;

count_m = 1;

for m = 1:col_num
    for n = 1:row_num
        %
        subplot('Position',[...
            start_x+(m-1)*(box_x+inter_x),...
            start_y-(n-1)*(box_y+inter_y),...
            box_x,box_y])
        % tpmss
        if n == 1
            selname = 'free-seg1-1tpmss-1wt-20220226';
            sel_far_idx = [13;6];
            sel_close_idx = [15;13;14];
        end
        % tpmpfc
        if n == 2
            selname = 'free-seg2-1tpmpfc-rwt-20240103';
            sel_far_idx = [4;3];
            sel_close_idx = [6;5;3];
        end
        % tpmm
        if n == 3
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

        sel_show_idx = sel_show_idx(1);
        
        
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

        if m == 2
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
            zlabel({show_brain_name{count},'z'})
            count = count+1;
            if n == 1
                title('Side view')
            end
        else
            xlabel('y')
            if n == 1
                title('Top view')
            end
        end

        if n == 3
            ylabel('x')
        end
    end
end

%% compare error
error_mat = zeros(size(all_data_cell,1),8);
for k = 1:size(all_data_cell,1)
    %
    tempgood = all_data_cell{k,10};
    tempcontrol = all_data_cell{k,11};
    tempop = all_data_cell{k,13};
    
    Train_pca = tempgood.Train_pca;
    YTrain = tempgood.YTrain;

    op_Train_pca = tempop.save_Train_pca;
    op_YTrain = tempop.save_YTrain;

    good_pca_predict = tempgood.pca_predict;
    good_ys_predict = tempgood.ys_predict;
    good_ys_pca_predict = tempgood.ys_pca_predict;
    control_pca_predict = tempcontrol.pca_predict;
    control_ys_pca_predict_rand = tempcontrol.ys_pca_predict_rand;

    op_pca_predict = tempop.save_pca_predict;
    op_ys_predict = tempop.save_ys_predict;
    op_ys_pca_predict = tempop.save_ys_pca_predict;

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
    
    err_op_pca_predict = ...
        mean(sqrt((op_pca_predict-op_Train_pca).^2),'all');
    err_op_ys_predict = ...
        mean(sqrt((op_ys_predict-op_YTrain).^2),'all');
    err_op_ys_pca_predict = ...
        mean(sqrt((op_ys_pca_predict-op_YTrain).^2),'all');

    error_mat(k,:) = [...
        err_good_pca_predict,err_control_pca_predict,...
        err_good_ys_predict,err_good_ys_pca_predict,...
        err_control_ys_pca_predict_rand,...
        err_op_pca_predict,err_op_ys_predict,...
        err_op_ys_pca_predict];
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
start_x = 0.3;
start_y = 0.69;

box_x = 0.13;
box_y = 0.14;

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
mk_size = 2;
cap_size = 1;

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

% show ys error
% start_x = 0.7;
start_y = 0.53;

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

net_cell = cell(size(raw_trial_cell,1),4);

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

    temp_op_states_encoder_r1 = ...
        all_data_cell{k,13}.states_encoder_r1;
    temp_op_states_encoder_r1 = reshape(...
        temp_op_states_encoder_r1,[...
        size(temp_op_states_encoder_r1,2),...
        size(temp_op_states_encoder_r1,3)]);

    temp_op_states_encoder_r2 = ...
        all_data_cell{k,13}.states_encoder_r2;
    temp_op_states_encoder_r2 = reshape(...
        temp_op_states_encoder_r2,[...
        size(temp_op_states_encoder_r2,2),...
        size(temp_op_states_encoder_r2,3)]);

    temp_op_states_decoder_r1 = ...
        all_data_cell{k,13}.states_decoder_r1;
    temp_op_states_decoder_r1 = reshape(...
        temp_op_states_decoder_r1,[...
        size(temp_op_states_decoder_r1,2),...
        size(temp_op_states_decoder_r1,3)]);

    % neu_num = 1000;
    % ex_num =800;
    % ih_num = neu_num-ex_num;
    % aa = 0.66;
    % 
    % ex_a = -0.8;
    % ih_a = 0.8;
    % 
    % op_decoder_r1_bias = ones(...
    %     size(temp_op_states_decoder_r1));
    % op_decoder_r1_bias(:,1:ex_num) = ex_a;
    % op_decoder_r1_bias(:,(1+ex_num):end) = ih_a;
    % 
    % temp_op_states_decoder_r1 = ...
    %     temp_op_states_decoder_r1+op_decoder_r1_bias;
    % temp_op_states_decoder_r1(...
    %     temp_op_states_decoder_r1>=1) = 1;
    % temp_op_states_decoder_r1(...
    %     temp_op_states_decoder_r1<=-1) = -1;

    temp_op_states_decoder_r2 = ...
        all_data_cell{k,13}.states_decoder_r2;
    temp_op_states_decoder_r2 = reshape(...
        temp_op_states_decoder_r2,[...
        size(temp_op_states_decoder_r2,2),...
        size(temp_op_states_decoder_r2,3)]);

    % figure
    % subplot(211)
    % imagesc(temp_states_decoder_r2')
    % subplot(212)
    % imagesc(temp_op_states_decoder_r2')
    % 
    % figure
    % subplot(211)
    % imagesc(temp_states_decoder_r1')
    % title(mean(temp_states_decoder_r1(:)))
    % subplot(212)
    % imagesc(temp_op_states_decoder_r1')
    % title(mean(temp_op_states_decoder_r1(:)))

    net_cell{k,1} = temp_states_decoder_r1;
    net_cell{k,2} = temp_op_states_decoder_r1;
    net_cell{k,3} = temp_states_decoder_r2;
    net_cell{k,4} = temp_op_states_decoder_r2;
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
        
        op_net_d1 = temp_op_states_decoder_r1(tempstart:tempend,:);
        op_net_d2 = temp_op_states_decoder_r2(tempstart:tempend,:);

        fcf_cell = [fcf_cell;...
            {newname,all_data_2,all_data_3,all_data_4,...
            all_data_5,all_data_6,all_data_7,all_data_8,...
            all_data_9,raw_trial_cell{k,1}},...
            net_XTrain,net_YTrain,...
            net_e1,net_e2,net_d1,net_d2,...
            op_net_d1,op_net_d2];

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
sort_pca_cell = cell(size(sort_fcf_cell,1),9);

for k = 1:size(sort_pca_cell,1)
    %% load data
    tempneu = sort_fcf_cell{k,2};
    tempXTrain = sort_fcf_cell{k,11};
    tempYTrain = sort_fcf_cell{k,12};
    tempe1 = sort_fcf_cell{k,13};
    tempe2 = sort_fcf_cell{k,14};
    tempd1 = sort_fcf_cell{k,15};
    tempd2 = sort_fcf_cell{k,16};

    tempopd1 = sort_fcf_cell{k,17};
    tempopd2 = sort_fcf_cell{k,18};
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

    [coeff_op_d1, score_op_d1, ~, ~, explained_op_d1] = ...
        pca(tempopd1');
    [coeff_op_d2, score_op_d2, ~, ~, explained_op_d2] = ...
        pca(tempopd2');
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

    sort_pca_cell{k,8} = ...
        {coeff_op_d1,score_op_d1,explained_op_d1};
    sort_pca_cell{k,9} = ...
        {coeff_op_d2,score_op_d2,explained_op_d2};
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

start_x = 0.52;
start_y = 0.795;

box_x = 0.08;
box_y = 0.039;

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


        set(gca,'XTickLabel',[])


    end
end

%% show behaivor bar
start_x = 0.91;
start_y = 0.762;

box_x = 0.08;
box_y = 0.07;

inter_y = 0.045;

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
%

subplot('Position',[start_x,start_y,box_x,box_y])
bar(1,mean_obj_beh_l,bar_w,'FaceColor',...
   object_pose_c)
hold on
bar(2,mean_sub_beh_l,bar_w,'FaceColor',...
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
ylabel({'Lyapunov','exponents'})

% show network bar
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

subplot('Position',[start_x,...
    start_y-(box_y+inter_y),box_x,box_y])
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
    'Dec L1',...
    'Dec L2',...
    'Enc L1',...
    'Enc L2'})
ylabel({'Lyapunov','exponents'})

% show far close far l exp
splname1 = split(sort_fcf_cell(:,1),'-');

trial_brain_name = cellfun(@(x) x(2:end),...
    splname1(:,3),'UniformOutput',false);

stat_cell = cell(size(show_name_brain,1),1);

subplot('Position',[start_x,...
    start_y-2*(box_y+inter_y),box_x,box_y])
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

ylabel({'Lyapunov','exponents'})

%% show neural modulation
start_x = 0.03;
start_y = 0.39;

box_x = 0.2;
box_y = 0.1;

subplot('Position',[start_x,start_y,box_x,box_y])

set(gca,'XTick',[],'YTick',[])
box on
title('Neural modulation记得图标出来是pfc')

set(gca,'FontSize',6)

%% show neural modulation demo
start_x = 0.04;
start_y = 0.29;

box_x = 0.18;
box_y = 0.05;

inter_x = 0.01;
inter_y = 0.008;

show_demo_id = 2;
sel_all_data = net_cell(show_demo_id,[2,1,4,3]);

op_d1 = sel_all_data{4};

show_y_label = {...
    'Rec + Opto','Rec'};

title_list = {'Decoder L1','Decoder L2'};

count = 1;
for m = 1:2
    for n = 1:2
        temph = subplot('Position',[...
            start_x+(m-1)*(box_x+inter_x),...
            start_y-(n-1)*(box_y+inter_y),...
            box_x,box_y]);
        imagesc(sel_all_data{count}',[-1,1])
        colormap(temph,cmap_neu)
        count = count+1;
        
        set(gca,'YTick',[1,1000])
        set(gca,'TickDir','out')
        box off

        set(gca,'XTick',[1,9000,18000])
        

        if m~=1
            set(gca,'YTickLabel',[])
        else
            ylabel(show_y_label{n})
        end

        if n==1
            set(gca,'XTickLabel',[])
            title(title_list{m})
        else
            set(gca,'XTickLabel',[0,5,10])
            xlabel('Time (min)')
        end
        set(gca,'FontSize',6)
    end
end

% colorbar
cbar_box_x = 0.05;
cbar_box_y = 0.005;

cbar_inter_x = -0.005;

temph = subplot('Position',[...
    start_x+2*(box_x+inter_x)+cbar_inter_x,...
    start_y,...
    cbar_box_y,cbar_box_x]);
imagesc(fliplr((1:256))')
colormap(temph,cmap_neu)
set(gca,'XTick',[],'YTick',[])

text(1,280,'-1','FontSize',6,'HorizontalAlignment','center')
text(1,-30,'1','FontSize',6,'HorizontalAlignment','center')

text(3,128,'Neural activities','FontSize',6,'Rotation',90,...
    'HorizontalAlignment','center')

%% show neural changes
net_mat = cell2mat(cellfun(@(x) mean(x(:)),...
    net_cell,'UniformOutput',false));

spl_name_list = split(raw_trial_cell(:,1),'-');

selidx = cell2mat(cellfun(@(x) strcmp(x(2:end),'tpmpfc'),...
    spl_name_list(:,3),'UniformOutput',false));

pfc_net_mat = net_mat(selidx,:);

sort_pfc_net_mat = pfc_net_mat(:,[2,1,4,3]);

mean_pfc_net_mat = mean(sort_pfc_net_mat);

std_pfc_net_mat = std(sort_pfc_net_mat)./...
    sqrt(size(sort_pfc_net_mat,1));


%%
start_x = 0.3;
start_y = 0.415;

box_x = 0.04;
box_y = 0.08;

x_list = [1,2,4,5];

sel_idx = 1:2;

bar_w = 0.6;

cap_size = 2;

mk_size = 2;

x_bias = bar_w/2;

show_x_tick = {'Rec + Opto','Rec'};


opdata = sort_pfc_net_mat(:,sel_idx(1));
freedata = sort_pfc_net_mat(:,sel_idx(2));

[h_norm_1,p_norm_1] = lillietest(opdata);
[h_norm_2,p_norm_2] = lillietest(freedata);

[h_var,p_var] = vartest2(opdata,freedata);

sum_h = h_norm_1+h_norm_2+h_var;

if sum_h==0
    [h,p] = ttest(opdata,freedata);
    disp('ttest')
    disp(p)
else
    [p,h] = signrank(opdata,freedata,'tail','left');
    disp('signrank')
    disp(p)
end

subplot('Position',[start_x,start_y,box_x,box_y])
bar(x_list(sel_idx(1)),mean_pfc_net_mat(sel_idx(1)),bar_w,...
    'FaceColor',op_c)
hold on
bar(x_list(sel_idx(2)),mean_pfc_net_mat(sel_idx(2)),bar_w,...
    'FaceColor',free_c)
hold on
errorbar(x_list(sel_idx),mean_pfc_net_mat(sel_idx),...
    std_pfc_net_mat(sel_idx),'LineStyle','none',...
    'Color','k','CapSize',cap_size)
hold on
for k = 1:size(sort_pfc_net_mat,1)
    plot(x_list(sel_idx)+x_bias,...
        sort_pfc_net_mat(k,sel_idx),'-',...
        'Color','k',...
        'LineWidth',0.25)
    hold on
    plot(x_list(sel_idx)+x_bias,...
        sort_pfc_net_mat(k,sel_idx),'o',...
        'MarkerSize',mk_size,...
        'MarkerFaceColor','w',...
        'MarkerEdgeColor','k',...
        'LineWidth',0.25)
    hold on
end

show_sign_y = 0.05;
plot(x_list(sel_idx),[show_sign_y,show_sign_y],...
    '-k')
hold on
text(mean(x_list(sel_idx)),show_sign_y,'*',...
    'HorizontalAlignment','center',...
    'VerticalAlignment','baseline')

hold off
box off

axis([0.3,2.7,-0.1,0.12])

set(gca,'XTick',x_list(sel_idx))
set(gca,'XTickLabel',show_x_tick)
set(gca,'XTickLabelRotation',60)

set(gca,'TickDir','out')
set(gca,'FontSize',6)

ylabel({'Neural activities of','decoder L1'})

%
start_x = 0.39;
start_y = 0.415;

% box_x = 0.03;
% box_y = 0.08;

x_list = [1,2,4,5];

sel_idx = 3:4;

bar_w = 0.6;

cap_size = 2;

mk_size = 2;

x_bias = bar_w/2;

show_x_tick = {'Rec + Opto','Rec'};


opdata = sort_pfc_net_mat(:,sel_idx(1));
freedata = sort_pfc_net_mat(:,sel_idx(2));

[h_norm_1,p_norm_1] = lillietest(opdata);
[h_norm_2,p_norm_2] = lillietest(freedata);

[h_var,p_var] = vartest2(opdata,freedata);

sum_h = h_norm_1+h_norm_2+h_var;

if sum_h==0
    [h,p] = ttest(opdata,freedata);
    disp('ttest')
    disp(p)
else
    [p,h] = signrank(opdata,freedata);
    disp('signrank')
    disp(p)
end

subplot('Position',[start_x,start_y,box_x,box_y])
bar(x_list(sel_idx(1)),mean_pfc_net_mat(sel_idx(1)),bar_w,...
    'FaceColor',op_c)
hold on
bar(x_list(sel_idx(2)),mean_pfc_net_mat(sel_idx(2)),bar_w,...
    'FaceColor',free_c)
hold on
errorbar(x_list(sel_idx),mean_pfc_net_mat(sel_idx),...
    std_pfc_net_mat(sel_idx),'LineStyle','none',...
    'Color','k','CapSize',cap_size)
hold on
for k = 1:size(sort_pfc_net_mat,1)
    plot(x_list(sel_idx)+x_bias,...
        sort_pfc_net_mat(k,sel_idx),'-',...
        'Color','k',...
        'LineWidth',0.25)
    hold on
    plot(x_list(sel_idx)+x_bias,...
        sort_pfc_net_mat(k,sel_idx),'o',...
        'MarkerSize',mk_size,...
        'MarkerFaceColor','w',...
        'MarkerEdgeColor','k',...
        'LineWidth',0.25)
    hold on
end

hold off
box off

axis([3.3,5.7,-0.02,0.02])

set(gca,'XTick',x_list(sel_idx))
set(gca,'XTickLabel',show_x_tick)

set(gca,'TickDir','out')
set(gca,'FontSize',6)
set(gca,'XTickLabelRotation',60)

ylabel('decoder L2')

% show poses comparison
start_x = 0.04;
start_y = 0.1;

box_x = 0.025;
box_y = 0.08;

pfc_sort_error_mat = sort_error_mat(6:10,[7,3]);

opdata = pfc_sort_error_mat(:,1);
freedata = pfc_sort_error_mat(:,2);

[h_norm_1,p_norm_1] = lillietest(opdata);
[h_norm_2,p_norm_2] = lillietest(freedata);

[h_var,p_var] = vartest2(opdata,freedata);

sum_h = h_norm_1+h_norm_2+h_var;

if sum_h==0
    [h,p] = ttest(opdata,freedata);
    disp('ttest')
    disp(p)
else
    [p,h] = signrank(opdata,freedata);
    disp('signrank')
    disp(p)
end

for k = 1:size(show_star_list,1)
    if show_star_list{k,1}<=p && p<show_star_list{k,2}
        show_star = show_star_list{k,3};
    end
end

mean_pfc_sort_error_mat = mean(pfc_sort_error_mat);
std_pfc_sort_error_mat = std(pfc_sort_error_mat)./...
    sqrt(size(pfc_sort_error_mat,1));

x_list = 1:2;

subplot('Position',[start_x,start_y,box_x,box_y])
bar(x_list(1),mean_pfc_sort_error_mat(1),bar_w,...
    'FaceColor',op_c)
hold on
bar(x_list(2),mean_pfc_sort_error_mat(2),bar_w,...
    'FaceColor',free_c)
hold on
errorbar(x_list,mean_pfc_sort_error_mat,...
    std_pfc_sort_error_mat,'LineStyle','none',...
    'Color','k','CapSize',cap_size)
hold on
for k = 1:size(pfc_sort_error_mat,1)
    plot(x_list+x_bias,...
        pfc_sort_error_mat(k,:),'-',...
        'Color','k',...
        'LineWidth',0.25)
    hold on
    plot(x_list+x_bias,...
        pfc_sort_error_mat(k,:),'o',...
        'MarkerSize',mk_size,...
        'MarkerFaceColor','w',...
        'MarkerEdgeColor','k',...
        'LineWidth',0.25)
    hold on
end

show_y_pos = 6.5;
plot(x_list,[show_y_pos,show_y_pos],'-k',...
    'LineWidth',0.25)
hold on
text(mean(x_list),show_y_pos,show_star,...
    'HorizontalAlignment','center',...
    'VerticalAlignment','baseline')

hold off
box off

set(gca,'XTick',x_list)
set(gca,'XTickLabel',show_x_tick)
set(gca,'XTickLabelRotation',60)

set(gca,'TickDir','out')
set(gca,'FontSize',6)

axis([0.3,2.7,0,7.5])

ylabel('MSE (pixels)')

%% calculate pose speed compare
YTrain_cell = cellfun(@(x) x.YTrain,...
    all_data_cell(selidx,10),'UniformOutput',false);
ys_pred_cell = cellfun(@(x) x.ys_predict,...
    all_data_cell(selidx,10),'UniformOutput',false);

YTrain_op_cell = cellfun(@(x) x.save_YTrain,...
    all_data_cell(selidx,13),'UniformOutput',false);
ys_pred_op_cell = cellfun(@(x) x.save_ys_predict,...
    all_data_cell(selidx,13),'UniformOutput',false);

loco_thres = 150;%150/10, 15cm/s
ys_speed_subject = cell(size(ys_pred_cell,1),1);
for k = 1:size(ys_pred_cell,1)
    temppose = ys_pred_cell{k,1};
    for m = 1:size(temppose,2)
        temppose(:,m) = smooth(...
            medfilt1(...
            temppose(:,m),30))/10;
    end
    
    temp_speed = zeros(1,(size(temppose,2)/3));
    for m = 1:size(temp_speed,2)
        ttpose = temppose(:,((m-1)*3+1):(m*3));

        tempv = sqrt(sum(diff(ttpose).^2,2))*fs;

        temp_speed(1,m) = mean(tempv(tempv<loco_thres));
    end
    ys_speed_subject{k,1} = temp_speed;
end
ys_speed_subject = cell2mat(ys_speed_subject);

ys_speed_op_subject = cell(size(ys_pred_op_cell,1),1);
for k = 1:size(ys_pred_op_cell,1)
    temppose = ys_pred_op_cell{k,1};
    for m = 1:size(temppose,2)
        temppose(:,m) = smooth(...
            medfilt1(...
            temppose(:,m),30),30)/10;
    end
    
    temp_speed = zeros(1,(size(temppose,2)/3));
    for m = 1:size(temp_speed,2)
        ttpose = temppose(:,((m-1)*3+1):(m*3));

        tempv = sqrt(sum(diff(ttpose).^2,2))*fs;

        temp_speed(1,m) = mean(tempv(tempv<loco_thres));
    end
    ys_speed_op_subject{k,1} = temp_speed;
end
ys_speed_op_subject = cell2mat(ys_speed_op_subject);

mean(ys_speed_op_subject(:))
mean(ys_speed_subject(:))

mean_ys_speed_op_subject = mean(ys_speed_op_subject,2);
mean_ys_speed_subject = mean(ys_speed_subject,2);

stat_ys_speed_op_subject = reshape(...
    ys_speed_op_subject,[...
    size(ys_speed_op_subject,1)*size(ys_speed_op_subject,2),1]);
stat_ys_speed_subject = reshape(...
    ys_speed_subject,[...
    size(ys_speed_subject,1)*size(ys_speed_subject,2),1]);

% stat
p_list_subject = zeros(1,size(ys_speed_op_subject,2));
for k = 1:size(ys_speed_op_subject,2)
    opdata = ys_speed_op_subject(:,k);
    freedata = ys_speed_subject(:,k);

    [h_norm_1,p_norm_1] = lillietest(opdata);
    [h_norm_2,p_norm_2] = lillietest(freedata);

    [h_var,p_var] = vartest2(opdata,freedata);

    sum_h = h_norm_1+h_norm_2+h_var;

    if sum_h==0
        [h,p] = ttest(opdata,freedata);
        disp('ttest')
        disp(p)
    else
        [p,h] = signrank(opdata,freedata);
        disp('signrank')
        disp(p)
    end
    p_list_subject(1,k) = p;
end

show_star_list = {...
    0.05,1,'ns';...
    0.01,0.05,'*';...
    0.001,0.01,'**';...
    0.0001,0.001,'***';...
    0,0.0001,'****';...
    };

show_star_y_subject = cell(size(p_list_subject));
for k = 1:length(p_list_subject)
    tempp = p_list_subject(k);
    for m = 1:size(show_star_list,1)
        if show_star_list{m,1}<=tempp &&...
                tempp<show_star_list{m,2}
            show_star_y_subject{k} = show_star_list{m,3};
        end
    end
end
show_star_y_subject = show_star_y_subject';
% show speed compare
start_x = 0.12;
start_y = 0.1;

box_x = 0.31;
box_y = 0.1;

bar_w = 0.22;
cap_size = 1;
x_bb = bar_w/2;
mk_size = 2;
x_bias = 0.22;

max_y = 9;

mean_ys_speed_op_subject = mean(ys_speed_op_subject);
mean_ys_speed_subject = mean(ys_speed_subject);

std_ys_speed_op_subject = std(ys_speed_op_subject)./...
    sqrt(size(ys_speed_op_subject,1));
std_ys_speed_subject = std(ys_speed_subject)./...
    sqrt(size(ys_speed_subject,1));


% show non-locomotion speed compare, cm/s
x_list = 1:size(ys_speed_op_subject,2);
x_list_left = x_list-x_bias;
x_list_right = x_list+x_bias;

body_point_name = {...
    'Nose';...
    'Left ear';...
    'Right ear';...
    'Neck';...
    'Left front limb';...
    'Right front limb';...
    'Left hind limb';...
    'Right hind limb';...
    'Left front paw';...
    'Right front paw';...
    'Left hind paw';...
    'Right hind paw';...
    'Back';...
    'Tail base';...
    'Mid tail';...
    'Tip tail';...
    };

subplot('Position',[start_x,start_y,box_x,box_y])
bar(x_list_left,mean_ys_speed_op_subject,bar_w,...
    'FaceColor',op_c)
hold on
bar(x_list_right,mean_ys_speed_subject,bar_w,...
    'FaceColor',free_c)
hold on
errorbar(x_list_left,mean_ys_speed_op_subject,...
    std_ys_speed_op_subject,'LineStyle','none',...
    'CapSize',cap_size,'Color','k')
hold on
errorbar(x_list_right,mean_ys_speed_subject,...
    std_ys_speed_subject,'LineStyle','none',...
    'CapSize',cap_size,'Color','k')
hold on
for m = 1:size(ys_speed_op_subject,2)
    for n = 1:size(ys_speed_op_subject,1)
        plot(x_bb+[x_list_left(m),x_list_right(m)],...
            [ys_speed_op_subject(n,m),ys_speed_subject(n,m)],...
            '-k','LineWidth',0.25)
        hold on
    end
end

for k = 1:size(ys_speed_op_subject,1)
    plot(x_list_left+x_bb,ys_speed_op_subject(k,:),...
        'o','LineWidth',0.25,...
        'MarkerSize',mk_size,...
        'MarkerFaceColor','w',...
        'MarkerEdgeColor','k')
    hold on
    plot(x_list_right+x_bb,ys_speed_subject(k,:),...
        'o','LineWidth',0.25,...
        'MarkerSize',mk_size,...
        'MarkerFaceColor','w',...
        'MarkerEdgeColor','k')
    hold on
end

% show star
show_star_y = 6;
for k = 1:size(show_star_y_subject,1)
    if ~strcmp(show_star_y_subject{k,1},'ns')
        plot([x_list_left(k),x_list_right(k)],...
            show_star_y*[1,1],'-k','LineWidth',0.25)
        hold on
        text(x_list(k),show_star_y,show_star_y_subject{k,1},...
            'Rotation',90,...
            'VerticalAlignment','middle',...
            'HorizontalAlignment','left')
        hold on
    end
end

hold off

box off

axis([0.3,16.7,0,8.5])

ylabel({'Non-locomotion','speed (cm/s)'})

set(gca,'FontSize',6)
set(gca,'TickDir','out')
set(gca,'XTick',x_list)
set(gca,'XTickLabel',body_point_name)

%% show pca modulation, only dmpfc
row_num = 2;
col_num = 4;

start_x = 0.52;
start_y = 0.49;

box_x = 0.08;
box_y = 0.025;

inter_x = 0.005;
inter_y = 0.005;

pad_len = 600;

x_tick = [150,300,450];
x_tick_label = [0,5,10];

spl_name_list = split(sort_fcf_cell(:,1),'-');

selpfcidx = cell2mat(cellfun(@(x) ...
    strcmp(x(2:end),'tpmpfc'),spl_name_list(:,3),...
    'UniformOutput',false));

pfc_norm_coeff_sort_pca_cell = norm_coeff_sort_pca_cell(...
    selpfcidx,:);

start_list = zeros(size(pfc_norm_coeff_sort_pca_cell,1),2);
end_list = start_list;

for k = 1:size(pfc_norm_coeff_sort_pca_cell,1)
    start_list(k,1) = baseline_far_frame;
    start_list(k,2) = k;

    end_list(k,1) = ...
        size(pfc_norm_coeff_sort_pca_cell{k,1},1)-...
        after_far_frame;
    end_list(k,2) = k;
end

show_seq_list = {...
    {'Optogenetic','decoder L1','dmPFC'},8;...
    {'Optogenetic','decoder L2','dmPFC'},9;...
    };

for m = 1:row_num
    temppc = pfc_norm_coeff_sort_pca_cell(:,show_seq_list{m,2});
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
            % title(['PC ',num2str(n)])
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

        % if m ~= row_num
        set(gca,'XTickLabel',[])
        % else
        %     set(gca,'XTickLabel',x_tick_label)
        %     xlabel('Time (s)')
        % end

    end
end

% show pca raw, only dmpfc
row_num = 2;
col_num = 4;

start_x = 0.52;
start_y = 0.43;

box_x = 0.08;
box_y = 0.025;

inter_x = 0.005;
inter_y = 0.005;

pad_len = 600;

x_tick = [150,300,450];
x_tick_label = [0,5,10];

spl_name_list = split(sort_fcf_cell(:,1),'-');

selpfcidx = cell2mat(cellfun(@(x) ...
    strcmp(x(2:end),'tpmpfc'),spl_name_list(:,3),...
    'UniformOutput',false));

pfc_norm_coeff_sort_pca_cell = norm_coeff_sort_pca_cell(...
    selpfcidx,:);

start_list = zeros(size(pfc_norm_coeff_sort_pca_cell,1),2);
end_list = start_list;

for k = 1:size(pfc_norm_coeff_sort_pca_cell,1)
    start_list(k,1) = baseline_far_frame;
    start_list(k,2) = k;

    end_list(k,1) = ...
        size(pfc_norm_coeff_sort_pca_cell{k,1},1)-...
        after_far_frame;
    end_list(k,2) = k;
end

show_seq_list = {...
    {'Decoder L1','dmPFC'},6;...
    {'Decoder L2','dmPFC'},7;...
    };

for m = 1:row_num
    temppc = pfc_norm_coeff_sort_pca_cell(:,show_seq_list{m,2});
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
            % title(['PC ',num2str(n)])
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


%% calculate high freq ratio
% res_dim = 20;
cut_dim = 120;
bin_w = 5;
high_freq_p = 0.25;
% sel_thres = 99.99999999;
% digits = floor(log10(abs(floor(sel_thres)))) + 1;
trajc_cell = cell(size(norm_coeff_sort_pca_cell,1),8);
for k = 1:size(trajc_cell,1)
    %% raw de r1
    temppc = norm_coeff_sort_pca_cell{k,6};
    tempfftmat = zeros(1,size(temppc,2));
    for m = 1:size(temppc,2)
        tempfft = traj_complexity_fft_ad(...
            temppc(...
            baseline_far_frame:(end-after_far_frame),m),...
            high_freq_p);
        tempfftmat(1,m) = tempfft;
    end
    % plot(tempfftmat)
    % title(k)
    % pause
    trajc_cell{k,1} = tempfftmat;
    
    %% raw de r2
    temppc = norm_coeff_sort_pca_cell{k,7};
    tempfftmat = zeros(1,size(temppc,2));
    for m = 1:size(temppc,2)
        tempfft = traj_complexity_fft_ad(...
            temppc(...
            baseline_far_frame:(end-after_far_frame),m),...
            high_freq_p);
        tempfftmat(1,m) = tempfft;
    end
    % plot(tempfftmat)
    % title(k)
    % pause
    trajc_cell{k,2} = tempfftmat;
    
    %% op de r1
    temppc = norm_coeff_sort_pca_cell{k,8};
    tempfftmat = zeros(1,size(temppc,2));
    for m = 1:size(temppc,2)
        tempfft = traj_complexity_fft_ad(...
            temppc(...
            baseline_far_frame:(end-after_far_frame),m),...
            high_freq_p);
        tempfftmat(1,m) = tempfft;
    end
    % plot(tempfftmat)
    % title(k)
    % pause
    trajc_cell{k,3} = tempfftmat;
    
    %% op de r2
    temppc = norm_coeff_sort_pca_cell{k,9};
    tempfftmat = zeros(1,size(temppc,2));
    for m = 1:size(temppc,2)
        tempfft = traj_complexity_fft_ad(...
            temppc(...
            baseline_far_frame:(end-after_far_frame),m),...
            high_freq_p);
        tempfftmat(1,m) = tempfft;
    end
    % plot(tempfftmat)
    % title(k)
    % pause
    trajc_cell{k,4} = tempfftmat;

    % figure(k+10)
    % plot(trajc_cell{k,1},'-b')
    % hold on
    % % plot(trajc_cell{k,2},'-g')
    % % hold on
    % % plot(trajc_cell{k,3},'-c')
    % % hold on
    % plot(trajc_cell{k,3},'-r')
    % hold off
    % 
    % axis([50,150,0,1])

    %% dim resize
    % temp_de_r1_ve = cumsum(sort_pca_cell{k,6}{1,3});
    % temp_de_r2_ve = cumsum(sort_pca_cell{k,7}{1,3});
    % temp_op_de_r1_ve = cumsum(sort_pca_cell{k,8}{1,3});
    % temp_op_de_r2_ve = cumsum(sort_pca_cell{k,9}{1,3});
    % 
    % trajc_cell{k,5} = imresize(...
    %     trajc_cell{k,1}(1:sum(temp_de_r1_ve<sel_thres)),...
    %     [1,res_dim]);
    % trajc_cell{k,6} = imresize(...
    %     trajc_cell{k,2}(1:sum(temp_de_r2_ve<sel_thres)),...
    %     [1,res_dim]);
    % trajc_cell{k,7} = imresize(...
    %     trajc_cell{k,3}(1:sum(temp_op_de_r1_ve<sel_thres)),...
    %     [1,res_dim]);
    % trajc_cell{k,8} = imresize(...
    %     trajc_cell{k,4}(1:sum(temp_op_de_r2_ve<sel_thres)),...
    %     [1,res_dim]);
    % 
    trajc_cell{k,5} = trajc_cell{k,1}(1:cut_dim);
    trajc_cell{k,6} = trajc_cell{k,2}(1:cut_dim);
    trajc_cell{k,7} = trajc_cell{k,3}(1:cut_dim);
    trajc_cell{k,8} = trajc_cell{k,4}(1:cut_dim);
end

% 每20个PC一个bar
spl_name_list = split(sort_fcf_cell(:,1),'-');

selidx = cell2mat(cellfun(@(x) strcmp(x(2:end),'tpmpfc'),...
    spl_name_list(:,3),'UniformOutput',false));

pfc_trajc_cell = trajc_cell(selidx,:);

pfc_sort_fcf_cell = sort_fcf_cell(selidx,:);

spl_brain_name = split(pfc_sort_fcf_cell(:,1),'-');

brain_name_list = {...
    '1tpmpfc';...
    '2tpmpfc';...
    '3tpmpfc';...
    '4tpmpfc';...
    '5tpmpfc';...
    };

% for k = 1:size(pfc_trajc_cell,1)
%     figure(k+10)
%     plot(pfc_trajc_cell{k,5},'-b')
%     hold on
%     % plot(trajc_cell{k,2},'-g')
%     % hold on
%     % plot(trajc_cell{k,3},'-c')
%     % hold on
%     plot(pfc_trajc_cell{k,7},'-r')
%     hold off
% 
%     % axis([0,100,0,1])
% end

pfc_trajc_mat_de_r1 = cell2mat(pfc_trajc_cell(:,5));
pfc_trajc_mat_de_r2 = cell2mat(pfc_trajc_cell(:,6));
pfc_trajc_mat_op_de_r1 = cell2mat(pfc_trajc_cell(:,7));
pfc_trajc_mat_op_de_r2 = cell2mat(pfc_trajc_cell(:,8));

group_de_r1 = zeros(size(brain_name_list,1),...
    size(pfc_trajc_mat_de_r1,2));
group_de_r2 = zeros(size(brain_name_list,1),...
    size(pfc_trajc_mat_de_r2,2));
group_op_de_r1 = zeros(size(brain_name_list,1),...
    size(pfc_trajc_mat_op_de_r1,2));
group_op_de_r2 = zeros(size(brain_name_list,1),...
    size(pfc_trajc_mat_op_de_r2,2));

for k = 1:size(brain_name_list,1)
    tselidx = strcmp(brain_name_list{k,1},...
        spl_brain_name(:,3));
    group_de_r1(k,:) = mean(...
        pfc_trajc_mat_de_r1(tselidx,:));
    group_de_r2(k,:) = mean(...
        pfc_trajc_mat_de_r2(tselidx,:));
    group_op_de_r1(k,:) = mean(...
        pfc_trajc_mat_op_de_r1(tselidx,:));
    group_op_de_r2(k,:) = mean(...
        pfc_trajc_mat_op_de_r2(tselidx,:));
end

mean_group_de_r1 = mean(group_de_r1);
mean_group_de_r2 = mean(group_de_r2);
mean_group_op_de_r1 = mean(group_op_de_r1);
mean_group_op_de_r2 = mean(group_op_de_r2);

% figure
% plot(mean_group_de_r1)
% hold on
% plot(mean_group_op_de_r1)
% hold off

bin_group_de_r1 = zeros(...
    size(group_de_r1,1),...
    size(group_de_r1,2)/bin_w);
bin_group_de_r2 = zeros(...
    size(group_de_r2,1),...
    size(group_de_r2,2)/bin_w);
bin_group_op_de_r1 = zeros(...
    size(group_op_de_r1,1),...
    size(group_op_de_r1,2)/bin_w);
bin_group_op_de_r2 = zeros(...
    size(group_op_de_r2,1),...
    size(group_op_de_r2,2)/bin_w);

for k = 1:size(bin_group_de_r1,2)
    bin_group_de_r1(:,k) = ...
        mean(group_de_r1(:,...
        (1+(k-1)*bin_w):(k*bin_w)),2);
    bin_group_de_r2(:,k) = ...
        mean(group_de_r2(:,...
        (1+(k-1)*bin_w):(k*bin_w)),2);
    bin_group_op_de_r1(:,k) = ...
        mean(group_op_de_r1(:,...
        (1+(k-1)*bin_w):(k*bin_w)),2);
    bin_group_op_de_r2(:,k) = ...
        mean(group_op_de_r2(:,...
        (1+(k-1)*bin_w):(k*bin_w)),2);
end

mean_bin_group_de_r1 = mean(bin_group_de_r1);
mean_bin_group_de_r2 = mean(bin_group_de_r2);
mean_bin_group_op_de_r1 = mean(bin_group_op_de_r1);
mean_bin_group_op_de_r2 = mean(bin_group_op_de_r2);

std_bin_group_de_r1 = std(bin_group_de_r1)./sqrt(size(bin_group_de_r1,1));
std_bin_group_de_r2 = std(bin_group_de_r2)./sqrt(size(bin_group_de_r2,1));
std_bin_group_op_de_r1 = std(bin_group_op_de_r1)./sqrt(size(bin_group_op_de_r1,1));
std_bin_group_op_de_r2 = std(bin_group_op_de_r2)./sqrt(size(bin_group_op_de_r2,1));
% % 
% figure
% plot(mean_bin_group_de_r2)
% hold on
% plot(mean_bin_group_op_de_r2)
% hold off

% paired test
p_list = zeros(2,size(bin_group_de_r1,2));
for k = 1:size(p_list,2)
    disp(k)
    opdata = bin_group_op_de_r1(:,k);
    freedata = bin_group_de_r1(:,k);
    
    [h_norm_1,p_norm_1] = lillietest(opdata);
    [h_norm_2,p_norm_2] = lillietest(freedata);

    [h_var,p_var] = vartest2(opdata,freedata);

    sum_h = h_norm_1+h_norm_2+h_var;

    if sum_h==0
        [h,p] = ttest(opdata,freedata);
        disp('ttest')
        disp(p)
    else
        [p,h] = signrank(opdata,freedata);
        disp('signrank')
        disp(p)
    end
    disp(p)
    p_list(1,k) = p;

    opdata = bin_group_op_de_r2(:,k);
    freedata = bin_group_de_r2(:,k);
    
    [h_norm_1,p_norm_1] = lillietest(opdata);
    [h_norm_2,p_norm_2] = lillietest(freedata);

    [h_var,p_var] = vartest2(opdata,freedata);

    sum_h = h_norm_1+h_norm_2+h_var;

    if sum_h==0
        [h,p] = ttest(opdata,freedata);
        disp('ttest')
        disp(p)
    else
        [p,h] = signrank(opdata,freedata);
        disp('signrank')
        disp(p)
    end
    disp(p)
    p_list(2,k) = p;
end

% show diff
start_x = 0.49;
start_y = 0.23;

box_x = 0.28;
box_y = 0.11;

inter_y = 0.02;

bar_w = 0.22;
cap_size = 1;
x_bb = bar_w/2;
mk_size = 1.5;
x_bias = 0.22;

axis_list = [0.3,24.7,0,1];
show_star_bias = -0.05;

show_x_list_data = 1:bin_w:cut_dim;
show_x_list = cell(length(show_x_list_data),1);

for k = 1:size(show_x_list,1)
    show_x_list{k} = [num2str(show_x_list_data(k)),...
        '-',num2str(show_x_list_data(k)+bin_w-1)];
end

% d1
show_data_left = bin_group_op_de_r1;
show_data_right = bin_group_de_r1;

show_p = p_list(1,:);

mean_show_data_left = mean(show_data_left);
mean_show_data_right = mean(show_data_right);
std_show_data_left = std(show_data_left)./sqrt(size(show_data_left,1));
std_show_data_right = std(show_data_right)./sqrt(size(show_data_right,1));

x_list = 1:size(show_data_left,2);
x_list_left = x_list-x_bias;
x_list_right = x_list+x_bias;

subplot('Position',[start_x,start_y,box_x,box_y])
templ1 = bar(x_list_left,mean_show_data_left,bar_w,...
    'FaceColor',op_c);
hold on
templ2 = bar(x_list_right,mean_show_data_right,bar_w,...
    'FaceColor',free_c);
hold on
errorbar(x_list_left,mean_show_data_left,...
    std_show_data_left,'LineStyle','none',...
    'CapSize',cap_size,'Color','k')
hold on
errorbar(x_list_right,mean_show_data_right,...
    std_show_data_right,'LineStyle','none',...
    'CapSize',cap_size,'Color','k')
hold on
for m = 1:size(show_data_left,2)
    for n = 1:size(show_data_left,1)
        plot(x_bb+[x_list_left(m),x_list_right(m)],...
            [show_data_left(n,m),show_data_right(n,m)],...
            '-k','LineWidth',0.25)
        hold on
    end
end

for k = 1:size(show_data_left,1)
    plot(x_list_left+x_bb,show_data_left(k,:),...
        'o','LineWidth',0.25,...
        'MarkerSize',mk_size,...
        'MarkerFaceColor','w',...
        'MarkerEdgeColor','k')
    hold on
    plot(x_list_right+x_bb,show_data_right(k,:),...
        'o','LineWidth',0.25,...
        'MarkerSize',mk_size,...
        'MarkerFaceColor','w',...
        'MarkerEdgeColor','k')
    hold on
end

show_star_y_list = cell(size(show_p));
for k = 1:length(show_p)
    tempp = show_p(k);
    for m = 1:size(show_star_list,1)
        if show_star_list{m,1}<=tempp &&...
                tempp<show_star_list{m,2}
            show_star_y_list{k} = show_star_list{m,3};
            continue
        elseif tempp==1
            show_star_y_list{k} = 'ns';
        end
    end
end

% show star
show_star_y = axis_list(end)+show_star_bias;
for k = 1:size(show_star_y_list,2)
    if ~strcmp(show_star_y_list{k},'ns')
        plot([x_list_left(k),x_list_right(k)],...
            show_star_y*[1,1],'-k','LineWidth',0.25)
        hold on
        text(x_list(k),show_star_y,show_star_y_list{k},...
            'Rotation',90,...
            'VerticalAlignment','middle',...
            'HorizontalAlignment','left')
        hold on
    end
end

hold off
box off

axis(axis_list)

set(gca,'TickDir','out')
set(gca,'FontSize',6)

set(gca,'XTick',x_list)
set(gca,'XTickLabel',[])

ylabel({'High frequency ratio (%)','of decoder 1'})

legend([templ1,templ2],{'Rec + Opto','Rec'},'box','off',...
    'Location','west')

%d2
show_data_left = bin_group_op_de_r2;
show_data_right = bin_group_de_r2;

show_p = p_list(2,:);

mean_show_data_left = mean(show_data_left);
mean_show_data_right = mean(show_data_right);
std_show_data_left = std(show_data_left)./sqrt(size(show_data_left,1));
std_show_data_right = std(show_data_right)./sqrt(size(show_data_right,1));

x_list = 1:size(show_data_left,2);
x_list_left = x_list-x_bias;
x_list_right = x_list+x_bias;

subplot('Position',[start_x,...
    start_y-(box_y+inter_y),box_x,box_y])
templ1 = bar(x_list_left,mean_show_data_left,bar_w,...
    'FaceColor',op_c);
hold on
templ2 = bar(x_list_right,mean_show_data_right,bar_w,...
    'FaceColor',free_c);
hold on
errorbar(x_list_left,mean_show_data_left,...
    std_show_data_left,'LineStyle','none',...
    'CapSize',cap_size,'Color','k')
hold on
errorbar(x_list_right,mean_show_data_right,...
    std_show_data_right,'LineStyle','none',...
    'CapSize',cap_size,'Color','k')
hold on
for m = 1:size(show_data_left,2)
    for n = 1:size(show_data_left,1)
        plot(x_bb+[x_list_left(m),x_list_right(m)],...
            [show_data_left(n,m),show_data_right(n,m)],...
            '-k','LineWidth',0.25)
        hold on
    end
end

for k = 1:size(show_data_left,1)
    plot(x_list_left+x_bb,show_data_left(k,:),...
        'o','LineWidth',0.25,...
        'MarkerSize',mk_size,...
        'MarkerFaceColor','w',...
        'MarkerEdgeColor','k')
    hold on
    plot(x_list_right+x_bb,show_data_right(k,:),...
        'o','LineWidth',0.25,...
        'MarkerSize',mk_size,...
        'MarkerFaceColor','w',...
        'MarkerEdgeColor','k')
    hold on
end

show_star_y_list = cell(size(show_p));
for k = 1:length(show_p)
    tempp = show_p(k);
    for m = 1:size(show_star_list,1)
        if show_star_list{m,1}<=tempp &&...
                tempp<show_star_list{m,2}
            show_star_y_list{k} = show_star_list{m,3};
            continue
        elseif tempp==1
            show_star_y_list{k} = 'ns';
        end
    end
end

% show star
show_star_y = axis_list(end)+show_star_bias;
for k = 1:size(show_star_y_list,2)
    if ~strcmp(show_star_y_list{k},'ns')
        plot([x_list_left(k),x_list_right(k)],...
            show_star_y*[1,1],'-k','LineWidth',0.25)
        hold on
        text(x_list(k),show_star_y,show_star_y_list{k},...
            'Rotation',90,...
            'VerticalAlignment','middle',...
            'HorizontalAlignment','left')
        hold on
    end
end

hold off
box off

axis(axis_list)

set(gca,'TickDir','out')
set(gca,'FontSize',6)

set(gca,'XTick',x_list)
set(gca,'XTickLabel',show_x_list)

% xlabel(['Dimensional normalized PCs (',...
%     num2str(sel_thres,digits),'% explained)'])

xlabel('PCs')

ylabel({'High frequency ratio (%)','of decoder 2'})

%% calculate l exp of op
sel_dim = 100;

sel_pfc_pc_cell = cellfun(@(x) x(:,1:sel_dim),...
    pfc_norm_coeff_sort_pca_cell(:,6:9),...
    'UniformOutput',false);


raw_de_r1_cell = cell(size(sel_pfc_pc_cell,1),sel_dim);
raw_de_r2_cell = cell(size(sel_pfc_pc_cell,1),sel_dim);

op_de_r1_cell = cell(size(sel_pfc_pc_cell,1),sel_dim);
op_de_r2_cell = cell(size(sel_pfc_pc_cell,1),sel_dim);

for k = 1:size(raw_de_r1_cell,1)
    temppc = sel_pfc_pc_cell{k,1};
    for m = 1:size(raw_de_r1_cell,2)
        raw_de_r1_cell{k,m} = temppc(:,m);
    end
end

for k = 1:size(raw_de_r2_cell,1)
    temppc = sel_pfc_pc_cell{k,2};
    for m = 1:size(raw_de_r2_cell,2)
        raw_de_r2_cell{k,m} = temppc(:,m);
    end
end

for k = 1:size(op_de_r1_cell,1)
    temppc = sel_pfc_pc_cell{k,3};
    for m = 1:size(op_de_r1_cell,2)
        op_de_r1_cell{k,m} = temppc(:,m);
    end
end

for k = 1:size(op_de_r2_cell,1)
    temppc = sel_pfc_pc_cell{k,4};
    for m = 1:size(op_de_r2_cell,2)
        op_de_r2_cell{k,m} = temppc(:,m);
    end
end

raw_de_r1_l_mat = ...
    cellfun(@(x) lyapunovExponent(x,30),...
    raw_de_r1_cell);

raw_de_r2_l_mat = ...
    cellfun(@(x) lyapunovExponent(x,30),...
    raw_de_r2_cell);

op_de_r1_l_mat = ...
    cellfun(@(x) lyapunovExponent(x,30),...
    op_de_r1_cell);

op_de_r2_l_mat = ...
    cellfun(@(x) lyapunovExponent(x,30),...
    op_de_r2_cell);

%% show l
group_num = 1;
group_raw_de_r1_l_cell = cell(1,...
    size(raw_de_r1_l_mat,2)/group_num);
group_raw_de_r2_l_cell = cell(1,...
    size(raw_de_r2_l_mat,2)/group_num);
group_op_de_r1_l_cell = cell(1,...
    size(op_de_r1_l_mat,2)/group_num);
group_op_de_r2_l_cell = cell(1,...
    size(op_de_r2_l_mat,2)/group_num);

for k = 1:size(group_raw_de_r1_l_cell,2)
    tempchunk = raw_de_r1_l_mat(:,...
        ((k-1)*group_num+1):(k*group_num));
    group_raw_de_r1_l_cell{1,k} = reshape(...
        tempchunk,[...
        size(tempchunk,1)*size(tempchunk,2),1]);
end

for k = 1:size(group_raw_de_r2_l_cell,2)
    tempchunk = raw_de_r2_l_mat(:,...
        ((k-1)*group_num+1):(k*group_num));
    group_raw_de_r2_l_cell{1,k} = reshape(...
        tempchunk,[...
        size(tempchunk,1)*size(tempchunk,2),1]);
end

for k = 1:size(group_op_de_r1_l_cell,2)
    tempchunk = op_de_r1_l_mat(:,...
        ((k-1)*group_num+1):(k*group_num));
    group_op_de_r1_l_cell{1,k} = reshape(...
        tempchunk,[...
        size(tempchunk,1)*size(tempchunk,2),1]);
end

for k = 1:size(group_op_de_r2_l_cell,2)
    tempchunk = op_de_r2_l_mat(:,...
        ((k-1)*group_num+1):(k*group_num));
    group_op_de_r2_l_cell{1,k} = reshape(...
        tempchunk,[...
        size(tempchunk,1)*size(tempchunk,2),1]);
end

group_op_de_r1_l_mat = cell2mat(group_op_de_r1_l_cell);
group_op_de_r2_l_mat = cell2mat(group_op_de_r2_l_cell);
group_raw_de_r1_l_mat = cell2mat(group_raw_de_r1_l_cell);
group_raw_de_r2_l_mat = cell2mat(group_raw_de_r2_l_cell);

disp('r1')
r1_l_p_list = zeros(1,size(group_op_de_r1_l_mat,2));
for k = 1:size(group_op_de_r1_l_mat,2)
    opdata = group_op_de_r1_l_mat(:,k);
    freedata = group_raw_de_r1_l_mat(:,k);
    
    [h_norm_1,p_norm_1] = lillietest(opdata);
    [h_norm_2,p_norm_2] = lillietest(freedata);
    
    [h_var,p_var] = vartest2(opdata,freedata);
    
    sum_h = h_norm_1+h_norm_2+h_var;
    
    if sum_h==0
        [h,p] = ttest(opdata,freedata);
        disp('ttest')
        disp(p)
    else
        [p,h] = signrank(opdata,freedata);
        disp('signrank')
        disp(p)
    end

    r1_l_p_list(1,k) = p;
end

disp('r2')
r2_l_p_list = zeros(1,size(group_op_de_r2_l_mat,2));
for k = 1:size(group_op_de_r2_l_mat,2)
    opdata = group_op_de_r2_l_mat(:,k);
    freedata = group_raw_de_r2_l_mat(:,k);
    
    [h_norm_1,p_norm_1] = lillietest(opdata);
    [h_norm_2,p_norm_2] = lillietest(freedata);
    
    [h_var,p_var] = vartest2(opdata,freedata);
    
    sum_h = h_norm_1+h_norm_2+h_var;
    
    if sum_h==0
        [h,p] = ttest(opdata,freedata);
        disp('ttest')
        disp(p)
    else
        [p,h] = signrank(opdata,freedata);
        disp('signrank')
        disp(p)
    end

    r2_l_p_list(1,k) = p;
end

%% show first 4 pc l
start_x = 0.91;
start_y = 0.42;

box_x = 0.08;
box_y = 0.08;

inter_y = 0.02;

show_axis = [0.5,3.5,-1,1];

sel_idx = 1:3;

bar_w = 0.22;
cap_size = 1;
x_bb = bar_w/2;
mk_size = 1.5;
x_bias = 0.23;

x_list = sel_idx;
x_list_left = x_list-x_bias;
x_list_right = x_list+x_bias;

sel_op_de_r1_l_mat = group_op_de_r1_l_mat(:,sel_idx);
sel_raw_de_r1_l_mat = group_raw_de_r1_l_mat(:,sel_idx);
sel_op_de_r2_l_mat = group_op_de_r2_l_mat(:,sel_idx);
sel_raw_de_r2_l_mat = group_raw_de_r2_l_mat(:,sel_idx);

sel_r1_l_p_list = r1_l_p_list(sel_idx);
sel_r2_l_p_list = r2_l_p_list(sel_idx);

mean_sel_op_de_r1_l_mat = mean(sel_op_de_r1_l_mat);
mean_sel_raw_de_r1_l_mat = mean(sel_raw_de_r1_l_mat);
mean_sel_op_de_r2_l_mat = mean(sel_op_de_r2_l_mat);
mean_sel_raw_de_r2_l_mat = mean(sel_raw_de_r2_l_mat);

std_sel_op_de_r1_l_mat = std(sel_op_de_r1_l_mat)./...
    sqrt(size(sel_op_de_r1_l_mat,1));
std_sel_raw_de_r1_l_mat = std(sel_raw_de_r1_l_mat)./...
    sqrt(size(sel_raw_de_r1_l_mat,1));
std_sel_op_de_r2_l_mat = std(sel_op_de_r2_l_mat)./...
    sqrt(size(sel_op_de_r2_l_mat,1));
std_sel_raw_de_r2_l_mat = std(sel_raw_de_r2_l_mat)./...
    sqrt(size(sel_raw_de_r2_l_mat,1));

subplot('Position',[start_x,start_y,box_x,box_y])
bar(x_list_left,mean_sel_op_de_r1_l_mat,bar_w,...
    'FaceColor',op_c)
hold on
bar(x_list_right,mean_sel_raw_de_r1_l_mat,bar_w,...
    'FaceColor',free_c)
hold on
errorbar(x_list_left,mean_sel_op_de_r1_l_mat,...
    std_sel_op_de_r1_l_mat,'LineStyle','none',...
    'CapSize',cap_size,'Color','k')
hold on
errorbar(x_list_right,mean_sel_raw_de_r1_l_mat,...
    std_sel_raw_de_r1_l_mat,'LineStyle','none',...
    'CapSize',cap_size,'Color','k')
hold on

for m = 1:size(sel_op_de_r1_l_mat,2)
    for n = 1:size(sel_op_de_r1_l_mat,1)
        plot(x_bb+[x_list_left(m),x_list_right(m)],...
            [sel_op_de_r1_l_mat(n,m),sel_raw_de_r1_l_mat(n,m)],...
            '-k','LineWidth',0.25)
        hold on
    end
end
for k = 1:size(sel_op_de_r1_l_mat,1)
    plot(x_list_left+x_bb,sel_op_de_r1_l_mat(k,:),...
        'o','LineWidth',0.25,...
        'MarkerSize',mk_size,...
        'MarkerFaceColor',op_c,...
        'MarkerEdgeColor',op_c)
    hold on
    plot(x_list_right+x_bb,sel_raw_de_r1_l_mat(k,:),...
        'o','LineWidth',0.25,...
        'MarkerSize',mk_size,...
        'MarkerFaceColor',free_c,...
        'MarkerEdgeColor',free_c)
    hold on
end
hold off

box off
axis(show_axis)

ylabel({'Lyapunov exponents','of Opto Dec L1'})
set(gca,'TickDir','out')
set(gca,'FontSize',6)
set(gca,'XTickLabel',[])


subplot('Position',[start_x,...
    start_y-inter_y-box_y,box_x,box_y])
bar(x_list_left,mean_sel_op_de_r2_l_mat,bar_w,...
    'FaceColor',op_c)
hold on
bar(x_list_right,mean_sel_raw_de_r2_l_mat,bar_w,...
    'FaceColor',free_c)
hold on
errorbar(x_list_left,mean_sel_op_de_r2_l_mat,...
    std_sel_op_de_r2_l_mat,'LineStyle','none',...
    'CapSize',cap_size,'Color','k')
hold on
errorbar(x_list_right,mean_sel_raw_de_r2_l_mat,...
    std_sel_raw_de_r2_l_mat,'LineStyle','none',...
    'CapSize',cap_size,'Color','k')
hold on

for m = 1:size(sel_op_de_r2_l_mat,2)
    for n = 1:size(sel_op_de_r2_l_mat,1)
        plot(x_bb+[x_list_left(m),x_list_right(m)],...
            [sel_op_de_r2_l_mat(n,m),sel_raw_de_r2_l_mat(n,m)],...
            '-k','LineWidth',0.25)
        hold on
    end
end
for k = 1:size(sel_op_de_r2_l_mat,1)
    plot(x_list_left+x_bb,sel_op_de_r2_l_mat(k,:),...
        'o','LineWidth',0.25,...
        'MarkerSize',mk_size,...
        'MarkerFaceColor',op_c,...
        'MarkerEdgeColor',op_c)
    hold on
    plot(x_list_right+x_bb,sel_raw_de_r2_l_mat(k,:),...
        'o','LineWidth',0.25,...
        'MarkerSize',mk_size,...
        'MarkerFaceColor',free_c,...
        'MarkerEdgeColor',free_c)
    hold on
end

% show star
show_star_sel_r2_l_p = cell(size(sel_r2_l_p_list));
for k = 1:length(sel_r2_l_p_list)
    tempp = sel_r2_l_p_list(k);
    for m = 1:size(show_star_list,1)
        if show_star_list{m,1}<=tempp &&...
                tempp<show_star_list{m,2}
            show_star_sel_r2_l_p{k} = show_star_list{m,3};
        end
    end
end
show_star_sel_r2_l_p = show_star_sel_r2_l_p';


show_star_y = 0.6;
for k = 1:size(show_star_sel_r2_l_p,1)
    if ~strcmp(show_star_sel_r2_l_p{k,1},'ns')
        plot([x_list_left(k),x_list_right(k)],...
            show_star_y*[1,1],'-k','LineWidth',0.25)
        hold on
        text(x_list(k),show_star_y,show_star_sel_r2_l_p{k,1},...
            'Rotation',0,...
            'VerticalAlignment','bottom',...
            'HorizontalAlignment','center')
        hold on
    end
end

hold off

box off
axis(show_axis)

ylabel({' ','of Opto Dec L2'})
xlabel('Neural PCs')
set(gca,'TickDir','out')
set(gca,'FontSize',6)

% show high dimension l
start_x = 0.82;
box_x = 0.17;
big_inter_y = 0.02;

mk_size = 1.5;

sel_idx_r1 = find(r1_l_p_list<0.05);
sel_idx_r2 = find(r2_l_p_list<0.05);

sel_idx_r2 = sel_idx_r2(sel_idx_r2>3);

sel_op_de_r1_l_mat = group_op_de_r1_l_mat(:,sel_idx_r1);
sel_raw_de_r1_l_mat = group_raw_de_r1_l_mat(:,sel_idx_r1);
sel_op_de_r2_l_mat = group_op_de_r2_l_mat(:,sel_idx_r2);
sel_raw_de_r2_l_mat = group_raw_de_r2_l_mat(:,sel_idx_r2);

sel_r1_l_p_list = r1_l_p_list(sel_idx_r1);
sel_r2_l_p_list = r2_l_p_list(sel_idx_r2);

mean_sel_op_de_r1_l_mat = mean(sel_op_de_r1_l_mat);
mean_sel_raw_de_r1_l_mat = mean(sel_raw_de_r1_l_mat);
mean_sel_op_de_r2_l_mat = mean(sel_op_de_r2_l_mat);
mean_sel_raw_de_r2_l_mat = mean(sel_raw_de_r2_l_mat);

std_sel_op_de_r1_l_mat = std(sel_op_de_r1_l_mat)./...
    sqrt(size(sel_op_de_r1_l_mat,1));
std_sel_raw_de_r1_l_mat = std(sel_raw_de_r1_l_mat)./...
    sqrt(size(sel_raw_de_r1_l_mat,1));
std_sel_op_de_r2_l_mat = std(sel_op_de_r2_l_mat)./...
    sqrt(size(sel_op_de_r2_l_mat,1));
std_sel_raw_de_r2_l_mat = std(sel_raw_de_r2_l_mat)./...
    sqrt(size(sel_raw_de_r2_l_mat,1));

% show r1
show_axis = [0.5,3.5,-3,17];

x_list = 1:length(sel_idx_r1);
x_list_left = x_list-x_bias;
x_list_right = x_list+x_bias;
subplot('Position',[start_x,...
    start_y-2*(inter_y+box_y)-big_inter_y,...
    box_x,box_y])
bar(x_list_left,mean_sel_op_de_r1_l_mat,bar_w,...
    'FaceColor',op_c)
hold on
bar(x_list_right,mean_sel_raw_de_r1_l_mat,bar_w,...
    'FaceColor',free_c)
hold on
errorbar(x_list_left,mean_sel_op_de_r1_l_mat,...
    std_sel_op_de_r1_l_mat,'LineStyle','none',...
    'CapSize',cap_size,'Color','k')
hold on
errorbar(x_list_right,mean_sel_raw_de_r1_l_mat,...
    std_sel_raw_de_r1_l_mat,'LineStyle','none',...
    'CapSize',cap_size,'Color','k')
hold on

for m = 1:size(sel_op_de_r1_l_mat,2)
    for n = 1:size(sel_op_de_r1_l_mat,1)
        plot([x_bb+x_list_left(m),x_list_right(m)-x_bb],...
            [sel_op_de_r1_l_mat(n,m),sel_raw_de_r1_l_mat(n,m)],...
            '-k','LineWidth',0.25)
        hold on
    end
end
for k = 1:size(sel_op_de_r1_l_mat,1)
    plot(x_list_left+x_bb,sel_op_de_r1_l_mat(k,:),...
        'o','LineWidth',0.25,...
        'MarkerSize',mk_size,...
        'MarkerFaceColor','w',...
        'MarkerEdgeColor','k')
    hold on
    plot(x_list_right-x_bb,sel_raw_de_r1_l_mat(k,:),...
        'o','LineWidth',0.25,...
        'MarkerSize',mk_size,...
        'MarkerFaceColor','w',...
        'MarkerEdgeColor','k')
    hold on
end

% show star
show_star_sel_r1_l_p = cell(size(sel_r1_l_p_list));
for k = 1:length(sel_r1_l_p_list)
    tempp = sel_r1_l_p_list(k);
    for m = 1:size(show_star_list,1)
        if show_star_list{m,1}<=tempp &&...
                tempp<show_star_list{m,2}
            show_star_sel_r1_l_p{k} = show_star_list{m,3};
        end
    end
end
show_star_sel_r1_l_p = show_star_sel_r1_l_p';


show_star_y = 14;
for k = 1:size(show_star_sel_r1_l_p,1)
    if ~strcmp(show_star_sel_r1_l_p{k,1},'ns')
        plot([x_list_left(k),x_list_right(k)],...
            show_star_y*[1,1],'-k','LineWidth',0.25)
        hold on
        text(x_list(k),show_star_y,show_star_sel_r1_l_p{k,1},...
            'Rotation',0,...
            'VerticalAlignment','bottom',...
            'HorizontalAlignment','center')
        hold on
    end
end

hold off

hold off

box off
axis(show_axis)

ylabel({'Lyapunov exponents','of Opto Dec L1'})
set(gca,'TickDir','out')
set(gca,'FontSize',6)
set(gca,'XTick',x_list)
set(gca,'XTickLabel',sel_idx_r1)

% show r2
show_axis = [0.5,6.5,-3,17];

x_list = 1:length(sel_idx_r2);
x_list_left = x_list-x_bias;
x_list_right = x_list+x_bias;
subplot('Position',[start_x,...
    start_y-3*(inter_y+box_y)-big_inter_y,...
    box_x,box_y])
bar(x_list_left,mean_sel_op_de_r2_l_mat,bar_w,...
    'FaceColor',op_c)
hold on
bar(x_list_right,mean_sel_raw_de_r2_l_mat,bar_w,...
    'FaceColor',free_c)
hold on
errorbar(x_list_left,mean_sel_op_de_r2_l_mat,...
    std_sel_op_de_r2_l_mat,'LineStyle','none',...
    'CapSize',cap_size,'Color','k')
hold on
errorbar(x_list_right,mean_sel_raw_de_r2_l_mat,...
    std_sel_raw_de_r2_l_mat,'LineStyle','none',...
    'CapSize',cap_size,'Color','k')
hold on

for m = 1:size(sel_op_de_r2_l_mat,2)
    for n = 1:size(sel_op_de_r2_l_mat,1)
        plot([x_bb+x_list_left(m),x_list_right(m)-x_bb],...
            [sel_op_de_r2_l_mat(n,m),sel_raw_de_r2_l_mat(n,m)],...
            '-k','LineWidth',0.25)
        hold on
    end
end
for k = 1:size(sel_op_de_r2_l_mat,1)
    plot(x_list_left+x_bb,sel_op_de_r2_l_mat(k,:),...
        'o','LineWidth',0.25,...
        'MarkerSize',mk_size,...
        'MarkerFaceColor','w',...
        'MarkerEdgeColor','k')
    hold on
    plot(x_list_right-x_bb,sel_raw_de_r2_l_mat(k,:),...
        'o','LineWidth',0.25,...
        'MarkerSize',mk_size,...
        'MarkerFaceColor','w',...
        'MarkerEdgeColor','k')
    hold on
end

% show star
show_star_sel_r2_l_p = cell(size(sel_r2_l_p_list));
for k = 1:length(sel_r2_l_p_list)
    tempp = sel_r2_l_p_list(k);
    for m = 1:size(show_star_list,1)
        if show_star_list{m,1}<=tempp &&...
                tempp<show_star_list{m,2}
            show_star_sel_r2_l_p{k} = show_star_list{m,3};
        end
    end
end
show_star_sel_r2_l_p = show_star_sel_r2_l_p';


show_star_y = 13;
for k = 1:size(show_star_sel_r2_l_p,1)
    if ~strcmp(show_star_sel_r2_l_p{k,1},'ns')
        plot([x_list_left(k),x_list_right(k)],...
            show_star_y*[1,1],'-k','LineWidth',0.25)
        hold on
        text(x_list(k),show_star_y,show_star_sel_r2_l_p{k,1},...
            'Rotation',0,...
            'VerticalAlignment','bottom',...
            'HorizontalAlignment','center')
        hold on
    end
end

hold off

box off
axis(show_axis)

ylabel({' ','of Opto Dec L2'})
xlabel('Neural PCs')
set(gca,'TickDir','out')
set(gca,'FontSize',6)
set(gca,'XTick',x_list)
set(gca,'XTickLabel',sel_idx_r2)










