%{
    show embedding
    show neural modulation
    far close far
%}
clear all
close all
%% set path
rootpath = ['H:\MTPM_body_language'];
beh_neu_path = [rootpath,'\beh_neu_20250918'];
%% load data
fileFolder = fullfile(beh_neu_path);
dirOutput = dir(fullfile(fileFolder,'*-neu.mat'));
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
%% split free and op fcf
splname = split(fcf_cell(:,10),'-');
sel_free_idx = strcmp(splname(:,1),'free');
sel_tpm_idx = strcmp(splname(:,1),'tpm');

free_fcf_cell = fcf_cell(sel_free_idx,:);
tpm_fcf_cell = fcf_cell(sel_tpm_idx,:);
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
%% calculate all umap
umap_cell = cell(size(all_data_cell,1),1);
for k = 1:size(all_data_cell,1)
    tempneu = all_data_cell{k,2};
    [~, umap, ~] = run_umap(...
        tempneu,'n_neighbors',8,...
    'min_dist',0.1,'metric','euclidean',...
    'n_components', 3, 'verbose', 'text',...
    'randomize',false);
    embedding = umap.embedding;
    umap_cell{k,1} = embedding;
end
%% plot canvas
hall = figure(1);
set(hall,'Position',[980,100,800,800])
set(hall,'color','white');
%% show embedding
show_brain_name = {...
    '6tpmpfc';...
    '7tpmpfc';...
    '8tpmpfc';...
    '9tpmpfc';...
    '10tpmpfc';...
    };

splname = split(neuNames,'-');

start_x = 0.03;
start_y = 0.8;

box_x = 0.15;
box_y = box_x;

inter_x = 0.05;
inter_y = 0.05;

time_cmap = cbrewer2('Spectral',256);

for k = 1:size(show_brain_name,1)
    %%
    tempbrainname = show_brain_name{k,1};
    selidx = strcmp(splname(:,3),tempbrainname);
    sel_umap = umap_cell(selidx,:);

    %% show
    subplot('Position',[...
    start_x+(k-1)*(box_x+inter_x),start_y,...
    box_x,box_y])

    score = sel_umap{1};
    show_cmap = mat2gray(...
    imresize(time_cmap,[size(score,1),3]));

    plot3(score(:,1),score(:,2),score(:,3),'-',...
        'LineWidth',0.25,'Color',0.8*ones(1,3))
    hold on
    scatter3(score(:,1),score(:,2),score(:,3),...
        2*ones(size(score,1),1),show_cmap,'filled')
    hold off

    min_x = min(score(:,1));
    max_x = max(score(:,1));
    min_y = min(score(:,2));
    max_y = max(score(:,2));
    min_z = min(score(:,3));
    max_z = max(score(:,3));

    axis([min_x,max_x,min_y,max_y,min_z,max_z])

    % axis off
    grid on
    set(gca,'XTickLabel',[],'YTickLabel',[],'ZTickLabel',[])
    xlabel('UMAP 1')
    ylabel('UMAP 2')
    zlabel('UMAP 3')
    set(gca,'FontSize',6)
    set(gca,'TickLength',[0,0])
    title(show_brain_name{k})

    %%
    subplot('Position',[...
        start_x+(k-1)*(box_x+inter_x),...
        start_y-box_y-inter_y,...
        box_x,box_y])
    score = sel_umap{2};
    show_cmap = mat2gray(...
    imresize(time_cmap,[size(score,1),3]));

    plot3(score(:,1),score(:,2),score(:,3),'-',...
        'LineWidth',0.25,'Color',0.8*ones(1,3))
    hold on
    scatter3(score(:,1),score(:,2),score(:,3),...
        2*ones(size(score,1),1),show_cmap,'filled')
    hold off

    min_x = min(score(:,1));
    max_x = max(score(:,1));
    min_y = min(score(:,2));
    max_y = max(score(:,2));
    min_z = min(score(:,3));
    max_z = max(score(:,3));

    axis([min_x,max_x,min_y,max_y,min_z,max_z])

    % axis off
    grid on
    set(gca,'XTickLabel',[],'YTickLabel',[],'ZTickLabel',[])
    xlabel('UMAP 1')
    ylabel('UMAP 2')
    zlabel('UMAP 3')
    set(gca,'FontSize',6)
    set(gca,'TickLength',[0,0])
end




