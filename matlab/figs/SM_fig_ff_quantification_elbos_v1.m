%{
    flow field quantification
%}
clear all
close all
addpath(genpath(pwd))
%% set path
rootpath = ['E:\MTPM_body_language'];
beh_neu_path = [rootpath,'\beh_neu_20240412'];
dy_path = [rootpath,'\dynamic_model_data_20241113'];
%% load dynamics
load_brain_name = {...
    'tpmss';...
    'tpmpfc';...
    'tpmm'};

brain_dy_cell = cell(3,size(load_brain_name,1));

for k = 1:size(brain_dy_cell,1)
    %%
    all_name = [load_brain_name{k,1},'_all_20241113.mat'];
    close_name = [load_brain_name{k,1},'_20241113.mat'];
    far_name = [load_brain_name{k,1},'_close_far_20241113.mat'];

    tempmat_all = load([dy_path,'\',all_name]);
    tempmat_close = load([dy_path,'\',close_name]);
    tempmat_far = load([dy_path,'\',far_name]);

    brain_dy_cell{1,k} = tempmat_close;
    brain_dy_cell{2,k} = tempmat_far;
    brain_dy_cell{3,k} = tempmat_all;
end
%% plot canvas
hall = figure(1);
set(hall,'Position',[680,0,800,800])
set(hall,'color','white');
%% show
neu_cmap = cbrewer2('Paired',12);

in_c = neu_cmap(5,:);
de_c = neu_cmap(1,:);
no_c = neu_cmap(3,:);

brain_c = [...
    de_c;...
    in_c;...
    no_c];

start_x = 0.05;
start_y = 0.8;

box_x = 0.25;
box_y = 0.15;

inter_x = 0.05;

show_title = {...
    'Far-close-far';...
    'Close-far';...
    'All'};

for m = 1:size(brain_dy_cell,1)
    subplot('Position',[...
        start_x+(m-1)*(box_x+inter_x),...
        start_y,box_x,box_y])
    for n = 1:size(brain_dy_cell,2)
        %
        temps = brain_dy_cell{m,n};
        temp_e = temps.q_dist_elbos_lem;

        plot(temp_e(1:500),'-','Color',brain_c(n,:))
        hold on
        
    end
    box off
    set(gca, 'XScale', 'log')
    set(gca,'TickDir','out')
    set(gca,'FontSize',6)

    ylabel('ELBO')
    xlabel('Iteration')

    title(show_title{m})
end
hold off































