%{
    fig2, 
    the comparison using correlation
%}
clear all
close all
addpath(genpath(pwd))
%% set path
rootpath = ['E:\MTPM_body_language'];

beh_video_path = [rootpath,'\raw_data\behavior_all'];

bea_path = [beh_video_path,'\BeA_path'];

process_tpm_path = [rootpath,...
    '\raw_data\tpm_suite2p\process'];

beh_neu_path = [rootpath,'\beh_neu_20240412'];
%% load data
fileFolder = fullfile(beh_neu_path);
dirOutput = dir(fullfile(fileFolder,'free*-cebra.mat'));
cebraNames = {dirOutput.name}';

cebra_cell = cell(size(cebraNames,1),13);
cebra_cell(:,1) = cebraNames;

smo_win = 60;

for k = 1:size(cebra_cell,1)
    tempdata = load([beh_neu_path,'\',cebraNames{k}]);
    cebra_cell{k,2} = tempdata.cebra;
    cebra_cell(k,3:10) = split(cebra_cell{k,1},'-');
    cebra_cell{k,11} = cebra_cell{k,5}(2:end);

    labelname = [cebra_cell{k,1}(1:(end-10)),'.mat'];

    templabel = load([beh_neu_path,'\',labelname]);

    neuname = [...
        cebra_cell{k,3},'-',...
        cebra_cell{k,4},'-',...
        cebra_cell{k,5},'-',...
        cebra_cell{k,6},'-',...
        cebra_cell{k,7},'-neu.mat',...
        ];

    tempneu = load([beh_neu_path,'\',neuname]);

    if strcmp(cebra_cell{k,8},'pose')
        temppose = templabel.coords3d;
        for m = 1:size(temppose,2)
            temppose(:,m) = smooth(...
                templabel.coords3d(:,m),smo_win);
        end
        cebra_cell{k,12} = temppose;
        cebra_cell{k,13} = tempneu.dff_smo_Fc';
    end

    if strcmp(cebra_cell{k,8},'beh_mod')
        cebra_cell{k,12} = templabel.beh_mod_list;
        cebra_cell{k,13} = tempneu.dff_smo_Fc';
    end

    if strcmp(cebra_cell{k,8},'seq')
        cebra_cell{k,12} = templabel.seq_label_list;
        cebra_cell{k,13} = tempneu.dff_smo_Fc';
    end
    disp(k)
end

dist_cell = cell(size(cebra_cell,1),3);
for k = 1:size(cebra_cell,1)
    distname = [...
        cebra_cell{k,3},'-',...
        cebra_cell{k,4},'-',...
        cebra_cell{k,5},'-',...
        cebra_cell{k,6},'-',...
        cebra_cell{k,7},'-',...
        'distance','-',...
        cebra_cell{k,9},'.mat'...
        ];
    tempdata = load([beh_neu_path,'\',distname]);

    dist_cell(k,:) = tempdata.dist_data;
    disp(k)
end

rec_error_cell = cell(size(cebra_cell,1),3);
for k = 1:size(rec_error_cell,1)
    errname = [cebra_cell{k,1}(1:(end-10)),...
        '-reconstruction_error.mat'];
    tempdata = load([beh_neu_path,'\',errname]);
    rec_error_cell{k,1} = tempdata.decode_pred';
    rec_error_cell{k,2} = tempdata.dist_error;
    rec_error_cell{k,3} = double(tempdata.dist_error_all)';
    if size(rec_error_cell{k,3},1)<size(rec_error_cell{k,3},2)
        rec_error_cell{k,3} = rec_error_cell{k,3}';
    end
end


cebra_pose_cell = cebra_cell(...
    strcmp(cebra_cell(:,8),'pose'),:);
cebra_mov_cell = cebra_cell(...
    strcmp(cebra_cell(:,8),'beh_mod'),:);
cebra_seq_cell = cebra_cell(...
    strcmp(cebra_cell(:,8),'seq'),:);

dist_pose_cell = dist_cell(...
    strcmp(cebra_cell(:,8),'pose'),:);
dist_mov_cell = dist_cell(...
    strcmp(cebra_cell(:,8),'beh_mod'),:);
dist_seq_cell = dist_cell(...
    strcmp(cebra_cell(:,8),'seq'),:);

error_pose_cell = rec_error_cell(...
    strcmp(cebra_cell(:,8),'pose'),:);
error_mov_cell = rec_error_cell(...
    strcmp(cebra_cell(:,8),'beh_mod'),:);
error_seq_cell = rec_error_cell(...
    strcmp(cebra_cell(:,8),'seq'),:);

%% create unique_label_list, mov
all_num_mov_label = cell(size(cebra_mov_cell,1),1);
all_str_mov_label = {};
for k = 1:size(all_num_mov_label,1)
    all_num_mov_label{k,1} = cell2mat(cebra_mov_cell{k,12}(:,2));
    all_str_mov_label = [all_str_mov_label;cebra_mov_cell{k,12}(:,1)];
end
all_num_mov_label = cell2mat(all_num_mov_label);
unique_num_mov_label = unique(all_num_mov_label);
unique_str_mov_label = cell(size(unique_num_mov_label,1),1);

for k = 1:size(unique_str_mov_label,1)
    tempnumlabel = unique_num_mov_label(k,1);
    unique_str_mov_label{k,1} = unique(...
        all_str_mov_label(all_num_mov_label==tempnumlabel));
end

%% create unique_label_list, seq
all_num_seq_label = cell(size(cebra_seq_cell,1),1);
for k = 1:size(all_num_seq_label,1)
    all_num_seq_label{k,1} = cebra_seq_cell{k,12}(:,1);
end
unique_num_seq_label = unique(cell2mat(all_num_seq_label));
%% plot canvas
hall = figure(1);
set(hall,'Position',[680,0,800,800])
set(hall,'color','white');
%% calculate the correlations between poses and neurons
corr_thres = 0.2;
% pose
corr_pose_neu_cell = cell(size(cebra_pose_cell,1),2);
for k = 1:size(cebra_pose_cell,1)
    %% load data
    temppose = cebra_pose_cell{k,12};
    tempneu = cebra_pose_cell{k,13};
    %% calculate the correlations
    [r,p] = corr(temppose,tempneu);
    %% select significant neurons
    selidx = ((p<0.05) .* (abs(r)>corr_thres))==1;
    selr = r(selidx);

    selidx_neu = sum(selidx)>0;
    % %% temp show
    % hist(selr,128)
    % title(cebra_cell{k,1})
    % xlabel(sum(selidx_neu)./length(selidx_neu))
    % pause
    %% append data
    corr_pose_neu_cell{k,1} = [...
        sum(selidx_neu),size(r,2),...
        sum(selidx_neu)/size(r,2)];
    corr_pose_neu_cell{k,2} = selidx_neu;
end
% mov
corr_mov_neu_cell = cell(size(cebra_mov_cell,1),2);
spec_corr_mov_cell = cell(size(cebra_mov_cell,1),1);
for k = 1:size(cebra_mov_cell,1)
    %% load data
    tempidx = cell2mat(cebra_mov_cell{k,12}(:,2));
    tempneu = cebra_mov_cell{k,13};
    
    %% create fire idx mat
    % figure
    tempfire = zeros(size(tempneu));
    for m = 1:size(tempfire,2)
        %%
        ttneu = tempneu(:,m);
        tempthres = 0.5;%std(ttneu);
        duration_thres = 30;%frames
        ttfire = ttneu>tempthres;
        firesavelist = idx2savelist(ttfire);
        firesavelist(firesavelist(:,3)==0,:) = [];
        tt_duration = firesavelist(:,2)-firesavelist(:,1);
        firesavelist(tt_duration<duration_thres,:) = [];
        for n = 1:size(firesavelist,1)
            tempfire(...
                firesavelist(n,1):firesavelist(n,2),m) = 1;
        end
        % plot(ttneu,'-b')
        % hold on
        % plot(tempfire(:,m),'-r')
        % hold off
        % pause
    end
    %% calculate correlations
    % create bw_label
    bw_label = zeros(size(tempidx,1),size(unique_num_mov_label,1));
    for m = 1:size(bw_label,2)
        templabel = unique_num_mov_label(m,1);
        bw_label(:,m) = templabel==tempidx;
    end

    % calculate correlation
    [r,p] = corr(bw_label,tempfire);
    
    %% select significant neurons
    selidx = ((p<0.05) .* (abs(r)>corr_thres))==1;
    selr = r(selidx);

    selidx_neu = sum(selidx)>0;
    %% find the specific correlation neuron
    spec_corr_list = zeros(size(selidx,1),2);
    spec_corr_list(:,1) = unique_num_mov_label;
    for m = 1:size(spec_corr_list,1)
        tempselidx = selidx(m,:);
        if sum(tempselidx)==1
            spec_corr_list(m,2) = find(tempselidx);
        end
    end
    
    spec_corr_mov_cell{k,1} = spec_corr_list;

    %% append data
    corr_mov_neu_cell{k,1} = [...
        sum(selidx_neu),size(r,2),...
        sum(selidx_neu)/size(r,2)];
    corr_mov_neu_cell{k,2} = selidx_neu;
end
% seq
% find correlations between no/meaning sequence and neurons
corr_mean_seq_neu_cell = cell(size(cebra_seq_cell,1),2);
corr_nomean_seq_neu_cell = cell(size(cebra_seq_cell,1),2);
spec_corr_seq_cell = cell(size(cebra_seq_cell,1),1);
for k = 1:size(cebra_seq_cell,1)
    %% load data
    tempidx = cebra_seq_cell{k,12}(:,1);
    tempneu = cebra_seq_cell{k,13};
    %% create fire idx mat
    % figure
    tempfire = zeros(size(tempneu));
    for m = 1:size(tempfire,2)
        %%
        ttneu = tempneu(:,m);
        tempthres = 0.5;%std(ttneu);
        duration_thres = 30;%frames
        ttfire = ttneu>tempthres;
        firesavelist = idx2savelist(ttfire);
        firesavelist(firesavelist(:,3)==0,:) = [];
        tt_duration = firesavelist(:,2)-firesavelist(:,1);
        firesavelist(tt_duration<duration_thres,:) = [];
        for n = 1:size(firesavelist,1)
            tempfire(...
                firesavelist(n,1):firesavelist(n,2),m) = 1;
        end
        % plot(ttneu,'-b')
        % hold on
        % plot(tempfire(:,m),'-r')
        % hold off
        % pause
    end
    %% calculate correlations
    % create bw_label
    bw_label = zeros(size(tempidx,1),size(unique_num_seq_label,1));
    for m = 1:size(bw_label,2)
        templabel = unique_num_seq_label(m,1);
        bw_label(:,m) = templabel==tempidx;
    end

    % calculate correlation
    [r,p] = corr(bw_label,tempfire);
    
    mean_r = r(2:end,:);
    mean_p = p(2:end,:);
    nomean_r = r(1,:);
    nomean_p = p(1,:);
    %% select significant neurons, mean
    mean_selidx = ((mean_p<0.05) .* (abs(mean_r)>corr_thres))==1;
    mean_selr = mean_r(mean_selidx);

    mean_selidx_neu = sum(mean_selidx)>0;
    %% find the specific correlation neuron
    spec_corr_list = zeros(size(mean_selidx,1),2);
    spec_corr_list(:,1) = unique_num_seq_label(2:end);
    for m = 1:size(spec_corr_list,1)
        tempselidx = mean_selidx(m,:);
        if sum(tempselidx)==1
            spec_corr_list(m,2) = find(tempselidx);
        end
    end
    
    spec_corr_seq_cell{k,1} = spec_corr_list;
    %% append data
    corr_mean_seq_neu_cell{k,1} = [...
        sum(mean_selidx_neu),size(r,2),...
        sum(mean_selidx_neu)/size(r,2)];
    corr_mean_seq_neu_cell{k,2} = mean_selidx_neu;

    %% select significant neurons, no mean
    nomean_selidx = ((nomean_p<0.05) .* (abs(nomean_r)>corr_thres))==1;
    nomean_selr = nomean_r(nomean_selidx);

    nomean_selidx_neu = nomean_selidx>0;
    %% append data
    corr_nomean_seq_neu_cell{k,1} = [...
        sum(nomean_selidx_neu),size(r,2),...
        sum(nomean_selidx_neu)/size(r,2)];
    corr_nomean_seq_neu_cell{k,2} = nomean_selidx_neu;
end
%% show the correlations across each brain area and individual
start_x = 0.61;
start_y = 0.8;

box_x = 0.12;
box_y = 0.18;

setcolor = cbrewer2('Spectral',11);
mouse_tpm_c = setcolor(3,:);
mouse_free_c = setcolor(9,:);

mouse_overlap = setcolor(1,:);

show_mice_name = {'Self','Partner'};

show_list = {...
    'tpm','tpmss',mouse_tpm_c;...
    'free','tpmss',mouse_free_c;...
    'tpm','tpmpfc',mouse_tpm_c;...
    'free','tpmpfc',mouse_free_c;...
    'tpm','tpmm',mouse_tpm_c;...
    'free','tpmm',mouse_free_c};

show_xtick = {...
    'S1','dmPFC','M1'};

xlist = [1,2,4,5,7,8];

sign_level = {...
    0.01,0.05,'*';
    0.001,0.01,'**';
    0.0001,0.001,'***';
    0,0.0001,'****'};

cap_size = 2;

line_w = 0.25;

mk_size = 2;

x_bias = 0.4;

stat_mat = zeros(5,size(show_list,1));

subplot('Position',[start_x,start_y,box_x,box_y])
% bar errorbar

legend_cell = cell(size(show_list,1),1);

for k = 1:size(show_list,1)
    %%
    selidx1 = strcmp(cebra_pose_cell(:,9),show_list{k,1});
    selidx2 = strcmp(cebra_pose_cell(:,11),show_list{k,2});

    selidx = selidx1&selidx2;

    sel_corr = cell2mat(corr_pose_neu_cell(selidx,1));

    stat_mat(:,k) = sel_corr(:,3);
    %% show
    mean_sel_corr = mean(sel_corr(:,3));
    std_sel_corr = std(sel_corr(:,3))./sqrt(size(sel_corr,1));
    legend_cell{k,1} = bar(xlist(k),mean_sel_corr,...
        'FaceColor',show_list{k,3},...
        'LineWidth',line_w);
    hold on
    errorbar(xlist(k),mean_sel_corr,std_sel_corr,...
        'Color','k','CapSize',cap_size,...
        'LineWidth',line_w)
    hold on
end
hold on
for k = 1:size(show_list,1)
    %%
    selidx1 = strcmp(cebra_pose_cell(:,9),show_list{k,1});
    selidx2 = strcmp(cebra_pose_cell(:,11),show_list{k,2});

    selidx = selidx1&selidx2;

    sel_corr = cell2mat(corr_pose_neu_cell(selidx,1));

    stat_mat(:,k) = sel_corr(:,3);
    %% show
    if rem(k,2) == 1
        selidx1 = strcmp(cebra_pose_cell(:,9),show_list{k+1,1});
        selidx2 = strcmp(cebra_pose_cell(:,11),show_list{k+1,2});
    
        selidx = selidx1&selidx2;
    
        sel_corr_2 = cell2mat(corr_pose_neu_cell(selidx,1));

        for m = 1:size(sel_corr,1)
            plot(x_bias+[xlist(k),xlist(k+1)],...
                [sel_corr(m,3),sel_corr_2(m,3)],...
                '-k','LineWidth',line_w)
            hold on
        end

        %% statistics
        [h_norm1,p_norm1] = lillietest(sel_corr(:,3));
        [h_norm2,p_norm2] = lillietest(sel_corr_2(:,3));
        [h_var,p_var] = vartest2(sel_corr(:,3),sel_corr_2(:,3));
        
        if (h_norm1 | h_norm2 | h_var) == 1
            [p,h] = ranksum(sel_corr(:,3),sel_corr_2(:,3));
        else
            [h,p] = ttest(sel_corr(:,3),sel_corr_2(:,3));
        end
        if h == 1
            plot([xlist(k),xlist(k+1)],[0.9,0.9],'k-',...
                'LineWidth',line_w)
            if sign_level{1,1}<=p && p<sign_level{1,2}
                show_star = sign_level{1,3};
            elseif sign_level{2,1}<=p && p<sign_level{2,2}
                show_star = sign_level{2,3};
            elseif sign_level{3,1}<=p && p<sign_level{3,2}
                show_star = sign_level{3,3};
            elseif sign_level{4,1}<=p && p<sign_level{4,2}
                show_star = sign_level{4,3};
            end
            text(...
                (xlist(k)+xlist(k+1))/2,...
                0.9,show_star,...
                'HorizontalAlignment','center',...
                'VerticalAlignment','bottom',...
                'FontName','Calibri')
        end
    end
    plot(x_bias+xlist(k)*ones(size(sel_corr(:,3))),sel_corr(:,3),...
        'o','LineWidth',line_w,...
        'MarkerEdgeColor','k',...
        'MarkerFaceColor','w',...
        'MarkerSize',mk_size)
    hold on
end
hold off

box off
set(gca,'XTick',(xlist(1:2:end)+xlist(2:2:end))/2)
set(gca,'TickDir','out')
set(gca,'XTickLabel',[])
set(gca,'XTickLabelRotation',0)
ylabel('Neural pose correlation ratio')
set(gca,'FontSize',6)
legend([legend_cell{1},legend_cell{2}],show_mice_name,...
    'Box','off','Location','northwest')
axis([0.3,8.7,0,1])
title('All')

%% close correlation
corr_pose_neu_close_cell = cell(size(cebra_pose_cell,1),1);
for k = 1:size(cebra_pose_cell,1)
    %% load data
    temppose = cebra_pose_cell{k,12}(dist_pose_cell{k,2}==1,:);
    tempneu = cebra_pose_cell{k,13}(dist_pose_cell{k,2}==1,:);
    %% calculate the correlations
    [r,p] = corr(temppose,tempneu);
    %% select significant neurons
    selidx = ((p<0.05) .* (abs(r)>corr_thres))==1;
    selr = r(selidx);

    selidx_neu = sum(selidx)>0;
    % %% temp show
    % hist(selr,128)
    % title(cebra_cell{k,1})
    % xlabel(sum(selidx_neu)./length(selidx_neu))
    % pause
    %% append data
    corr_pose_neu_close_cell{k,1} = [...
        sum(selidx_neu),size(r,2),...
        sum(selidx_neu)/size(r,2)];
end
%% far correlation
corr_pose_neu_far_cell = cell(size(cebra_pose_cell,1),1);
for k = 1:size(cebra_pose_cell,1)
    %% load data
    temppose = cebra_pose_cell{k,12}(dist_pose_cell{k,2}==0,:);
    tempneu = cebra_pose_cell{k,13}(dist_pose_cell{k,2}==0,:);
    %% calculate the correlations
    [r,p] = corr(temppose,tempneu);
    %% select significant neurons
    selidx = ((p<0.05) .* (abs(r)>corr_thres))==1;
    selr = r(selidx);

    selidx_neu = sum(selidx)>0;
    % %% temp show
    % hist(selr,128)
    % title(cebra_cell{k,1})
    % xlabel(sum(selidx_neu)./length(selidx_neu))
    % pause
    %% append data
    corr_pose_neu_far_cell{k,1} = [...
        sum(selidx_neu),size(r,2),...
        sum(selidx_neu)/size(r,2)];
end
%% show the close correlations across each brain area and individual
start_x = 0.74;
start_y = 0.8;

box_x = 0.12;
box_y = 0.18;

setcolor = cbrewer2('Spectral',11);
mouse_tpm_c = setcolor(3,:);
mouse_free_c = setcolor(9,:);

show_mice_name = {'Self','Partner'};

show_list = {...
    'tpm','tpmss',mouse_tpm_c;...
    'free','tpmss',mouse_free_c;...
    'tpm','tpmpfc',mouse_tpm_c;...
    'free','tpmpfc',mouse_free_c;...
    'tpm','tpmm',mouse_tpm_c;...
    'free','tpmm',mouse_free_c};

show_xtick = {...
    'S1','dmPFC','M1'};

xlist = [1,2,4,5,7,8];

cap_size = 2;

line_w = 0.25;

mk_size = 2;

x_bias = 0.4;

stat_mat = zeros(5,size(show_list,1));

subplot('Position',[start_x,start_y,box_x,box_y])
% bar errorbar

legend_cell = cell(size(show_list,1),1);

for k = 1:size(show_list,1)
    %%
    selidx1 = strcmp(cebra_pose_cell(:,9),show_list{k,1});
    selidx2 = strcmp(cebra_pose_cell(:,11),show_list{k,2});

    selidx = selidx1&selidx2;

    sel_corr = cell2mat(corr_pose_neu_close_cell(selidx,:));

    stat_mat(:,k) = sel_corr(:,3);
    %% show
    mean_sel_corr = mean(sel_corr(:,3));
    std_sel_corr = std(sel_corr(:,3))./sqrt(size(sel_corr,1));
    legend_cell{k,1} = bar(xlist(k),mean_sel_corr,...
        'FaceColor',show_list{k,3},...
        'LineWidth',line_w);
    hold on
    errorbar(xlist(k),mean_sel_corr,std_sel_corr,...
        'Color','k','CapSize',cap_size,...
        'LineWidth',line_w)
    hold on
end
hold on
for k = 1:size(show_list,1)
    %%
    selidx1 = strcmp(cebra_pose_cell(:,9),show_list{k,1});
    selidx2 = strcmp(cebra_pose_cell(:,11),show_list{k,2});

    selidx = selidx1&selidx2;

    sel_corr = cell2mat(corr_pose_neu_close_cell(selidx,:));

    stat_mat(:,k) = sel_corr(:,3);
    %% show
    if rem(k,2) == 1
        selidx1 = strcmp(cebra_pose_cell(:,9),show_list{k+1,1});
        selidx2 = strcmp(cebra_pose_cell(:,11),show_list{k+1,2});
    
        selidx = selidx1&selidx2;
    
        sel_corr_2 = cell2mat(corr_pose_neu_close_cell(selidx,:));

        for m = 1:size(sel_corr,1)
            plot(x_bias+[xlist(k),xlist(k+1)],...
                [sel_corr(m,3),sel_corr_2(m,3)],...
                '-k','LineWidth',line_w)
            hold on
        end

        %% statistics
        [h_norm1,p_norm1] = lillietest(sel_corr(:,3));
        [h_norm2,p_norm2] = lillietest(sel_corr_2(:,3));
        [h_var,p_var] = vartest2(sel_corr(:,3),sel_corr_2(:,3));
        
        if (h_norm1 | h_norm2 | h_var) == 1
            [p,h] = ranksum(sel_corr(:,3),sel_corr_2(:,3));
        else
            [h,p] = ttest(sel_corr(:,3),sel_corr_2(:,3));
        end
        if h == 1
            plot([xlist(k),xlist(k+1)],[0.9,0.9],'k-',...
                'LineWidth',line_w)
            if sign_level{1,1}<=p && p<sign_level{1,2}
                show_star = sign_level{1,3};
            elseif sign_level{2,1}<=p && p<sign_level{2,2}
                show_star = sign_level{2,3};
            elseif sign_level{3,1}<=p && p<sign_level{3,2}
                show_star = sign_level{3,3};
            elseif sign_level{4,1}<=p && p<sign_level{4,2}
                show_star = sign_level{4,3};
            end
            text(...
                (xlist(k)+xlist(k+1))/2,...
                0.9,show_star,...
                'HorizontalAlignment','center',...
                'VerticalAlignment','bottom',...
                'FontName','Calibri')
        end
    end
    plot(x_bias+xlist(k)*ones(size(sel_corr(:,3))),sel_corr(:,3),...
        'o','LineWidth',line_w,...
        'MarkerEdgeColor','k',...
        'MarkerFaceColor','w',...
        'MarkerSize',mk_size)
    hold on
end
hold off

box off
set(gca,'XTick',(xlist(1:2:end)+xlist(2:2:end))/2)
set(gca,'TickDir','out')
set(gca,'XTickLabel',[])
set(gca,'XTickLabelRotation',0)
set(gca,'YTickLabel',[])
set(gca,'FontSize',6)
axis([0.3,8.7,0,1])
title('Close')
%% show the far correlations across each brain area and individual
start_x = 0.87;
start_y = 0.8;

box_x = 0.12;
box_y = 0.18;

setcolor = cbrewer2('Spectral',11);
mouse_tpm_c = setcolor(3,:);
mouse_free_c = setcolor(9,:);

show_mice_name = {'Self','Partner'};

show_list = {...
    'tpm','tpmss',mouse_tpm_c;...
    'free','tpmss',mouse_free_c;...
    'tpm','tpmpfc',mouse_tpm_c;...
    'free','tpmpfc',mouse_free_c;...
    'tpm','tpmm',mouse_tpm_c;...
    'free','tpmm',mouse_free_c};

show_xtick = {...
    'S1','dmPFC','M1'};

xlist = [1,2,4,5,7,8];

cap_size = 2;

line_w = 0.25;

mk_size = 2;

x_bias = 0.4;

stat_mat = zeros(5,size(show_list,1));

subplot('Position',[start_x,start_y,box_x,box_y])
% bar errorbar

legend_cell = cell(size(show_list,1),1);

for k = 1:size(show_list,1)
    %%
    selidx1 = strcmp(cebra_pose_cell(:,9),show_list{k,1});
    selidx2 = strcmp(cebra_pose_cell(:,11),show_list{k,2});

    selidx = selidx1&selidx2;

    sel_corr = cell2mat(corr_pose_neu_far_cell(selidx,:));

    stat_mat(:,k) = sel_corr(:,3);
    %% show
    mean_sel_corr = mean(sel_corr(:,3));
    std_sel_corr = std(sel_corr(:,3))./sqrt(size(sel_corr,1));
    legend_cell{k,1} = bar(xlist(k),mean_sel_corr,...
        'FaceColor',show_list{k,3},...
        'LineWidth',line_w);
    hold on
    errorbar(xlist(k),mean_sel_corr,std_sel_corr,...
        'Color','k','CapSize',cap_size,...
        'LineWidth',line_w)
    hold on
end
hold on
for k = 1:size(show_list,1)
    %%
    selidx1 = strcmp(cebra_pose_cell(:,9),show_list{k,1});
    selidx2 = strcmp(cebra_pose_cell(:,11),show_list{k,2});

    selidx = selidx1&selidx2;

    sel_corr = cell2mat(corr_pose_neu_far_cell(selidx,:));

    stat_mat(:,k) = sel_corr(:,3);
    %% show
    if rem(k,2) == 1
        selidx1 = strcmp(cebra_pose_cell(:,9),show_list{k+1,1});
        selidx2 = strcmp(cebra_pose_cell(:,11),show_list{k+1,2});
    
        selidx = selidx1&selidx2;
    
        sel_corr_2 = cell2mat(corr_pose_neu_far_cell(selidx,:));

        for m = 1:size(sel_corr,1)
            plot(x_bias+[xlist(k),xlist(k+1)],...
                [sel_corr(m,3),sel_corr_2(m,3)],...
                '-k','LineWidth',line_w)
            hold on
        end

        %% statistics
        [h_norm1,p_norm1] = lillietest(sel_corr(:,3));
        [h_norm2,p_norm2] = lillietest(sel_corr_2(:,3));
        [h_var,p_var] = vartest2(sel_corr(:,3),sel_corr_2(:,3));
        
        if (h_norm1 | h_norm2 | h_var) == 1
            [p,h] = ranksum(sel_corr(:,3),sel_corr_2(:,3));
        else
            [h,p] = ttest(sel_corr(:,3),sel_corr_2(:,3));
        end
        if h == 1
            plot([xlist(k),xlist(k+1)],[0.9,0.9],'k-',...
                'LineWidth',line_w)
            if sign_level{1,1}<=p && p<sign_level{1,2}
                show_star = sign_level{1,3};
            elseif sign_level{2,1}<=p && p<sign_level{2,2}
                show_star = sign_level{2,3};
            elseif sign_level{3,1}<=p && p<sign_level{3,2}
                show_star = sign_level{3,3};
            elseif sign_level{4,1}<=p && p<sign_level{4,2}
                show_star = sign_level{4,3};
            end
            text(...
                (xlist(k)+xlist(k+1))/2,...
                0.9,show_star,...
                'HorizontalAlignment','center',...
                'VerticalAlignment','bottom',...
                'FontName','Calibri')
        end
    end
    plot(x_bias+xlist(k)*ones(size(sel_corr(:,3))),sel_corr(:,3),...
        'o','LineWidth',line_w,...
        'MarkerEdgeColor','k',...
        'MarkerFaceColor','w',...
        'MarkerSize',mk_size)
    hold on
end
hold off

box off
set(gca,'XTick',(xlist(1:2:end)+xlist(2:2:end))/2)
set(gca,'TickDir','out')
set(gca,'XTickLabel',[])
set(gca,'XTickLabelRotation',0)
set(gca,'YTickLabel',[])
set(gca,'FontSize',6)
axis([0.3,8.7,0,1])
title('Far')
%% show the position distribution of all the cells
pos_dist_cell = cell(size(cebra_pose_cell,1),1);

var_thres = 1;
for k = 1:size(cebra_pose_cell,1)
    %%
    tempneu = cebra_pose_cell{k,13};
    var_neu_mat = ones(size(tempneu,1),1)*std(tempneu);
    thres_neu_mat = var_neu_mat*var_thres;
    
    fire_neu_idx = tempneu>thres_neu_mat;
    %% temp show
    % figure
    % for m = 1:size(tempneu,2)
    %     plot(tempneu(:,m),'b-')
    %     hold on
    %     plot(fire_neu_idx(:,m),'r-')
    %     hold off
    %     pause
    % end
    %% fire_save_list
    forward_diff_neu_idx = diff(...
        [zeros(1,size(fire_neu_idx,2));fire_neu_idx]);
    backward_diff_neu_idx = diff(...
        [fire_neu_idx;zeros(1,size(fire_neu_idx,2))]);
    
    savelist_cell = cell(size(forward_diff_neu_idx,2),1);

    for m = 1:size(savelist_cell,1)
        tempidx1 = forward_diff_neu_idx(:,m);
        tempidx2 = backward_diff_neu_idx(:,m);
        start_pos = find(tempidx1==1);
        end_pos = find(tempidx2==-1);
        savelist_cell{m,1} = [start_pos,end_pos];
    end

    %% append data
    pos_dist_cell{k,1} = savelist_cell;
end
%% show position related firing
start_x = 0.01;
start_y = 0.8;

box_x = 0.182;
box_y = box_x;

inter_x = 0.005;

show_pos_brain = {...
    'S1','dmPFC','M1'};

show_list = {...
    'tpm','free','tpmss',[-220,330,-140,410];...
    'tpm','free','tpmpfc',[-230,260,-210,230];...
    'tpm','free','tpmm',[-240,210,-320,160]...
    };

mk_size = 4;

sel_mouse_idx = 3;

for k = 1:length(show_pos_brain)
    %% load data
    tpm_selidx = strcmp(show_list{k,1},cebra_pose_cell(:,9))&...
        strcmp(show_list{k,3},cebra_pose_cell(:,11));
    free_selidx = strcmp(show_list{k,2},cebra_pose_cell(:,9))&...
        strcmp(show_list{k,3},cebra_pose_cell(:,11));

    tpm_cebra_cell = cebra_pose_cell(tpm_selidx,:);
    free_cebra_cell = cebra_pose_cell(free_selidx,:);

    tpm_pos_dist_cell = pos_dist_cell(tpm_selidx,:);
    free_pos_dist_cell = pos_dist_cell(free_selidx,:);

    tpm_dist_cell = dist_cell(tpm_selidx,:);
    free_dist_cell = dist_cell(free_selidx,:);

    tpm_corr_pose_neu_cell = ...
        corr_pose_neu_cell(tpm_selidx,:);
    free_corr_pose_neu_cell = ...
        corr_pose_neu_cell(free_selidx,:);


    tpm_pos_mat = cell(size(tpm_pos_dist_cell,1),1);
    for m = sel_mouse_idx%1%:size(tpm_pos_dist_cell,1)
        tempsavelist = cell2mat(...
            tpm_pos_dist_cell{m,1}(tpm_corr_pose_neu_cell{m,2},:));
        temppose = tpm_cebra_cell{m,12}(:,1:3);
        tempdist = tpm_dist_cell{m,2};
        selpose = temppose(tempsavelist(:,1),:);
        seldist = tempdist(tempsavelist(:,1),:);
        tpm_pos_mat{m,:} = [selpose,seldist];
    end
    tpm_pos_mat = cell2mat(tpm_pos_mat);

    free_pos_mat = cell(size(free_pos_dist_cell,1),1);
    for m = sel_mouse_idx%1%:size(free_pos_dist_cell,1)
        tempsavelist = cell2mat(...
            free_pos_dist_cell{m,1}(free_corr_pose_neu_cell{m,2},:));
        temppose = free_cebra_cell{m,12}(:,1:3);
        tempdist = free_dist_cell{m,2};
        selpose = temppose(tempsavelist(:,1),:);
        seldist = tempdist(tempsavelist(:,1),:);
        free_pos_mat{m,:} = [selpose,seldist];
    end
    free_pos_mat = cell2mat(free_pos_mat);
    %% random selection
    sel_num = 1000;
    rng(1234)
    tpm_rand_selidx = randi(size(tpm_pos_mat,1),[sel_num,1]);
    % sel_tpm_pos_mat = tpm_pos_mat(tpm_rand_selidx,:);
    sel_tpm_pos_mat = tpm_pos_mat;
    rng(1234)
    free_rand_selidx = randi(size(free_pos_mat,1),[sel_num,1]);
    % sel_free_pos_mat = free_pos_mat(free_rand_selidx,:);
    sel_free_pos_mat = free_pos_mat;

    show_data_list = [...
        sel_tpm_pos_mat(:,1:3);...
        sel_free_pos_mat(:,1:3)];

    show_clr_list = [...
        ones(size(sel_tpm_pos_mat,1),1)*mouse_tpm_c;...
        ones(size(sel_free_pos_mat,1),1)*mouse_free_c...
        ];

    overlap_idx = [...
        sel_tpm_pos_mat(:,4);...
        sel_free_pos_mat(:,4)...
        ]==1;
    show_clr_list(overlap_idx,:) = ...
        ones(sum(overlap_idx,1),1)*mouse_overlap;
    %% show
    subplot('Position',[...
        start_x+(k-1)*(box_x+inter_x),...
        start_y,box_x,box_y])

    scatter3(...
        show_data_list(:,1),...
        show_data_list(:,2),...
        show_data_list(:,3),...
        mk_size*ones(size(show_data_list,1),1),...
        show_clr_list,...
        'filled','MarkerFaceAlpha',0.5);

    view(2)
    box on
    axis(show_list{k,end})
    title(show_pos_brain{k})
    set(gca,'FontSize',6)
    set(gca,'XTick',[],'YTick',[])
end
%% show mov compare
%% show three specific correlation cases of neuron, three brain areas
max_num = cellfun(@(x) sum(x(:,2)~=0),spec_corr_mov_cell,...
    'UniformOutput',false);
select_idx_cell = {...
    1,'tpmss';...
    11,'tpmpfc';...
    5,'tpmm'};

show_ylabel = {...
    'S1','dmPFC','M1'};

show_neu_num = 5;

start_x = 0.03;
start_y = 0.73;

box_x = 0.53;
box_y = 0.06;

inter_y = 0.005;

line_w = 0.25;

mov_cmap = [1,1,1;cbrewer2('Spectral',...
    length(unique_num_mov_label))];

for k = 1:size(select_idx_cell,1)
    %% load data
    selidx = select_idx_cell{k,1};

    tempneu = cebra_mov_cell{selidx,13};
    tempneuidx = spec_corr_mov_cell{selidx,1};
    tempneuidx(tempneuidx(:,2)==0,:) = [];
    tempneuidx = tempneuidx(1:show_neu_num,:);

    templabel = cell2mat(cebra_mov_cell{selidx,12}(:,2));
    %% select data
    seltempneu = tempneu(:,tempneuidx(:,2));
    %% recreate the labels
    tempshowlabel = zeros(size(templabel));
    for m = 1:size(tempneuidx,1)
        tempshowlabel(templabel==tempneuidx(m,1),:) = ...
            find(unique_num_mov_label==tempneuidx(m,1));
    end
    %% create cmaplist
    neu_cmaplist = zeros(size(tempneuidx,1),3);
    for m = 1:size(neu_cmaplist,1)
        neu_cmaplist(m,:) = mov_cmap(...
            1+find(unique_num_mov_label==tempneuidx(m,1)),:);
    end
    %%
    temph = subplot('Position',[...
        start_x,...
        start_y-(k-1)*(box_y+inter_y),...
        box_x,box_y]);
    imagesc(tempshowlabel',[0,length(unique_num_mov_label)])
    colormap(mov_cmap)
    hold on
    plot([0,27000],[1.5,1.5],'-k','LineWidth',line_w)
    hold on
    for m = 1:size(seltempneu,2)
        tempy = mat2gray(seltempneu(:,m)');
        tempx = 1:length(tempy);
        plot(tempx,2*(m*0.7+tempy),'-','LineWidth',line_w,...
            'Color',neu_cmaplist(m,:))
        hold on
    end
    hold off
    axis([9000,27001,0.5,9])
    set(gca,'YDir','normal')
    set(gca,'FontSize',6)
    box off
    set(gca,'TickDir','out')
    set(gca,'YTick',[])
    set(gca,'XTick',1:9000:27001)
    if k == 3
        set(gca,'XTickLabel',-5:5:15)
    else
        set(gca,'XTickLabel',[])
    end
    ylabel(show_ylabel{k})
end
%% show mov all corr
start_x = 0.61;
start_y = 0.6;

box_x = 0.12;
box_y = 0.18;

setcolor = cbrewer2('Spectral',11);
mouse_tpm_c = setcolor(3,:);
mouse_free_c = setcolor(9,:);

mouse_overlap = setcolor(1,:);

show_mice_name = {'Self','Partner'};

show_list = {...
    'tpm','tpmss',mouse_tpm_c;...
    'free','tpmss',mouse_free_c;...
    'tpm','tpmpfc',mouse_tpm_c;...
    'free','tpmpfc',mouse_free_c;...
    'tpm','tpmm',mouse_tpm_c;...
    'free','tpmm',mouse_free_c};

show_xtick = {...
    'S1','dmPFC','M1'};

xlist = [1,2,4,5,7,8];

cap_size = 2;

line_w = 0.25;

mk_size = 2;

x_bias = 0.4;

stat_mat = zeros(5,size(show_list,1));

subplot('Position',[start_x,start_y,box_x,box_y])
% bar errorbar

legend_cell = cell(size(show_list,1),1);

for k = 1:size(show_list,1)
    %%
    selidx1 = strcmp(cebra_mov_cell(:,9),show_list{k,1});
    selidx2 = strcmp(cebra_mov_cell(:,11),show_list{k,2});

    selidx = selidx1&selidx2;

    sel_corr = cell2mat(corr_mov_neu_cell(selidx,1));

    stat_mat(:,k) = sel_corr(:,3);
    %% show
    mean_sel_corr = mean(sel_corr(:,3));
    std_sel_corr = std(sel_corr(:,3))./sqrt(size(sel_corr,1));
    legend_cell{k,1} = bar(xlist(k),mean_sel_corr,...
        'FaceColor',show_list{k,3},...
        'LineWidth',line_w);
    hold on
    errorbar(xlist(k),mean_sel_corr,std_sel_corr,...
        'Color','k','CapSize',cap_size,...
        'LineWidth',line_w)
    hold on
end
hold on
for k = 1:size(show_list,1)
    %%
    selidx1 = strcmp(cebra_mov_cell(:,9),show_list{k,1});
    selidx2 = strcmp(cebra_mov_cell(:,11),show_list{k,2});

    selidx = selidx1&selidx2;

    sel_corr = cell2mat(corr_mov_neu_cell(selidx,1));

    stat_mat(:,k) = sel_corr(:,3);
    %% show
    if rem(k,2) == 1
        selidx1 = strcmp(cebra_mov_cell(:,9),show_list{k+1,1});
        selidx2 = strcmp(cebra_mov_cell(:,11),show_list{k+1,2});
    
        selidx = selidx1&selidx2;
    
        sel_corr_2 = cell2mat(corr_mov_neu_cell(selidx,1));

        for m = 1:size(sel_corr,1)
            plot(x_bias+[xlist(k),xlist(k+1)],...
                [sel_corr(m,3),sel_corr_2(m,3)],...
                '-k','LineWidth',line_w)
            hold on
        end

        %% statistics
        [h_norm1,p_norm1] = lillietest(sel_corr(:,3));
        [h_norm2,p_norm2] = lillietest(sel_corr_2(:,3));
        [h_var,p_var] = vartest2(sel_corr(:,3),sel_corr_2(:,3));
        
        if (h_norm1 | h_norm2 | h_var) == 1
            [p,h] = ranksum(sel_corr(:,3),sel_corr_2(:,3));
        else
            [h,p] = ttest(sel_corr(:,3),sel_corr_2(:,3));
        end
        if h == 1
            plot([xlist(k),xlist(k+1)],[0.9,0.9],'k-',...
                'LineWidth',line_w)
            if sign_level{1,1}<=p && p<sign_level{1,2}
                show_star = sign_level{1,3};
            elseif sign_level{2,1}<=p && p<sign_level{2,2}
                show_star = sign_level{2,3};
            elseif sign_level{3,1}<=p && p<sign_level{3,2}
                show_star = sign_level{3,3};
            elseif sign_level{4,1}<=p && p<sign_level{4,2}
                show_star = sign_level{4,3};
            end
            text(...
                (xlist(k)+xlist(k+1))/2,...
                0.9,show_star,...
                'HorizontalAlignment','center',...
                'VerticalAlignment','bottom',...
                'FontName','Calibri')
        end
    end
    plot(x_bias+xlist(k)*ones(size(sel_corr(:,3))),sel_corr(:,3),...
        'o','LineWidth',line_w,...
        'MarkerEdgeColor','k',...
        'MarkerFaceColor','w',...
        'MarkerSize',mk_size)
    hold on

    
end
hold off

box off
set(gca,'XTick',(xlist(1:2:end)+xlist(2:2:end))/2)
set(gca,'TickDir','out')
set(gca,'XTickLabel',[])
set(gca,'XTickLabelRotation',0)
ylabel('Neural movement correlation ratio')
set(gca,'FontSize',6)
% legend([legend_cell{1},legend_cell{2}],show_mice_name,...
%     'Box','off','Location','northwest')
axis([0.3,8.7,0,1])
% title('All')
%% find correlations between movement and neurons, close
corr_thres = 0.2;
corr_mov_neu_close_cell = cell(size(cebra_mov_cell,1),2);
for k = 1:size(cebra_mov_cell,1)
    %% load data
    tempidx = cell2mat(cebra_mov_cell{k,12}(:,2));
    tempneu = cebra_mov_cell{k,13};

    tempidx = tempidx(dist_mov_cell{k,2}==1,:);
    tempneu = tempneu(dist_mov_cell{k,2}==1,:);
    
    %% create fire idx mat
    % figure
    tempfire = zeros(size(tempneu));
    for m = 1:size(tempfire,2)
        %%
        ttneu = tempneu(:,m);
        tempthres = 0.5;%std(ttneu);
        duration_thres = 30;%frames
        ttfire = ttneu>tempthres;
        firesavelist = idx2savelist(ttfire);
        firesavelist(firesavelist(:,3)==0,:) = [];
        tt_duration = firesavelist(:,2)-firesavelist(:,1);
        firesavelist(tt_duration<duration_thres,:) = [];
        for n = 1:size(firesavelist,1)
            tempfire(...
                firesavelist(n,1):firesavelist(n,2),m) = 1;
        end
        % plot(ttneu,'-b')
        % hold on
        % plot(tempfire(:,m),'-r')
        % hold off
        % pause
    end
    %% calculate correlations
    % create bw_label
    bw_label = zeros(size(tempidx,1),size(unique_num_mov_label,1));
    for m = 1:size(bw_label,2)
        templabel = unique_num_mov_label(m,1);
        bw_label(:,m) = templabel==tempidx;
    end

    % calculate correlation
    [r,p] = corr(bw_label,tempfire);

    %% select significant neurons
    selidx = ((p<0.05) .* (abs(r)>corr_thres))==1;
    selr = r(selidx);

    selidx_neu = sum(selidx)>0;
    %% append data
    corr_mov_neu_close_cell{k,1} = [...
        sum(selidx_neu),size(r,2),...
        sum(selidx_neu)/size(r,2)];
    corr_mov_neu_close_cell{k,2} = selidx_neu;
end
%% find correlations between movement and neurons, far
corr_thres = 0.2;
corr_mov_neu_far_cell = cell(size(cebra_mov_cell,1),2);
for k = 1:size(cebra_mov_cell,1)
    %% load data
    tempidx = cell2mat(cebra_mov_cell{k,12}(:,2));
    tempneu = cebra_mov_cell{k,13};

    tempidx = tempidx(dist_mov_cell{k,2}==0,:);
    tempneu = tempneu(dist_mov_cell{k,2}==0,:);
    
    %% create fire idx mat
    % figure
    tempfire = zeros(size(tempneu));
    for m = 1:size(tempfire,2)
        %%
        ttneu = tempneu(:,m);
        tempthres = 0.5;%std(ttneu);
        duration_thres = 30;%frames
        ttfire = ttneu>tempthres;
        firesavelist = idx2savelist(ttfire);
        firesavelist(firesavelist(:,3)==0,:) = [];
        tt_duration = firesavelist(:,2)-firesavelist(:,1);
        firesavelist(tt_duration<duration_thres,:) = [];
        for n = 1:size(firesavelist,1)
            tempfire(...
                firesavelist(n,1):firesavelist(n,2),m) = 1;
        end
        % plot(ttneu,'-b')
        % hold on
        % plot(tempfire(:,m),'-r')
        % hold off
        % pause
    end
    %% calculate correlations
    % create bw_label
    bw_label = zeros(size(tempidx,1),size(unique_num_mov_label,1));
    for m = 1:size(bw_label,2)
        templabel = unique_num_mov_label(m,1);
        bw_label(:,m) = templabel==tempidx;
    end

    % calculate correlation
    [r,p] = corr(bw_label,tempfire);

    %% select significant neurons
    selidx = ((p<0.05) .* (abs(r)>corr_thres))==1;
    selr = r(selidx);

    selidx_neu = sum(selidx)>0;
    %% append data
    corr_mov_neu_far_cell{k,1} = [...
        sum(selidx_neu),size(r,2),...
        sum(selidx_neu)/size(r,2)];
    corr_mov_neu_far_cell{k,2} = selidx_neu;
end
%% show the close correlations across each brain area and individual
start_x = 0.74;
start_y = 0.6;

box_x = 0.12;
box_y = 0.18;

setcolor = cbrewer2('Spectral',11);
mouse_tpm_c = setcolor(3,:);
mouse_free_c = setcolor(9,:);

show_mice_name = {'Self','Partner'};

show_list = {...
    'tpm','tpmss',mouse_tpm_c;...
    'free','tpmss',mouse_free_c;...
    'tpm','tpmpfc',mouse_tpm_c;...
    'free','tpmpfc',mouse_free_c;...
    'tpm','tpmm',mouse_tpm_c;...
    'free','tpmm',mouse_free_c};

show_xtick = {...
    'S1','dmPFC','M1'};

xlist = [1,2,4,5,7,8];

cap_size = 2;

line_w = 0.25;

mk_size = 2;

x_bias = 0.4;

stat_mat = zeros(5,size(show_list,1));

subplot('Position',[start_x,start_y,box_x,box_y])
% bar errorbar

legend_cell = cell(size(show_list,1),1);

for k = 1:size(show_list,1)
    %%
    selidx1 = strcmp(cebra_mov_cell(:,9),show_list{k,1});
    selidx2 = strcmp(cebra_mov_cell(:,11),show_list{k,2});

    selidx = selidx1&selidx2;

    sel_corr = cell2mat(corr_mov_neu_close_cell(selidx,1));

    stat_mat(:,k) = sel_corr(:,3);
    %% show
    mean_sel_corr = mean(sel_corr(:,3));
    std_sel_corr = std(sel_corr(:,3))./sqrt(size(sel_corr,1));
    legend_cell{k,1} = bar(xlist(k),mean_sel_corr,...
        'FaceColor',show_list{k,3},...
        'LineWidth',line_w);
    hold on
    errorbar(xlist(k),mean_sel_corr,std_sel_corr,...
        'Color','k','CapSize',cap_size,...
        'LineWidth',line_w)
    hold on
end
hold on
for k = 1:size(show_list,1)
    %%
    selidx1 = strcmp(cebra_mov_cell(:,9),show_list{k,1});
    selidx2 = strcmp(cebra_mov_cell(:,11),show_list{k,2});

    selidx = selidx1&selidx2;

    sel_corr = cell2mat(corr_mov_neu_close_cell(selidx,1));

    stat_mat(:,k) = sel_corr(:,3);
    %% show
    if rem(k,2) == 1
        selidx1 = strcmp(cebra_mov_cell(:,9),show_list{k+1,1});
        selidx2 = strcmp(cebra_mov_cell(:,11),show_list{k+1,2});
    
        selidx = selidx1&selidx2;
    
        sel_corr_2 = cell2mat(corr_mov_neu_close_cell(selidx,1));

        for m = 1:size(sel_corr,1)
            plot(x_bias+[xlist(k),xlist(k+1)],...
                [sel_corr(m,3),sel_corr_2(m,3)],...
                '-k','LineWidth',line_w)
            hold on
        end
        %% statistics
        [h_norm1,p_norm1] = lillietest(sel_corr(:,3));
        [h_norm2,p_norm2] = lillietest(sel_corr_2(:,3));
        [h_var,p_var] = vartest2(sel_corr(:,3),sel_corr_2(:,3));
        
        if (h_norm1 | h_norm2 | h_var) == 1
            [p,h] = ranksum(sel_corr(:,3),sel_corr_2(:,3));
        else
            [h,p] = ttest(sel_corr(:,3),sel_corr_2(:,3));
        end
        if h == 1
            plot([xlist(k),xlist(k+1)],[0.9,0.9],'k-',...
                'LineWidth',line_w)
            if sign_level{1,1}<=p && p<sign_level{1,2}
                show_star = sign_level{1,3};
            elseif sign_level{2,1}<=p && p<sign_level{2,2}
                show_star = sign_level{2,3};
            elseif sign_level{3,1}<=p && p<sign_level{3,2}
                show_star = sign_level{3,3};
            elseif sign_level{4,1}<=p && p<sign_level{4,2}
                show_star = sign_level{4,3};
            end
            text(...
                (xlist(k)+xlist(k+1))/2,...
                0.9,show_star,...
                'HorizontalAlignment','center',...
                'VerticalAlignment','bottom',...
                'FontName','Calibri')
        end
    end
    plot(x_bias+xlist(k)*ones(size(sel_corr(:,3))),sel_corr(:,3),...
        'o','LineWidth',line_w,...
        'MarkerEdgeColor','k',...
        'MarkerFaceColor','w',...
        'MarkerSize',mk_size)
    hold on
end
hold off

box off
set(gca,'XTick',(xlist(1:2:end)+xlist(2:2:end))/2)
set(gca,'TickDir','out')
set(gca,'XTickLabel',[])
set(gca,'XTickLabelRotation',0)
set(gca,'YTickLabel',[])
set(gca,'FontSize',6)
axis([0.3,8.7,0,1])
% title('Close')
%% show the far correlations across each brain area and individual
start_x = 0.87;
start_y = 0.6;

box_x = 0.12;
box_y = 0.18;

setcolor = cbrewer2('Spectral',11);
mouse_tpm_c = setcolor(3,:);
mouse_free_c = setcolor(9,:);

show_mice_name = {'Self','Partner'};

show_list = {...
    'tpm','tpmss',mouse_tpm_c;...
    'free','tpmss',mouse_free_c;...
    'tpm','tpmpfc',mouse_tpm_c;...
    'free','tpmpfc',mouse_free_c;...
    'tpm','tpmm',mouse_tpm_c;...
    'free','tpmm',mouse_free_c};

show_xtick = {...
    'S1','dmPFC','M1'};

xlist = [1,2,4,5,7,8];

cap_size = 2;

line_w = 0.25;

mk_size = 2;

x_bias = 0.4;

stat_mat = zeros(5,size(show_list,1));

subplot('Position',[start_x,start_y,box_x,box_y])
% bar errorbar

legend_cell = cell(size(show_list,1),1);

for k = 1:size(show_list,1)
    %%
    selidx1 = strcmp(cebra_mov_cell(:,9),show_list{k,1});
    selidx2 = strcmp(cebra_mov_cell(:,11),show_list{k,2});

    selidx = selidx1&selidx2;

    sel_corr = cell2mat(corr_mov_neu_far_cell(selidx,1));

    stat_mat(:,k) = sel_corr(:,3);
    %% show
    mean_sel_corr = mean(sel_corr(:,3));
    std_sel_corr = std(sel_corr(:,3))./sqrt(size(sel_corr,1));
    legend_cell{k,1} = bar(xlist(k),mean_sel_corr,...
        'FaceColor',show_list{k,3},...
        'LineWidth',line_w);
    hold on
    errorbar(xlist(k),mean_sel_corr,std_sel_corr,...
        'Color','k','CapSize',cap_size,...
        'LineWidth',line_w)
    hold on
    
end
hold on
for k = 1:size(show_list,1)
    %%
    selidx1 = strcmp(cebra_mov_cell(:,9),show_list{k,1});
    selidx2 = strcmp(cebra_mov_cell(:,11),show_list{k,2});

    selidx = selidx1&selidx2;

    sel_corr = cell2mat(corr_mov_neu_far_cell(selidx,1));

    stat_mat(:,k) = sel_corr(:,3);
    %% show
    if rem(k,2) == 1
        selidx1 = strcmp(cebra_mov_cell(:,9),show_list{k+1,1});
        selidx2 = strcmp(cebra_mov_cell(:,11),show_list{k+1,2});
    
        selidx = selidx1&selidx2;
    
        sel_corr_2 = cell2mat(corr_mov_neu_far_cell(selidx,1));

        for m = 1:size(sel_corr,1)
            plot(x_bias+[xlist(k),xlist(k+1)],...
                [sel_corr(m,3),sel_corr_2(m,3)],...
                '-k','LineWidth',line_w)
            hold on
        end

        %% statistics
        [h_norm1,p_norm1] = lillietest(sel_corr(:,3));
        [h_norm2,p_norm2] = lillietest(sel_corr_2(:,3));
        [h_var,p_var] = vartest2(sel_corr(:,3),sel_corr_2(:,3));
        
        if (h_norm1 | h_norm2 | h_var) == 1
            [p,h] = ranksum(sel_corr(:,3),sel_corr_2(:,3));
        else
            [h,p] = ttest(sel_corr(:,3),sel_corr_2(:,3));
        end
        if h == 1
            plot([xlist(k),xlist(k+1)],[0.9,0.9],'k-',...
                'LineWidth',line_w)
            if sign_level{1,1}<=p && p<sign_level{1,2}
                show_star = sign_level{1,3};
            elseif sign_level{2,1}<=p && p<sign_level{2,2}
                show_star = sign_level{2,3};
            elseif sign_level{3,1}<=p && p<sign_level{3,2}
                show_star = sign_level{3,3};
            elseif sign_level{4,1}<=p && p<sign_level{4,2}
                show_star = sign_level{4,3};
            end
            text(...
                (xlist(k)+xlist(k+1))/2,...
                0.9,show_star,...
                'HorizontalAlignment','center',...
                'VerticalAlignment','bottom',...
                'FontName','Calibri')
        end
    end
    plot(x_bias+xlist(k)*ones(size(sel_corr(:,3))),sel_corr(:,3),...
        'o','LineWidth',line_w,...
        'MarkerEdgeColor','k',...
        'MarkerFaceColor','w',...
        'MarkerSize',mk_size)
    hold on
    
end
hold off

box off
set(gca,'XTick',(xlist(1:2:end)+xlist(2:2:end))/2)
set(gca,'TickDir','out')
set(gca,'XTickLabel',[])
set(gca,'XTickLabelRotation',0)
set(gca,'YTickLabel',[])
set(gca,'FontSize',6)
axis([0.3,8.7,0,1])
% title('Far')
%% show seq
%% show three specific correlation cases of neuron, three brain areas
max_num = cellfun(@(x) sum(x(:,2)~=0),spec_corr_seq_cell,...
    'UniformOutput',false);
select_idx_cell = {...
    7,'tpmss';...
    15,'tpmpfc';...
    21,'tpmm'};

show_ylabel = {...
    'S1','dmPFC','M1'};

show_neu_num = 3;

start_x = 0.03;
start_y = 0.53;

box_x = 0.53;
box_y = 0.06;

inter_y = 0.005;

line_w = 0.25;

seq_cmap = [1,1,1;cbrewer2('Spectral',...
    length(unique_num_seq_label))];

for k = 1:size(select_idx_cell,1)
    %% load data
    selidx = select_idx_cell{k,1};

    tempneu = cebra_seq_cell{selidx,13};
    tempneuidx = spec_corr_seq_cell{selidx,1};
    tempneuidx(tempneuidx(:,2)==0,:) = [];
    tempneuidx = tempneuidx(1:show_neu_num,:);

    templabel = cebra_seq_cell{selidx,12};
    %% select data
    seltempneu = tempneu(:,tempneuidx(:,2));
    %% recreate the labels
    tempshowlabel = zeros(size(templabel));
    for m = 1:size(tempneuidx,1)
        tempshowlabel(templabel==tempneuidx(m,1),:) = ...
            find(unique_num_seq_label==tempneuidx(m,1));
    end
    %% create cmaplist
    neu_cmaplist = zeros(size(tempneuidx,1),3);
    for m = 1:size(neu_cmaplist,1)
        neu_cmaplist(m,:) = seq_cmap(...
            1+find(unique_num_seq_label==tempneuidx(m,1)),:);
    end
    %%
    temph = subplot('Position',[...
        start_x,...
        start_y-(k-1)*(box_y+inter_y),...
        box_x,box_y]);
    imagesc(tempshowlabel',[0,length(unique_num_seq_label)])
    colormap(seq_cmap)
    hold on
    plot([0,27000],[1.5,1.5],'-k','LineWidth',line_w)
    hold on
    for m = 1:size(seltempneu,2)
        tempy = mat2gray(seltempneu(:,m)');
        tempx = 1:length(tempy);
        plot(tempx,2*(m*0.7+tempy),'-','LineWidth',line_w,...
            'Color',neu_cmaplist(m,:))
        hold on
    end
    hold off
    axis([9000,27001,0.5,6])
    set(gca,'YDir','normal')
    set(gca,'FontSize',6)
    box off
    set(gca,'TickDir','out')
    set(gca,'YTick',[])
    set(gca,'XTick',1:9000:27001)
    if k == 3
        set(gca,'XTickLabel',-5:5:15)
    else
        set(gca,'XTickLabel',[])
    end
    ylabel(show_ylabel{k})
end
%% show the correlations across each brain area and individual
start_x = 0.61;
start_y = 0.4;

box_x = 0.12;
box_y = 0.18;

setcolor = cbrewer2('Spectral',11);
mouse_tpm_c = setcolor(3,:);
mouse_free_c = setcolor(9,:);

mouse_overlap = setcolor(1,:);

show_mice_name = {'Self','Partner'};

show_list = {...
    'tpm','tpmss',mouse_tpm_c;...
    'free','tpmss',mouse_free_c;...
    'tpm','tpmpfc',mouse_tpm_c;...
    'free','tpmpfc',mouse_free_c;...
    'tpm','tpmm',mouse_tpm_c;...
    'free','tpmm',mouse_free_c};

show_xtick = {...
    'S1','dmPFC','M1'};

xlist = [1,2,4,5,7,8];

cap_size = 2;

line_w = 0.25;

mk_size = 2;

x_bias = 0.4;

stat_mat = zeros(5,size(show_list,1));

subplot('Position',[start_x,start_y,box_x,box_y])
% bar errorbar

legend_cell = cell(size(show_list,1),1);

for k = 1:size(show_list,1)
    %%
    selidx1 = strcmp(cebra_seq_cell(:,9),show_list{k,1});
    selidx2 = strcmp(cebra_seq_cell(:,11),show_list{k,2});

    selidx = selidx1&selidx2;

    sel_corr = cell2mat(corr_mean_seq_neu_cell(selidx,1));

    stat_mat(:,k) = sel_corr(:,3);
    %% show
    mean_sel_corr = mean(sel_corr(:,3));
    std_sel_corr = std(sel_corr(:,3))./sqrt(size(sel_corr,1));
    legend_cell{k,1} = bar(xlist(k),mean_sel_corr,...
        'FaceColor',show_list{k,3},...
        'LineWidth',line_w);
    hold on
    errorbar(xlist(k),mean_sel_corr,std_sel_corr,...
        'Color','k','CapSize',cap_size,...
        'LineWidth',line_w)
    hold on
end
hold on
for k = 1:size(show_list,1)
    %%
    selidx1 = strcmp(cebra_seq_cell(:,9),show_list{k,1});
    selidx2 = strcmp(cebra_seq_cell(:,11),show_list{k,2});

    selidx = selidx1&selidx2;

    sel_corr = cell2mat(corr_mean_seq_neu_cell(selidx,1));

    stat_mat(:,k) = sel_corr(:,3);
    %% show
    if rem(k,2) == 1
        selidx1 = strcmp(cebra_seq_cell(:,9),show_list{k+1,1});
        selidx2 = strcmp(cebra_seq_cell(:,11),show_list{k+1,2});
    
        selidx = selidx1&selidx2;
    
        sel_corr_2 = cell2mat(corr_mean_seq_neu_cell(selidx,1));

        for m = 1:size(sel_corr,1)
            plot(x_bias+[xlist(k),xlist(k+1)],...
                [sel_corr(m,3),sel_corr_2(m,3)],...
                '-k','LineWidth',line_w)
            hold on
        end
        %% statistics
        [h_norm1,p_norm1] = lillietest(sel_corr(:,3));
        [h_norm2,p_norm2] = lillietest(sel_corr_2(:,3));
        [h_var,p_var] = vartest2(sel_corr(:,3),sel_corr_2(:,3));
        
        if (h_norm1 | h_norm2 | h_var) == 1
            [p,h] = ranksum(sel_corr(:,3),sel_corr_2(:,3));
        else
            [h,p] = ttest(sel_corr(:,3),sel_corr_2(:,3));
        end
        if h == 1
            plot([xlist(k),xlist(k+1)],[0.9,0.9],'k-',...
                'LineWidth',line_w)
            if sign_level{1,1}<=p && p<sign_level{1,2}
                show_star = sign_level{1,3};
            elseif sign_level{2,1}<=p && p<sign_level{2,2}
                show_star = sign_level{2,3};
            elseif sign_level{3,1}<=p && p<sign_level{3,2}
                show_star = sign_level{3,3};
            elseif sign_level{4,1}<=p && p<sign_level{4,2}
                show_star = sign_level{4,3};
            end
            text(...
                (xlist(k)+xlist(k+1))/2,...
                0.9,show_star,...
                'HorizontalAlignment','center',...
                'VerticalAlignment','bottom',...
                'FontName','Calibri')
        end
    end
    plot(x_bias+xlist(k)*ones(size(sel_corr(:,3))),sel_corr(:,3),...
        'o','LineWidth',line_w,...
        'MarkerEdgeColor','k',...
        'MarkerFaceColor','w',...
        'MarkerSize',mk_size)
    hold on
    
end
hold off

box off
set(gca,'XTick',(xlist(1:2:end)+xlist(2:2:end))/2)
set(gca,'TickDir','out')
set(gca,'XTickLabel',show_xtick)
set(gca,'XTickLabelRotation',0)
ylabel('Neural sequence correlation ratio')
set(gca,'FontSize',6)
% legend([legend_cell{1},legend_cell{2}],show_mice_name,...
%     'Box','off','Location','northwest')
axis([0.3,8.7,0,1])
% title('All')
%% find correlations between sequence and neurons, close
corr_thres = 0.2;
corr_mean_seq_neu_close_cell = cell(size(cebra_seq_cell,1),2);
corr_nomean_seq_neu_close_cell = cell(size(cebra_seq_cell,1),2);
for k = 1:size(cebra_seq_cell,1)
    %% load data
    tempidx = cebra_seq_cell{k,12}(:,1);
    tempneu = cebra_seq_cell{k,13};

    tempidx = tempidx(dist_seq_cell{k,2}==1,:);
    tempneu = tempneu(dist_seq_cell{k,2}==1,:);
    %% create fire idx mat
    % figure
    tempfire = zeros(size(tempneu));
    for m = 1:size(tempfire,2)
        %%
        ttneu = tempneu(:,m);
        tempthres = 0.5;%std(ttneu);
        duration_thres = 30;%frames
        ttfire = ttneu>tempthres;
        firesavelist = idx2savelist(ttfire);
        firesavelist(firesavelist(:,3)==0,:) = [];
        tt_duration = firesavelist(:,2)-firesavelist(:,1);
        firesavelist(tt_duration<duration_thres,:) = [];
        for n = 1:size(firesavelist,1)
            tempfire(...
                firesavelist(n,1):firesavelist(n,2),m) = 1;
        end
        % plot(ttneu,'-b')
        % hold on
        % plot(tempfire(:,m),'-r')
        % hold off
        % pause
    end
    %% calculate correlations
    % create bw_label
    bw_label = zeros(size(tempidx,1),size(unique_num_seq_label,1));
    for m = 1:size(bw_label,2)
        templabel = unique_num_seq_label(m,1);
        bw_label(:,m) = templabel==tempidx;
    end

    % calculate correlation
    [r,p] = corr(bw_label,tempfire);
    
    mean_r = r(2:end,:);
    mean_p = p(2:end,:);
    nomean_r = r(1,:);
    nomean_p = p(1,:);
    %% select significant neurons, mean
    mean_selidx = ((mean_p<0.05) .* (abs(mean_r)>corr_thres))==1;
    mean_selr = mean_r(mean_selidx);

    mean_selidx_neu = sum(mean_selidx)>0;
    %% append data
    corr_mean_seq_neu_close_cell{k,1} = [...
        sum(mean_selidx_neu),size(r,2),...
        sum(mean_selidx_neu)/size(r,2)];
    corr_mean_seq_neu_close_cell{k,2} = mean_selidx_neu;

    %% select significant neurons, no mean
    nomean_selidx = ((nomean_p<0.05) .* (abs(nomean_r)>corr_thres))==1;
    nomean_selr = nomean_r(nomean_selidx);

    nomean_selidx_neu = nomean_selidx>0;
    %% append data
    corr_nomean_seq_neu_close_cell{k,1} = [...
        sum(nomean_selidx_neu),size(r,2),...
        sum(nomean_selidx_neu)/size(r,2)];
    corr_nomean_seq_neu_close_cell{k,2} = nomean_selidx_neu;
end
%% find correlations between movement and neurons, far
corr_thres = 0.2;
corr_mean_seq_neu_far_cell = cell(size(cebra_seq_cell,1),2);
corr_nomean_seq_neu_far_cell = cell(size(cebra_seq_cell,1),2);
for k = 1:size(cebra_seq_cell,1)
    %% load data
    tempidx = cebra_seq_cell{k,12}(:,1);
    tempneu = cebra_seq_cell{k,13};

    tempidx = tempidx(dist_seq_cell{k,2}==0,:);
    tempneu = tempneu(dist_seq_cell{k,2}==0,:);
    %% create fire idx mat
    % figure
    tempfire = zeros(size(tempneu));
    for m = 1:size(tempfire,2)
        %%
        ttneu = tempneu(:,m);
        tempthres = 0.5;%std(ttneu);
        duration_thres = 30;%frames
        ttfire = ttneu>tempthres;
        firesavelist = idx2savelist(ttfire);
        firesavelist(firesavelist(:,3)==0,:) = [];
        tt_duration = firesavelist(:,2)-firesavelist(:,1);
        firesavelist(tt_duration<duration_thres,:) = [];
        for n = 1:size(firesavelist,1)
            tempfire(...
                firesavelist(n,1):firesavelist(n,2),m) = 1;
        end
        % plot(ttneu,'-b')
        % hold on
        % plot(tempfire(:,m),'-r')
        % hold off
        % pause
    end
    %% calculate correlations
    % create bw_label
    bw_label = zeros(size(tempidx,1),size(unique_num_seq_label,1));
    for m = 1:size(bw_label,2)
        templabel = unique_num_seq_label(m,1);
        bw_label(:,m) = templabel==tempidx;
    end

    % calculate correlation
    [r,p] = corr(bw_label,tempfire);
    
    mean_r = r(2:end,:);
    mean_p = p(2:end,:);
    nomean_r = r(1,:);
    nomean_p = p(1,:);
    %% select significant neurons, mean
    mean_selidx = ((mean_p<0.05) .* (abs(mean_r)>corr_thres))==1;
    mean_selr = mean_r(mean_selidx);

    mean_selidx_neu = sum(mean_selidx)>0;
    %% append data
    corr_mean_seq_neu_far_cell{k,1} = [...
        sum(mean_selidx_neu),size(r,2),...
        sum(mean_selidx_neu)/size(r,2)];
    corr_mean_seq_neu_far_cell{k,2} = mean_selidx_neu;

    %% select significant neurons, no mean
    nomean_selidx = ((nomean_p<0.05) .* (abs(nomean_r)>corr_thres))==1;
    nomean_selr = nomean_r(nomean_selidx);

    nomean_selidx_neu = nomean_selidx>0;
    %% append data
    corr_nomean_seq_neu_far_cell{k,1} = [...
        sum(nomean_selidx_neu),size(r,2),...
        sum(nomean_selidx_neu)/size(r,2)];
    corr_nomean_seq_neu_far_cell{k,2} = nomean_selidx_neu;
end
%% show the close correlations across each brain area and individual
start_x = 0.74;
start_y = 0.4;

box_x = 0.12;
box_y = 0.18;

setcolor = cbrewer2('Spectral',11);
mouse_tpm_c = setcolor(3,:);
mouse_free_c = setcolor(9,:);

show_mice_name = {'Self','Partner'};

show_list = {...
    'tpm','tpmss',mouse_tpm_c;...
    'free','tpmss',mouse_free_c;...
    'tpm','tpmpfc',mouse_tpm_c;...
    'free','tpmpfc',mouse_free_c;...
    'tpm','tpmm',mouse_tpm_c;...
    'free','tpmm',mouse_free_c};

show_xtick = {...
    'S1','dmPFC','M1'};

xlist = [1,2,4,5,7,8];

cap_size = 2;

line_w = 0.25;

mk_size = 2;

x_bias = 0.4;

stat_mat = zeros(5,size(show_list,1));

subplot('Position',[start_x,start_y,box_x,box_y])
% bar errorbar

legend_cell = cell(size(show_list,1),1);

for k = 1:size(show_list,1)
    %%
    selidx1 = strcmp(cebra_seq_cell(:,9),show_list{k,1});
    selidx2 = strcmp(cebra_seq_cell(:,11),show_list{k,2});

    selidx = selidx1&selidx2;

    sel_corr = cell2mat(corr_mean_seq_neu_close_cell(selidx,1));

    stat_mat(:,k) = sel_corr(:,3);
    %% show
    mean_sel_corr = mean(sel_corr(:,3));
    std_sel_corr = std(sel_corr(:,3))./sqrt(size(sel_corr,1));
    legend_cell{k,1} = bar(xlist(k),mean_sel_corr,...
        'FaceColor',show_list{k,3},...
        'LineWidth',line_w);
    hold on
    errorbar(xlist(k),mean_sel_corr,std_sel_corr,...
        'Color','k','CapSize',cap_size,...
        'LineWidth',line_w)
    hold on
end
hold on
for k = 1:size(show_list,1)
    %%
    selidx1 = strcmp(cebra_seq_cell(:,9),show_list{k,1});
    selidx2 = strcmp(cebra_seq_cell(:,11),show_list{k,2});

    selidx = selidx1&selidx2;

    sel_corr = cell2mat(corr_mean_seq_neu_close_cell(selidx,1));

    stat_mat(:,k) = sel_corr(:,3);
    %% show
    if rem(k,2) == 1
        selidx1 = strcmp(cebra_seq_cell(:,9),show_list{k+1,1});
        selidx2 = strcmp(cebra_seq_cell(:,11),show_list{k+1,2});
    
        selidx = selidx1&selidx2;
    
        sel_corr_2 = cell2mat(corr_mean_seq_neu_close_cell(selidx,1));

        for m = 1:size(sel_corr,1)
            plot(x_bias+[xlist(k),xlist(k+1)],...
                [sel_corr(m,3),sel_corr_2(m,3)],...
                '-k','LineWidth',line_w)
            hold on
        end
        %% statistics
        [h_norm1,p_norm1] = lillietest(sel_corr(:,3));
        [h_norm2,p_norm2] = lillietest(sel_corr_2(:,3));
        [h_var,p_var] = vartest2(sel_corr(:,3),sel_corr_2(:,3));
        
        if (h_norm1 | h_norm2 | h_var) == 1
            [p,h] = ranksum(sel_corr(:,3),sel_corr_2(:,3));
        else
            [h,p] = ttest(sel_corr(:,3),sel_corr_2(:,3));
        end
        if h == 1
            plot([xlist(k),xlist(k+1)],[0.9,0.9],'k-',...
                'LineWidth',line_w)
            if sign_level{1,1}<=p && p<sign_level{1,2}
                show_star = sign_level{1,3};
            elseif sign_level{2,1}<=p && p<sign_level{2,2}
                show_star = sign_level{2,3};
            elseif sign_level{3,1}<=p && p<sign_level{3,2}
                show_star = sign_level{3,3};
            elseif sign_level{4,1}<=p && p<sign_level{4,2}
                show_star = sign_level{4,3};
            end
            text(...
                (xlist(k)+xlist(k+1))/2,...
                0.9,show_star,...
                'HorizontalAlignment','center',...
                'VerticalAlignment','bottom',...
                'FontName','Calibri')
        end
    end
    plot(x_bias+xlist(k)*ones(size(sel_corr(:,3))),sel_corr(:,3),...
        'o','LineWidth',line_w,...
        'MarkerEdgeColor','k',...
        'MarkerFaceColor','w',...
        'MarkerSize',mk_size)
    hold on
end
hold off

box off
set(gca,'XTick',(xlist(1:2:end)+xlist(2:2:end))/2)
set(gca,'TickDir','out')
set(gca,'XTickLabel',show_xtick)
set(gca,'XTickLabelRotation',0)
set(gca,'YTickLabel',[])
set(gca,'FontSize',6)
axis([0.3,8.7,0,1])
% title('Close')
%% show the far correlations across each brain area and individual
start_x = 0.87;
start_y = 0.4;

box_x = 0.12;
box_y = 0.18;

setcolor = cbrewer2('Spectral',11);
mouse_tpm_c = setcolor(3,:);
mouse_free_c = setcolor(9,:);

show_mice_name = {'Self','Partner'};

show_list = {...
    'tpm','tpmss',mouse_tpm_c;...
    'free','tpmss',mouse_free_c;...
    'tpm','tpmpfc',mouse_tpm_c;...
    'free','tpmpfc',mouse_free_c;...
    'tpm','tpmm',mouse_tpm_c;...
    'free','tpmm',mouse_free_c};

show_xtick = {...
    'S1','dmPFC','M1'};

xlist = [1,2,4,5,7,8];

cap_size = 2;

line_w = 0.25;

mk_size = 2;

x_bias = 0.4;

stat_mat = zeros(5,size(show_list,1));

subplot('Position',[start_x,start_y,box_x,box_y])
% bar errorbar

legend_cell = cell(size(show_list,1),1);

for k = 1:size(show_list,1)
    %%
    selidx1 = strcmp(cebra_seq_cell(:,9),show_list{k,1});
    selidx2 = strcmp(cebra_seq_cell(:,11),show_list{k,2});

    selidx = selidx1&selidx2;

    sel_corr = cell2mat(corr_mean_seq_neu_far_cell(selidx,1));

    stat_mat(:,k) = sel_corr(:,3);
    %% show
    mean_sel_corr = mean(sel_corr(:,3));
    std_sel_corr = std(sel_corr(:,3))./sqrt(size(sel_corr,1));
    legend_cell{k,1} = bar(xlist(k),mean_sel_corr,...
        'FaceColor',show_list{k,3},...
        'LineWidth',line_w);
    hold on
    errorbar(xlist(k),mean_sel_corr,std_sel_corr,...
        'Color','k','CapSize',cap_size,...
        'LineWidth',line_w)
    hold on
end
hold on
for k = 1:size(show_list,1)
    %%
    selidx1 = strcmp(cebra_seq_cell(:,9),show_list{k,1});
    selidx2 = strcmp(cebra_seq_cell(:,11),show_list{k,2});

    selidx = selidx1&selidx2;

    sel_corr = cell2mat(corr_mean_seq_neu_far_cell(selidx,1));

    stat_mat(:,k) = sel_corr(:,3);
    %% show
    if rem(k,2) == 1
        selidx1 = strcmp(cebra_seq_cell(:,9),show_list{k+1,1});
        selidx2 = strcmp(cebra_seq_cell(:,11),show_list{k+1,2});
    
        selidx = selidx1&selidx2;
    
        sel_corr_2 = cell2mat(corr_mean_seq_neu_far_cell(selidx,1));

        for m = 1:size(sel_corr,1)
            plot(x_bias+[xlist(k),xlist(k+1)],...
                [sel_corr(m,3),sel_corr_2(m,3)],...
                '-k','LineWidth',line_w)
            hold on
        end
        %% statistics
        [h_norm1,p_norm1] = lillietest(sel_corr(:,3));
        [h_norm2,p_norm2] = lillietest(sel_corr_2(:,3));
        [h_var,p_var] = vartest2(sel_corr(:,3),sel_corr_2(:,3));
        
        if (h_norm1 | h_norm2 | h_var) == 1
            [p,h] = ranksum(sel_corr(:,3),sel_corr_2(:,3));
        else
            [h,p] = ttest(sel_corr(:,3),sel_corr_2(:,3));
        end
        if h == 1
            plot([xlist(k),xlist(k+1)],[0.9,0.9],'k-',...
                'LineWidth',line_w)
            if sign_level{1,1}<=p && p<sign_level{1,2}
                show_star = sign_level{1,3};
            elseif sign_level{2,1}<=p && p<sign_level{2,2}
                show_star = sign_level{2,3};
            elseif sign_level{3,1}<=p && p<sign_level{3,2}
                show_star = sign_level{3,3};
            elseif sign_level{4,1}<=p && p<sign_level{4,2}
                show_star = sign_level{4,3};
            end
            text(...
                (xlist(k)+xlist(k+1))/2,...
                0.9,show_star,...
                'HorizontalAlignment','center',...
                'VerticalAlignment','bottom',...
                'FontName','Calibri')
        end
    end
    plot(x_bias+xlist(k)*ones(size(sel_corr(:,3))),sel_corr(:,3),...
        'o','LineWidth',line_w,...
        'MarkerEdgeColor','k',...
        'MarkerFaceColor','w',...
        'MarkerSize',mk_size)
    hold on
end
hold off

box off
set(gca,'XTick',(xlist(1:2:end)+xlist(2:2:end))/2)
set(gca,'TickDir','out')
set(gca,'XTickLabel',show_xtick)
set(gca,'XTickLabelRotation',0)
set(gca,'YTickLabel',[])
set(gca,'FontSize',6)
axis([0.3,8.7,0,1])
% title('Far')
%% show the performance of cebra reconstruction, pose
start_x = 0.03;
start_y = 0.17;

box_x = 0.095;
box_y = 0.18;

inter_x = 0.005;

show_list = {...
    'tpm','tpmss',mouse_tpm_c;...
    'free','tpmss',mouse_free_c;...
    'tpm','tpmpfc',mouse_tpm_c;...
    'free','tpmpfc',mouse_free_c;...
    'tpm','tpmm',mouse_tpm_c;...
    'free','tpmm',mouse_free_c};

show_xtick = {...
    'S1','dmPFC','M1'};

xlist = [1,2,4,5,7,8];

cap_size = 2;

line_w = 0.25;

mk_size = 2;

x_bias = 0.4;

cut_idx_range = 9001:27000;

for k = 1:3
    if k == 1
        % show all
        for m = 1:size(show_list,1)
            selidx1 = strcmp(cebra_pose_cell(:,9),show_list{m,1});
            selidx2 = strcmp(cebra_pose_cell(:,11),show_list{m,2});
            selidx = selidx1&selidx2;

            selerror = cell2mat(error_pose_cell(selidx,2));

            mean_sel_corr = mean(selerror);
            std_sel_corr = std(selerror)./sqrt(size(selerror,1));

            subplot('Position',[...
            start_x+(k-1)*(box_x+inter_x),...
            start_y,box_x,box_y])
            legend_cell{k,1} = bar(xlist(m),mean_sel_corr,...
                        'FaceColor',show_list{m,3},...
                        'LineWidth',line_w);
            hold on
            errorbar(xlist(m),mean_sel_corr,std_sel_corr,...
                'Color','k','CapSize',cap_size,...
                'LineWidth',line_w)
            hold on

        end
        for m = 1:size(show_list,1)
            selidx1 = strcmp(cebra_pose_cell(:,9),show_list{m,1});
            selidx2 = strcmp(cebra_pose_cell(:,11),show_list{m,2});
            selidx = selidx1&selidx2;

            selerror = cell2mat(error_pose_cell(selidx,2));

            mean_sel_corr = mean(selerror);
            std_sel_corr = std(selerror)./sqrt(size(selerror,1));


            if rem(m,2) == 1
                selidx1 = strcmp(cebra_pose_cell(:,9),show_list{m+1,1});
                selidx2 = strcmp(cebra_pose_cell(:,11),show_list{m+1,2});
            
                selidx = selidx1&selidx2;
            
                sel_error_2 = cell2mat(error_pose_cell(selidx,2));
        
                for n = 1:size(sel_corr,1)
                    plot(x_bias+[xlist(m),xlist(m+1)],...
                        [selerror(n),sel_error_2(n)],...
                        '-k','LineWidth',line_w)
                    hold on
                end

                %% statistics
                [h_norm1,p_norm1] = lillietest(selerror);
                [h_norm2,p_norm2] = lillietest(sel_error_2);
                [h_var,p_var] = vartest2(selerror,sel_error_2);
                
                if (h_norm1 | h_norm2 | h_var) == 1
                    [p,h] = ranksum(selerror,sel_error_2);
                else
                    [h,p] = ttest(selerror,sel_error_2);
                end
                if h == 1
                    plot([xlist(m),xlist(m+1)],[6,6],'k-',...
                        'LineWidth',line_w)
                    if sign_level{1,1}<=p && p<sign_level{1,2}
                        show_star = sign_level{1,3};
                    elseif sign_level{2,1}<=p && p<sign_level{2,2}
                        show_star = sign_level{2,3};
                    elseif sign_level{3,1}<=p && p<sign_level{3,2}
                        show_star = sign_level{3,3};
                    elseif sign_level{4,1}<=p && p<sign_level{4,2}
                        show_star = sign_level{4,3};
                    end
                    text(...
                        (xlist(m)+xlist(m+1))/2,...
                        6,show_star,...
                        'HorizontalAlignment','center',...
                        'VerticalAlignment','bottom',...
                        'FontName','Calibri')
                end
            end
            plot(x_bias+xlist(m)*ones(size(selerror)),selerror,...
                'o','LineWidth',line_w,...
                'MarkerEdgeColor','k',...
                'MarkerFaceColor','w',...
                'MarkerSize',mk_size)
            hold on
        end
        hold off

        box off
        set(gca,'XTick',(xlist(1:2:end)+xlist(2:2:end))/2)
        set(gca,'TickDir','out')
        set(gca,'XTickLabel',show_xtick)
        set(gca,'XTickLabelRotation',0)
        % set(gca,'YTickLabel',[])
        set(gca,'FontSize',6)
        axis([0.3,8.7,0,7])
        title('All')
        ylabel('Pose test RMSE (Pixels)')
        
    elseif k == 2
        % show close
        for m = 1:size(show_list,1)
            selidx1 = strcmp(cebra_pose_cell(:,9),show_list{m,1});
            selidx2 = strcmp(cebra_pose_cell(:,11),show_list{m,2});
            selidx = selidx1&selidx2;

            sel_raw_error = cellfun(...
                @(x,y) mean(x(y(cut_idx_range)==1)),...
                error_pose_cell(selidx,3),...
                dist_pose_cell(selidx,2),...
                'UniformOutput',false);
            
            selerror = cell2mat(sel_raw_error);

            mean_sel_corr = mean(selerror);
            std_sel_corr = std(selerror)./sqrt(size(selerror,1));

            subplot('Position',[...
            start_x+(k-1)*(box_x+inter_x),...
            start_y,box_x,box_y])
            legend_cell{k,1} = bar(xlist(m),mean_sel_corr,...
                        'FaceColor',show_list{m,3},...
                        'LineWidth',line_w);
            hold on
            errorbar(xlist(m),mean_sel_corr,std_sel_corr,...
                'Color','k','CapSize',cap_size,...
                'LineWidth',line_w)
            hold on

        end
        for m = 1:size(show_list,1)
            selidx1 = strcmp(cebra_pose_cell(:,9),show_list{m,1});
            selidx2 = strcmp(cebra_pose_cell(:,11),show_list{m,2});
            selidx = selidx1&selidx2;

            sel_raw_error = cellfun(...
                @(x,y) mean(x(y(cut_idx_range)==1)),...
                error_pose_cell(selidx,3),...
                dist_pose_cell(selidx,2),...
                'UniformOutput',false);
            
            selerror = cell2mat(sel_raw_error);

            mean_sel_corr = mean(selerror);
            std_sel_corr = std(selerror)./sqrt(size(selerror,1));


            if rem(m,2) == 1
                selidx1 = strcmp(cebra_pose_cell(:,9),show_list{m+1,1});
                selidx2 = strcmp(cebra_pose_cell(:,11),show_list{m+1,2});
            
                selidx = selidx1&selidx2;
            
                sel_raw_error = cellfun(...
                @(x,y) mean(x(y(cut_idx_range)==1)),...
                error_pose_cell(selidx,3),...
                dist_pose_cell(selidx,2),...
                'UniformOutput',false);
            
                sel_error_2 = cell2mat(sel_raw_error);
        
                for n = 1:size(sel_corr,1)
                    plot(x_bias+[xlist(m),xlist(m+1)],...
                        [selerror(n),sel_error_2(n)],...
                        '-k','LineWidth',line_w)
                    hold on
                end

                %% statistics
                [h_norm1,p_norm1] = lillietest(selerror);
                [h_norm2,p_norm2] = lillietest(sel_error_2);
                [h_var,p_var] = vartest2(selerror,sel_error_2);
                
                if (h_norm1 | h_norm2 | h_var) == 1
                    [p,h] = ranksum(selerror,sel_error_2);
                else
                    [h,p] = ttest(selerror,sel_error_2);
                end
                if h == 1
                    plot([xlist(m),xlist(m+1)],[6,6],'k-',...
                        'LineWidth',line_w)
                    if sign_level{1,1}<=p && p<sign_level{1,2}
                        show_star = sign_level{1,3};
                    elseif sign_level{2,1}<=p && p<sign_level{2,2}
                        show_star = sign_level{2,3};
                    elseif sign_level{3,1}<=p && p<sign_level{3,2}
                        show_star = sign_level{3,3};
                    elseif sign_level{4,1}<=p && p<sign_level{4,2}
                        show_star = sign_level{4,3};
                    end
                    text(...
                        (xlist(m)+xlist(m+1))/2,...
                        6,show_star,...
                        'HorizontalAlignment','center',...
                        'VerticalAlignment','bottom',...
                        'FontName','Calibri')
                end
            end
            plot(x_bias+xlist(m)*ones(size(selerror)),selerror,...
                'o','LineWidth',line_w,...
                'MarkerEdgeColor','k',...
                'MarkerFaceColor','w',...
                'MarkerSize',mk_size)
            hold on
        end
        hold off

        box off
        set(gca,'XTick',(xlist(1:2:end)+xlist(2:2:end))/2)
        set(gca,'TickDir','out')
        set(gca,'XTickLabel',show_xtick)
        set(gca,'XTickLabelRotation',0)
        set(gca,'YTickLabel',[])
        set(gca,'FontSize',6)
        axis([0.3,8.7,0,7])
        title('Close')

    elseif k == 3
        % show far
        for m = 1:size(show_list,1)
            selidx1 = strcmp(cebra_pose_cell(:,9),show_list{m,1});
            selidx2 = strcmp(cebra_pose_cell(:,11),show_list{m,2});
            selidx = selidx1&selidx2;

            sel_raw_error = cellfun(...
                @(x,y) mean(x(y(cut_idx_range)==0)),...
                error_pose_cell(selidx,3),...
                dist_pose_cell(selidx,2),...
                'UniformOutput',false);
            
            selerror = cell2mat(sel_raw_error);

            mean_sel_corr = mean(selerror);
            std_sel_corr = std(selerror)./sqrt(size(selerror,1));

            subplot('Position',[...
            start_x+(k-1)*(box_x+inter_x),...
            start_y,box_x,box_y])
            legend_cell{k,1} = bar(xlist(m),mean_sel_corr,...
                        'FaceColor',show_list{m,3},...
                        'LineWidth',line_w);
            hold on
            errorbar(xlist(m),mean_sel_corr,std_sel_corr,...
                'Color','k','CapSize',cap_size,...
                'LineWidth',line_w)
            hold on

        end
        for m = 1:size(show_list,1)
            selidx1 = strcmp(cebra_pose_cell(:,9),show_list{m,1});
            selidx2 = strcmp(cebra_pose_cell(:,11),show_list{m,2});
            selidx = selidx1&selidx2;

            sel_raw_error = cellfun(...
                @(x,y) mean(x(y(cut_idx_range)==0)),...
                error_pose_cell(selidx,3),...
                dist_pose_cell(selidx,2),...
                'UniformOutput',false);
            
            selerror = cell2mat(sel_raw_error);

            mean_sel_corr = mean(selerror);
            std_sel_corr = std(selerror)./sqrt(size(selerror,1));


            if rem(m,2) == 1
                selidx1 = strcmp(cebra_pose_cell(:,9),show_list{m+1,1});
                selidx2 = strcmp(cebra_pose_cell(:,11),show_list{m+1,2});
            
                selidx = selidx1&selidx2;

                sel_raw_error = cellfun(...
                @(x,y) mean(x(y(cut_idx_range)==0)),...
                error_pose_cell(selidx,3),...
                dist_pose_cell(selidx,2),...
                'UniformOutput',false);
            
                sel_error_2 = cell2mat(sel_raw_error);
            
                for n = 1:size(sel_corr,1)
                    plot(x_bias+[xlist(m),xlist(m+1)],...
                        [selerror(n),sel_error_2(n)],...
                        '-k','LineWidth',line_w)
                    hold on
                end

                %% statistics
                [h_norm1,p_norm1] = lillietest(selerror);
                [h_norm2,p_norm2] = lillietest(sel_error_2);
                [h_var,p_var] = vartest2(selerror,sel_error_2);
                
                if (h_norm1 | h_norm2 | h_var) == 1
                    [p,h] = ranksum(selerror,sel_error_2);
                else
                    [h,p] = ttest(selerror,sel_error_2);
                end
                if h == 1
                    plot([xlist(m),xlist(m+1)],[6,6],'k-',...
                        'LineWidth',line_w)
                    if sign_level{1,1}<=p && p<sign_level{1,2}
                        show_star = sign_level{1,3};
                    elseif sign_level{2,1}<=p && p<sign_level{2,2}
                        show_star = sign_level{2,3};
                    elseif sign_level{3,1}<=p && p<sign_level{3,2}
                        show_star = sign_level{3,3};
                    elseif sign_level{4,1}<=p && p<sign_level{4,2}
                        show_star = sign_level{4,3};
                    end
                    text(...
                        (xlist(m)+xlist(m+1))/2,...
                        6,show_star,...
                        'HorizontalAlignment','center',...
                        'VerticalAlignment','bottom',...
                        'FontName','Calibri')
                end
            end
            plot(x_bias+xlist(m)*ones(size(selerror)),selerror,...
                'o','LineWidth',line_w,...
                'MarkerEdgeColor','k',...
                'MarkerFaceColor','w',...
                'MarkerSize',mk_size)
            hold on
        end
        hold off

        box off
        set(gca,'XTick',(xlist(1:2:end)+xlist(2:2:end))/2)
        set(gca,'TickDir','out')
        set(gca,'XTickLabel',show_xtick)
        set(gca,'XTickLabelRotation',0)
        set(gca,'YTickLabel',[])
        set(gca,'FontSize',6)
        axis([0.3,8.7,0,7])
        title('Far')
    else
        disp('error')
    end
end
%% show the performance of cebra reconstruction, mov
start_x = 0.36;
start_y = 0.17;

box_x = 0.095;
box_y = 0.18;

inter_x = 0.005;

show_list = {...
    'tpm','tpmss',mouse_tpm_c;...
    'free','tpmss',mouse_free_c;...
    'tpm','tpmpfc',mouse_tpm_c;...
    'free','tpmpfc',mouse_free_c;...
    'tpm','tpmm',mouse_tpm_c;...
    'free','tpmm',mouse_free_c};

show_xtick = {...
    'S1','dmPFC','M1'};

xlist = [1,2,4,5,7,8];

cap_size = 2;

line_w = 0.25;

mk_size = 2;

x_bias = 0.4;

cut_idx_range = 9001:27000;

for k = 1:3
    if k == 1
        % show all
        for m = 1:size(show_list,1)
            selidx1 = strcmp(cebra_mov_cell(:,9),show_list{m,1});
            selidx2 = strcmp(cebra_mov_cell(:,11),show_list{m,2});
            selidx = selidx1&selidx2;

            selerror = cell2mat(error_mov_cell(selidx,2));

            mean_sel_corr = mean(selerror);
            std_sel_corr = std(selerror)./sqrt(size(selerror,1));

            subplot('Position',[...
            start_x+(k-1)*(box_x+inter_x),...
            start_y,box_x,box_y])
            legend_cell{k,1} = bar(xlist(m),mean_sel_corr,...
                        'FaceColor',show_list{m,3},...
                        'LineWidth',line_w);
            hold on
            errorbar(xlist(m),mean_sel_corr,std_sel_corr,...
                'Color','k','CapSize',cap_size,...
                'LineWidth',line_w)
            hold on

        end
        for m = 1:size(show_list,1)
            selidx1 = strcmp(cebra_mov_cell(:,9),show_list{m,1});
            selidx2 = strcmp(cebra_mov_cell(:,11),show_list{m,2});
            selidx = selidx1&selidx2;

            selerror = cell2mat(error_mov_cell(selidx,2));

            mean_sel_corr = mean(selerror);
            std_sel_corr = std(selerror)./sqrt(size(selerror,1));


            if rem(m,2) == 1
                selidx1 = strcmp(cebra_mov_cell(:,9),show_list{m+1,1});
                selidx2 = strcmp(cebra_mov_cell(:,11),show_list{m+1,2});
            
                selidx = selidx1&selidx2;
            
                sel_error_2 = cell2mat(error_mov_cell(selidx,2));
        
                for n = 1:size(sel_corr,1)
                    plot(x_bias+[xlist(m),xlist(m+1)],...
                        [selerror(n),sel_error_2(n)],...
                        '-k','LineWidth',line_w)
                    hold on
                end

                %% statistics
                [h_norm1,p_norm1] = lillietest(selerror);
                [h_norm2,p_norm2] = lillietest(sel_error_2);
                [h_var,p_var] = vartest2(selerror,sel_error_2);
                
                if (h_norm1 | h_norm2 | h_var) == 1
                    [p,h] = ranksum(selerror,sel_error_2);
                else
                    [h,p] = ttest(selerror,sel_error_2);
                end
                if h == 1
                    plot([xlist(m),xlist(m+1)],[6,6],'k-',...
                        'LineWidth',line_w)
                    if sign_level{1,1}<=p && p<sign_level{1,2}
                        show_star = sign_level{1,3};
                    elseif sign_level{2,1}<=p && p<sign_level{2,2}
                        show_star = sign_level{2,3};
                    elseif sign_level{3,1}<=p && p<sign_level{3,2}
                        show_star = sign_level{3,3};
                    elseif sign_level{4,1}<=p && p<sign_level{4,2}
                        show_star = sign_level{4,3};
                    end
                    text(...
                        (xlist(m)+xlist(m+1))/2,...
                        6,show_star,...
                        'HorizontalAlignment','center',...
                        'VerticalAlignment','bottom',...
                        'FontName','Calibri')
                end
            end
            plot(x_bias+xlist(m)*ones(size(selerror)),selerror,...
                'o','LineWidth',line_w,...
                'MarkerEdgeColor','k',...
                'MarkerFaceColor','w',...
                'MarkerSize',mk_size)
            hold on
        end
        hold off

        box off
        set(gca,'XTick',(xlist(1:2:end)+xlist(2:2:end))/2)
        set(gca,'TickDir','out')
        set(gca,'XTickLabel',show_xtick)
        set(gca,'XTickLabelRotation',0)
        % set(gca,'YTickLabel',[])
        set(gca,'FontSize',6)
        axis([0.3,8.7,0,1])
        title('All')
        ylabel('Movement test Hamming distance')
        
    elseif k == 2
        % show close
        for m = 1:size(show_list,1)
            selidx1 = strcmp(cebra_mov_cell(:,9),show_list{m,1});
            selidx2 = strcmp(cebra_mov_cell(:,11),show_list{m,2});
            selidx = selidx1&selidx2;

            sel_raw_error = cellfun(...
                @(x,y) mean(x(y(cut_idx_range)==1)),...
                error_mov_cell(selidx,3),...
                dist_mov_cell(selidx,2),...
                'UniformOutput',false);
            
            selerror = cell2mat(sel_raw_error);

            mean_sel_corr = mean(selerror);
            std_sel_corr = std(selerror)./sqrt(size(selerror,1));

            subplot('Position',[...
            start_x+(k-1)*(box_x+inter_x),...
            start_y,box_x,box_y])
            legend_cell{k,1} = bar(xlist(m),mean_sel_corr,...
                        'FaceColor',show_list{m,3},...
                        'LineWidth',line_w);
            hold on
            errorbar(xlist(m),mean_sel_corr,std_sel_corr,...
                'Color','k','CapSize',cap_size,...
                'LineWidth',line_w)
            hold on

        end
        for m = 1:size(show_list,1)
            selidx1 = strcmp(cebra_mov_cell(:,9),show_list{m,1});
            selidx2 = strcmp(cebra_mov_cell(:,11),show_list{m,2});
            selidx = selidx1&selidx2;

            sel_raw_error = cellfun(...
                @(x,y) mean(x(y(cut_idx_range)==1)),...
                error_mov_cell(selidx,3),...
                dist_mov_cell(selidx,2),...
                'UniformOutput',false);
            
            selerror = cell2mat(sel_raw_error);

            mean_sel_corr = mean(selerror);
            std_sel_corr = std(selerror)./sqrt(size(selerror,1));


            if rem(m,2) == 1
                selidx1 = strcmp(cebra_mov_cell(:,9),show_list{m+1,1});
                selidx2 = strcmp(cebra_mov_cell(:,11),show_list{m+1,2});
                selidx = selidx1&selidx2;

                sel_raw_error = cellfun(...
                @(x,y) mean(x(y(cut_idx_range)==1)),...
                error_mov_cell(selidx,3),...
                dist_mov_cell(selidx,2),...
                'UniformOutput',false);
            
                sel_error_2 = cell2mat(sel_raw_error);
  
                for n = 1:size(sel_corr,1)
                    plot(x_bias+[xlist(m),xlist(m+1)],...
                        [selerror(n),sel_error_2(n)],...
                        '-k','LineWidth',line_w)
                    hold on
                end

                %% statistics
                [h_norm1,p_norm1] = lillietest(selerror);
                [h_norm2,p_norm2] = lillietest(sel_error_2);
                [h_var,p_var] = vartest2(selerror,sel_error_2);
                
                if (h_norm1 | h_norm2 | h_var) == 1
                    [p,h] = ranksum(selerror,sel_error_2);
                else
                    [h,p] = ttest(selerror,sel_error_2);
                end
                if h == 1
                    plot([xlist(m),xlist(m+1)],[6,6],'k-',...
                        'LineWidth',line_w)
                    if sign_level{1,1}<=p && p<sign_level{1,2}
                        show_star = sign_level{1,3};
                    elseif sign_level{2,1}<=p && p<sign_level{2,2}
                        show_star = sign_level{2,3};
                    elseif sign_level{3,1}<=p && p<sign_level{3,2}
                        show_star = sign_level{3,3};
                    elseif sign_level{4,1}<=p && p<sign_level{4,2}
                        show_star = sign_level{4,3};
                    end
                    text(...
                        (xlist(m)+xlist(m+1))/2,...
                        6,show_star,...
                        'HorizontalAlignment','center',...
                        'VerticalAlignment','bottom',...
                        'FontName','Calibri')
                end
            end
            plot(x_bias+xlist(m)*ones(size(selerror)),selerror,...
                'o','LineWidth',line_w,...
                'MarkerEdgeColor','k',...
                'MarkerFaceColor','w',...
                'MarkerSize',mk_size)
            hold on
        end
        hold off

        box off
        set(gca,'XTick',(xlist(1:2:end)+xlist(2:2:end))/2)
        set(gca,'TickDir','out')
        set(gca,'XTickLabel',show_xtick)
        set(gca,'XTickLabelRotation',0)
        set(gca,'YTickLabel',[])
        set(gca,'FontSize',6)
        axis([0.3,8.7,0,1])
        title('Close')

    elseif k == 3
        % show far
        for m = 1:size(show_list,1)
            selidx1 = strcmp(cebra_mov_cell(:,9),show_list{m,1});
            selidx2 = strcmp(cebra_mov_cell(:,11),show_list{m,2});
            selidx = selidx1&selidx2;

            sel_raw_error = cellfun(...
                @(x,y) mean(x(y(cut_idx_range)==0)),...
                error_mov_cell(selidx,3),...
                dist_mov_cell(selidx,2),...
                'UniformOutput',false);
            
            selerror = cell2mat(sel_raw_error);

            mean_sel_corr = mean(selerror);
            std_sel_corr = std(selerror)./sqrt(size(selerror,1));

            subplot('Position',[...
            start_x+(k-1)*(box_x+inter_x),...
            start_y,box_x,box_y])
            legend_cell{k,1} = bar(xlist(m),mean_sel_corr,...
                        'FaceColor',show_list{m,3},...
                        'LineWidth',line_w);
            hold on
            errorbar(xlist(m),mean_sel_corr,std_sel_corr,...
                'Color','k','CapSize',cap_size,...
                'LineWidth',line_w)
            hold on

        end
        for m = 1:size(show_list,1)
            selidx1 = strcmp(cebra_mov_cell(:,9),show_list{m,1});
            selidx2 = strcmp(cebra_mov_cell(:,11),show_list{m,2});
            selidx = selidx1&selidx2;

            sel_raw_error = cellfun(...
                @(x,y) mean(x(y(cut_idx_range)==0)),...
                error_mov_cell(selidx,3),...
                dist_mov_cell(selidx,2),...
                'UniformOutput',false);
            
            selerror = cell2mat(sel_raw_error);

            mean_sel_corr = mean(selerror);
            std_sel_corr = std(selerror)./sqrt(size(selerror,1));


            if rem(m,2) == 1
                selidx1 = strcmp(cebra_mov_cell(:,9),show_list{m+1,1});
                selidx2 = strcmp(cebra_mov_cell(:,11),show_list{m+1,2});
            
                selidx = selidx1&selidx2;
            
                sel_raw_error = cellfun(...
                @(x,y) mean(x(y(cut_idx_range)==0)),...
                error_mov_cell(selidx,3),...
                dist_mov_cell(selidx,2),...
                'UniformOutput',false);
            
                sel_error_2 = cell2mat(sel_raw_error);
        
                for n = 1:size(sel_corr,1)
                    plot(x_bias+[xlist(m),xlist(m+1)],...
                        [selerror(n),sel_error_2(n)],...
                        '-k','LineWidth',line_w)
                    hold on
                end

                %% statistics
                [h_norm1,p_norm1] = lillietest(selerror);
                [h_norm2,p_norm2] = lillietest(sel_error_2);
                [h_var,p_var] = vartest2(selerror,sel_error_2);
                
                if (h_norm1 | h_norm2 | h_var) == 1
                    [p,h] = ranksum(selerror,sel_error_2);
                else
                    [h,p] = ttest(selerror,sel_error_2);
                end
                if h == 1
                    plot([xlist(m),xlist(m+1)],[6,6],'k-',...
                        'LineWidth',line_w)
                    if sign_level{1,1}<=p && p<sign_level{1,2}
                        show_star = sign_level{1,3};
                    elseif sign_level{2,1}<=p && p<sign_level{2,2}
                        show_star = sign_level{2,3};
                    elseif sign_level{3,1}<=p && p<sign_level{3,2}
                        show_star = sign_level{3,3};
                    elseif sign_level{4,1}<=p && p<sign_level{4,2}
                        show_star = sign_level{4,3};
                    end
                    text(...
                        (xlist(m)+xlist(m+1))/2,...
                        6,show_star,...
                        'HorizontalAlignment','center',...
                        'VerticalAlignment','bottom',...
                        'FontName','Calibri')
                end
            end
            plot(x_bias+xlist(m)*ones(size(selerror)),selerror,...
                'o','LineWidth',line_w,...
                'MarkerEdgeColor','k',...
                'MarkerFaceColor','w',...
                'MarkerSize',mk_size)
            hold on
            
        end
        hold off

        box off
        set(gca,'XTick',(xlist(1:2:end)+xlist(2:2:end))/2)
        set(gca,'TickDir','out')
        set(gca,'XTickLabel',show_xtick)
        set(gca,'XTickLabelRotation',0)
        set(gca,'YTickLabel',[])
        set(gca,'FontSize',6)
        axis([0.3,8.7,0,1])
        title('Far')
    else
        disp('error')
    end
end
%% show the performance of cebra reconstruction, seq
start_x = 0.69;
start_y = 0.17;

box_x = 0.095;
box_y = 0.18;

inter_x = 0.005;

show_list = {...
    'tpm','tpmss',mouse_tpm_c;...
    'free','tpmss',mouse_free_c;...
    'tpm','tpmpfc',mouse_tpm_c;...
    'free','tpmpfc',mouse_free_c;...
    'tpm','tpmm',mouse_tpm_c;...
    'free','tpmm',mouse_free_c};

show_xtick = {...
    'S1','dmPFC','M1'};

xlist = [1,2,4,5,7,8];

cap_size = 2;

line_w = 0.25;

mk_size = 2;

x_bias = 0.4;

cut_idx_range = 9001:27000;

for k = 1:3
    if k == 1
        % show all
        for m = 1:size(show_list,1)
            selidx1 = strcmp(cebra_seq_cell(:,9),show_list{m,1});
            selidx2 = strcmp(cebra_seq_cell(:,11),show_list{m,2});
            selidx = selidx1&selidx2;

            selerror = cell2mat(error_seq_cell(selidx,2));

            mean_sel_corr = mean(selerror);
            std_sel_corr = std(selerror)./sqrt(size(selerror,1));

            subplot('Position',[...
            start_x+(k-1)*(box_x+inter_x),...
            start_y,box_x,box_y])
            legend_cell{k,1} = bar(xlist(m),mean_sel_corr,...
                        'FaceColor',show_list{m,3},...
                        'LineWidth',line_w);
            hold on
            errorbar(xlist(m),mean_sel_corr,std_sel_corr,...
                'Color','k','CapSize',cap_size,...
                'LineWidth',line_w)
            hold on

        end
        for m = 1:size(show_list,1)
            selidx1 = strcmp(cebra_seq_cell(:,9),show_list{m,1});
            selidx2 = strcmp(cebra_seq_cell(:,11),show_list{m,2});
            selidx = selidx1&selidx2;

            selerror = cell2mat(error_seq_cell(selidx,2));

            mean_sel_corr = mean(selerror);
            std_sel_corr = std(selerror)./sqrt(size(selerror,1));


            if rem(m,2) == 1
                selidx1 = strcmp(cebra_seq_cell(:,9),show_list{m+1,1});
                selidx2 = strcmp(cebra_seq_cell(:,11),show_list{m+1,2});
            
                selidx = selidx1&selidx2;
            
                sel_error_2 = cell2mat(error_seq_cell(selidx,2));
        
                for n = 1:size(sel_corr,1)
                    plot(x_bias+[xlist(m),xlist(m+1)],...
                        [selerror(n),sel_error_2(n)],...
                        '-k','LineWidth',line_w)
                    hold on
                end
                %% statistics
                [h_norm1,p_norm1] = lillietest(selerror);
                [h_norm2,p_norm2] = lillietest(sel_error_2);
                [h_var,p_var] = vartest2(selerror,sel_error_2);
                
                if (h_norm1 | h_norm2 | h_var) == 1
                    [p,h] = ranksum(selerror,sel_error_2);
                else
                    [h,p] = ttest(selerror,sel_error_2);
                end
                if h == 1
                    plot([xlist(m),xlist(m+1)],[6,6],'k-',...
                        'LineWidth',line_w)
                    if sign_level{1,1}<=p && p<sign_level{1,2}
                        show_star = sign_level{1,3};
                    elseif sign_level{2,1}<=p && p<sign_level{2,2}
                        show_star = sign_level{2,3};
                    elseif sign_level{3,1}<=p && p<sign_level{3,2}
                        show_star = sign_level{3,3};
                    elseif sign_level{4,1}<=p && p<sign_level{4,2}
                        show_star = sign_level{4,3};
                    end
                    text(...
                        (xlist(m)+xlist(m+1))/2,...
                        6,show_star,...
                        'HorizontalAlignment','center',...
                        'VerticalAlignment','bottom',...
                        'FontName','Calibri')
                end
            end
            plot(x_bias+xlist(m)*ones(size(selerror)),selerror,...
                'o','LineWidth',line_w,...
                'MarkerEdgeColor','k',...
                'MarkerFaceColor','w',...
                'MarkerSize',mk_size)
            hold on
        end
        hold off

        box off
        set(gca,'XTick',(xlist(1:2:end)+xlist(2:2:end))/2)
        set(gca,'TickDir','out')
        set(gca,'XTickLabel',show_xtick)
        set(gca,'XTickLabelRotation',0)
        % set(gca,'YTickLabel',[])
        set(gca,'FontSize',6)
        axis([0.3,8.7,0,1])
        title('All')
        ylabel('Sequence test Hamming distance')
        
    elseif k == 2
        % show close
        for m = 1:size(show_list,1)
            selidx1 = strcmp(cebra_seq_cell(:,9),show_list{m,1});
            selidx2 = strcmp(cebra_seq_cell(:,11),show_list{m,2});
            selidx = selidx1&selidx2;

            sel_raw_error = cellfun(...
                @(x,y) mean(x(y(cut_idx_range)==1)),...
                error_seq_cell(selidx,3),...
                dist_seq_cell(selidx,2),...
                'UniformOutput',false);
            
            selerror = cell2mat(sel_raw_error);

            mean_sel_corr = mean(selerror);
            std_sel_corr = std(selerror)./sqrt(size(selerror,1));

            subplot('Position',[...
            start_x+(k-1)*(box_x+inter_x),...
            start_y,box_x,box_y])
            legend_cell{k,1} = bar(xlist(m),mean_sel_corr,...
                        'FaceColor',show_list{m,3},...
                        'LineWidth',line_w);
            hold on
            errorbar(xlist(m),mean_sel_corr,std_sel_corr,...
                'Color','k','CapSize',cap_size,...
                'LineWidth',line_w)
            hold on

        end
        for m = 1:size(show_list,1)
            selidx1 = strcmp(cebra_seq_cell(:,9),show_list{m,1});
            selidx2 = strcmp(cebra_seq_cell(:,11),show_list{m,2});
            selidx = selidx1&selidx2;

            sel_raw_error = cellfun(...
                @(x,y) mean(x(y(cut_idx_range)==1)),...
                error_seq_cell(selidx,3),...
                dist_seq_cell(selidx,2),...
                'UniformOutput',false);
            
            selerror = cell2mat(sel_raw_error);

            mean_sel_corr = mean(selerror);
            std_sel_corr = std(selerror)./sqrt(size(selerror,1));


            if rem(m,2) == 1
                selidx1 = strcmp(cebra_seq_cell(:,9),show_list{m+1,1});
                selidx2 = strcmp(cebra_seq_cell(:,11),show_list{m+1,2});
            
                selidx = selidx1&selidx2;
            
                sel_raw_error = cellfun(...
                @(x,y) mean(x(y(cut_idx_range)==1)),...
                error_seq_cell(selidx,3),...
                dist_seq_cell(selidx,2),...
                'UniformOutput',false);
            
                sel_error_2 = cell2mat(sel_raw_error);
        
                for n = 1:size(sel_corr,1)
                    plot(x_bias+[xlist(m),xlist(m+1)],...
                        [selerror(n),sel_error_2(n)],...
                        '-k','LineWidth',line_w)
                    hold on
                end

                %% statistics
                [h_norm1,p_norm1] = lillietest(selerror);
                [h_norm2,p_norm2] = lillietest(sel_error_2);
                [h_var,p_var] = vartest2(selerror,sel_error_2);
                
                if (h_norm1 | h_norm2 | h_var) == 1
                    [p,h] = ranksum(selerror,sel_error_2);
                else
                    [h,p] = ttest(selerror,sel_error_2);
                end
                if h == 1
                    plot([xlist(m),xlist(m+1)],[6,6],'k-',...
                        'LineWidth',line_w)
                    if sign_level{1,1}<=p && p<sign_level{1,2}
                        show_star = sign_level{1,3};
                    elseif sign_level{2,1}<=p && p<sign_level{2,2}
                        show_star = sign_level{2,3};
                    elseif sign_level{3,1}<=p && p<sign_level{3,2}
                        show_star = sign_level{3,3};
                    elseif sign_level{4,1}<=p && p<sign_level{4,2}
                        show_star = sign_level{4,3};
                    end
                    text(...
                        (xlist(m)+xlist(m+1))/2,...
                        6,show_star,...
                        'HorizontalAlignment','center',...
                        'VerticalAlignment','bottom',...
                        'FontName','Calibri')
                end
            end
            plot(x_bias+xlist(m)*ones(size(selerror)),selerror,...
                'o','LineWidth',line_w,...
                'MarkerEdgeColor','k',...
                'MarkerFaceColor','w',...
                'MarkerSize',mk_size)
            hold on
        end
        hold off

        box off
        set(gca,'XTick',(xlist(1:2:end)+xlist(2:2:end))/2)
        set(gca,'TickDir','out')
        set(gca,'XTickLabel',show_xtick)
        set(gca,'XTickLabelRotation',0)
        set(gca,'YTickLabel',[])
        set(gca,'FontSize',6)
        axis([0.3,8.7,0,1])
        title('Close')

    elseif k == 3
        % show far
        for m = 1:size(show_list,1)
            selidx1 = strcmp(cebra_seq_cell(:,9),show_list{m,1});
            selidx2 = strcmp(cebra_seq_cell(:,11),show_list{m,2});
            selidx = selidx1&selidx2;

            sel_raw_error = cellfun(...
                @(x,y) mean(x(y(cut_idx_range)==0)),...
                error_seq_cell(selidx,3),...
                dist_seq_cell(selidx,2),...
                'UniformOutput',false);
            
            selerror = cell2mat(sel_raw_error);

            mean_sel_corr = mean(selerror);
            std_sel_corr = std(selerror)./sqrt(size(selerror,1));

            subplot('Position',[...
            start_x+(k-1)*(box_x+inter_x),...
            start_y,box_x,box_y])
            legend_cell{k,1} = bar(xlist(m),mean_sel_corr,...
                        'FaceColor',show_list{m,3},...
                        'LineWidth',line_w);
            hold on
            errorbar(xlist(m),mean_sel_corr,std_sel_corr,...
                'Color','k','CapSize',cap_size,...
                'LineWidth',line_w)
            hold on

        end
        for m = 1:size(show_list,1)
            selidx1 = strcmp(cebra_seq_cell(:,9),show_list{m,1});
            selidx2 = strcmp(cebra_seq_cell(:,11),show_list{m,2});
            selidx = selidx1&selidx2;

            sel_raw_error = cellfun(...
                @(x,y) mean(x(y(cut_idx_range)==0)),...
                error_seq_cell(selidx,3),...
                dist_seq_cell(selidx,2),...
                'UniformOutput',false);
            
            selerror = cell2mat(sel_raw_error);

            mean_sel_corr = mean(selerror);
            std_sel_corr = std(selerror)./sqrt(size(selerror,1));


            if rem(m,2) == 1
                selidx1 = strcmp(cebra_seq_cell(:,9),show_list{m+1,1});
                selidx2 = strcmp(cebra_seq_cell(:,11),show_list{m+1,2});
            
                selidx = selidx1&selidx2;
            
                sel_raw_error = cellfun(...
                @(x,y) mean(x(y(cut_idx_range)==0)),...
                error_seq_cell(selidx,3),...
                dist_seq_cell(selidx,2),...
                'UniformOutput',false);
            
                sel_error_2 = cell2mat(sel_raw_error);
        
                for n = 1:size(sel_corr,1)
                    plot(x_bias+[xlist(m),xlist(m+1)],...
                        [selerror(n),sel_error_2(n)],...
                        '-k','LineWidth',line_w)
                    hold on
                end

                %% statistics
                [h_norm1,p_norm1] = lillietest(selerror);
                [h_norm2,p_norm2] = lillietest(sel_error_2);
                [h_var,p_var] = vartest2(selerror,sel_error_2);
                
                if (h_norm1 | h_norm2 | h_var) == 1
                    [p,h] = ranksum(selerror,sel_error_2);
                else
                    [h,p] = ttest(selerror,sel_error_2);
                end
                if h == 1
                    plot([xlist(m),xlist(m+1)],[6,6],'k-',...
                        'LineWidth',line_w)
                    if sign_level{1,1}<=p && p<sign_level{1,2}
                        show_star = sign_level{1,3};
                    elseif sign_level{2,1}<=p && p<sign_level{2,2}
                        show_star = sign_level{2,3};
                    elseif sign_level{3,1}<=p && p<sign_level{3,2}
                        show_star = sign_level{3,3};
                    elseif sign_level{4,1}<=p && p<sign_level{4,2}
                        show_star = sign_level{4,3};
                    end
                    text(...
                        (xlist(m)+xlist(m+1))/2,...
                        6,show_star,...
                        'HorizontalAlignment','center',...
                        'VerticalAlignment','bottom',...
                        'FontName','Calibri')
                end
            end
            plot(x_bias+xlist(m)*ones(size(selerror)),selerror,...
                'o','LineWidth',line_w,...
                'MarkerEdgeColor','k',...
                'MarkerFaceColor','w',...
                'MarkerSize',mk_size)
            hold on
        end
        hold off

        box off
        set(gca,'XTick',(xlist(1:2:end)+xlist(2:2:end))/2)
        set(gca,'TickDir','out')
        set(gca,'XTickLabel',show_xtick)
        set(gca,'XTickLabelRotation',0)
        set(gca,'YTickLabel',[])
        set(gca,'FontSize',6)
        axis([0.3,8.7,0,1])
        title('Far')
    else
        disp('error')
    end
end















































