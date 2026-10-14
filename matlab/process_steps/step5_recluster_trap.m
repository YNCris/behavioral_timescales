%{
    recluster of bea
%}
clear all
close all
genPath = genpath('./');
addpath(genPath)
%% set file path
rootpath = ['X:\hanyaning\multi_mice_test\' ...
    'Social_analysis\data\MTPM_body_language\' ...
    'raw_data\behavior_all\BeA_path'];
filepath = [rootpath,'\struct\trap'];
savedatapath = [rootpath,'\recluster_data_trap'];
mkdir(savedatapath)
%% get all BeA structs
fileFolder = fullfile(filepath);
dirOutput = dir(fullfile(fileFolder,'*.mat'));
fileNames = {dirOutput.name}';
%% load data
load_flag = true;%load data flag
tic
if load_flag
    XY_cell = cell(size(fileNames,1),1);
    ReMap_cell = cell(size(fileNames,1),1);
    Seglist_cell = cell(size(fileNames,1),1);
    V_cell = cell(size(fileNames,1),1);
    for k = 1:size(fileNames,1)
        tempBeA = load([filepath,'\',fileNames{k,1}]);
        cent_num = 13;
        pixel2mm = 1;
        fs = tempBeA.BeA.DataInfo.VideoInfo.FrameRate;%tempBeA.BeA.DataInfo.VideoInfo.FrameRate;
        XY_cell{k,1} = tempBeA.BeA.BeA_DecData.XY;
        ReMap_cell{k,1} = tempBeA.BeA.BeA_DecData.L2.ReMap;
        Seglist_cell{k,1} = tempBeA.BeA.BeA_DecData.L2.Seglist;
        cent_X = tempBeA.BeA.PreproData.X(:,cent_num);
        cent_Y = tempBeA.BeA.PreproData.Y(:,cent_num);
        cent_Z = tempBeA.BeA.PreproData.Z(:,cent_num);
        cent_XYZ = [cent_X,cent_Y,cent_Z];
        temp_vel_XYZ = diff(cent_XYZ);
        vel_XYZ = [temp_vel_XYZ; temp_vel_XYZ(end, :)];
        vel_raw = sqrt(vel_XYZ(:, 1).^2 + vel_XYZ(:, 2).^2 + vel_XYZ(:, 3).^2);
        vel_raw = fs*vel_raw/pixel2mm;%speed/s
        V_cell{k,1} = medfilt1(vel_raw',5);
%         imagesc(tempBeA.BeA.BeA_DecData.K)
%         title(fileNames{k,1})
%         colorbar
%         pause
        toc
    end
    %% save temp data
    save([savedatapath,'\recluster_raw_data.mat'],'XY_cell','ReMap_cell','Seglist_cell','V_cell');
else
    load([savedatapath,'\recluster_raw_data.mat']);
end
toc
%% create savelist
savelist_cell = cell(size(Seglist_cell,1),1);
for k = 1:size(savelist_cell,1)
    temp_Seglist = Seglist_cell{k,1};
    temp_ReMap = ReMap_cell{k,1};
    temp_savelist = zeros(size(temp_ReMap,2)-1,5);
    temp_savelist(:,1:3) = Create_savelist(temp_ReMap,temp_Seglist);
    savelist_cell{k,1} = temp_savelist;
end
%% create data_sample_cell
selection = [1,1,1,1,1,1,1,1,...
    1,1,1,1,1,1,1,1,...
    1,1,1,1,1,1,1,1,...
    1,1,1,1,1,1,1,1,...
    1,1,1,1,0,0,1,1,...
    0,1,0,0,0,0,0,0];
% selection = [1,1,1,1,1,1,1,1,...
%     1,1,1,1,1,1,1,1,...
%     1,1,1,1,1,1,1,1,...
%     1,1,1,1,1,1,1,1,...
%     1,1,1,1,1,1,1,1,...
%     1,1,1,1,1,1,1,1];
data_sample_cell = [];
for k = 1:size(savelist_cell,1)
    temp_savelist = savelist_cell{k,1};
    for m = 1:size(temp_savelist,1)
        tempdata = XY_cell{k,1}(selection==1,temp_savelist(m,1):temp_savelist(m,2));
        tempV = mean(mean(V_cell{k,1}(:,temp_savelist(m,1):temp_savelist(m,2))));
        tempsavelist = temp_savelist(m,:);
        tempsavelist(1,5) = m;
        tempfilename = fileNames{k,1};
        data_sample_cell = [data_sample_cell;{tempdata,tempsavelist,tempfilename,tempV}];
    end
end
%% calculate dtak
tic
dist_mat = zeros(size(data_sample_cell,1),size(data_sample_cell,1));
for m = 1:size(data_sample_cell,1)
    for n = m:size(data_sample_cell,1)
        %% get data
        seg_data1 = data_sample_cell{m,1};
        seg_data2 = data_sample_cell{n,1};
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
%% fill full matrix
dist_mat_all = dist_mat + triu(dist_mat, 1)';
%% embedding
% [reduction, umap, clusterIdentifiers] = run_umap(dist_mat_all,...
%     'n_neighbors',199,'sgd_tasks',1,...
%     'min_dist',0.05,'metric','seuclidean','n_components', 2, 'verbose', 'text');
[reduction, umap, clusterIdentifiers] = run_umap(dist_mat_all,...
    'n_neighbors',199,'sgd_tasks',1,...
    'min_dist',0.05,'metric','seuclidean','n_components', 2, 'verbose', 'text');
embedding = umap.embedding;
% plot(embedding(:,1),embedding(:,2),'o')
% axis square
% embedding = tsne(dist_mat_all,'Perplexity',5);
plot(embedding(:,1),embedding(:,2),'o')
axis square
%% add speed dimension
Vdim = [data_sample_cell{:,4}]';
embed3 = [embedding,Vdim];
% zscore
zscore_embed3 = [zscore(embed3(:,1)),zscore(embed3(:,2)),zscore(embed3(:,3))];
%% data_sample_cell reassignment
for k = 1:size(data_sample_cell,1)
    data_sample_cell{k,5} = embed3(k,:);
    data_sample_cell{k,6} = zscore_embed3(k,:);
end
% save('.\data\data_sample_cell.mat','data_sample_cell')
%%
%% hierarchical clustering
n_clus = 80;
D = pdist(zscore_embed3,'seuclidean');
Z = squareform(D);
tree = linkage(Z, 'ward','euclidean');
T = cluster(tree,'maxclust',n_clus);
% cutoff = median([tree(end-2,3) tree(end-1,3)]);
% dendrogram(tree,'ColorThreshold',cutoff)
% 
best_label_embedding = [zscore_embed3,T];
%% 
close all
cmaplist3 = best_label_embedding(:,4);
cmapcolor3 = imresize(colormap('jet'),[length(unique(cmaplist3)),3]);
cmap3 = zeros(size(cmaplist3,1),3);
for k = 1:size(cmap3,1)
    cmap3(k,:) = cmapcolor3(cmaplist3(k,1),:);
end
scatter3(best_label_embedding(:,1),best_label_embedding(:,2),best_label_embedding(:,3),...
    10*ones(size(best_label_embedding(:,1))),cmap3,'filled');
axis square
% axis([-0.5,0.5,-0.5,0.5,-2,12])
xlabel('UMAP 1')
ylabel('UMAP 2')
zlabel('Speed')
%% data_sample_cell add data
for k = 1:size(data_sample_cell,1)
    data_sample_cell{k,2}(1,4) = best_label_embedding(k,4);
end
%% save data
save([savedatapath,'\dist_mat_all_80.mat'],'dist_mat_all','-v7.3');
save([savedatapath,'\embedding_80.mat'],'best_label_embedding','-v7.3');
save([savedatapath,'\data_sample_cell_80.mat'],'data_sample_cell','-v7.3');
disp('save finished!');
%% save to lower matlab format to reduce the time of python reading
py_dsc = data_sample_cell(:,2:3);
save([savedatapath,'\py_dsc_80.mat'],'py_dsc')
disp('save finished!');
%% reset path
recluster_path = savedatapath;
%% 视频切割分组
%% 创建路径
savepath = [recluster_path,'\cut_beh_80'];
mkdir(savepath);
%% 创建单层路径
Tlist = cell2mat(data_sample_cell(:,2));
unique_T = unique(Tlist(:,4));
for k = 1:size(unique_T,1)
    temp1 = num2str(unique_T(k,1));
    mkdir([savepath,'\',temp1])
end
%% 切割视频，单层路径
CQI = calClus_qulity_fast(dist_mat_all, best_label_embedding(:,4));
%%
videopath = rootpath;
fileFolder = fullfile(videopath);
dirOutput = dir(fullfile(fileFolder,'*.avi'));
videonames = {dirOutput.name}';
for n = 1:size(videonames,1)
    vidobj = VideoReader([videopath,'\',videonames{n,1}]);
    for k = 1:size(data_sample_cell,1)
        if strcmp([videonames{n,1}(1,1:(end-4)),'_struct'], ...
                data_sample_cell{k,3}(1,1:(end-4)))
            tempstartframe = data_sample_cell{k,2}(1,1);
            tempendframe = data_sample_cell{k,2}(1,2);
            temp1 = num2str(data_sample_cell{k,2}(1,4));
            temp2 = data_sample_cell{k,3}(1,1:(end-4));
            temp3 = num2str(data_sample_cell{k,2}(1,3));
            temp4 = num2str(CQI(1,k),'%4.2f');
            writeobj = VideoWriter([savepath,'\',temp1,'\',temp4,'_',temp2,'_',temp3,'_',...
                num2str(tempstartframe),'_',num2str(tempendframe),'.avi']);
            writeobj.FrameRate = vidobj.FrameRate;
            open(writeobj);
            for m = tempstartframe:tempendframe
                frame = read(vidobj,m);
                writeVideo(writeobj,frame);
            end
            close(writeobj);
        end
    end
    disp(n);
end































