%{
    fig2, 说明神经元集群编码
%}
clear all
close all
addpath(genpath(pwd))
%% set path
rootpath = ['X:\hanyaning\MTPM_body_language'];
beh_neu_path = [rootpath,'\beh_neu_20240412'];
%% load data
fileFolder = fullfile(beh_neu_path);
dirOutput = dir(fullfile(fileFolder,'free*-neu.mat'));
neuNames = {dirOutput.name}';

all_data_cell = cell(size(neuNames,1),8);
%{rootname,neudata,pose_self,mov_self,seq_self,
% pose_partner,mov_partner,seq_partner}

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

    disp(k)
end
%% cut mov trials
mov_before_time = 2;%s
mov_during_time = 2;%s
mov_after_time = 2;%s

fs = 30;

mov_before_frame = mov_before_time*fs;%s
mov_during_frame = mov_during_time*fs;%s
mov_after_frame = mov_after_time*fs;%s

load_flag = true;

if load_flag
    mov_trial_cell = {};
    for k = 1:size(all_data_cell,1)
        tempname = all_data_cell{k,1};
        loadname = [tempname,'neutrial_mov_tpm.mat'];
        tempdata = load([beh_neu_path,'\',loadname]);
        mov_trial_cell = [mov_trial_cell;...
            tempdata.temp_trial_cell];
        disp(k)
    end
else
    for k = 1:size(all_data_cell,1)
        tempname = all_data_cell{k,1};
        tempneu = all_data_cell{k,2};
        tempmov = cell2mat(all_data_cell{k,4}(:,2));
    
        savelist = idx2savelist(tempmov);
    
        savelist(:,1) = savelist(:,1)-before_frame;
        savelist(:,2) = savelist(:,2)+after_frame;
    
        savelist(savelist(:,1)<1,:) = [];
        savelist(savelist(:,2)>length(tempmov),:) = [];
        
        temp_trial_cell = {};
    
        for m = 1:size(savelist,1)
            start_pos = savelist(m,1);
            end_pos = savelist(m,2);
            movname = savelist(m,3);
            for n = 1:size(tempneu,2)
                neuname = n;
                newname = [tempname,'-',num2str(movname),'-',num2str(neuname)];
                cutneu = tempneu(start_pos:end_pos,n);
                before_neu = cutneu(1:before_frame);
                during_neu = cutneu((1+before_frame):(end-after_frame));
                after_neu = cutneu((1+end-after_frame):end);
    
                final_neu = [...
                    before_neu;...
                    imresize(during_neu,[during_frame,1]);...
                    after_neu;...
                    ]'-mean(before_neu);% float baseline
                temp_trial_cell = [temp_trial_cell;...
                    {newname,final_neu}];
            end
        end
        
        %% save
        save([beh_neu_path,'\',tempname,'neutrial_mov_tpm.mat'],...
            'temp_trial_cell')
        disp(k)
    end
end
%% calculate change labels of mov
mov_change_label_list = zeros(size(mov_trial_cell,1),1);
change_thres = 0.2;%std of baseline

boundary_thres = 0;% a torlerent of behavior noise
tic
for k = 1:size(mov_trial_cell,1)
    tempdata = mov_trial_cell{k,2};
    during_neu = tempdata(...
        (mov_before_frame+1-boundary_thres):...
        (length(tempdata)-mov_after_frame+boundary_thres));

    before_neu = tempdata(1:mov_before_frame);

    [h,p] = ttest2(during_neu,before_neu);

    % std_baseline = max(abs(baseline_neu));

    % max_neu = max(during_neu);
    % 
    % min_neu = min(during_neu);

    % mean_neu = mean(during_neu);

    if p<0.05
        mean_baseline_neu = mean(before_neu);
        mean_during_neu = mean(during_neu);

        if mean_baseline_neu>mean_during_neu
            mov_change_label_list(k,1) = -1;
        else
            mov_change_label_list(k,1) = 1;
        end
    else
    end

    % if mean_neu>(change_thres*std_baseline)
    %     change_label_list(k,1) = 1;
    % elseif (-1*mean_neu)>(change_thres*std_baseline)
    %     change_label_list(k,1) = -1;
    % end

    if rem(k,1000) == 0
        disp(k)
        toc
    end
end
toc
%% cut seq trials
seq_before_time = 10;%s
seq_during_time = 10;%s
seq_after_time = 10;%s

fs = 30;

seq_before_frame = seq_before_time*fs;%s
seq_during_frame = seq_during_time*fs;%s
seq_after_frame = seq_after_time*fs;%s

load_flag = true;

if load_flag
    seq_trial_cell = {};
    for k = 1:size(all_data_cell,1)
        tempname = all_data_cell{k,1};
        loadname = [tempname,'neutrial_seq_tpm.mat'];
        tempdata = load([beh_neu_path,'\',loadname]);
        seq_trial_cell = [seq_trial_cell;...
            tempdata.temp_trial_cell];
        disp(k)
    end
else
    for k = 1:size(all_data_cell,1)
        tempname = all_data_cell{k,1};
        tempneu = all_data_cell{k,2};
        tempseq = all_data_cell{k,5};
    
        savelist = idx2savelist(tempseq);
    
        savelist(:,1) = savelist(:,1)-before_frame;
        savelist(:,2) = savelist(:,2)+after_frame;
    
        savelist(savelist(:,1)<1,:) = [];
        savelist(savelist(:,2)>length(tempseq),:) = [];

        savelist(savelist(:,3)==0,:) = [];
        
        temp_trial_cell = {};
    
        for m = 1:size(savelist,1)
            start_pos = savelist(m,1);
            end_pos = savelist(m,2);
            movname = savelist(m,3);
            for n = 1:size(tempneu,2)
                neuname = n;
                newname = [tempname,'-',num2str(movname),'-',num2str(neuname)];
                cutneu = tempneu(start_pos:end_pos,n);
                before_neu = cutneu(1:before_frame);
                during_neu = cutneu((1+before_frame):(end-after_frame));
                after_neu = cutneu((1+end-after_frame):end);
    
                final_neu = [...
                    before_neu;...
                    imresize(during_neu,[during_frame,1]);...
                    after_neu;...
                    ]'-mean(before_neu);% float baseline
                temp_trial_cell = [temp_trial_cell;...
                    {newname,final_neu}];
            end
        end
        
        %% save
        save([beh_neu_path,'\',tempname,'neutrial_seq_tpm.mat'],...
            'temp_trial_cell')
        disp(k)
    end
end
%% calculate change labels of seq
seq_change_label_list = zeros(size(seq_trial_cell,1),1);
change_thres = 0.2;%std of baseline

boundary_thres = 0;% a torlerent of behavior noise
tic
for k = 1:size(seq_trial_cell,1)
    tempdata = seq_trial_cell{k,2};
    during_neu = tempdata(...
        (seq_before_frame+1-boundary_thres):...
        (length(tempdata)-seq_after_frame+boundary_thres));

    before_neu = tempdata(1:seq_before_frame);

    [h,p] = ttest2(during_neu,before_neu);

    % std_baseline = max(abs(baseline_neu));

    % max_neu = max(during_neu);
    % 
    % min_neu = min(during_neu);

    % mean_neu = mean(during_neu);

    if p<0.05
        mean_baseline_neu = mean(before_neu);
        mean_during_neu = mean(during_neu);

        if mean_baseline_neu>mean_during_neu
            seq_change_label_list(k,1) = -1;
        else
            seq_change_label_list(k,1) = 1;
        end
    else
    end

    % if mean_neu>(change_thres*std_baseline)
    %     change_label_list(k,1) = 1;
    % elseif (-1*mean_neu)>(change_thres*std_baseline)
    %     change_label_list(k,1) = -1;
    % end

    if rem(k,1000) == 0
        disp(k)
        toc
    end
end
toc
%% plot canvas
hall = figure(1);
set(hall,'Position',[680,0,800,800])
set(hall,'color','white');
%% show the correlations between poses 
% and neural activities
corr_cell = cell(size(all_data_cell,1),1);

for k = 1:size(all_data_cell,1)
    %%
    tempneu = all_data_cell{k,2};
    temppose = all_data_cell{k,3};
    %% neu corr
    corr_mat = zeros(size(size(tempneu,2),1),2);
    for m = 1:size(tempneu,2)
        tt_neu = tempneu(:,m);
        tempcorr = zeros(size(temppose,2),2);
        for n = 1:size(temppose,2)
            tt_pose = temppose(:,n);
            [r,p] = corrcoef(tt_neu,tt_pose);
            tempcorr(n,:) = [r(1,2),p(1,2)];
        end

        tempcorr(tempcorr(:,2)>=0.05,:) = [];

        max_corr = max(tempcorr(:,1));
        min_corr = min(tempcorr(:,1));

        if max_corr>abs(min_corr)
            corr_mat(m,1) = max_corr;
            corr_mat(m,2) = ...
                tempcorr(tempcorr(:,1)==max_corr,2);
        else
            corr_mat(m,1) = min_corr;
            corr_mat(m,2) = ...
                tempcorr(tempcorr(:,1)==min_corr,2);
        end
    end
    %% append data
    corr_cell{k,1} = corr_mat;
    disp(k)
end
%% show correlation distributions, 3 brain area
spl_name = split(all_data_cell(:,1),'-');
brain_name_list = cellfun(@(x) x(2:end),...
    spl_name(:,3),'UniformOutput',false);

unique_brain_name = {...
    'tpmss';...
    'tpmpfc';...
    'tpmm'};

corr_brain_list = cell(size(unique_brain_name,1),1);
for k = 1:size(unique_brain_name,1)
    tempname = unique_brain_name{k,1};
    selidx = strcmp(tempname,brain_name_list);

    selcorr = cell2mat(corr_cell(selidx,:));

    corr_brain_list{k,1} = selcorr(:,1);
end

% Fit Gaussian mixture model to data

GM_list = cell(size(corr_brain_list,1),1);
k_num = 2;
for k = 1:size(GM_list,1)
    GMModel = fitgmdist(...
        corr_brain_list{k,1},k_num);
    GM_list{k,1} = GMModel;
end
%% show correlation of poses
start_x = 0.03;
start_y = 0.87;

box_x = 0.2;
box_y = 0.12;

x_list = -1:0.01:1;

show_x_tick = -0.5:0.25:0.5;

neu_cmap = cbrewer2('Paired',12);

in_c = neu_cmap(5,:);
de_c = neu_cmap(1,:);
no_c = neu_cmap(3,:);

brain_c = [...
    de_c;...
    in_c;...
    no_c];

ind_c = [...
        in_c;...
        no_c;...
        de_c];

show_brain_name = {...
    'S1';...
    'dmPFC';...
    'M1'};

legend_h = cell(size(GM_list,1),1);

subplot('Position',[start_x,start_y,box_x,box_y])
for k = 1:size(GM_list,1)
    y = pdf(GM_list{k},x_list');
    legend_h{k,1} = ...
        plot(x_list,y,'-','Color',brain_c(k,:));
    hold on
end
hold off

axis([-0.5,0.5,0,4])
ylabel('Density')
xlabel('Neuron-pose correlation coefficient')

legend([legend_h{1},legend_h{2},legend_h{3}],...
    show_brain_name,'Box','off')

set(gca,'XTick',show_x_tick)

set(gca,'FontSize',6)
set(gca,'TickDir','out')

box off

%% calculate the ratio of each brain area
corr_thres = 0.1;

corr_ratio_brain_list = cell(size(corr_brain_list,1),1);

for k = 1:size(corr_ratio_brain_list,1)
    tempcorr = corr_brain_list{k,1};
    tempbw = zeros(size(tempcorr));
    tempbw(tempcorr>corr_thres) = 1;
    tempbw(tempcorr<(-1*corr_thres)) = -1;

    temptbl = tabulate(tempbw);

    pat_list = zeros(1,3);

    for m = 1:size(temptbl,1)
        if temptbl(m,1) == 1
            pat_list(1,1) = temptbl(m,3)/100;
        elseif temptbl(m,1) == 0
            pat_list(1,2) = temptbl(m,3)/100;
        elseif temptbl(m,1) == -1
            pat_list(1,3) = temptbl(m,3)/100;
        end
    end

    corr_ratio_brain_list{k,1} = pat_list;
end

%% show pies of correlations
start_x = 0.24;
start_y = 0.86;

box_x = 0.11;
box_y = box_x;

inter_x = 0.01;

show_ind_name_list = {...
    'Positive';...
    'Low';...
    'Negative'};

for k = 1:size(corr_ratio_brain_list,1)
    temptbl = corr_ratio_brain_list{k,1};
    subplot('Position',[...
        start_x+(k-1)*(box_x+inter_x),...
        start_y,box_x,box_y])
    piechart(temptbl,'ColorOrder',ind_c)
    title(show_brain_name{k})
    set(gca,'FontSize',6)
end

% show figure legend
leg_box_x = 0.02;
leg_box_y = 0.12;

subplot('Position',[...
        start_x+3*(box_x+inter_x),...
        start_y,leg_box_x,leg_box_y])
for k = 1:3
    plot([0,1],[k,k],'-','Color',ind_c(k,:),...
        'LineWidth',6)
    hold on
    text(1.2,k,show_ind_name_list{k},'FontSize',6)
end
hold off

axis off

axis([0,2,-5,3])

%% show coding space
corr_ratio_cell = cell(size(corr_cell,1),1);

for k = 1:size(corr_cell,1)
    tempcorr = corr_cell{k,1}(:,1);

    tempbw = zeros(size(tempcorr));
    tempbw(tempcorr>corr_thres) = 1;
    tempbw(tempcorr<(-1*corr_thres)) = -1;

    temptbl = tabulate(tempbw);

    pat_list = zeros(1,3);

    for m = 1:size(temptbl,1)
        if temptbl(m,1) == 1
            pat_list(1,1) = temptbl(m,3)/100;
        elseif temptbl(m,1) == 0
            pat_list(1,2) = temptbl(m,3)/100;
        elseif temptbl(m,1) == -1
            pat_list(1,3) = temptbl(m,3)/100;
        end
    end

    corr_ratio_cell{k,1} = pat_list;
end

corr_ratio_mat = cell2mat(corr_ratio_cell);
[coeff,score,latent,tsquared,explained] = ...
    pca(corr_ratio_mat);

show_brain_name_list = {...
    'tpmss';...
    'tpmpfc';...
    'tpmm'};

show_brain_vec = {...
    'S1 vector';...
    'dmPFC vector';...
    'M1 vector';...
    };

dot_size = 10;

cmaplist = zeros(size(brain_name_list,1),3);
for k = 1:size(show_brain_name_list,1)
    tempname = show_brain_name_list{k};
    selidx = strcmp(tempname,brain_name_list);
    cmaplist(selidx,:) = ones(sum(selidx),1)*...
        brain_c(k,:);
end

start_x = 0.7;
start_y = 0.87;

box_x = 0.12;
box_y = box_x;

subplot('Position',[start_x,start_y,box_x,box_y])
scatter(score(:,1),score(:,2),...
    dot_size*ones(size(score,1),1),cmaplist,'filled')
hold on
% show feature vector of each brain area

for k = 1:size(show_brain_name_list,1)
    tempbrain = show_brain_name_list{k};
    selidx = strcmp(tempbrain,brain_name_list);
    sel_score = score(selidx,1:2);
    mean_score = mean(sel_score);

    length_score = (max(abs(sel_score(:,1)))+...
        max(abs(sel_score(:,2))))/2*20;

    x = [0,mean_score(1)]*length_score;
    y = [0,mean_score(2)]*length_score;
    
    plot(x,y,'-','Color','k')
    hold on
    plot(x(2),y(2),'o','MarkerFaceColor',brain_c(k,:),...
        'MarkerEdgeColor','k','MarkerSize',4)
    hold on
    text(x(2),y(2),show_brain_vec{k},...
        'FontSize',6)
    hold on
end
hold off

grid on

set(gca,'TickDir','out')
set(gca,'FontSize',6)
xlabel('PC 1 (60.9%)')
ylabel('PC 2 (39.1%)')

% quantify the distance
start_x = 0.87;
start_y = 0.87;

box_x = 0.12;
box_y = box_x;

dist_bar_group = {...
    'tpmss','tpmm';...
    'tpmss','tpmpfc';...
    'tpmm','tpmpfc'};

bar_w = 0.6;
mk_size = 3;

x_list = 1:size(dist_bar_group,1);

x_label_list = {...
    'S1 - M1';...
    'S1 - dmPFC';...
    'M1 - dmPFC'};

stat_cell = cell(1,size(dist_bar_group,1));

subplot('Position',[start_x,start_y,box_x,box_y])
for k = 1:size(dist_bar_group,1)
    tempname1 = dist_bar_group{k,1};
    tempname2 = dist_bar_group{k,2};

    sel_c1 = brain_c(strcmp(tempname1,show_brain_name_list),:);
    sel_c2 = brain_c(strcmp(tempname2,show_brain_name_list),:);
    
    sel_c = (sel_c1+sel_c2)/2;

    selidx1 = strcmp(tempname1,brain_name_list);
    selidx2 = strcmp(tempname2,brain_name_list);

    sel_score1 = score(selidx1,1:2);
    sel_score2 = score(selidx2,1:2);

    close_dist_1 = zeros(size(sel_score1,1),1);
    close_dist_2 = zeros(size(sel_score2,1),1);

    for m = 1:size(close_dist_1,1)
        tempscore = sel_score1(m,:);
        distmat = pdist2(tempscore,sel_score2);
        close_dist_1(m,:) = min(distmat);
    end

    for m = 1:size(close_dist_2,1)
        tempscore = sel_score2(m,:);
        distmat = pdist2(tempscore,sel_score1);
        close_dist_2(m,:) = min(distmat);
    end

    close_dist = [close_dist_1;close_dist_2];
    

    stat_cell{k} = close_dist;

    mean_close_dist = mean(close_dist);

    std_close_dist = std(close_dist)./sqrt(length(close_dist));

    bar(x_list(k),mean_close_dist,...
        'FaceColor',sel_c,...
        'BarWidth',bar_w)
    hold on
    errorbar(x_list(k),mean_close_dist,std_close_dist,...
        'Color','k')
    hold on
    plot(bar_w/2+ones(length(close_dist),1)*x_list(k),...
        close_dist,...
        'o',...
        'MarkerFaceColor','w',...
        'MarkerEdgeColor','k',...
        'MarkerSize',mk_size,...
        'LineWidth',0.25)
    hold on
end

stat_mat = cell2mat(stat_cell);

hold off
axis([0.4,3.6,0,0.5])
box off
set(gca,'FontSize',6)
set(gca,'TickDir','out')
set(gca,'XTick',x_list)
set(gca,'XTickLabel',[])
ylabel('Feature distance')

%% create pose_ratio_cell
pose_ratio_cell = cell(size(corr_ratio_cell,1),3);
for k = 1:size(pose_ratio_cell,1)
    pose_ratio_cell{k,1} = corr_ratio_cell{k,1};
    pose_ratio_cell{k,2} = all_data_cell{k,1};
    pose_ratio_cell{k,3} = brain_name_list{k,1};
end

%% show the heatmap of mov
mov_spl_name = split(mov_trial_cell(:,1),'-');
mov_brain_name_list = cellfun(@(x) x(2:end),...
    mov_spl_name(:,3),'UniformOutput',false);

mov_brain_trial_cell = cell(size(unique_brain_name,1),3);

for k = 1:size(mov_brain_trial_cell,1)
    tempname = unique_brain_name{k,1};
    selidx = strcmp(tempname,mov_brain_name_list);
    selmov = cell2mat(mov_trial_cell(selidx,2));
    selchange = mov_change_label_list(selidx,:);

    mov_brain_trial_cell{k,1} = selmov;
    mov_brain_trial_cell{k,2} = selchange;
    mov_brain_trial_cell{k,3} = mov_trial_cell(selidx,1);
end
%% compare the coding at cell level
mov_brain_cell_cell = cell(size(mov_brain_trial_cell,1),3);

for k = 1:size(mov_brain_cell_cell,1)
    %%
    tempname = mov_brain_trial_cell{k,3};
    tempmat = mov_brain_trial_cell{k,1};
    unique_name = unique(tempname);

    mov_cell_change_list = zeros(size(unique_name,1),1);
    cellmat = zeros(size(unique_name,1),size(tempmat,2));
    
    tic
    for m = 1:size(unique_name,1)
        selidx = strcmp(unique_name{m,1},tempname);
        selmat = tempmat(selidx,:);
        tempdata = mean(selmat,1);

        cellmat(m,:) = tempdata;
        

        during_neu = tempdata(...
        (mov_before_frame+1-boundary_thres):...
        (length(tempdata)-mov_after_frame+boundary_thres));

        before_neu = tempdata(1:mov_before_frame);
    
        [h,p] = ttest2(during_neu,before_neu);
    
        % std_baseline = max(abs(baseline_neu));
    
        % max_neu = max(during_neu);
        % 
        % min_neu = min(during_neu);
    
        % mean_neu = mean(during_neu);
    
        if p<0.05
            mean_baseline_neu = mean(before_neu);
            mean_during_neu = mean(during_neu);
    
            if mean_baseline_neu>mean_during_neu
                mov_cell_change_list(m,1) = -1;
            else
                mov_cell_change_list(m,1) = 1;
            end
        else
        end

        if rem(m,1000) == 0
            disp(m)
            toc
        end
    end

    mov_brain_cell_cell{k,1} = cellmat;
    mov_brain_cell_cell{k,2} = mov_cell_change_list;
    mov_brain_cell_cell{k,3} = unique_name;
end
%% show
start_x = 0.03;
start_y = 0.74;

box_x = 0.2;
box_y = 0.08;

inter_y = 0.006;

ind_cmap = flipud(cbrewer2('RdBu',256));

c_range = 0.5;

x_tick_list = [1,60,120,180];
x_ticklabel_list = [-2,0,2,4];

for k = 1:size(mov_brain_cell_cell,1)
    temph = subplot('Position',[start_x,...
        start_y-(k-1)*(box_y+inter_y),...
        box_x,box_y]);
    tempmat = mov_brain_cell_cell{k,1};
    tempchange = mov_brain_cell_cell{k,2};
    [sortchange,sortidx] = sort(tempchange,'descend');
    change_idx = find(diff(sortchange)~=0);
    imagesc(tempmat(sortidx,:),[-c_range,c_range])
    colormap(ind_cmap)
    hold on
    plot([60,60],[0,size(tempmat,1)],'--k')
    hold on
    plot([120,120],[0,size(tempmat,1)],'--k')
    hold on
    plot([1,180],[change_idx(1),change_idx(1)],'--k')
    hold on
    plot([1,180],[change_idx(2),change_idx(2)],'--k')
    hold off

    box off

    set(gca,'XTick',x_tick_list)

    ylabel(['Neurons of ',show_brain_name{k}])

    if k == 3
        set(gca,'XTickLabel',x_ticklabel_list)
        % xlabel('Time (s)')
    else
        set(gca,'XTickLabel',[])
    end
    
    set(gca,'TickDir','out')
    set(gca,'FontSize',6)
end

%% calculate percentage at cell level
%% show pies 
start_x = 0.24;
start_y = 0.7;

box_x = 0.11;
box_y = box_x;

inter_x = 0.01;

show_ind_name_list = {...
    'Positive';...
    'Low';...
    'Negative'};

for k = 1:size(mov_brain_cell_cell,1)
    temptbl = tabulate(mov_brain_cell_cell{k,2});

    pat_list = zeros(1,3);

    for m = 1:size(temptbl,1)
        if temptbl(m,1) == 1
            pat_list(1,1) = temptbl(m,3)/100;
        elseif temptbl(m,1) == 0
            pat_list(1,2) = temptbl(m,3)/100;
        elseif temptbl(m,1) == -1
            pat_list(1,3) = temptbl(m,3)/100;
        end
    end
    
    subplot('Position',[...
        start_x+(k-1)*(box_x+inter_x),...
        start_y,box_x,box_y])
    piechart(pat_list,'ColorOrder',ind_c)
    title(show_brain_name{k})
    set(gca,'FontSize',6)
end

% show figure legend
leg_box_x = 0.02;
leg_box_y = 0.12;

subplot('Position',[...
        start_x+3*(box_x+inter_x),...
        start_y,leg_box_x,leg_box_y])
for k = 1:3
    plot([0,1],[k,k],'-','Color',ind_c(k,:),...
        'LineWidth',6)
    hold on
    text(1.2,k,show_ind_name_list{k},'FontSize',6)
end
hold off

axis off

axis([0,2,-5,3])
%% show the change trial in cell
mov_trial_cell_cell = cell(size(mov_brain_trial_cell,1),1);

for k = 1:size(mov_trial_cell_cell,1)
    tempchange = mov_brain_trial_cell{k,2};
    tempname = mov_brain_trial_cell{k,3};
    unique_name = unique(tempname);

    cell_change = cell(size(unique_name,1),1);
    for n = 1:size(unique_name,1)
        selidx = strcmp(unique_name{n},tempname);
        selchange = tempchange(selidx);
        temptbl = tabulate(selchange);

        pat_list = zeros(1,3);

        for m = 1:size(temptbl,1)
            if temptbl(m,1) == 1
                pat_list(1,1) = temptbl(m,3)/100;
            elseif temptbl(m,1) == 0
                pat_list(1,2) = temptbl(m,3)/100;
            elseif temptbl(m,1) == -1
                pat_list(1,3) = temptbl(m,3)/100;
            end
        end

        cell_change{n,1} = pat_list;
    end

    cell_change_mat = cell2mat(cell_change);

    mov_trial_cell_cell{k,1} = cell_change_mat;
end
%% show pca
start_x = 0.25;
start_y = 0.57;

box_x = 0.1;
box_y = box_x;

inter_x = 0.02;

show_ind_name_list = {...
    'Positive';...
    'Low';...
    'Negative'};

for k = 1:size(mov_trial_cell_cell,1)
    temptbl = mov_trial_cell_cell{k,1};

    [coeff,score,~,~,explained] = ...
    pca(temptbl);
    
    subplot('Position',[...
        start_x+(k-1)*(box_x+inter_x),...
        start_y,box_x,box_y])
    scatter(score(:,1),score(:,2),...
        ones(size(score,1),1),...
        0.7*ones(size(score,1),3),'filled')
    hold on
    for m = 1:size(coeff,1)
        plot([0,coeff(m,1)],[0,coeff(m,2)],'-',...
            'Color',ind_c(m,:))
        hold on
        plot(coeff(m,1),coeff(m,2),'o',...
            'MarkerFaceColor',ind_c(m,:),...
            'MarkerEdgeColor','k',...
            'MarkerSize',5)
        hold on
        text(coeff(m,1),coeff(m,2),show_ind_name_list{m},...
            'FontSize',6)
        hold on
    end
    hold off
    axis([-1,1,-1,1])
    box on
    set(gca,'XTick',[],'YTick',[])

    xlabel(['PC 1 (',num2str(explained(1),3),'%)'])
    ylabel(['PC 2 (',num2str(explained(2),3),'%)'])

    set(gca,'FontSize',6)

    box off
end

%% show coding space of mov
mov_ratio_cell = {};

for k = 1:size(mov_brain_cell_cell,1)
    tempname = mov_brain_cell_cell{k,3};
    splname = split(tempname,'-');
    mouse_name = cellfun(@(a,b,c,d,e) ...
        [a,'-',b,'-',c,'-',d,'-',e],...
        splname(:,1),splname(:,2),...
        splname(:,3),splname(:,4),...
        splname(:,5),'UniformOutput',false);
    unique_mouse_name = unique(mouse_name);

    brain_area = splname{1,3}(2:end);

    tempcode = mov_brain_cell_cell{k,2};

    mouse_code = cell(size(unique_mouse_name,1),1);

    for m = 1:size(unique_mouse_name,1)
        selidx = strcmp(unique_mouse_name{m},mouse_name);
        selcode = tempcode(selidx,1);

        temptbl = tabulate(selcode);

        pat_list = zeros(1,3);

        for n = 1:size(temptbl,1)
            if temptbl(n,1) == 1
                pat_list(1,1) = temptbl(n,3)/100;
            elseif temptbl(n,1) == 0
                pat_list(1,2) = temptbl(n,3)/100;
            elseif temptbl(n,1) == -1
                pat_list(1,3) = temptbl(n,3)/100;
            end
        end

        mouse_code{m,1} = pat_list;

        mov_ratio_cell = [mov_ratio_cell;...
            {mouse_code{m,1},unique_mouse_name{m},brain_area}];
    end
end

mov_ratio_mat = cell2mat(mov_ratio_cell(:,1));

[coeff,score,latent,tsquared,explained] = ...
    pca(mov_ratio_mat);

show_brain_name_list = {...
    'tpmss';...
    'tpmpfc';...
    'tpmm'};

show_brain_vec = {...
    'S1 vector';...
    'dmPFC vector';...
    'M1 vector';...
    };

dot_size = 10;

cmaplist = zeros(size(mov_ratio_mat,1),3);
for k = 1:size(show_brain_name_list,1)
    tempname = show_brain_name_list{k};
    selidx = strcmp(tempname,mov_ratio_cell(:,3));
    cmaplist(selidx,:) = ones(sum(selidx),1)*...
        brain_c(k,:);
end

start_x = 0.7;
start_y = 0.71;

box_x = 0.12;
box_y = box_x;

subplot('Position',[start_x,start_y,box_x,box_y])
scatter(score(:,1),score(:,2),...
    dot_size*ones(size(score,1),1),cmaplist,'filled')
hold on
% show feature vector of each brain area

for k = 1:size(show_brain_name_list,1)
    tempbrain = show_brain_name_list{k};
    selidx = strcmp(tempbrain,mov_ratio_cell(:,3));
    sel_score = score(selidx,1:2);
    mean_score = mean(sel_score);

    length_score = (max(abs(sel_score(:,1)))+...
        max(abs(sel_score(:,2))))/2*50;

    x = [0,mean_score(1)]*length_score;
    y = [0,mean_score(2)]*length_score;
    
    plot(x,y,'-','Color','k')
    hold on
    plot(x(2),y(2),'o','MarkerFaceColor',brain_c(k,:),...
        'MarkerEdgeColor','k','MarkerSize',4)
    hold on
    text(x(2),y(2),show_brain_vec{k},...
        'FontSize',6)
    hold on
end
hold off

grid on

set(gca,'TickDir','out')
set(gca,'FontSize',6)
xlabel('PC 1 (60.9%)')
ylabel('PC 2 (39.1%)')

% quantify the distance
start_x = 0.87;
start_y = 0.71;

box_x = 0.12;
box_y = box_x;

dist_bar_group = {...
    'tpmss','tpmm';...
    'tpmss','tpmpfc';...W
    'tpmm','tpmpfc'};

bar_w = 0.6;
mk_size = 3;

x_list = 1:size(dist_bar_group,1);

x_label_list = {...
    'S1 - M1';...
    'S1 - dmPFC';...
    'M1 - dmPFC'};

show_star = {...
    1,2,'*',0.08};

stat_cell = cell(1,size(dist_bar_group,1));

subplot('Position',[start_x,start_y,box_x,box_y])
for k = 1:size(dist_bar_group,1)
    tempname1 = dist_bar_group{k,1};
    tempname2 = dist_bar_group{k,2};

    sel_c1 = brain_c(strcmp(tempname1,show_brain_name_list),:);
    sel_c2 = brain_c(strcmp(tempname2,show_brain_name_list),:);
    
    sel_c = (sel_c1+sel_c2)/2;

    selidx1 = strcmp(tempname1,mov_ratio_cell(:,3));
    selidx2 = strcmp(tempname2,mov_ratio_cell(:,3));

    sel_score1 = score(selidx1,1:2);
    sel_score2 = score(selidx2,1:2);

    close_dist_1 = zeros(size(sel_score1,1),1);
    close_dist_2 = zeros(size(sel_score2,1),1);

    for m = 1:size(close_dist_1,1)
        tempscore = sel_score1(m,:);
        distmat = pdist2(tempscore,sel_score2);
        close_dist_1(m,:) = min(distmat);
    end

    for m = 1:size(close_dist_2,1)
        tempscore = sel_score2(m,:);
        distmat = pdist2(tempscore,sel_score1);
        close_dist_2(m,:) = min(distmat);
    end

    close_dist = [close_dist_1;close_dist_2];

    stat_cell{k} = close_dist;

    mean_close_dist = mean(close_dist);

    std_close_dist = std(close_dist)./sqrt(length(close_dist));

    bar(x_list(k),mean_close_dist,...
        'FaceColor',sel_c,...
        'BarWidth',bar_w)
    hold on
    errorbar(x_list(k),mean_close_dist,std_close_dist,...
        'Color','k')
    hold on
    plot(bar_w/2+ones(length(close_dist),1)*x_list(k),...
        close_dist,...
        'o',...
        'MarkerFaceColor','w',...
        'MarkerEdgeColor','k',...
        'MarkerSize',mk_size,...
        'LineWidth',0.25)
    hold on
    % show star
    plot([show_star{1},show_star{2}],...
        [show_star{4},show_star{4}],'-k',...
        'LineWidth',0.25)
    hold on
    text((show_star{1}+show_star{2})/2,show_star{4},...
        show_star{3},'VerticalAlignment','bottom',...
        'HorizontalAlignment','center')
    hold on
end

stat_mat = cell2mat(stat_cell);

hold off
axis([0.4,3.6,0,0.08])
box off
set(gca,'FontSize',6)
set(gca,'TickDir','out')
set(gca,'XTick',x_list)
set(gca,'XTickLabel',x_label_list)
ylabel('Feature distance')

%% show the distance between three changes
start_x = 0.65;
start_y = 0.57;

box_x = 0.1;
box_y = 0.09;

inter_x = 0.02;

for k = 1:size(mov_trial_cell_cell,1)
    temptbl = mov_trial_cell_cell{k,1};

    [coeff,score,~,~,explained] = ...
    pca(temptbl);

    neu_pos = score(:,1:2);

    cent_pos = coeff(:,1:2);

    dist_cell = cell(size(cent_pos,1),1);
    for m = 1:size(dist_cell,1)
        tempcent = cent_pos(m,:);
        tempdist = pdist2(tempcent,neu_pos);
        dist_cell{m,1} = tempdist';
    end
    
    subplot('Position',[...
        start_x+(k-1)*(box_x+inter_x),...
        start_y,box_x,box_y])

    legend_cell = cell(size(dist_cell,1),1);
    for m = 1:size(dist_cell,1)
        tempdist = dist_cell{m,1};

        xlist = 0:0.001:1.5;

        [F,XI]= ksdensity(tempdist,xlist);

        legend_cell{m} = plot(XI,F,'-','Color',ind_c(m,:));
        hold on
    end
    hold off
    
    axis([0,1.5,0,2.5])

    box off

    if k == 1
        legend([legend_cell{1},legend_cell{2},legend_cell{3}],...
            show_ind_name_list,'Box','off')
        ylabel('Density')
    else
        set(gca,'YTickLabel',[])
    end

    xlabel(show_brain_name{k})

    set(gca,'FontSize',6)
    set(gca,'TickDir','out')
end

%% show the heatmap of seq
seq_spl_name = split(seq_trial_cell(:,1),'-');
seq_brain_name_list = cellfun(@(x) x(2:end),...
    seq_spl_name(:,3),'UniformOutput',false);

seq_brain_trial_cell = cell(size(unique_brain_name,1),3);

for k = 1:size(seq_brain_trial_cell,1)
    tempname = unique_brain_name{k,1};
    selidx = strcmp(tempname,seq_brain_name_list);
    selseq = cell2mat(seq_trial_cell(selidx,2));
    selchange = seq_change_label_list(selidx,:);

    seq_brain_trial_cell{k,1} = selseq;
    seq_brain_trial_cell{k,2} = selchange;
    seq_brain_trial_cell{k,3} = seq_trial_cell(selidx,1);
end
%% compare the coding at cell level
seq_brain_cell_cell = cell(size(seq_brain_trial_cell,1),3);

for k = 1:size(seq_brain_cell_cell,1)
    %%
    tempname = seq_brain_trial_cell{k,3};
    tempmat = seq_brain_trial_cell{k,1};
    unique_name = unique(tempname);

    seq_cell_change_list = zeros(size(unique_name,1),1);
    cellmat = zeros(size(unique_name,1),size(tempmat,2));
    
    tic
    for m = 1:size(unique_name,1)
        selidx = strcmp(unique_name{m,1},tempname);
        selmat = tempmat(selidx,:);
        tempdata = mean(selmat,1);

        cellmat(m,:) = tempdata;
        

        during_neu = tempdata(...
        (seq_before_frame+1-boundary_thres):...
        (length(tempdata)-seq_after_frame+boundary_thres));

        before_neu = tempdata(1:seq_before_frame);
    
        [h,p] = ttest2(during_neu,before_neu);
    
        % std_baseline = max(abs(baseline_neu));
    
        % max_neu = max(during_neu);
        % 
        % min_neu = min(during_neu);
    
        % mean_neu = mean(during_neu);
    
        if p<0.05
            mean_baseline_neu = mean(before_neu);
            mean_during_neu = mean(during_neu);
    
            if mean_baseline_neu>mean_during_neu
                seq_cell_change_list(m,1) = -1;
            else
                seq_cell_change_list(m,1) = 1;
            end
        else
        end

        if rem(m,1000) == 0
            disp(m)
            toc
        end
    end

    seq_brain_cell_cell{k,1} = cellmat;
    seq_brain_cell_cell{k,2} = seq_cell_change_list;
    seq_brain_cell_cell{k,3} = unique_name;
end
%% show
start_x = 0.03;
start_y = 0.45;

box_x = 0.2;
box_y = 0.08;

inter_y = 0.006;

ind_cmap = flipud(cbrewer2('RdBu',256));

c_range = 0.5;

x_tick_list = [1,300,600,900];
x_ticklabel_list = [-10,0,10,20];

for k = 1:size(seq_brain_cell_cell,1)
    temph = subplot('Position',[start_x,...
        start_y-(k-1)*(box_y+inter_y),...
        box_x,box_y]);
    tempmat = seq_brain_cell_cell{k,1};
    tempchange = seq_brain_cell_cell{k,2};
    [sortchange,sortidx] = sort(tempchange,'descend');
    change_idx = find(diff(sortchange)~=0);
    imagesc(tempmat(sortidx,:),[-c_range,c_range])
    colormap(ind_cmap)
    hold on
    plot([300,300],[0,size(tempmat,1)],'--k')
    hold on
    plot([600,600],[0,size(tempmat,1)],'--k')
    hold on
    plot([1,900],[change_idx(1),change_idx(1)],'--k')
    hold on
    plot([1,900],[change_idx(2),change_idx(2)],'--k')
    hold off

    box off

    set(gca,'XTick',x_tick_list)

    ylabel(['Neurons of ',show_brain_name{k}])

    if k == 3
        set(gca,'XTickLabel',x_ticklabel_list)
        xlabel('Time (s)')
    else
        set(gca,'XTickLabel',[])
    end
    
    ax = gca;
    ax.YAxis.Exponent = 4;
    set(gca,'TickDir','out')
    set(gca,'FontSize',6)
end

% show colorbar
cbar_box_x = 0.05;
cbar_box_y = 0.006;

cbar_inter_y = 0.005;

subplot('Position',[...
    start_x+box_x-cbar_box_x,...
    start_y+box_y+cbar_inter_y,...
    cbar_box_x,cbar_box_y])
imagesc(1:256)
box on
set(gca,'XTick',[],'YTick',[])
title('-0.5  Δ(ΔF/F)  0.5')

%% calculate percentage at cell level
%% show pies 
start_x = 0.24;
start_y = 0.41;

box_x = 0.11;
box_y = box_x;

inter_x = 0.01;

show_ind_name_list = {...
    'Positive';...
    'Low';...
    'Negative'};

for k = 1:size(seq_brain_cell_cell,1)
    temptbl = tabulate(seq_brain_cell_cell{k,2});

    pat_list = zeros(1,3);

    for m = 1:size(temptbl,1)
        if temptbl(m,1) == 1
            pat_list(1,1) = temptbl(m,3)/100;
        elseif temptbl(m,1) == 0
            pat_list(1,2) = temptbl(m,3)/100;
        elseif temptbl(m,1) == -1
            pat_list(1,3) = temptbl(m,3)/100;
        end
    end
    
    subplot('Position',[...
        start_x+(k-1)*(box_x+inter_x),...
        start_y,box_x,box_y])
    piechart(pat_list,'ColorOrder',ind_c)
    title(show_brain_name{k})
    set(gca,'FontSize',6)
end

% show figure legend
leg_box_x = 0.02;
leg_box_y = 0.12;

subplot('Position',[...
        start_x+3*(box_x+inter_x),...
        start_y,leg_box_x,leg_box_y])
for k = 1:3
    plot([0,1],[k,k],'-','Color',ind_c(k,:),...
        'LineWidth',6)
    hold on
    text(1.2,k,show_ind_name_list{k},'FontSize',6)
end
hold off

axis off

axis([0,2,-5,3])
%% show the change trial in cell
seq_trial_cell_cell = cell(size(seq_brain_trial_cell,1),1);

for k = 1:size(seq_trial_cell_cell,1)
    tempchange = seq_brain_trial_cell{k,2};
    tempname = seq_brain_trial_cell{k,3};
    unique_name = unique(tempname);

    cell_change = cell(size(unique_name,1),1);
    for n = 1:size(unique_name,1)
        selidx = strcmp(unique_name{n},tempname);
        selchange = tempchange(selidx);
        temptbl = tabulate(selchange);

        pat_list = zeros(1,3);

        for m = 1:size(temptbl,1)
            if temptbl(m,1) == 1
                pat_list(1,1) = temptbl(m,3)/100;
            elseif temptbl(m,1) == 0
                pat_list(1,2) = temptbl(m,3)/100;
            elseif temptbl(m,1) == -1
                pat_list(1,3) = temptbl(m,3)/100;
            end
        end

        cell_change{n,1} = pat_list;
    end

    cell_change_mat = cell2mat(cell_change);

    seq_trial_cell_cell{k,1} = cell_change_mat;
end
%% show pca
start_x = 0.25;
start_y = 0.28;

box_x = 0.1;
box_y = box_x;

inter_x = 0.02;

show_ind_name_list = {...
    'Positive';...
    'Low';...
    'Negative'};

for k = 1:size(seq_trial_cell_cell,1)
    temptbl = seq_trial_cell_cell{k,1};

    [coeff,score,~,~,explained] = ...
    pca(temptbl);
    
    subplot('Position',[...
        start_x+(k-1)*(box_x+inter_x),...
        start_y,box_x,box_y])
    scatter(score(:,1),score(:,2),...
        ones(size(score,1),1),...
        0.7*ones(size(score,1),3),'filled')
    hold on
    for m = 1:size(coeff,1)
        plot([0,coeff(m,1)],[0,coeff(m,2)],'-',...
            'Color',ind_c(m,:))
        hold on
        plot(coeff(m,1),coeff(m,2),'o',...
            'MarkerFaceColor',ind_c(m,:),...
            'MarkerEdgeColor','k',...
            'MarkerSize',5)
        hold on
        text(coeff(m,1),coeff(m,2),show_ind_name_list{m},...
            'FontSize',6)
        hold on
    end
    hold off
    axis([-1,1,-1,1])
    box on
    set(gca,'XTick',[],'YTick',[])

    xlabel(['PC 1 (',num2str(explained(1),3),'%)'])
    ylabel(['PC 2 (',num2str(explained(2),3),'%)'])

    set(gca,'FontSize',6)

    box off
end
%% show coding space of seq
seq_ratio_cell = {};

for k = 1:size(seq_brain_cell_cell,1)
    tempname = seq_brain_cell_cell{k,3};
    splname = split(tempname,'-');
    mouse_name = cellfun(@(a,b,c,d,e) ...
        [a,'-',b,'-',c,'-',d,'-',e],...
        splname(:,1),splname(:,2),...
        splname(:,3),splname(:,4),...
        splname(:,5),'UniformOutput',false);
    unique_mouse_name = unique(mouse_name);

    brain_area = splname{1,3}(2:end);

    tempcode = seq_brain_cell_cell{k,2};

    mouse_code = cell(size(unique_mouse_name,1),1);

    for m = 1:size(unique_mouse_name,1)
        selidx = strcmp(unique_mouse_name{m},mouse_name);
        selcode = tempcode(selidx,1);

        temptbl = tabulate(selcode);

        pat_list = zeros(1,3);

        for n = 1:size(temptbl,1)
            if temptbl(n,1) == 1
                pat_list(1,1) = temptbl(n,3)/100;
            elseif temptbl(n,1) == 0
                pat_list(1,2) = temptbl(n,3)/100;
            elseif temptbl(n,1) == -1
                pat_list(1,3) = temptbl(n,3)/100;
            end
        end

        mouse_code{m,1} = pat_list;

        seq_ratio_cell = [seq_ratio_cell;...
            {mouse_code{m,1},unique_mouse_name{m},brain_area}];
    end
end

seq_ratio_mat = cell2mat(seq_ratio_cell(:,1));

[coeff,score,latent,tsquared,explained] = ...
    pca(seq_ratio_mat);

show_brain_name_list = {...
    'tpmss';...
    'tpmpfc';...
    'tpmm'};

show_brain_vec = {...
    'S1 vector';...
    'dmPFC vector';...
    'M1 vector';...
    };

dot_size = 10;

cmaplist = zeros(size(seq_ratio_mat,1),3);
for k = 1:size(show_brain_name_list,1)
    tempname = show_brain_name_list{k};
    selidx = strcmp(tempname,seq_ratio_cell(:,3));
    cmaplist(selidx,:) = ones(sum(selidx),1)*...
        brain_c(k,:);
end

start_x = 0.7;
start_y = 0.41;

box_x = 0.12;
box_y = box_x;

subplot('Position',[start_x,start_y,box_x,box_y])
scatter(score(:,1),score(:,2),...
    dot_size*ones(size(score,1),1),cmaplist,'filled')
hold on
% show feature vector of each brain area

for k = 1:size(show_brain_name_list,1)
    tempbrain = show_brain_name_list{k};
    selidx = strcmp(tempbrain,seq_ratio_cell(:,3));
    sel_score = score(selidx,1:2);
    mean_score = mean(sel_score);

    length_score = (max(abs(sel_score(:,1)))+...
        max(abs(sel_score(:,2))))/2*30;

    x = [0,mean_score(1)]*length_score;
    y = [0,mean_score(2)]*length_score;
    
    plot(x,y,'-','Color','k')
    hold on
    plot(x(2),y(2),'o','MarkerFaceColor',brain_c(k,:),...
        'MarkerEdgeColor','k','MarkerSize',4)
    hold on
    text(x(2),y(2),show_brain_vec{k},...
        'FontSize',6)
    hold on
end
hold off

grid on

set(gca,'TickDir','out')
set(gca,'FontSize',6)
xlabel('PC 1 (60.9%)')
ylabel('PC 2 (39.1%)')

% quantify the distance
start_x = 0.87;
start_y = 0.41;

box_x = 0.12;
box_y = box_x;

dist_bar_group = {...
    'tpmss','tpmm';...
    'tpmss','tpmpfc';...
    'tpmm','tpmpfc'};

bar_w = 0.6;
mk_size = 3;

x_list = 1:size(dist_bar_group,1);

x_label_list = {...
    'S1 - M1';...
    'S1 - dmPFC';...
    'M1 - dmPFC'};

show_star = {...
    1,2,'***',0.09;...
    1,3,'*',0.11};

stat_cell = cell(1,size(dist_bar_group,1));

subplot('Position',[start_x,start_y,box_x,box_y])
for k = 1:size(dist_bar_group,1)
    tempname1 = dist_bar_group{k,1};
    tempname2 = dist_bar_group{k,2};

    sel_c1 = brain_c(strcmp(tempname1,show_brain_name_list),:);
    sel_c2 = brain_c(strcmp(tempname2,show_brain_name_list),:);
    
    sel_c = (sel_c1+sel_c2)/2;

    selidx1 = strcmp(tempname1,seq_ratio_cell(:,3));
    selidx2 = strcmp(tempname2,seq_ratio_cell(:,3));

    sel_score1 = score(selidx1,1:2);
    sel_score2 = score(selidx2,1:2);

    close_dist_1 = zeros(size(sel_score1,1),1);
    close_dist_2 = zeros(size(sel_score2,1),1);

    for m = 1:size(close_dist_1,1)
        tempscore = sel_score1(m,:);
        distmat = pdist2(tempscore,sel_score2);
        close_dist_1(m,:) = min(distmat);
    end

    for m = 1:size(close_dist_2,1)
        tempscore = sel_score2(m,:);
        distmat = pdist2(tempscore,sel_score1);
        close_dist_2(m,:) = min(distmat);
    end

    close_dist = [close_dist_1;close_dist_2];

    stat_cell{k} = close_dist;

    mean_close_dist = mean(close_dist);

    std_close_dist = std(close_dist)./sqrt(length(close_dist));

    bar(x_list(k),mean_close_dist,...
        'FaceColor',sel_c,...
        'BarWidth',bar_w)
    hold on
    errorbar(x_list(k),mean_close_dist,std_close_dist,...
        'Color','k')
    hold on
    plot(bar_w/2+ones(length(close_dist),1)*x_list(k),...
        close_dist,...
        'o',...
        'MarkerFaceColor','w',...
        'MarkerEdgeColor','k',...
        'MarkerSize',mk_size,...
        'LineWidth',0.25)
    hold on
    % show star
    for m = 1:size(show_star,1)
        plot([show_star{m,1},show_star{m,2}],...
            [show_star{m,4},show_star{m,4}],'-k',...
            'LineWidth',0.25)
        hold on
        text((show_star{m,1}+show_star{m,2})/2,show_star{m,4},...
            show_star{m,3},'VerticalAlignment','bottom',...
            'HorizontalAlignment','center')
        hold on
    end
end

stat_mat = cell2mat(stat_cell);

hold off
axis([0.4,3.6,0,0.12])
box off
set(gca,'FontSize',6)
set(gca,'TickDir','out')
set(gca,'XTick',x_list)
set(gca,'XTickLabel',x_label_list)
ylabel('Feature distance')


%% show the distance between three changes
start_x = 0.65;
start_y = 0.28;

box_x = 0.1;
box_y = 0.09;

inter_x = 0.02;

for k = 1:size(seq_trial_cell_cell,1)
    temptbl = seq_trial_cell_cell{k,1};

    [coeff,score,~,~,explained] = ...
    pca(temptbl);

    neu_pos = score(:,1:2);

    cent_pos = coeff(:,1:2);

    dist_cell = cell(size(cent_pos,1),1);
    for m = 1:size(dist_cell,1)
        tempcent = cent_pos(m,:);
        tempdist = pdist2(tempcent,neu_pos);
        dist_cell{m,1} = tempdist';
    end
    
    subplot('Position',[...
        start_x+(k-1)*(box_x+inter_x),...
        start_y,box_x,box_y])

    legend_cell = cell(size(dist_cell,1),1);
    for m = 1:size(dist_cell,1)
        tempdist = dist_cell{m,1};

        xlist = 0:0.001:1.5;

        [F,XI]= ksdensity(tempdist,xlist);

        legend_cell{m} = plot(XI,F,'-','Color',ind_c(m,:));
        hold on
    end
    hold off
    
    axis([0,1.5,0,4])

    box off

    if k == 1
        legend([legend_cell{1},legend_cell{2},legend_cell{3}],...
            show_ind_name_list,'Box','off')
        ylabel('Density')
    else
        set(gca,'YTickLabel',[])
    end

    xlabel(show_brain_name{k})

    set(gca,'FontSize',6)
    set(gca,'TickDir','out')
end

%% show the comparison across pose, mov, and seq
all_ratio_cell = [...
    pose_ratio_cell;mov_ratio_cell;seq_ratio_cell];

for k = 1:15
    all_ratio_cell{k,4} = 'pose';
end

for k = 16:30
    all_ratio_cell{k,4} = 'mov';
end

for k = 31:45
    all_ratio_cell{k,4} = 'seq';
end

all_ratio_mat = cell2mat(all_ratio_cell(:,1));
all_ratio_mat(1:15,:) = mat2gray(all_ratio_mat(1:15,:));
all_ratio_mat(16:30,:) = mat2gray(all_ratio_mat(16:30,:));
all_ratio_mat(31:45,:) = mat2gray(all_ratio_mat(31:45,:));

for k = 1:size(all_ratio_cell,1)
    all_ratio_cell{k,1} = all_ratio_mat(k,:);
end

[coeff,score,~,~,explained] = ...
    pca(all_ratio_mat);

start_x = 0.03;
start_y = 0.1;

box_x = 0.56;
box_y = 0.14;

brain_c = [...
    de_c;...
    in_c;...
    no_c];

subplot('Position',[start_x,start_y,box_x,box_y])
% plot line first
unique_mice_name = unique(all_ratio_cell(:,2));

for m = 1:size(coeff,1)
    plot([0,coeff(m,1)],[0,coeff(m,2)],'-',...
        'Color','k')
    hold on
    plot(coeff(m,1),coeff(m,2),'o',...
        'MarkerFaceColor',0.7*ones(1,3),...
        'MarkerEdgeColor','k',...
        'MarkerSize',5)
    hold on
    text(coeff(m,1),coeff(m,2),show_ind_name_list{m},...
        'FontSize',6)
    hold on
end
hold on

for k = 1:size(unique_mice_name,1)
    selidx = strcmp(...
        unique_mice_name{k,1},all_ratio_cell(:,2));
    selbrain = unique(all_ratio_cell(selidx,3));
    selscore = score(selidx,1:2);

    if strcmp(selbrain,'tpmss')
        show_c = brain_c(1,:);    
    elseif strcmp(selbrain,'tpmpfc')
        show_c = brain_c(2,:); 
    elseif strcmp(selbrain,'tpmm')
        show_c = brain_c(3,:); 
    end

    plot(selscore(:,1),selscore(:,2),'-',...
        'Color',show_c)
    hold on
end
hold on

%
for k = 1:size(score,1)
    if strcmp(all_ratio_cell{k,4},'pose')
        mk = 'o';
    elseif strcmp(all_ratio_cell{k,4},'mov')
        mk = '^';
    elseif strcmp(all_ratio_cell{k,4},'seq')
        mk = 'd';
    end

    if strcmp(all_ratio_cell{k,3},'tpmss')
        show_c = brain_c(1,:);    
    elseif strcmp(all_ratio_cell{k,3},'tpmpfc')
        show_c = brain_c(2,:); 
    elseif strcmp(all_ratio_cell{k,3},'tpmm')
        show_c = brain_c(3,:); 
    end

    temph = plot(score(k,1),score(k,2),mk,...
        'MarkerEdgeColor',show_c,...
        'MarkerFaceColor',show_c,...
        'MarkerSize',5);
    hold on
end
hold off


xy_edge = 0.01;

% axis([...
%     min(score(:,1))-xy_edge,...
%     max(score(:,1))+xy_edge,...
%     min(score(:,2))-xy_edge,...
%     max(score(:,2))+xy_edge])

box off
set(gca,'TickDir','out')
set(gca,'FontSize',6)

grid on
% set(gca,'XTickLabel',[],'YTickLabel',[])

xlabel(['PC 1 (',num2str(explained(1),3),'%)'])
ylabel(['PC 2 (',num2str(explained(2),3),'%)'])

%% independent condition comparison
all_dist = pdist2(score(:,1:2),coeff(:,1:2));

low_dist = all_dist(:,2);

comb_cond = cellfun(@(x,y) [x,'-',y],...
    all_ratio_cell(:,3),all_ratio_cell(:,4),...
    'UniformOutput',false);

unique_comb_cond = unique(comb_cond);

cond_dist_cell = cell(size(unique_comb_cond,1),8);
cond_dist_cell(:,1) = unique_comb_cond;

show_level = {...
    'pose','Pose';...
    'mov','Move';...
    'seq','Seq'};

for k = 1:size(cond_dist_cell,1)
    tempname = unique_comb_cond{k,1};
    selidx = strcmp(tempname,comb_cond);
    cond_dist_cell{k,2} = low_dist(selidx);
    cond_dist_cell{k,3} = mean(cond_dist_cell{k,2});
    cond_dist_cell{k,4} = std(cond_dist_cell{k,2})./sqrt(5);
    
    splname = split(tempname,'-');

    cond_dist_cell{k,5} = splname{1};
    cond_dist_cell{k,6} = splname{2};

    brainidx = strcmp(cond_dist_cell{k,5},show_brain_name_list);
    levelidx = strcmp(cond_dist_cell{k,6},show_level(:,1));

    cond_dist_cell{k,7} = [...
        show_brain_name{brainidx},'-',show_level{levelidx,2}];

    cond_dist_cell{k,8} = brain_c(brainidx,:);
end

[~,sort_idx] = sort(cell2mat(cond_dist_cell(:,3)),'descend');

sort_cond_dist_cell = cond_dist_cell(sort_idx,:);

% show
start_x = 0.65;
start_y = 0.12;

box_x = 0.34;
box_y = 0.12;

x_bias = 0.3;
bar_w = 0.6;

mk_size = 3;

show_star = {...
    1,3,'**',1.3;...
    1,4,'**',1.1;...
    2,6,'*',0.9};

subplot('Position',[start_x,start_y,box_x,box_y])
for k = 1:size(sort_cond_dist_cell,1)
    tempy = sort_cond_dist_cell{k,2};
    bar(k,sort_cond_dist_cell{k,3},bar_w,...
        'FaceColor',sort_cond_dist_cell{k,8})
    hold on
    errorbar(k,sort_cond_dist_cell{k,3},...
        sort_cond_dist_cell{k,4},'Color','k')
    hold on
    plot(k*ones(length(tempy),1)+x_bias,tempy,'o',...
        'MarkerFaceColor','w',...
        'MarkerEdgeColor','k',...
        'LineWidth',0.25,'MarkerSize',mk_size)
    hold on
end

% show star
for m = 1:size(show_star,1)
    plot([show_star{m,1},show_star{m,2}],...
        [show_star{m,4},show_star{m,4}],'-k',...
        'LineWidth',0.25)
    hold on
    text((show_star{m,1}+show_star{m,2})/2,show_star{m,4},...
        show_star{m,3},'VerticalAlignment','bottom',...
        'HorizontalAlignment','center')
    hold on
end
hold off

axis([0.3,9.7,0,1.4])

box off

ylabel('Distance to Low')

set(gca,'XTick',1:size(sort_cond_dist_cell,1))
set(gca,'XTickLabel',sort_cond_dist_cell(:,7))
set(gca,'TickDir','out')
set(gca,'FontSize',6)












