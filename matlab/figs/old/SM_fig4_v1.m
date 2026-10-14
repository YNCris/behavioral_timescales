%{
    umap, tsne, pca的latent embeddings对照，时间变量
%}
clear all
close all
%% set path
rootpath = ['X:\hanyaning\multi_mice_test\Social_analysis\' ...
    'data\MTPM_social_20220228_all'];
datapath = [rootpath,'\recluster_data'];
%% load data
load([datapath,'/umap_tsne_pca_embed_cell_20230613.mat']);
load([datapath,'/embed_cell_20230613.mat']);
%% plot canvas
hall = figure(1);
set(hall,'Position',[900,100,800,800])
set(hall,'color','white');
%% show
start_x = 0.03;
start_y = 0.85;
box_x = 0.09;
box_y = box_x;
inter_x = 0.005;
inter_y = inter_x;

big_y_bias = 0.3;

x_num = 10;
y_num = 3;

xy_bias = 5;

cmaplist_time = cbrewer2('Spectral',9000);


% umap
count = 1;
for m = 1:x_num
    for n = 1:y_num
        embedding = umap_tsne_pca_embed_cell{count,1};
        subplot('Position',...
            [start_x+(m-1)*(box_x+inter_x),...
             start_y-(n-1)*(box_y+inter_y),...
             box_x,box_y])
        scatter(embedding(:,1),embedding(:,2),...
            2*ones(size(embedding,1),1),cmaplist_time,...
            'filled')
        set(gca,'XTick',[],'YTick',[])

        min_x = min(embedding(:,1));
        max_x = max(embedding(:,1));
        min_y = min(embedding(:,2));
        max_y = max(embedding(:,2));
        axis([min_x-xy_bias,max_x+xy_bias,...
            min_y-xy_bias,max_y+xy_bias])
        box on
        count = count+1;
    end
end

% tsne
count = 1;
for m = 1:x_num
    for n = 1:y_num
        embedding = umap_tsne_pca_embed_cell{count,2};
        subplot('Position',...
            [start_x+(m-1)*(box_x+inter_x),...
             start_y-big_y_bias-(n-1)*(box_y+inter_y),...
             box_x,box_y])
        scatter(embedding(:,1),embedding(:,2),...
            2*ones(size(embedding,1),1),cmaplist_time,...
            'filled')
        set(gca,'XTick',[],'YTick',[])

        min_x = min(embedding(:,1));
        max_x = max(embedding(:,1));
        min_y = min(embedding(:,2));
        max_y = max(embedding(:,2));
        axis([min_x-xy_bias,max_x+xy_bias,...
            min_y-xy_bias,max_y+xy_bias])
        box on
        count = count+1;
    end
end

% pca
count = 1;
for m = 1:x_num
    for n = 1:y_num
        embedding = umap_tsne_pca_embed_cell{count,3};
        subplot('Position',...
            [start_x+(m-1)*(box_x+inter_x),...
             start_y-2*big_y_bias-(n-1)*(box_y+inter_y),...
             box_x,box_y])
        scatter(embedding(:,1),embedding(:,2),...
            2*ones(size(embedding,1),1),cmaplist_time,...
            'filled')
        set(gca,'XTick',[],'YTick',[])

        min_x = min(embedding(:,1));
        max_x = max(embedding(:,1));
        min_y = min(embedding(:,2));
        max_y = max(embedding(:,2));
        axis([min_x-xy_bias,max_x+xy_bias,...
            min_y-xy_bias,max_y+xy_bias])
        box on
        count = count+1;
    end
end















