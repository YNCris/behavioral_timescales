%{
    fig4, 
    the comparison at movement level
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
dirOutput = dir(fullfile(fileFolder,'free*seq*-cebra.mat'));
cebraNames = {dirOutput.name}';

cebra_cell = cell(size(cebraNames,1),13);
cebra_cell(:,1) = cebraNames;

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
%% plot canvas
hall = figure(1);
set(hall,'Position',[680,0,800,800])
set(hall,'color','white');
%% create unique_label_list
all_num_label = cell(size(cebra_cell,1),1);
for k = 1:size(all_num_label,1)
    all_num_label{k,1} = cebra_cell{k,12}(:,1);
end
unique_num_label = unique(cell2mat(all_num_label));
%% find correlations between no/meaning sequence and neurons
corr_thres = 0.2;
corr_mean_seq_neu_cell = cell(size(cebra_cell,1),2);
corr_nomean_seq_neu_cell = cell(size(cebra_cell,1),2);
for k = 1:size(cebra_cell,1)
    %% load data
    tempidx = cebra_cell{k,12}(:,1);
    tempneu = cebra_cell{k,13};
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
    bw_label = zeros(size(tempidx,1),size(unique_num_label,1));
    for m = 1:size(bw_label,2)
        templabel = unique_num_label(m,1);
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
    selidx1 = strcmp(cebra_cell(:,9),show_list{k,1});
    selidx2 = strcmp(cebra_cell(:,11),show_list{k,2});

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
    selidx1 = strcmp(cebra_cell(:,9),show_list{k,1});
    selidx2 = strcmp(cebra_cell(:,11),show_list{k,2});

    selidx = selidx1&selidx2;

    sel_corr = cell2mat(corr_mean_seq_neu_cell(selidx,1));

    stat_mat(:,k) = sel_corr(:,3);
    %% show
    if rem(k,2) == 1
        selidx1 = strcmp(cebra_cell(:,9),show_list{k+1,1});
        selidx2 = strcmp(cebra_cell(:,11),show_list{k+1,2});
    
        selidx = selidx1&selidx2;
    
        sel_corr_2 = cell2mat(corr_mean_seq_neu_cell(selidx,1));

        for m = 1:size(sel_corr,1)
            plot(x_bias+[xlist(k),xlist(k+1)],...
                [sel_corr(m,3),sel_corr_2(m,3)],...
                '-k','LineWidth',line_w)
            hold on
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
ylabel('Neural pose correlation ratio')
set(gca,'FontSize',6)
legend([legend_cell{1},legend_cell{2}],show_mice_name,...
    'Box','off','Location','northwest')
axis([0.3,8.7,0,1])
title('All')
%% find correlations between sequence and neurons, close
corr_thres = 0.2;
corr_mean_seq_neu_close_cell = cell(size(cebra_cell,1),2);
corr_nomean_seq_neu_close_cell = cell(size(cebra_cell,1),2);
for k = 1:size(cebra_cell,1)
    %% load data
    tempidx = cebra_cell{k,12}(:,1);
    tempneu = cebra_cell{k,13};

    tempidx = tempidx(dist_cell{k,2}==1,:);
    tempneu = tempneu(dist_cell{k,2}==1,:);
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
    bw_label = zeros(size(tempidx,1),size(unique_num_label,1));
    for m = 1:size(bw_label,2)
        templabel = unique_num_label(m,1);
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
corr_mean_seq_neu_far_cell = cell(size(cebra_cell,1),2);
corr_nomean_seq_neu_far_cell = cell(size(cebra_cell,1),2);
for k = 1:size(cebra_cell,1)
    %% load data
    tempidx = cebra_cell{k,12}(:,1);
    tempneu = cebra_cell{k,13};

    tempidx = tempidx(dist_cell{k,2}==0,:);
    tempneu = tempneu(dist_cell{k,2}==0,:);
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
    bw_label = zeros(size(tempidx,1),size(unique_num_label,1));
    for m = 1:size(bw_label,2)
        templabel = unique_num_label(m,1);
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
    selidx1 = strcmp(cebra_cell(:,9),show_list{k,1});
    selidx2 = strcmp(cebra_cell(:,11),show_list{k,2});

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
    selidx1 = strcmp(cebra_cell(:,9),show_list{k,1});
    selidx2 = strcmp(cebra_cell(:,11),show_list{k,2});

    selidx = selidx1&selidx2;

    sel_corr = cell2mat(corr_mean_seq_neu_close_cell(selidx,1));

    stat_mat(:,k) = sel_corr(:,3);
    %% show
    if rem(k,2) == 1
        selidx1 = strcmp(cebra_cell(:,9),show_list{k+1,1});
        selidx2 = strcmp(cebra_cell(:,11),show_list{k+1,2});
    
        selidx = selidx1&selidx2;
    
        sel_corr_2 = cell2mat(corr_mean_seq_neu_close_cell(selidx,1));

        for m = 1:size(sel_corr,1)
            plot(x_bias+[xlist(k),xlist(k+1)],...
                [sel_corr(m,3),sel_corr_2(m,3)],...
                '-k','LineWidth',line_w)
            hold on
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
    selidx1 = strcmp(cebra_cell(:,9),show_list{k,1});
    selidx2 = strcmp(cebra_cell(:,11),show_list{k,2});

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
    selidx1 = strcmp(cebra_cell(:,9),show_list{k,1});
    selidx2 = strcmp(cebra_cell(:,11),show_list{k,2});

    selidx = selidx1&selidx2;

    sel_corr = cell2mat(corr_mean_seq_neu_far_cell(selidx,1));

    stat_mat(:,k) = sel_corr(:,3);
    %% show
    if rem(k,2) == 1
        selidx1 = strcmp(cebra_cell(:,9),show_list{k+1,1});
        selidx2 = strcmp(cebra_cell(:,11),show_list{k+1,2});
    
        selidx = selidx1&selidx2;
    
        sel_corr_2 = cell2mat(corr_mean_seq_neu_far_cell(selidx,1));

        for m = 1:size(sel_corr,1)
            plot(x_bias+[xlist(k),xlist(k+1)],...
                [sel_corr(m,3),sel_corr_2(m,3)],...
                '-k','LineWidth',line_w)
            hold on
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
title('Far')






























