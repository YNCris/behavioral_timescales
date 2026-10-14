%{
    fig3, body language in latent embeddings
%}
clear all
close all
addpath(genpath(pwd))
%% set path
rootpath = ['X:\hanyaning\multi_mice_test\Social_analysis\' ...
    'data\MTPM_social_20220228_all'];
datapath = [rootpath,'\recluster_data'];
%% plot canvas
hall = figure(1);
set(hall,'Position',[900,100,800,800])
set(hall,'color','white');
%% load data
fileFolder = fullfile(datapath);
dirOutput = dir(fullfile(fileFolder,'*single_animal_embedding.mat'));
fileNames = {dirOutput.name}';

embed_cell = cell(size(fileNames,1),1);
for k = 1:size(fileNames,1)
    tempdata = load([datapath,'\',fileNames{k,1}]);
    embed_cell{k,1} = tempdata;
end
%% show latent embedding across time
start_x = 0.03;
start_y = 0.8;
box_x = 0.15;
box_y = box_x;
inter_x = 0.05;
for k = 1:size(embed_cell,1)
    %%
    embed = embed_cell{k,1}.single_animal_embedding;
    %% plot
    subplot('Position',...
        [start_x+(k-1)*(inter_x+box_x),start_y,box_x,box_y])
    scatter3(embedding(:,1),embedding(:,2),...
            2*ones(size(embedding,1),1),cmaplist_time,...
            'filled')
end


































