%{
    lde of all the neural data of all mice
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

all_data_cell = cell(size(neuNames,1),9);
%{rootname,neudata,pose_self,mov_self,seq_self,
% pose_partner,mov_partner,seq_partner, distance}

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
    disp(k)
end
%% UMAP of all data
umap_cell = cell(size(all_data_cell,1),1);

for k = 1:size(umap_cell,1)
    %%
    tempneu = all_data_cell{k,2};
    rootname = all_data_cell{k,1};
    %%
    [~, umap, ~] = run_umap(...
        tempneu,'n_neighbors',8,...
    'min_dist',0.1,'metric','euclidean',...
    'n_components', 3, 'verbose', 'text',...
    'randomize',false);

    umap_embedding = umap.embedding;

    umap_cell{k,1} = umap_embedding;

    save([beh_neu_path,'\',rootname,...
        '-neu_umap.mat'],'umap_embedding')

    disp(k)
end
%% PCA of all data
pca_cell = cell(size(all_data_cell,1),1);

for k = 1:size(pca_cell,1)
    %% 
    tempneu = all_data_cell{k,2};
    rootname = all_data_cell{k,1};
    %% 
    [coeff, score, latent, tsquared, explained, mu] = ...
        pca(tempneu');

    cumsum_exp = cumsum(explained);

    pca_embedding = {...
        coeff, score, latent,...
        tsquared, explained, mu,cumsum_exp};

    %%
    pca_cell{k,1} = pca_embedding;

    save([beh_neu_path,'\',rootname,...
        '-neu_pca.mat'],'pca_embedding')

    disp(k)
end
%% show umap embedding
%% plot canvas
hall = figure(1);
set(hall,'Position',[680,0,800,800])
set(hall,'color','white');
%% show umap 3d
start_x = 0.03;
start_y = 0.7;

box_x = 0.17;
box_y = box_x;

inter_x = 0.01;
inter_y = 0.03;

time_cmap = cbrewer2('Spectral',256);

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

        tempembed = umap_cell{selidx,1};

         subplot('Position',...
                [start_x+(n-1)*(box_x+inter_x),...
                start_y-(m-1)*(box_y+inter_y),box_x,box_y])

        score = tempembed;
        show_cmap = mat2gray(...
        imresize(time_cmap,[size(score,1),3]));

        plot3(score(:,1),score(:,2),score(:,3),'-k')
        hold on
        scatter3(score(:,1),score(:,2),score(:,3),...
            1*ones(size(score,1),1),show_cmap,'filled')
        hold off
        title([show_brain_name{m},' mouse ',num2str(n)])

        grid on

        set(gca,'TickDir','out')
        set(gca,'FontSize',6)
        set(gca,'XTickLabel',[],'YTickLabel',[],'ZTickLabel',[])

        if n == 1
            zlabel('UMAP 3')
        end
        xlabel('UMAP 1')
        ylabel('UMAP 2')
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

text(0.5,280,'-5','FontSize',6,'VerticalAlignment','middle')
text(0.5,-30,'max','FontSize',6,'VerticalAlignment','middle')

text(2.5,128,'Time (s)','FontSize',6,'Rotation',90,...
    'HorizontalAlignment','center')









