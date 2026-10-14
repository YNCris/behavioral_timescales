%{
    optogenetic behavior remapping
%}
clear all
close all
%% set path
ref_root_path = ['H:\MTPM_body_language\' ...
    'raw_data\behavior_all\BeA_path'];
data_root_path = ['H:\MTPM_body_language\' ...
    'raw_data\behavior_op_20250915\BeA_path'];
%% load ref and data
ref_dir = {...
    'recluster_data_free';...
    'recluster_data_tpm'};

data_dir = ref_dir;

ref_dsc_cell = cell(size(ref_dir,1),1);
data_dsc_cell = cell(size(ref_dir,1),1);
for k = 1:size(ref_dir,1)
    %%
    tempdata = load([ref_root_path,'\', ...
        ref_dir{k},'\data_sample_cell_80.mat']);
    ref_dsc_cell{k,1} = tempdata.data_sample_cell;

    tempdata = load([data_root_path,'\', ...
        data_dir{k},'\data_sample_cell_80_raw.mat']);
    data_dsc_cell{k,1} = tempdata.data_sample_cell;

    disp(k)
end

%% processing
new_dsc_cell = data_dsc_cell;
for k = 1:size(ref_dsc_cell,1)
    %%
    ref_dsc = ref_dsc_cell{k,1};
    data_dsc = data_dsc_cell{k,1};

    ref_save_list = cell2mat(ref_dsc(:,2));

    idx_list = ref_save_list(:,4);

    %% calculate dtak
    tic
    dist_mat = zeros(size(ref_dsc,1),size(data_dsc,1));
    for m = 1:size(ref_dsc,1)
        for n = 1:size(data_dsc,1)
            %% get data
            seg_data1 = ref_dsc{m,1};
            seg_data2 = data_dsc{n,1};
            %% calculate dtak
		    condist_mat = conDist(seg_data1,seg_data2);
		    Kdistmat = conKnl_DTAK(...
                condist_mat, 'g', 'nei', 30);
		    wFs1 = ones(1,size(Kdistmat,1));
		    wFs2 = ones(1,size(Kdistmat,2));
		    [T,~,~] = dtakFord(Kdistmat,0,wFs1,wFs2);
            dist_mat(m,n) = T;
        end
        disp(m/size(data_sample_cell,1))
    end
    toc
    %% find best match
    for m = 1:size(dist_mat,2)
        tempk = dist_mat(:,m);
        sel_idx = find(tempk==max(tempk));
        data_dsc{m,2}(1,4) = idx_list(sel_idx);
    end

    new_dsc_cell{k,1} = data_dsc;

    disp(k)
end
%% check and save
idx_cell = cell(size(new_dsc_cell,1),1);
for k = 1:size(idx_cell,1)
    %% check
    data_sample_cell = new_dsc_cell{k,1};
    tempsavelist = cell2mat(data_sample_cell(:,2));
    idx_cell{k,1} = tempsavelist(:,4);
    %% save
    save([data_root_path,'\', ...
        data_dir{k},'\data_sample_cell_80.mat'],...
        'data_sample_cell','-v7.3')
    disp(k)
end








