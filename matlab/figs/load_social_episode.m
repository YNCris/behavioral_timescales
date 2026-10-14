%{
    读取社交部分数据
%}
clear all
close all
addpath(genpath(pwd))

rmpath(['Z:\hanyaning\multi_mice_test\Social_analysis\' ...
    'code\SBeA_Analysis\SBeA_v0.0.1\TPM\figs\function\' ...
    'gtw\lib\subspace']);
rmpath(['Z:\hanyaning\multi_mice_test\Social_analysis\' ...
    'code\SBeA_Analysis\SBeA_v0.0.1\TPM\figs\old\function\' ...
    'gtw\lib\subspace']);
%% set path
rootpath = ['X:\hanyaning\MTPM_body_language'];
beh_neu_path = [rootpath,'\beh_neu_20240412'];
%% load data
fileFolder = fullfile(beh_neu_path);
dirOutput = dir(fullfile(fileFolder,'free*-neu.mat'));
neuNames = {dirOutput.name}';

all_data_cell = cell(size(neuNames,1),9);
%{rootname,neudata,pose_self,mov_self,seq_self,
% pose_partner,mov_partner,seq_partner, distance}

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
            all_data_9,all_data_cell{k,1}}];

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


%% show components，成分可视化
start_x = 0.67;
start_y = 0.47;

box_x = 0.1;
box_y = 0.1;

inter_x = 0.01;
inter_y = 0.02;

count = 1;

for m = 1:2
    for n = 1:3
        temph = subplot('Position',[...
            start_x+(n-1)*(box_x+inter_x),...
            start_y-(m-1)*(box_y+inter_y),...
            box_x,box_y]);

        sel_pc_idx = count;

        pc_mat = zeros(size(pca_cell,1),pad_len);

        start_list = zeros(size(pc_mat,1),2);
        end_list = zeros(size(pc_mat,1),2);
        
        for k = 1:size(pca_cell,1)
            temppc = pca_cell{k,1}(:,sel_pc_idx);
            pc_mat(k,1:length(temppc)) = mat2gray(temppc);
            start_list(k,:) = [baseline_far_frame,k];
            end_list(k,:) = [length(temppc)-after_far_frame,k];
        end
        
        len_idx = cell2mat(cellfun(@(x) size(x,1),...
            pca_cell(:,1),'UniformOutput',false));
        
        [~,sort_idx] = sort(len_idx,'descend');
        
        sort_pc_mat = pc_mat(sort_idx,:);
        start_list = start_list(sort_idx,:);
        end_list = end_list(sort_idx,:);
        end_list(:,2) = 1:size(end_list,1);
        
        count = count+1;

        imagesc(sort_pc_mat)


        hold on
        plot(start_list(:,1),start_list(:,2),'-k')
        hold on
        plot(end_list(:,1),end_list(:,2),'-k')
        hold off

        title(['PC ',num2str(sel_pc_idx)])

        set(gca,'FontSize',6)
        set(gca,'TickDir','out')

        if m == 1
            set(gca,'XTickLabel',[])
        else
            set(gca,'XTickLabelRotation',0)
            xlabel('Time (s)')
        end
        
        set(gca,'YTick',[1,98])
        if n == 1
            ylabel('Neural PC')
        else
            set(gca,'YTickLabel',[])
        end
        box off
    end
end
