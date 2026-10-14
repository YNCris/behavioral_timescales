%{
    find stereotyped sequences
%}
clear all
close all
genPath = genpath('./');
addpath(genPath)
%% set path
rootpath = 'H:\MTPM_body_language\';
beh_path = [rootpath,'\raw_data\behavior_op_20250915'];
bea_path = [beh_path,'\BeA_path'];
template_path = [rootpath,...
    '\raw_data\behavior_all\BeA_path\recluster_data_merge'];

beh_neu_path = [rootpath,'\beh_neu_20250918'];
%% load sequence template
seq_dsc = load([template_path,'\find_stereotyped_sequences.mat']);
ref_seq = seq_dsc.data_sample_cell(:,1);
%% load raw data
dataname_list = {'tpm';'free'};

all_label_dsc = {};

for k = 1:size(dataname_list,1)
    temp_behname = readtable([bea_path,...
        '\recluster_data_',dataname_list{k},...
        '\cut_beh_80\beh_label.xlsx']);
    templabelname = temp_behname.Behavior;
    temp_dsc_io = load([bea_path,...
        '\recluster_data_',dataname_list{k},...
        '\py_dsc_80.mat']);
    temp_dsc = temp_dsc_io.py_dsc;

    splname = split(temp_dsc(:,2),'_');
    splname = splname(:,1);

    for m = 1:size(temp_dsc,1)
        templabel = temp_dsc{m,1}(4);
        all_label_dsc = [all_label_dsc;...
            {temp_dsc{m,1},splname{m,1},...
            templabelname{templabel}}];
    end
end
%% load names
rootNames = unique(all_label_dsc(:,2));

%% match template
for k = 1:size(rootNames,1)
    %% load data
    tempname = rootNames{k,1};
    sel_idx = strcmp(tempname, all_label_dsc(:,2));
    sel_dsc = all_label_dsc(sel_idx,:);

    mov_cell = sel_dsc(:,3);
    %% matching
    % mov_cell: 完整行为序列 (Nx1 cell)
    % ref_seq : 模板集合 (Mx1 cell，每个元素是1xK cell)
    % results : struct 数组，包含模板、模板序号、匹配位置（不重叠，优先长模板）

    results = struct('template', {}, 'index', {}, 'positions', {});
    N = numel(mov_cell);
    used = false(N,1); % 标记是否已被占用

    % 1. 按模板长度排序（长的在前）
    lens = cellfun(@numel, ref_seq);
    [~, order] = sort(lens, 'descend');

    % 2. 遍历模板（长的先）
    for kk = 1:numel(order)
        m = order(kk);      % 原始模板序号
        tmpl = ref_seq{m};
        L = numel(tmpl);
        matchPos = [];

        % 滑动窗口精确比较
        for i = 1:(N-L+1)
            if all(strcmp(mov_cell(i:i+L-1)', tmpl)) ...
                    && ~any(used(i:i+L-1))   % 没有和已有匹配重叠
                matchPos = [matchPos; [i, i+L-1]]; %#ok<AGROW>
                used(i:i+L-1) = true; % 标记占用
            end
        end

        if ~isempty(matchPos)
            results(end+1).template = tmpl; %#ok<AGROW>
            results(end).index = m;         % 保存模板原始序号
            results(end).positions = matchPos;
        end
    end
    %% generate match list
    match_list = zeros(size(mov_cell,1),1);
    for m = 1:length(results)
        temppos = results(m).positions;
        for n = 1:size(temppos,1)
            match_list(...
                temppos(n,1):...
                temppos(n,2),1) = ...
            seq_dsc.T_class(results(m).index);
        end
    end
    %% append labels
    seq_label_list = zeros(sel_dsc{end,1}(1,2),1);

    for m = 1:size(sel_dsc,1)
        tempsavelist1 = sel_dsc{m,1};
        templabel = match_list(m);

        selrange = ...
            tempsavelist1(1,1):...
            tempsavelist1(1,2);

        seq_label_list(selrange,1) = templabel;
    end
    %% save sequence label
    rawsplname = split(tempname,'-');

    savename = [rawsplname{2},'-',...
                rawsplname{3},'-',...
                rawsplname{4},'-',...
                rawsplname{5},'-',...
                rawsplname{6},'-seq-',...
                rawsplname{1},'.mat'];
    %%
    save([beh_neu_path,'\',savename],...
            'seq_label_list')
    disp(k)
end
disp('save!')






































