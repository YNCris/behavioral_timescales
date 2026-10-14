%{
    cebra quantification
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

all_data_cell = cell(size(neuNames,1),8);
%{rootname,neudata,pose_self,mov_self,seq_self,
% pose_partner,mov_partner,seq_partner, distance}

for k = 1:size(all_data_cell,1)
    rootname = neuNames{k}(1:(end-8));
    all_data_cell{k,1} = rootname;
    
    tempdata = load([beh_neu_path,'\',neuNames{k}]);
    all_data_cell{k,2} = tempdata.dff_smo_Fc';

    tempdata = load([beh_neu_path,'\',rootname,...
        '-pose-tpm-reconstruction_error.mat']);
    all_data_cell{k,3} = tempdata.dist_error;

    tempdata = load([beh_neu_path,'\',rootname,...
        '-beh_mod-tpm-reconstruction_error.mat']);
    all_data_cell{k,4} = 1-tempdata.dist_error;

    tempdata = load([beh_neu_path,'\',rootname,...
        '-seq-tpm-reconstruction_error.mat']);
    all_data_cell{k,5} = 1-tempdata.dist_error;

    tempdata = load([beh_neu_path,'\',rootname,...
        '-pose-free-reconstruction_error.mat']);
    all_data_cell{k,6} = tempdata.dist_error;

    tempdata = load([beh_neu_path,'\',rootname,...
        '-beh_mod-free-reconstruction_error.mat']);
    all_data_cell{k,7} = 1-tempdata.dist_error;

    tempdata = load([beh_neu_path,'\',rootname,...
        '-seq-free-reconstruction_error.mat']);
    all_data_cell{k,8} = 1-tempdata.dist_error;
    
    disp(k)
end
%% plot canvas
hall = figure(1);
set(hall,'Position',[680,0,800,800])
set(hall,'color','white');
%% show
start_x = 0.05;
start_y = 0.8;

box_x = 0.2;
box_y = 0.15;

inter_x = 0.04;

show_title = {...
    'Poses';...
    'Movements';...
    'Sequences'};

show_ylabel = {...
    'MSE of Pixels';...
    'Accuracy';...
    'Accuracy'};

show_x_label = {...
    'S1-Subject';...
    'dmPFC-Subject';...
    'M1-Subject';...
    'S1-Object';...
    'dmPFC-Object';...
    'M1-Object';...
    };

brain_seq = {...
    'tpmss','S1';...
    'tpmpfc','dmPFC';...
    'tpmm','M1'};

splname1 = split(all_data_cell(:,1),'-');

raw_brain_name = cellfun(@(x) x(2:end),...
    splname1(:,3),'UniformOutput',false);

neu_cmap = cbrewer2('Paired',12);

in_c = neu_cmap(5,:);
de_c = neu_cmap(1,:);
no_c = neu_cmap(3,:);

brain_c = [...
    de_c;...
    in_c;...
    no_c];

show_brain_c = [brain_c;brain_c];

xlist = 1:6;

bar_w = 0.6;

cap_size = 2;

x_bias = 0.3;

axis_list = [...
    0.3,6.7,0,10;...
    0.3,6.7,0,1;...
    0.3,6.7,0,1];

mk_size = 2;

stat_cell = cell(1,3);
for k = 1:3
    %% sel data
    sel_self_data = cell2mat(all_data_cell(:,k+2));
    sel_partner_data = cell2mat(all_data_cell(:,k+5));

    bar_data = zeros(5,6);

    for m = 1:size(brain_seq,1)
        selidx = strcmp(raw_brain_name,brain_seq{m,1});
        bar_data(:,m) = sel_self_data(selidx,:);
    end

    for m = 1:size(brain_seq,1)
        selidx = strcmp(raw_brain_name,brain_seq{m,1});
        bar_data(:,m+3) = sel_partner_data(selidx,:);
    end

    mean_bar_data = mean(bar_data);

    std_bar_data = std(bar_data)./sqrt(size(bar_data,1));
    %% comp
    stat_x = [...
        bar_data(:,1);...
        bar_data(:,2);...
        bar_data(:,3);...
        bar_data(:,4);...
        bar_data(:,5);...
        bar_data(:,6);...
        ];

    stat_y = [...
        1*ones(5,1);...
        2*ones(5,1);...
        3*ones(5,1);...
        4*ones(5,1);...
        5*ones(5,1);...
        6*ones(5,1);...
        ];

    [~,~,stats] = anova1(stat_x,stat_y,'off');
    results = multcompare(stats,'Display','off');

    sel_sign = results(:,end)<0.05;

    disp(k)
    disp(mean(stat_x))
    disp(std(stat_x)./sqrt(length(stat_x)))
    %disp(results(sel_sign,:))
    % disp(results)
    stat_cell{k} = results;
    %% show
    subplot('Position',[...
        start_x+(k-1)*(box_x+inter_x),...
        start_y,box_x,box_y])
    
    for m = 1:size(mean_bar_data,2)
        bar(m,mean_bar_data(m),bar_w,...
            'FaceColor',show_brain_c(m,:))
        hold on
        errorbar(m,mean_bar_data(m),std_bar_data(m),...
            'CapSize',cap_size,'Color','k')
        hold on
        plot(m*ones(size(bar_data,1),1)+x_bias,...
            bar_data(:,m),'o',...
            'MarkerFaceColor','w',...
            'MarkerEdgeColor','k',...
            'MarkerSize',mk_size,...
            'LineWidth',0.25)
        hold on
    end
    
    hold off
    title(show_title{k})

    ylabel(show_ylabel{k})

    set(gca,'FontSize',6)

    set(gca,'TickDir','out')

    set(gca,'XTick',xlist)

    set(gca,'XTickLabel',show_x_label)

    box off

    axis(axis_list(k,:))
end

%% compare movement and sequences
start_x = 0.79;
start_y = 0.8;

box_x = 0.2;
box_y = 0.15;

show_data = cell2mat(all_data_cell(:,[4,5,7,8]));

mean_show_data = mean(show_data);
std_show_data = std(show_data)./sqrt(size(show_data,1));

bar_c = 0.7*ones(1,3);

x_tick_label_list = {...
    'Subject-Movement';...
    'Subject-Sequence';...
    'Object-Movement';...
    'Object-Sequence';...
    };



subplot('Position',[start_x,start_y,box_x,box_y])

bar(1:4,mean_show_data,bar_w,...
    'FaceColor',bar_c)
hold on
errorbar(1:4,mean_show_data,std_show_data,...
    'CapSize',cap_size,'LineStyle','none',...
    'Color','k')
hold on
for k = 1:size(show_data,1)
    plot((1:4)+x_bias,show_data(k,:),'-k',...
        'LineWidth',0.25)
    hold on
end
for k = 1:4
    plot(k*ones(size(show_data,1),1)+x_bias,...
        show_data(:,k),...
        'o','MarkerEdgeColor','k',...
        'MarkerFaceColor','w',...
        'MarkerSize',4,...
        'LineWidth',0.25)
    hold on
end
hold off

box off
set(gca,'FontSize',6)
set(gca,'TickDir','out')

set(gca,'XTickLabel',x_tick_label_list)

axis([0.3,4.7,0,1])
ylabel('Accuracy')

%% show stat
stat_x = [...
    show_data(:,1);...
    show_data(:,2);...
    show_data(:,3);...
    show_data(:,4);...
    ];

stat_y = [...
    1*ones(15,1);...
    2*ones(15,1);...
    3*ones(15,1);...
    4*ones(15,1);...
    ];

[~,~,stats] = anova1(stat_x,stat_y,'off');
results = multcompare(stats,'Display','off');

sel_sign = results(results(:,end)<0.05,[1,2,6]);






