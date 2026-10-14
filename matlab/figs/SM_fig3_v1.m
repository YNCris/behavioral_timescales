%{
    可视化pdist矩阵
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

all_data_cell = cell(size(neuNames,1),12);
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
    disp(k)
end
%% pdist
pdist_cell = cell(size(all_data_cell,1),1);

res_size = 10;

for k = 1:size(all_data_cell,1)
    tempumap = all_data_cell{k,10};
    distmat = squareform(pdist(tempumap));
    res_distmat = distmat(1:res_size:end,1:res_size:end);

    pdist_cell{k,1} = res_distmat;
    disp(k)
end
%% plot canvas
hall = figure(1);
set(hall,'Position',[680,0,800,800])
set(hall,'color','white');
%% show distmat
start_x = 0.03;
start_y = 0.7;

box_x = 0.17;
box_y = box_x;

inter_x = 0.015;
inter_y = 0.03;

time_cmap = flipud(cbrewer2('Blues',256));

splname = split(all_data_cell(:,1),'-');
all_mouse_idx = cellfun(@(x) x(1),...
    splname(:,3),'UniformOutput',false);

all_brain_name = cellfun(@(x) x(2:end),...
    splname(:,3),'UniformOutput',false);

show_brain = {...
    'tpmss';...
    'tpmpfc';...
    'tpmm'};

show_brain_name = {...
    'S1';...
    'dmPFC';...
    'M1'};

show_mouse = 1:5;

for m = 1:size(show_brain,1)
    for n = 1:length(show_mouse)
        sel_brain_idx = strcmp(show_brain{m},...
            all_brain_name);
        sel_mouse_idx = strcmp(all_mouse_idx,...
            num2str(n));
        selidx = sel_brain_idx&sel_mouse_idx;

        tempdist = pdist_cell{selidx,1};

        temph = subplot('Position',...
                [start_x+(n-1)*(box_x+inter_x),...
                start_y-(m-1)*(box_y+inter_y),box_x,box_y]);

        imagesc(tempdist)
        colormap(temph,time_cmap)

        set(gca,'TickDir','out')
        set(gca,'FontSize',6)
        
        box off

        title([show_brain_name{m},' mouse ',num2str(n)])

        if n == 1
            ylabel('Time (min)')
            set(gca,'YTickLabel',[0,15])
        else
            set(gca,'YTickLabel',[])
        end
        if m == 3
            xlabel('Time (min)')
            set(gca,'XTickLabel',[0,15])
        else
            set(gca,'XTickLabel',[])
        end

        set(gca,'XTick',[1,2700])
        set(gca,'YTick',[1,2700])

        
    end
end

% colorbar
cbar_box_x = 0.006;
cbar_box_y = 0.05;

cbar_inter_x = -0.01;

temph = subplot('Position',[...
    start_x+5*(box_x+inter_x)+cbar_inter_x,...
    start_y+box_y-cbar_box_y,...
    cbar_box_x,cbar_box_y]);
imagesc(flipud((1:256)'))
colormap(temph,time_cmap)
set(gca,'XTick',[],'YTick',[])

text(0.5,280,'0','FontSize',6,'VerticalAlignment','middle')
text(0.5,-30,'1','FontSize',6,'VerticalAlignment','middle')

text(2.5,128,'Distance','FontSize',6,'Rotation',90,...
    'HorizontalAlignment','center')

%% pdist


%% create swiss roll data
N = 2^11; % number of points considered
t = rand(1,N);
t = sort(4*pi*sqrt(t))'; 
%t = sort(generateRVFromRand(2^11,@(x)1/32/pi^2*x,@(x)4*pi*sqrt(x)))';
z = 8*pi*rand(N,1); % random heights
x = (t+.1).*cos(t);
y = (t+.1).*sin(t);
data = tempneu; % data of interest is in the form of a n-by-3 matrix
%% visualize the data
cmap = jet(size(data,1));
% scatter3(x,y,z,20,cmap);
% title('Original data');
%% Changing these values will lead to different nonlinear embeddings
knn    = ceil(0.03*N); % each patch will only look at its knn nearest neighbors in R^d
sigma2 = 100; % determines strength of connection in graph... see below
%% now let's get pairwise distance info and create graph 
m                = size(data,1);
dt               = squareform(pdist(data));
[srtdDt,srtdIdx] = sort(dt,'ascend');
dt               = srtdDt(1:knn+1,:);
nidx             = srtdIdx(1:knn+1,:);
% nz   = dt(:) > 0;
% mind = min(dt(nz));
% maxd = max(dt(nz));
% compute weights
tempW  = exp(-dt.^2/sigma2); 
% build weight matrix
i = repmat(1:m,knn+1,1);
W = sparse(i(:),double(nidx(:)),tempW(:),m,m); 
W = max(W,W'); % for undirected graph.
% The original normalized graph Laplacian, non-corrected for density
ld = diag(sum(W,2).^(-1/2));
DO = ld*W*ld;
DO = max(DO,DO');%(DO + DO')/2;
% get eigenvectors
[v,d] = eigs(DO,10,'la');
eigVecIdx = nchoosek(1:3,2);
%%
for i = 1:size(eigVecIdx,1)
    figure,scatter(v(:,eigVecIdx(i,1)),v(:,eigVecIdx(i,2)),20,cmap)
    title('Nonlinear embedding');
    xlabel(['\phi_',num2str(eigVecIdx(i,1))]);
    ylabel(['\phi_',num2str(eigVecIdx(i,2))]);
end
figure,subplot(1,2,1)
scatter3(x,y,z,20,cmap);
title('Original data');
subplot(1,2,2)
scatter(v(:,2),v(:,4),20,cmap)
title('Nonlinear embedding')




