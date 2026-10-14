%{
    fig2, analysis the neural patterns according to:
    1. brain area
    2. behavior levels
    3. self/partner
%}
clear all
close all
%% set path
rootpath = ['E:\MTPM_body_language'];
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
before_time = 2;%s
during_time = 2;%s
after_time = 2;%s

fs = 30;

before_frame = before_time*fs;%s
during_frame = during_time*fs;%s
after_frame = after_time*fs;%s

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


mov_trial_mat = cell2mat(mov_trial_cell(:,2));

%% calculate change labels of mov
mov_change_label_list = zeros(size(mov_trial_cell,1),1);
change_thres = 0.2;%std of baseline

boundary_thres = 0;% a torlerent of behavior noise
tic
for k = 1:size(mov_trial_cell,1)
    tempdata = mov_trial_cell{k,2};
    during_neu = tempdata(...
        (before_frame+1-boundary_thres):...
        (length(tempdata)-after_frame+boundary_thres));

    before_neu = tempdata(1:before_frame);

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
%% show the heat map of all trials
[~,sortidx] = sort(mov_change_label_list,'descend');

sort_mov_trial = mov_trial_mat(sortidx,:);
%% split the data according to the brain area
mov_splname = split(mov_trial_cell(:,1),'-');
brain_name_list = cellfun(@(x) x(2:end),...
    mov_splname(:,3),'UniformOutput',false);
% sort heatmap by brain area
brain_area_list = {...
    'tpmss';...
    'tpmpfc';...
    'tpmm'};
% show
figure
for k = 1:size(brain_area_list,1)
    tempname = brain_area_list{k,1};
    selidx = strcmp(brain_name_list,tempname);
    selmat = mov_trial_mat(selidx,:);

    sel_label_list = mov_change_label_list(selidx,:);

    [~,sortidx] = sort(sel_label_list,'descend');

    temp_sort_mov_trial = selmat(sortidx,:);

    subplot(1,3,k)
    imagesc(temp_sort_mov_trial,[-0.2,0.2])
    colorbar
    title(tempname)
end

%% mouse-based quantification, cross conditions
% cbmm=[condition,brain,mouse,mov];
cbmm_name_list = cellfun(@(a,b,c,d,e,f) ...
    [a,'-',b,'-',c,'-',d,'-',e,'-',f],...
    mov_splname(:,1),mov_splname(:,2),...
    mov_splname(:,3),mov_splname(:,4),...
    mov_splname(:,5),mov_splname(:,6),...
    'UniformOutput',false...
    );

unique_cbmm_name_list = unique(cbmm_name_list);

cbmm_splname = split(unique_cbmm_name_list,'-');

cbmm_brain_name = cellfun(@(x) x(2:end),...
    cbmm_splname(:,3),'UniformOutput',false);

cbmm_feat_list = cell(size(unique_cbmm_name_list,1),1);

for k = 1:size(unique_cbmm_name_list,1)
    tempname = unique_cbmm_name_list{k,1};
    selidx = strcmp(cbmm_name_list,tempname);
    selchange = mov_change_label_list(selidx);
    sel_tbl = tabulate(selchange);

    pat_list = zeros(1,3);

    for m = 1:size(sel_tbl,1)
        if sel_tbl(m,1) == 1
            pat_list(1,1) = sel_tbl(m,3)/100;
        elseif sel_tbl(m,1) == 0
            pat_list(1,2) = sel_tbl(m,3)/100;
        elseif sel_tbl(m,1) == -1
            pat_list(1,3) = sel_tbl(m,3)/100;
        end
    end

    cbmm_feat_list{k,1} = pat_list;
end

cbmm_feat_mat = cell2mat(cbmm_feat_list);
%% temp show feature mat, all
figure
plot3(cbmm_feat_mat(:,1),cbmm_feat_mat(:,2),...
    cbmm_feat_mat(:,3),'o')
%% give color to brain areas
neu_cmap = cbrewer2('Paired',12);

in_c = neu_cmap(5,:);
de_c = neu_cmap(3,:);
no_c = neu_cmap(1,:);

brain_c = [...
    de_c;...
    in_c;...
    no_c];

dot_size = 10;

cbmm_cmaplist = zeros(size(unique_cbmm_name_list,1),3);
for k = 1:size(brain_area_list,1)
    tempname = brain_area_list{k};
    selidx = strcmp(tempname,cbmm_brain_name);
    cbmm_cmaplist(selidx,:) = ones(sum(selidx),1)*...
        brain_c(k,:);
end

figure
scatter3(cbmm_feat_mat(:,1),cbmm_feat_mat(:,2),...
    cbmm_feat_mat(:,3),...
    dot_size*ones(size(cbmm_feat_mat,1),1),...
    cbmm_cmaplist,'filled')

xlabel('[1]')
ylabel('[0]')
zlabel('[-1]')
%% calculate unique cell average
unique_cell_name = unique(mov_trial_cell(:,1));

mov_cell_cell = cell(size(unique_cell_name,1),1);
tic
for k = 1:size(unique_cell_name,1)
    tempname = unique_cell_name{k,1};
    selidx = strcmp(tempname,mov_trial_cell(:,1));
    selcell = mov_trial_mat(selidx,:);
    mov_cell_cell{k,1} = mean(selcell,1);

    if rem(k,1000) == 0
        disp(k)
        toc
    end
end
%% further split data to each seq
mov_spl_cell_name = split(unique_cell_name,'-');
mov_seq_name = cellfun(@(a,b,c,d,e,f) ...
    [a,'-',b,'-',c,'-',d,'-',e,'-',f],...
    mov_spl_cell_name(:,1),...
    mov_spl_cell_name(:,2),...
    mov_spl_cell_name(:,3),...
    mov_spl_cell_name(:,4),...
    mov_spl_cell_name(:,5),...
    mov_spl_cell_name(:,6),...
    'UniformOutput',false...
    );

unique_mov_seq_name = unique(mov_seq_name);

mov_seq_cell = cell(size(unique_mov_seq_name,1),1);

for k = 1:size(unique_mov_seq_name,1)
    tempname = unique_mov_seq_name{k,1};
    selidx = strcmp(tempname,mov_seq_name);
    seldata = mov_cell_cell(selidx,:);
    mov_seq_cell{k,1} = cell2mat(seldata);
end

%% temp show
figure
for k = 1:size(mov_seq_cell,1)
    tempname = unique_mov_seq_name{k};
    tempmat = mov_seq_cell{k};
    imagesc(tempmat,[-0.2,0.2])
    title(tempname)
    pause
end

%% calculate the significant of each mov
before_time = 2;%s
during_time = 2;%s
after_time = 2;%s

fs = 30;

before_frame = before_time*fs;%s
during_frame = during_time*fs;%s
after_frame = after_time*fs;%s

mov_sign_cell = cell(size(unique_mov_seq_name,1),1);
for k = 1:size(unique_mov_seq_name,1)
    tempmat = mov_seq_cell{k};
    tempchange = zeros(size(tempmat,1),1);
    for m = 1:size(tempmat,1)
        tempdata = tempmat(m,:);
        during_neu = tempdata(...
        (before_frame+1-boundary_thres):...
        (length(tempdata)-after_frame+boundary_thres));

        before_neu = tempdata(1:before_frame);
    
        [h,p] = ttest2(during_neu,before_neu);

        if p<0.05
            mean_baseline_neu = mean(before_neu);
            mean_during_neu = mean(during_neu);
    
            if mean_baseline_neu>mean_during_neu
                tempchange(m,1) = -1;
            else
                tempchange(m,1) = 1;
            end
        else
        end
    end
    mov_sign_cell{k,1} = tempchange;
end
%% calculate the neural activity similarity
before_time = 2;%s
during_time = 2;%s
after_time = 2;%s

fs = 30;

before_frame = before_time*fs;%s
during_frame = during_time*fs;%s
after_frame = after_time*fs;%s

mov_sim_mat = zeros(...
    size(unique_mov_seq_name,1),...
    size(unique_mov_seq_name,1));

for m = 1:size(mov_sim_mat,1)
    for n = 1:size(mov_sim_mat,2)
        tempneu1 = mov_seq_cell{m,1}(:,...
        (before_frame+1-boundary_thres):...
        (length(tempdata)-after_frame+boundary_thres));
        tempneu2 = mov_seq_cell{n,1}(:,...
        (before_frame+1-boundary_thres):...
        (length(tempdata)-after_frame+boundary_thres));

        tempdist = pdist2(tempneu1,tempneu2);

        mov_sim_mat(m,n) = mean(tempdist(:));
    end
    disp(m)
end
%% calculate intra similarity and inter similarity
spl_mov_seq_name = split(unique_mov_seq_name,'-');

unique_mov = unique(spl_mov_seq_name(:,6));

sim_list = zeros(size(unique_mov,1),2);

for k = 1:size(unique_mov,1)
    selidx_intra = strcmp(unique_mov{k},spl_mov_seq_name(:,6));
    selidx_inter = ~selidx_intra;

    intra_mat1 = mov_sim_mat(selidx_intra,:);
    intra_mat2 = intra_mat1(selidx_intra);

    sim_list(k,1) = mean(intra_mat2);

    inter_mat1 = mov_sim_mat(selidx_intra,:);
    inter_mat2 = intra_mat1(selidx_inter);

    sim_list(k,2) = mean(inter_mat2);
end
%% cut seq trials
before_time = 10;%s
during_time = 10;%s
after_time = 10;%s

fs = 30;

before_frame = before_time*fs;%s
during_frame = during_time*fs;%s
after_frame = after_time*fs;%s

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


seq_trial_mat = cell2mat(seq_trial_cell(:,2));


%% calculate change labels of seq
seq_change_label_list = zeros(size(seq_trial_cell,1),1);
change_thres = 0.2;%std of baseline

boundary_thres = 0;% a torlerent of behavior noise
tic
for k = 1:size(seq_trial_cell,1)
    tempdata = seq_trial_cell{k,2};
    during_neu = tempdata(...
        (before_frame+1-boundary_thres):...
        (length(tempdata)-after_frame+boundary_thres));

    before_neu = tempdata(1:before_frame);

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


%% show the heat map of all trials
[~,sortidx] = sort(seq_change_label_list,'descend');

sort_seq_trial = seq_trial_mat(sortidx,:);

%% split the data according to the brain area
seq_splname = split(seq_trial_cell(:,1),'-');
brain_name_list = cellfun(@(x) x(2:end),...
    seq_splname(:,3),'UniformOutput',false);

%% sort heatmap by brain area
brain_area_list = {...
    'tpmss';...
    'tpmpfc';...
    'tpmm'};

brain_heatmap_cell = cell(size(brain_area_list,1),1);

figure
for k = 1:size(brain_heatmap_cell,1)
    tempname = brain_area_list{k,1};
    selidx = strcmp(brain_name_list,tempname);
    selmat = seq_trial_mat(selidx,:);

    sel_label_list = seq_change_label_list(selidx,:);

    [~,sortidx] = sort(sel_label_list,'descend');

    temp_sort_seq_trial = selmat(sortidx,:);

    subplot(1,3,k)
    imagesc(temp_sort_seq_trial,[-0.2,0.2])
    colorbar
    title(tempname)
end

%% mouse-based quantification, cross conditions
% cbms=[condition,brain,mouse,seq];
cbms_name_list = cellfun(@(a,b,c,d,e,f) ...
    [a,'-',b,'-',c,'-',d,'-',e,'-',f],...
    seq_splname(:,1),seq_splname(:,2),...
    seq_splname(:,3),seq_splname(:,4),...
    seq_splname(:,5),seq_splname(:,6),...
    'UniformOutput',false...
    );

unique_cbms_name_list = unique(cbms_name_list);

cbms_splname = split(unique_cbms_name_list,'-');

cbms_brain_name = cellfun(@(x) x(2:end),...
    cbms_splname(:,3),'UniformOutput',false);

cbms_feat_list = cell(size(unique_cbms_name_list,1),1);

for k = 1:size(unique_cbms_name_list,1)
    tempname = unique_cbms_name_list{k,1};
    selidx = strcmp(cbms_name_list,tempname);
    selchange = seq_change_label_list(selidx);
    sel_tbl = tabulate(selchange);

    pat_list = zeros(1,3);

    for m = 1:size(sel_tbl,1)
        if sel_tbl(m,1) == 1
            pat_list(1,1) = sel_tbl(m,3)/100;
        elseif sel_tbl(m,1) == 0
            pat_list(1,2) = sel_tbl(m,3)/100;
        elseif sel_tbl(m,1) == -1
            pat_list(1,3) = sel_tbl(m,3)/100;
        end
    end

    cbms_feat_list{k,1} = pat_list;
end

cbms_feat_mat = cell2mat(cbms_feat_list);

%% temp show feature mat, all
figure
plot3(cbms_feat_mat(:,1),cbms_feat_mat(:,2),...
    cbms_feat_mat(:,3),'o')
%% give color to brain areas
neu_cmap = cbrewer2('Paired',12);

in_c = neu_cmap(5,:);
de_c = neu_cmap(3,:);
no_c = neu_cmap(1,:);

brain_c = [...
    de_c;...
    in_c;...
    no_c];

dot_size = 10;

cbms_cmaplist = zeros(size(unique_cbms_name_list,1),3);
for k = 1:size(brain_area_list,1)
    tempname = brain_area_list{k};
    selidx = strcmp(tempname,cbms_brain_name);
    cbms_cmaplist(selidx,:) = ones(sum(selidx),1)*...
        brain_c(k,:);
end

figure
scatter3(cbms_feat_mat(:,1),cbms_feat_mat(:,2),...
    cbms_feat_mat(:,3),...
    dot_size*ones(size(cbms_feat_mat,1),1),...
    cbms_cmaplist,'filled')

xlabel('[1]')
ylabel('[0]')
zlabel('[-1]')

%% show together
figure

dot_size = 20;

scatter3(cbmm_feat_mat(:,1),cbmm_feat_mat(:,2),...
    cbmm_feat_mat(:,3),...
    dot_size*ones(size(cbmm_feat_mat,1),1),...
    cbmm_cmaplist)
hold on
scatter3(cbms_feat_mat(:,1),cbms_feat_mat(:,2),...
    cbms_feat_mat(:,3),...
    dot_size*ones(size(cbms_feat_mat,1),1),...
    cbms_cmaplist,'filled')
hold off
xlabel('[1]')
ylabel('[0]')
zlabel('[-1]')










