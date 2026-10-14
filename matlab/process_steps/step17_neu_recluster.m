%{
    recluster dtak
%}
clear all
close all
addpath(genpath(pwd))
%% set path
rootpath = ['E:\MTPM_body_language'];
beh_neu_path = [rootpath,'\beh_neu_20240412'];
%% load data
fileFolder = fullfile(beh_neu_path);
dirOutput = dir(fullfile(fileFolder,'free*-neu.mat'));
neuNames = {dirOutput.name}';

all_data_cell = cell(size(neuNames,1),13);
%{rootname,neudata,pose_self,mov_self,seq_self,
% pose_partner,mov_partner,seq_partner, distance,
% umap_embedding,pca_embedding}

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
        '-neu_umap.mat']);
    all_data_cell{k,10} = tempdata.umap_embedding;

    tempdata = load([beh_neu_path,'\',rootname,...
        '-neu_pca.mat']);
    all_data_cell{k,11} = tempdata.pca_embedding;

    tempdata = load([beh_neu_path,'\',rootname,...
        '-neu_linear_pred.mat']);
    all_data_cell{k,12} = tempdata.linear_pred;

    tempdata = load([beh_neu_path,'\',rootname,...
        '-neu_dtak.mat']);
    all_data_cell{k,13} = tempdata.BeA_DecData.L2;
    disp(k)
end
%% create savelist
savelist_cell = cell(size(all_data_cell,1),1);
for k = 1:size(savelist_cell,1)
    temp_Seglist = all_data_cell{k,13}.Seglist;
    temp_ReMap = all_data_cell{k,13}.ReMap;
    temp_savelist = Create_savelist(temp_ReMap,temp_Seglist);
    savelist_cell{k,1} = temp_savelist;
end
%% create dsc
data_sample_cell = [];
for k = 1:size(savelist_cell,1)
    temp_savelist = savelist_cell{k,1};
    for m = 1:size(temp_savelist,1)
        tempdata = zscore(all_data_cell{k,10}(...
            temp_savelist(m,1):temp_savelist(m,2),:)',[],2);
        tempsavelist = temp_savelist(m,:);
        tempsavelist(1,5) = m;
        tempfilename = all_data_cell{k,1};
        data_sample_cell = [data_sample_cell;...
            {tempdata,tempsavelist,tempfilename}];
    end
end
%% gtw alignment, bootstrap template, too slow
% sel_dsc = data_sample_cell(:,:);
% Xs = sel_dsc(:,1)';
% l = 60;
% ns = cellDim(Xs, 2);
% bas = baTems(l, ns, 'pol', ...
%     [3 .4], 'tan', [3 .6 1]);
% aliT = [];
% 
% inp = 'linear'; qp = 'matlab'; dp = 'c';
% 
% parGtw = st('nItMa', 50, 'th', 0);
% parCca = st('d', 3, 'lams', 0);
% parFtw = st('nItMa', 2, 'th', 0, ...
%     'lam', 0, 'nor', 'n', 'qp', qp, 'inp', inp);
% 
% % utw (initialization)
% aliUtw = utw(Xs, bas, aliT);
% %
% ali = gtw( ...
%     Xs, ...
%     bas, ...
%     aliUtw, ...
%     aliT, ...
%     parGtw, ...
%     parCca, ...
%     parFtw);
% % reconstruction
% % parameter
% parPca = st('d', 3, 'homo', 'y');
% parMk = st('mkSiz', 3, 'lnWid', 1, 'ln', '-');
% 
% % current
% homo_Xs = homoX(Xs);
% [Ys, ~, Us] = gtwTra(homo_Xs, ali, parCca, parFtw);
% new_Ys = Ys';
% for m = 1:size(new_Ys,1)
%     new_Ys{m} = Ys{m}(1:3,:);
% end
%% calculate dtak of new_Ys
tic
new_Ys = data_sample_cell(:,1);
dist_mat = zeros(size(new_Ys,1),...
    size(new_Ys,1));
for m = 1:size(new_Ys,1)
    seg_data1 = new_Ys{m,1};
    for n = m:size(new_Ys,1)
        %% get data
        seg_data2 = new_Ys{n,1};
        %% calculate dtak
		condist_mat = conDist(seg_data1,seg_data2);
		Kdistmat = conKnl_DTAK(...
            condist_mat, 'g', 'nei', 1);
		wFs1 = ones(1,size(Kdistmat,1));
		wFs2 = ones(1,size(Kdistmat,2));
		[T,~,~] = dtakFord(Kdistmat,0,wFs1,wFs2);
        dist_mat(m,n) = T;
    end
    disp(m/size(new_Ys,1))
end
toc
% fill full matrix
dist_mat_all = dist_mat + triu(dist_mat, 1)';
%% embedding
% [reduction, umap, clusterIdentifiers] = run_umap(dist_mat_all,...
%     'n_neighbors',199,'sgd_tasks',1,...
%     'min_dist',0.05,'metric','seuclidean','n_components', 2, 'verbose', 'text');
[reduction, umap, clusterIdentifiers] = run_umap(...
    mat2gray(dist_mat_all),...
    'n_neighbors',199,'sgd_tasks',1,...
    'min_dist',0.05,'metric','seuclidean',...
    'n_components', 2, 'verbose', 'text',...
    'randomize',false);
embedding = umap.embedding;
figure
plot(embedding(:,1),embedding(:,2),'o')
%% cluster number calculate
E1 = evalclusters(...
    embedding,'linkage','silhouette','KList',1:20);

figure
plot(E1)

%% hierarchical clustering
n_clus = 8;
D = pdist(embedding,'seuclidean');
Z = squareform(D);
tree = linkage(Z, 'ward','euclidean');
T = cluster(tree,'maxclust',n_clus);

figure
cmaplist3 = T;
cmapcolor3 = cbrewer2('Spectral',length(unique(cmaplist3)));
cmap3 = cmapcolor3(cmaplist3,:);
scatter(embedding(:,1),...
    embedding(:,2),...
    10*ones(size(embedding(:,1))),cmap3,'filled');
axis square
xlabel('UMAP 1')
ylabel('UMAP 2')

%% show each mice as label
sel_dsc = data_sample_cell;
mouse_cmap = cbrewer2('Spectral',size(all_data_cell,1));

mouse_cmaplist = zeros(size(sel_dsc,1),3);
for k = 1:size(mouse_cmap,1)
    tempname = all_data_cell{k,1};

    selidx = strcmp(tempname,sel_dsc(:,3));
    mouse_cmaplist(selidx,:) = ones(sum(selidx),1)*...
        mouse_cmap(k,:);
end

figure
scatter(embedding(:,1),...
    embedding(:,2),...
    2*ones(size(embedding(:,1))),mouse_cmaplist,'filled');
axis square
xlabel('UMAP 1')
ylabel('UMAP 2')

%% show raw data distribution
figure
for k = 1:size(sel_dsc,1)
    plot3(...
        sel_dsc{k,1}(1,:),...
        sel_dsc{k,1}(2,:),...
        sel_dsc{k,1}(3,:),...
        '-','Color',cmap3(k,:)...
        )
    hold on
end
hold off

%% map all the data
% all_labels = T;
% 
% for k = 1:size(all_data_cell,1)
%     tempname = all_data_cell{k,1};
%     selidx = strcmp(tempname,data_sample_cell(:,3));
%     sel_data = data_sample_cell(selidx,1);
%     sel_label = all_labels(selidx,1);
% 
%     selref = sel_label ~= 0;
%     ref_data = sel_data(selref,:);
%     ref_label = sel_label(selref);
% 
%     obj_data = sel_data(~selref,:);
%     %% dtak
%     tic
%     temp_dist_mat = zeros(size(obj_data,1),...
%         size(ref_data,1));
%     for m = 1:size(obj_data,1)
%         seg_data1 = obj_data{m,1};
%         for n = 1:size(ref_data,1)
%             %% get data
%             seg_data2 = ref_data{n,1};
%             %% calculate dtak
% 		    condist_mat = conDist(seg_data1,seg_data2);
% 		    Kdistmat = conKnl_DTAK(...
%                 condist_mat, 'g', 'nei', 1);
% 		    wFs1 = ones(1,size(Kdistmat,1));
% 		    wFs2 = ones(1,size(Kdistmat,2));
% 		    [T_dtak,~,~] = dtakFord(Kdistmat,0,wFs1,wFs2);
%             temp_dist_mat(m,n) = T_dtak;
%         end
%     end
%     toc
%     %% 
%     max_idx_list = zeros(size(temp_dist_mat,1),1);
%     for m = 1:size(temp_dist_mat,1)
%         tempdist = temp_dist_mat(m,:);
%         max_idx = find(tempdist==max(tempdist));
%         max_idx_list(m,1) = max_idx;
%     end
% 
%     new_label = ref_label(max_idx_list);
% 
%     temp_new_label = sel_label;
%     temp_new_label(sel_label==0) = new_label;
% 
%     all_labels(selidx) = temp_new_label;
% 
%     disp(k)
% end
%% append to data sample cell
all_labels = T;
for k = 1:size(data_sample_cell,1)
    data_sample_cell{k,4} = all_labels(k);
end
%% save
save([beh_neu_path,'\dist_mat_all_20240822.mat'],...
    'dist_mat_all','-v7.3')
save([beh_neu_path,'\embedding_20240822.mat'],...
    'embedding','-v7.3')
save([beh_neu_path,'\data_sample_cell_20240822.mat'],...
    'data_sample_cell','-v7.3')
disp('save!')









