%{
    lde of far-close-far of each mouse
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
%% split far-close-far trial
fs = 30;
baseline_far_time = 5;%s
after_far_time = 5;%s
min_close_time = 2;%s
max_close_time = 10;%s

baseline_far_frame = baseline_far_time*fs;
after_far_frame = after_far_time*fs;
min_close_frame = min_close_time*fs;
max_close_frame = max_close_time*fs;

fcf_cell = {};

for k = 1:size(all_data_cell,1)
    %% load data
    tempdist = all_data_cell{k,9};
    
    %% select trials
    distsavelist = idx2savelist(tempdist{2});

    all_close_list = distsavelist(distsavelist(:,3)==1,:);

    all_close_list(all_close_list(:,1)<baseline_far_frame,:) = [];
    all_close_list(all_close_list(:,2)>...
        length(tempdist{2})-after_far_frame,:) = [];
    all_close_list(...
        (all_close_list(:,2)-all_close_list(:,1))<...
        min_close_frame,:) = [];
    all_close_list(...
        (all_close_list(:,2)-all_close_list(:,1))>...
        max_close_frame,:) = [];

    selidx = zeros(size(all_close_list,1),1);

    for m = 1:size(all_close_list,1)
        tempstart = all_close_list(m,1);
        tempend = all_close_list(m,2);
        seldata_baseline = tempdist{2}(...
            (tempstart-baseline_far_frame):(tempstart-1));
        seldata_after = tempdist{2}(...
            (tempend+1):(tempend+after_far_frame));

        if sum(seldata_baseline)==0 && sum(seldata_after)==0
            selidx(m,1) = 1;
        end
    end

    sel_close_list = all_close_list(selidx==1,:);
    %% append data
    for m = 1:size(sel_close_list,1)
        tempstart = sel_close_list(m,1)-baseline_far_frame;
        tempend = sel_close_list(m,2)+after_far_frame;

        newname = [all_data_cell{k,1},'-',num2str(m)];
        all_data_2 = all_data_cell{k,2}(tempstart:tempend,:);
        all_data_3 = all_data_cell{k,3}(tempstart:tempend,:);
        all_data_4 = all_data_cell{k,4}(tempstart:tempend,:);
        all_data_5 = all_data_cell{k,5}(tempstart:tempend,:);
        all_data_6 = all_data_cell{k,6}(tempstart:tempend,:);
        all_data_7 = all_data_cell{k,7}(tempstart:tempend,:);
        all_data_8 = all_data_cell{k,8}(tempstart:tempend,:);
        all_data_9 = all_data_cell{k,9}{3}(tempstart:tempend,:);

        fcf_cell = [fcf_cell;...
            {newname,all_data_2,all_data_3,all_data_4,...
            all_data_5,all_data_6,all_data_7,all_data_8,...
            all_data_9,all_data_cell{k,1}}];

        unique(all_data_5)
    end
    %%
    disp(k)
end
%% show mov and seq of all the trials
% sort data by length
fcf_length = cell2mat(cellfun(@(x) size(x,1),fcf_cell(:,2),...
    'UniformOutput',false));

[~,sortidx] = sort(fcf_length,'descend');

sort_fcf_cell = fcf_cell(sortidx,:);
%% create the unique_mov and unique_seq
all_mov = [];
all_mov_name = {};
for k = 1:size(fcf_cell,1)
    all_mov = [all_mov;...
        cell2mat(fcf_cell{k,4}(:,2));...
        cell2mat(fcf_cell{k,7}(:,2))];
    all_mov_name = [all_mov_name;...
        fcf_cell{k,4}(:,1);...
        fcf_cell{k,7}(:,1)];
end
unique_mov = unique(all_mov);
cmap_mov = cbrewer2('BuPu',length(unique_mov));

uniuqe_mov_name = cell(size(unique_mov));
for k = 1:size(unique_mov,1)
    tempname = all_mov_name(unique_mov(k)==all_mov);
    uniuqe_mov_name{k} = tempname{1};
end

all_seq = [];
for k = 1:size(fcf_cell,1)
    all_seq = [all_seq;fcf_cell{k,5};fcf_cell{k,8}];
end
unique_seq = unique(all_seq);
unique_seq = unique_seq(2:end);
cmap_seq = cbrewer2('BuPu',length(unique_seq));

%% get unique mouse
spl_fcf_name = split(sort_fcf_cell(:,1),'-');

sort_fcf_name_list = cellfun(@(a,b,c,d,e) ...
    [a,'-',b,'-',c,'-',d,'-',e],...
    spl_fcf_name(:,1),...
    spl_fcf_name(:,2),...
    spl_fcf_name(:,3),...
    spl_fcf_name(:,4),...
    spl_fcf_name(:,5),...
    'UniformOutput',false);

unique_fcf_name = unique(sort_fcf_name_list);

fcf_mouse_cell = cell(size(unique_fcf_name,1),6);

for k = 1:size(fcf_mouse_cell,1)
    %% load
    fcf_mouse_cell{k,1} = unique_fcf_name{k};
    selidx = strcmp(fcf_mouse_cell{k,1},...
        sort_fcf_name_list);
    sel_fcf = sort_fcf_cell(selidx,2);
    fcf_mouse_cell{k,2} = cell2mat(sel_fcf);
    fcf_mouse_cell{k,3} = sel_fcf;
    %% calculate umap
    [~, umap, ~] = run_umap(...
        fcf_mouse_cell{k,2},'n_neighbors',8,...
    'min_dist',0.1,'metric','euclidean',...
    'n_components', 3, 'verbose', 'text',...
    'randomize',false);
    embedding = umap.embedding;
    %% split
    fcf_mouse_cell{k,4} = embedding;

    trial_size = cellfun(@(x) size(x,1),...
        fcf_mouse_cell{k,3},...
        'UniformOutput',false);

    end_pos = cumsum(cell2mat(trial_size));
    start_pos = [1;end_pos(1:(end-1))+1];

    spl_embed = cell(size(start_pos,1),1);
    for m = 1:size(start_pos,1)
        spl_embed{m,1} = embedding(...
            start_pos(m,1):end_pos(m,1),:);
    end

    fcf_mouse_cell{k,5} = spl_embed;
end
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

splname = split(fcf_mouse_cell(:,1),'-');
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
        sel_brain_idx = strcmp(show_brain{m},all_brain_name);
        sel_mouse_idx = strcmp(all_mouse_idx,num2str(n));
        selidx = sel_brain_idx&sel_mouse_idx;

        tempembed = fcf_mouse_cell{selidx,5};

         subplot('Position',...
                [start_x+(n-1)*(box_x+inter_x),...
                start_y-(m-1)*(box_y+inter_y),box_x,box_y])

        for k = 1:size(tempembed,1)
            score = tempembed{k,1};
            show_cmap = mat2gray(...
            imresize(time_cmap,[size(score,1),3]));

            plot3(score(:,1),score(:,2),score(:,3),'-k')
            hold on
            scatter3(score(:,1),score(:,2),score(:,3),...
                5*ones(size(score,1),1),show_cmap,'filled')
            hold on
        end
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