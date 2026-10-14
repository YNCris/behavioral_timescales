%{
    fig3, 
    the comparison between far-close and close-far

    story:
    The behavior state transition/interaction
    to
    The neural state transition

    假设：
    far-close：自身行为状态被同伴行为状态改变
               不同脑区处理不同层次的同伴行为
    close-far：同伴行为状态被自身行为状态改变
               不同脑区处理行为交互
%}
clear all
close all
addpath(genpath(pwd))
%% set path
rootpath = ['E:\MTPM_body_language'];

beh_video_path = [rootpath,'\raw_data\behavior_all'];

bea_path = [beh_video_path,'\BeA_path'];

process_tpm_path = [rootpath,...
    '\raw_data\tpm_suite2p\process'];

beh_neu_path = [rootpath,'\beh_neu_20240412'];
%% load data
fileFolder = fullfile(beh_neu_path);
dirOutput = dir(fullfile(fileFolder,'free*-cebra.mat'));
cebraNames = {dirOutput.name}';

cebra_cell = cell(size(cebraNames,1),13);
cebra_cell(:,1) = cebraNames;

smo_win = 60;

for k = 1:size(cebra_cell,1)
    tempdata = load([beh_neu_path,'\',cebraNames{k}]);
    cebra_cell{k,2} = tempdata.cebra;
    cebra_cell(k,3:10) = split(cebra_cell{k,1},'-');
    cebra_cell{k,11} = cebra_cell{k,5}(2:end);

    labelname = [cebra_cell{k,1}(1:(end-10)),'.mat'];

    templabel = load([beh_neu_path,'\',labelname]);

    neuname = [...
        cebra_cell{k,3},'-',...
        cebra_cell{k,4},'-',...
        cebra_cell{k,5},'-',...
        cebra_cell{k,6},'-',...
        cebra_cell{k,7},'-neu.mat',...
        ];

    tempneu = load([beh_neu_path,'\',neuname]);

    if strcmp(cebra_cell{k,8},'pose')
        temppose = templabel.coords3d;
        for m = 1:size(temppose,2)
            temppose(:,m) = smooth(...
                templabel.coords3d(:,m),smo_win);
        end
        cebra_cell{k,12} = temppose;
        cebra_cell{k,13} = tempneu.dff_smo_Fc';
    end

    if strcmp(cebra_cell{k,8},'beh_mod')
        cebra_cell{k,12} = templabel.beh_mod_list;
        cebra_cell{k,13} = tempneu.dff_smo_Fc';
    end

    if strcmp(cebra_cell{k,8},'seq')
        cebra_cell{k,12} = templabel.seq_label_list;
        cebra_cell{k,13} = tempneu.dff_smo_Fc';
    end
    disp(k)
end

dist_cell = cell(size(cebra_cell,1),3);
for k = 1:size(cebra_cell,1)
    distname = [...
        cebra_cell{k,3},'-',...
        cebra_cell{k,4},'-',...
        cebra_cell{k,5},'-',...
        cebra_cell{k,6},'-',...
        cebra_cell{k,7},'-',...
        'distance','-',...
        cebra_cell{k,9},'.mat'...
        ];
    tempdata = load([beh_neu_path,'\',distname]);

    dist_cell(k,:) = tempdata.dist_data;
    disp(k)
end

data_sample_cell = {};
for k = 1:size(cebra_cell,1)
    dscname = [...
        cebra_cell{k,3},'-',...
        cebra_cell{k,4},'-',...
        cebra_cell{k,5},'-',...
        cebra_cell{k,6},'-',...
        cebra_cell{k,7},'-',...
        cebra_cell{k,8},'-',...
        'dsc_fc_cf','-',...
        cebra_cell{k,9},'.mat'...
        ];
    tempdata = load([beh_neu_path,'\',dscname]);

    data_sample_cell = [data_sample_cell;...
        tempdata.data_sample_cell];
    disp(k)
end
%% create the labellist of the mov and seq
cebra_pose_cell = cebra_cell(...
    strcmp(cebra_cell(:,8),'pose'),:);
cebra_mov_cell = cebra_cell(...
    strcmp(cebra_cell(:,8),'beh_mod'),:);
cebra_seq_cell = cebra_cell(...
    strcmp(cebra_cell(:,8),'seq'),:);
% mov
unique_num_label_mov = unique(cell2mat(...
    cellfun(@(x) cell2mat(x(:,2)),...
    cebra_mov_cell(:,12),...
    'UniformOutput',false)));
% seq
unique_num_label_seq = unique(cell2mat(...
    cebra_seq_cell(:,12)));

cmap_mov = cbrewer2('Spectral',length(unique_num_label_mov));
cmap_seq = [1,1,1;cbrewer2('Spectral',...
    length(unique_num_label_seq)-1)];
%% plot canvas
hall = figure(1);
set(hall,'Position',[680,0,800,800])
set(hall,'color','white');
%% show the behavior correlations, 
% mov and seq level
% far-close
selidx1 = strcmp(data_sample_cell(:,7),'beh_mod');
selidx2 = strcmp(data_sample_cell(:,7),'seq');
selidx3 = strcmp(data_sample_cell(:,11),'far_close');

selidx = ((selidx1+selidx2).*selidx3)==1;

sel_dsc = data_sample_cell(selidx,:);

start_x = 0.06;
start_y = 0.7;

box_x = 0.2;
box_y = 0.25;

inter_x = 0.01;
inter_y = 0.01;

deng_x = 0.05;

fs = 30;
baseline_time = 5;%s
after_time = 20;%s

baseline_frame = baseline_time*fs;
after_frame = after_time*fs;

show_list = {...
    {'tpm','beh_mod'},{'tpm','seq'};...
    {'free','beh_mod'},{'free','seq'}...
    };

for m = 1:size(show_list,1)
    for n = 1:size(show_list,2)
        %% select data
        tempshowname = show_list{m,n};
        selidx1 = strcmp(sel_dsc(:,8),tempshowname{1});
        selidx2 = strcmp(sel_dsc(:,7),tempshowname{2});

        selidx = (selidx1.*selidx2)==1;

        tempdsc = sel_dsc(selidx,:);
        
        if n == 1
            tempmovlist = cell2mat(cellfun(...
                @(x) cell2mat(x(:,2))',...
                tempdsc(:,14),...
                'UniformOutput',false));
            %sort
            if m == 1
                D = pdist(tempmovlist,'hamming');
                Z = squareform(D);
                tree = linkage(Z, 'ward','euclidean');
                leafOrder_beh = optimalleaforder(tree,D);
            end

            sortmovlist = tempmovlist(leafOrder_beh,:);

            showlist = sortmovlist;
        elseif n == 2
            tempseqlist = cell2mat(cellfun(...
                @(x) x', tempdsc(:,14),...
                'UniformOutput',false));
            sortseqlist = tempseqlist(leafOrder_beh,:);

            showlist = sortseqlist;
            
        end
        %% show
        subplot('Position',[...
            start_x+(n-1)*(box_x+inter_x),...
            start_y-(m-1)*(box_y+inter_y),...
            box_x,box_y])
        imagesc(showlist)

        set(gca,'TickDir','out')
        box off
    end
end

































































