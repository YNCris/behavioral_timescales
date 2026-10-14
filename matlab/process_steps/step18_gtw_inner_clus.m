%{
    gtw inner clus
%}
clear all
close all
addpath(genpath(pwd))
%% set path
rootpath = ['E:\MTPM_body_language'];
beh_neu_path = [rootpath,'\beh_neu_20240412'];
%% load data
load([beh_neu_path,'\dist_mat_all_20240819.mat'])
load([beh_neu_path,'\embedding_20240819.mat'])
load([beh_neu_path,'\data_sample_cell_20240819.mat'])
%% 
T = cell2mat(data_sample_cell(:,4));
unique_T = unique(T);

gtw_cell = cell(size(unique_T,1),1);

for k = 1:size(gtw_cell,1)
    %% gtw
    selidx = T == unique_T(k);

    Xs = data_sample_cell(selidx,1)';
    l = 300;
    ns = cellDim(Xs, 2);
    bas = baTems(l, ns, 'pol', ...
        [3 .4], 'tan', [3 .6 1]);
    aliT = [];
    
    inp = 'linear'; qp = 'matlab'; dp = 'c';
    
    parGtw = st('nItMa', 50, 'th', 0);
    parCca = st('d', 3, 'lams', 0);
    parFtw = st('nItMa', 2, 'th', 0, ...
        'lam', 0, 'nor', 'n', 'qp', qp, 'inp', inp);
    
    % utw (initialization)
    aliUtw = utw(Xs, bas, aliT);
    %
    ali = gtw( ...
        Xs, ...
        bas, ...
        aliUtw, ...
        aliT, ...
        parGtw, ...
        parCca, ...
        parFtw);
    % reconstruction
    % parameter
    parPca = st('d', 3, 'homo', 'y');
    parMk = st('mkSiz', 3, 'lnWid', 1, 'ln', '-');
    
    % current
    homo_Xs = homoX(Xs);
    [Ys, ~, Us] = gtwTra(homo_Xs, ali, parCca, parFtw);
    new_Ys = Ys';
    for m = 1:size(new_Ys,1)
        new_Ys{m} = Ys{m}(1:3,:);
    end

    gtw_cell{k} = new_Ys;
    disp(k)
end
%% save
save([beh_neu_path,'\gtw_cell_20240819.mat'],...
    'gtw_cell','-v7.3')
disp('save!')






