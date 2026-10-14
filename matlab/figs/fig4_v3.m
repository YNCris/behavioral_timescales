%{
    研究close后的far
%}
clear all
close all
addpath(genpath(pwd))
%% set path
rootpath = ['X:\hanyaning\MTPM_body_language'];
beh_neu_path = [rootpath,'\beh_neu_20240412'];
figpath = [rootpath,'\paper\figs\fig4'];
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

%% load fracs
[out, ~, ~] = importdata(...
    [figpath,'\self_2_state_mov_frac_20240909.xlsx']);
sign_self_mov_frac = out.textdata(:,5);

[out, ~, ~] = importdata(...
    [figpath,'\partner_2_state_mov_frac_20240909.xlsx']);
sign_partner_mov_frac = out.textdata(:,5);
%% split far-close-far trial
fs = 30;
baseline_close_time = 1;%s
min_far_time = 10;%s
max_far_time = 180;%s

baseline_close_frame = baseline_close_time*fs;
min_far_frame = min_far_time*fs;
max_far_frame = max_far_time*fs;

cf_cell = {};

for k = 1:size(all_data_cell,1)
    %% load data
    tempdist = all_data_cell{k,9};
    
    %% select trials
    distsavelist = idx2savelist(tempdist{2});

    all_far_list = distsavelist(distsavelist(:,3)==0,:);

    all_far_list(all_far_list(:,1)<...
        baseline_close_frame,:) = [];
    all_far_list(...
        (all_far_list(:,2)-all_far_list(:,1))<...
        min_far_frame,:) = [];
    all_far_list(...
        (all_far_list(:,2)-all_far_list(:,1))>...
        max_far_frame,:) = [];

    selidx = zeros(size(all_far_list,1),1);

    for m = 1:size(all_far_list,1)
        tempstart = all_far_list(m,1);
        tempend = all_far_list(m,2);
        seldata_baseline = tempdist{2}(...
            (tempstart-baseline_close_frame):(tempstart-1));

        if sum(seldata_baseline)==baseline_close_frame
            selidx(m,1) = 1;
        end
    end

    all_far_list = all_far_list(selidx==1,:);
    %% append data
    for m = 1:size(all_far_list,1)
        tempstart = all_far_list(m,1)-baseline_close_frame;
        tempend = all_far_list(m,2);

        newname = [all_data_cell{k,1},'-',num2str(m)];
        all_data_2 = all_data_cell{k,2}(tempstart:tempend,:);
        all_data_3 = all_data_cell{k,3}(tempstart:tempend,:);
        all_data_4 = all_data_cell{k,4}(tempstart:tempend,:);
        all_data_5 = all_data_cell{k,5}(tempstart:tempend,:);
        all_data_6 = all_data_cell{k,6}(tempstart:tempend,:);
        all_data_7 = all_data_cell{k,7}(tempstart:tempend,:);
        all_data_8 = all_data_cell{k,8}(tempstart:tempend,:);
        all_data_9 = all_data_cell{k,9}{3}(tempstart:tempend,:);

        cf_cell = [cf_cell;...
            {newname,all_data_2,all_data_3,all_data_4,...
            all_data_5,all_data_6,all_data_7,all_data_8,...
            all_data_9,all_data_cell{k,1}},...
            all_data_cell{k,9}{1}(tempstart:tempend,:),...
            ];

        % unique(all_data_5)
    end
    %%
    disp(k)
end

%% create the unique_mov and unique_seq
all_mov = [];
all_mov_name = {};
for k = 1:size(cf_cell,1)
    all_mov = [all_mov;...
        cell2mat(cf_cell{k,4}(:,2));...
        cell2mat(cf_cell{k,7}(:,2))];
    all_mov_name = [all_mov_name;...
        cf_cell{k,4}(:,1);...
        cf_cell{k,7}(:,1)];
end
unique_mov = unique(all_mov);
cmap_mov = cbrewer2('BuPu',length(unique_mov));

unique_mov_name = cell(size(unique_mov));
for k = 1:size(unique_mov,1)
    tempname = all_mov_name(unique_mov(k)==all_mov);
    unique_mov_name{k} = tempname{1};
end

all_seq = [];
for k = 1:size(cf_cell,1)
    all_seq = [all_seq;cf_cell{k,5};cf_cell{k,8}];
end
unique_seq = unique(all_seq);
unique_seq = unique_seq(2:end);
cmap_seq = cbrewer2('BuPu',length(unique_seq));

%% plot canvas
hall = figure(1);
set(hall,'Position',[680,0,800,800])
set(hall,'color','white');

%% draw two mice close-far
start_x = 0.03;
start_y = 0.94;

box_x = 0.12;
box_y = 0.1;

% % two mice
% subplot('Position',[start_x,start_y,box_x,box_y])
% box on
% set(gca,'XTick',[],'YTick',[])

% distance, 二次函数表示远近远
% start_x = 0.01;
start_y = 0.88;
% 
% box_x = 0.138;
box_y = 0.1;
subplot('Position',[start_x,start_y,box_x,box_y])
x = 0:0.1:20;
y = sqrt(x);
plot(x,y,'-k')
xlabel('Time')
ylabel('Distance')
box off
set(gca,'XTick',[],'YTick',[])
set(gca,'FontSize',6)

%% show mov and seq of all the trials
% sort data by length
cf_length = cell2mat(cellfun(@(x) size(x,1),cf_cell(:,2),...
    'UniformOutput',false));

[~,sortidx] = sort(cf_length,'descend');

sort_cf_cell = cf_cell(sortidx,:);

%% extract seq
seq_cell = cell(size(unique_seq,1),1);
for k = 1:size(unique_seq,1)
    tempseq = unique_seq(k,1);
    saveseqlist = {};
    for m = 1:size(sort_cf_cell,1)
        seqlist_1 = sort_cf_cell{m,5};
        seqlist_2 = sort_cf_cell{m,8};
        movlist_1 = sort_cf_cell{m,4}(:,1);
        movlist_2 = sort_cf_cell{m,7}(:,1);
        movidxlist_1 = cell2mat(...
            sort_cf_cell{m,4}(:,2));
        movidxlist_2 = cell2mat(...
            sort_cf_cell{m,7}(:,2));

        savelist1 = idx2savelist(seqlist_1);
        savelist2 = idx2savelist(seqlist_2);

        selidx1 = savelist1(:,3)==tempseq;
        selidx2 = savelist2(:,3)==tempseq;
        
        if sum(selidx1) > 0
            selsavelist1 = savelist1(selidx1,:);
            for n = 1:size(selsavelist1,1)
                sel_movidxlist_1 = movidxlist_1(...
                    selsavelist1(1):selsavelist1(2));
                diffidx = [1;diff(sel_movidxlist_1)~=0];
                saveseqlist = [saveseqlist;...
                    {movlist_1(diffidx==1)'}];
            end    
        end

        if sum(selidx2) > 0
            selsavelist2 = savelist2(selidx2,:);
            for n = 1:size(selsavelist2,1)
                sel_movidxlist_2 = movidxlist_2(...
                    selsavelist2(1):selsavelist2(2));
                diffidx = [1;diff(sel_movidxlist_2)~=0];
                saveseqlist = [saveseqlist;...
                    {movlist_2(diffidx==1)'}];
            end    
        end   
    end
    seq_cell{k,1} = saveseqlist;
end

%% show mov and seq of self
start_x = 0.19;
start_y = 0.88;

box_x = 0.13;
box_y = 0.1;

inter_x = 0.03;
inter_y = 0.01;

x_tick = [1,30,330,630,930];
x_tick_label = [-1,0,10,20,30];

% create mov mat
pad_len = 4800;
self_mov_mat = -1*ones(size(sort_cf_cell,1),pad_len);
start_list = zeros(size(self_mov_mat,1),2);
end_list = zeros(size(self_mov_mat,1),2);

for k = 1:size(self_mov_mat,1)
    tempmov = cell2mat(sort_cf_cell{k,4}(:,2))';
    self_mov_mat(k,1:length(tempmov)) = tempmov;
    start_list(k,:) = [baseline_close_frame,k];
    end_list(k,:) = [length(tempmov),k];
end

temph = subplot('Position',[start_x,start_y,box_x,box_y]);
imagesc(self_mov_mat)
colormap(temph,[1,1,1;cmap_mov])
hold on
plot(start_list(:,1),start_list(:,2),'-k')
hold on
plot(end_list(:,1),end_list(:,2),'-k')
hold off

axis([0,630,0,size(start_list,1)])
box off
title('Self')

ylabel('Movements')

set(gca,'XTick',x_tick)
% set(gca,'XTickLabel',[])
set(gca,'XTickLabel',x_tick_label)

set(gca,'YTick',[1,size(self_mov_mat,1)])

set(gca,'TickDir','out')
set(gca,'FontSize',6)
xlabel('Time (s)')

% create seq mat
self_seq_mat = -1*ones(size(sort_cf_cell,1),pad_len);
start_list = zeros(size(self_seq_mat,1),2);
end_list = zeros(size(self_seq_mat,1),2);

for k = 1:size(self_seq_mat,1)
    tempseq = sort_cf_cell{k,5}';
    self_seq_mat(k,1:length(tempseq)) = tempseq;
    start_list(k,:) = [baseline_close_frame,k];
    end_list(k,:) = [length(tempseq),k];
end

temph = subplot('Position',[...
    start_x+2*(box_x+inter_x),...
    start_y,box_x,box_y]);
imagesc(self_seq_mat)
colormap(temph,[1,1,1;1,1,1;cmap_seq])
hold on
plot(start_list(:,1),start_list(:,2),'-k')
hold on
plot(end_list(:,1),end_list(:,2),'-k')
hold off
box off
axis([0,630,0,size(start_list,1)])

ylabel('Sequences')

set(gca,'XTick',x_tick)
set(gca,'XTickLabel',x_tick_label)

set(gca,'YTick',[1,size(self_seq_mat,1)])
set(gca,'YTickLabel',[])

set(gca,'TickDir','out')
set(gca,'FontSize',6)
title('Self')
xlabel('Time (s)')

% show mov and seq of partner
% create mov mat
part_mov_mat = -1*ones(size(sort_cf_cell,1),pad_len);
start_list = zeros(size(part_mov_mat,1),2);
end_list = zeros(size(part_mov_mat,1),2);

for k = 1:size(part_mov_mat,1)
    tempmov = cell2mat(sort_cf_cell{k,7}(:,2))';
    part_mov_mat(k,1:length(tempmov)) = tempmov;
    start_list(k,:) = [baseline_close_frame,k];
    end_list(k,:) = [length(tempmov),k];
end

temph = subplot('Position',[start_x+box_x+inter_x,...
    start_y,box_x,box_y]);
imagesc(part_mov_mat)
colormap(temph,[1,1,1;cmap_mov])
hold on
plot(start_list(:,1),start_list(:,2),'-k')
hold on
plot(end_list(:,1),end_list(:,2),'-k')
hold off

axis([0,630,0,size(start_list,1)])

box off

set(gca,'XTick',x_tick)
set(gca,'XTickLabel',x_tick_label)

set(gca,'YTick',[1,size(part_mov_mat,1)])
set(gca,'YTickLabel',[])

title('Partner')
set(gca,'TickDir','out')
set(gca,'FontSize',6)
xlabel('Time (s)')

% create seq mat
part_seq_mat = -1*ones(size(sort_cf_cell,1),pad_len);
start_list = zeros(size(part_seq_mat,1),2);
end_list = zeros(size(part_seq_mat,1),2);

for k = 1:size(part_seq_mat,1)
    tempseq = sort_cf_cell{k,8}';
    part_seq_mat(k,1:length(tempseq)) = tempseq;
    start_list(k,:) = [baseline_close_frame,k];
    end_list(k,:) = [length(tempseq),k];
end

temph = subplot('Position',[...
    start_x+3*(box_x+inter_x),...
    start_y,box_x,box_y]);
imagesc(part_seq_mat)
colormap(temph,[1,1,1;1,1,1;cmap_seq])
hold on
plot(start_list(:,1),start_list(:,2),'-k')
hold on
plot(end_list(:,1),end_list(:,2),'-k')
hold off

axis([0,630,0,size(start_list,1)])

box off

set(gca,'XTick',x_tick)
set(gca,'XTickLabel',x_tick_label)

set(gca,'YTick',[1,size(part_seq_mat,1)])
set(gca,'YTickLabel',[])


set(gca,'TickDir','out')
set(gca,'FontSize',6)
title('Partner')
xlabel('Time (s)')

% colorbar, mov
cbar_box_x = 0.006;
cbar_box_y = 0.05;

cbar_inter_x = -0.03;

temph = subplot('Position',[...
    start_x+1*(box_x+inter_x)+cbar_inter_x,...
    start_y+box_y-cbar_box_y,...
    cbar_box_x,cbar_box_y]);
imagesc(flipud((1:max(unique_mov))'))
colormap(temph,cmap_mov)
set(gca,'XTick',[],'YTick',[])

text(0.5,50,'1','FontSize',6,'VerticalAlignment','middle')
text(0.5,-1,'49','FontSize',6,'VerticalAlignment','middle')

text(2.5,25,{'Movement','categories'},...
    'FontSize',6,'Rotation',90,...
    'HorizontalAlignment','center')

% colorbar, seq
cbar_box_x = 0.006;
cbar_box_y = 0.05;

cbar_inter_x = -0.03;

temph = subplot('Position',[...
    start_x+3*(box_x+inter_x)+cbar_inter_x,...
    start_y+box_y-cbar_box_y,...
    cbar_box_x,cbar_box_y]);
imagesc(flipud((1:max(unique_seq))'))
colormap(temph,cmap_seq)
set(gca,'XTick',[],'YTick',[])

text(0.5,36,'1','FontSize',6,'VerticalAlignment','middle')
text(0.5,-1,'35','FontSize',6,'VerticalAlignment','middle')

text(2.5,17,{'Sequence','Categories'},...
    'FontSize',6,'Rotation',90,...
    'HorizontalAlignment','center')

%% show neural activities
neu_mat = [];
start_list_neu = [];
end_list_neu = [];

count = 1;

for k = 1:size(sort_cf_cell,1)
    tempneu = sort_cf_cell{k,2}';
    padneu = nan(size(tempneu,1),pad_len);

    for m = 1:size(padneu,1)
        ttneu = tempneu(m,:);
        padneu(m,1:length(ttneu)) = ttneu;
        start_list_neu = [start_list_neu;...
            [baseline_close_frame,count]];
        end_list_neu = [end_list_neu;[length(ttneu),count]];

        count = count+1;
    end

    neu_mat = [neu_mat;padneu];
end

%%
show_range = [-0.5,0.5];

cmap_neu = flipud(cbrewer2('RdBu',256));

temph = subplot('Position',[...
    start_x+4*(box_x+inter_x),...
    start_y,box_x,box_y]);
imagesc(neu_mat,show_range)

colormap(temph,[1,1,1;cmap_neu])
hold on
plot(start_list_neu(:,1),start_list_neu(:,2),'-k')
hold on
plot(end_list_neu(:,1),end_list_neu(:,2),'-k')
hold off

axis([0,630,0,size(neu_mat,1)])

box off
set(gca,'FontSize',6)
set(gca,'TickDir','out')
set(gca,'XTick',x_tick)
set(gca,'XTickLabel',x_tick_label)
xlabel('Time (s)')
ylabel('Neural activities')

% colorbar
cbar_box_x = 0.006;
cbar_box_y = 0.05;

cbar_inter_x = -0.02;

temph = subplot('Position',[...
    start_x+5*(box_x+inter_x)+cbar_inter_x,...
    start_y+box_y-cbar_box_y,...
    cbar_box_x,cbar_box_y]);
imagesc(flipud((1:256)'))
colormap(temph,cmap_neu)
set(gca,'XTick',[],'YTick',[])

text(0.5,280,'-0.5','FontSize',6,'VerticalAlignment','middle')
text(0.5,-30,'0.5','FontSize',6,'VerticalAlignment','middle')

text(2.5,128,'ΔF/F','FontSize',6,'Rotation',90,...
    'HorizontalAlignment','center')

%% pca
pca_cell = cell(size(sort_cf_cell,1),1);

for k = 1:size(pca_cell,1)
    tempneu = sort_cf_cell{k,2};
    [coeff, score, ~, ~, explained] = pca(tempneu');
    pca_cell{k,1} = {coeff,score,...
        explained,cumsum(explained)};
    disp(k)
end

%% show pcs
start_x = 0.03;
start_y = 0.73;

box_x = 0.13;
box_y = 0.1;

inter_x = 0.03;

for k = 1:6
    %%
    sel_pc = cellfun(@(x) mat2gray(x{1}(:,k)'),...
        pca_cell,'UniformOutput',false);

    pad_pc_mat = nan(size(sel_pc,1),pad_len);
    start_list = zeros(size(pad_pc_mat,1),2);
    end_list = zeros(size(pad_pc_mat,1),2);
    
    for m = 1:size(pad_pc_mat,1)
        temppca = sel_pc{m};
        pad_pc_mat(m,1:length(temppca)) = temppca;
        start_list(m,:) = [baseline_close_frame,m];
        end_list(m,:) = [length(temppca),m];
    end
    temph = subplot('Position',...
        [start_x+(k-1)*(inter_x+box_x),...
        start_y,box_x,box_y]);
    imagesc(pad_pc_mat)

    colormap(temph,[1,1,1;cmap_neu])

    hold on
    plot(start_list(:,1),start_list(:,2),'-k')
    hold on
    plot(end_list(:,1),end_list(:,2),'-k')

    axis([0,630,0,size(start_list,1)])

    title(['PC ',num2str(k)])

    set(gca,'FontSize',6)

    box off
    set(gca,'TickDir','out')

    set(gca,'XTick',x_tick)
    set(gca,'XTickLabel',x_tick_label)
    set(gca,'YTick',[1,size(part_seq_mat,1)])

    if k ~= 1
        set(gca,'YTickLabel',[])
    end
    xlabel('Time (s)')
end

% colorbar
cbar_box_x = 0.006;
cbar_box_y = 0.05;

cbar_inter_x = 0.01;

temph = subplot('Position',[...
    start_x+5*(box_x+inter_x)+box_x+cbar_inter_x,...
    start_y+box_y-cbar_box_y,...
    cbar_box_x,cbar_box_y]);
imagesc(fliplr((1:256))')
colormap(temph,cmap_neu)
set(gca,'XTick',[],'YTick',[])

text(0.5,280,'0','FontSize',6,'VerticalAlignment','middle')
text(0.5,-30,'1','FontSize',6,'VerticalAlignment','middle')

text(2.5,128,'PC coefficient','FontSize',6,'Rotation',90,...
    'HorizontalAlignment','center')

set(gca,'FontSize',6)

%% linear mapping
mapping_flag = 0;

map_name_list = {...
    'free-seg1-1tpmss-1wt-20220226';...
    'free-seg4-2tpmss-4wt-20220226';...
    'free-seg1-3tpmss-5wt-20220227';...
    'free-seg5-4tpmss-2wt-20220227';...
    'free-seg4-5tpmss-4wt-20220227';...
    'free-seg2-1tpmpfc-rwt-20240103';...
    'free-seg1-2tpmpfc-rwt-20231208';...
    'free-seg2-3tpmpfc-rwt-20231227';...
    'free-seg1-4tpmpfc-rwt-20231228';...
    'free-seg2-5tpmpfc-rwt-20231229';...
    'free-seg2-1tpmm-rwt-20231107';...
    'free-seg2-2tpmm-rwt-20231108';...
    'free-seg1-3tpmm-rwt-20231124';...
    'free-seg1-4tpmm-rwt-20231225';...
    'free-seg2-5tpmm-rwt-20240102';...
    };

if mapping_flag == 1

    self_map_pose_cell = cell(size(map_name_list,1),...
        size(map_name_list,1));
    self_map_mov_cell = cell(size(map_name_list,1),...
        size(map_name_list,1));
    self_map_seq_cell = cell(size(map_name_list,1),...
        size(map_name_list,1));
    partner_map_pose_cell = cell(size(map_name_list,1),...
        size(map_name_list,1));
    partner_map_mov_cell = cell(size(map_name_list,1),...
        size(map_name_list,1));
    partner_map_seq_cell = cell(size(map_name_list,1),...
        size(map_name_list,1));
    
    self_raw_pose_cell = self_map_pose_cell;
    self_raw_mov_cell = self_map_mov_cell;
    self_raw_seq_cell = self_map_seq_cell;
    partner_raw_pose_cell = partner_map_pose_cell;
    partner_raw_mov_cell = partner_map_mov_cell;
    partner_raw_seq_cell = partner_map_seq_cell;
    % cross mapping
    map_len = 330;%10s
    for m = 1:size(self_map_pose_cell,1)
        for n = 1:size(self_map_pose_cell,2)
            %% load data
            tempname1 = map_name_list{m,1};% brain
            tempname2 = map_name_list{n,1};% behavior
    
            selidx1 = strcmp(tempname1,sort_cf_cell(:,10));
            selidx2 = strcmp(tempname2,sort_cf_cell(:,10));
    
            selbrain = pca_cell(selidx1,:);
            selbeh = sort_cf_cell(selidx2,3:end);
            %% cross mapping
            temp_self_map_pose = [];
            temp_self_map_mov = [];
            temp_self_map_seq = [];
            temp_partner_map_pose = [];
            temp_partner_map_mov = [];
            temp_partner_map_seq = [];
    
            for p = 1:size(selbrain,1)
                for q = 1:size(selbeh,1)
                    tempneu = selbrain{p,1}{1}(1:map_len,:);
                    self_temppose = selbeh{q,1}(1:map_len,:);
                    partner_temppose = selbeh{q,4}(1:map_len,:);
                    
                    self_tempmov = ...
                        cell2mat(selbeh{q,2}(:,2));
                    self_tempmov = self_tempmov(1:map_len,:);
                    partner_tempmov = ...
                        cell2mat(selbeh{q,5}(:,2));
                    partner_tempmov = partner_tempmov(1:map_len,:);
                    
                    self_tempseq = selbeh{q,3}(1:map_len,:);
                    partner_tempseq = selbeh{q,6}(1:map_len,:);
                    
                    % pose
                    self_pose_rlist = ...
                        zeros(size(self_temppose,2),1);
                    for a = 1:size(self_temppose,2)
                        %
                        ttpose = self_temppose(:,a);
                        mdl = fitglm(tempneu,ttpose);
                        ypred = predict(mdl,tempneu);
                        [r,rp] = corr(ttpose,ypred);
                        self_pose_rlist(a,1) = r;
                    end
    
                    partner_pose_rlist = ...
                        zeros(size(partner_temppose,2),1);
                    for a = 1:size(partner_temppose,2)
                        %
                        ttpose = partner_temppose(:,a);
                        mdl = fitglm(tempneu,ttpose);
                        ypred = predict(mdl,tempneu);
                        [r,rp] = corr(ttpose,ypred);
                        partner_pose_rlist(a,1) = r;
                    end
    
                    % mov
                    train_neu = tempneu;
                    mdl = fitcdiscr(train_neu,self_tempmov);
                    ypred = predict(mdl,tempneu);
                    prec = ypred==self_tempmov;
                    
                    self_mov_prec = -1*ones(size(unique_mov));
                    for a = 1:size(self_mov_prec,1)
                        selprec = prec(...
                            unique_mov(a)==self_tempmov,:);
                        if size(selprec,1) > 0
                            self_mov_prec(a) = mean(selprec);
                        end
                    end
                    self_mov_prec(self_mov_prec==-1) = [];
    
                    train_neu = tempneu;
                    mdl = fitcdiscr(train_neu,partner_tempmov);
                    ypred = predict(mdl,tempneu);
                    prec = ypred==partner_tempmov;
                    
                    partner_mov_prec = -1*ones(size(unique_mov));
                    for a = 1:size(partner_mov_prec,1)
                        selprec = prec(...
                            unique_mov(a)==partner_tempmov,:);
                        if size(selprec,1) > 0
                            partner_mov_prec(a) = mean(selprec);
                        end
                    end
                    partner_mov_prec(partner_mov_prec==-1) = [];
    
                    % seq
                    train_neu = tempneu;
                    mdl = fitcdiscr(train_neu,self_tempseq);
                    ypred = predict(mdl,tempneu);
                    prec = ypred==self_tempseq;
    
                    self_seq_prec = -1*ones(size(unique_seq));
                    for a = 1:size(self_seq_prec,1)
                        selprec = prec(...
                            unique_seq(a)==self_tempseq,:);
                        if size(selprec,1) > 0
                            self_seq_prec(a) = mean(selprec);
                        end
                    end
                    self_seq_prec(self_seq_prec==-1) = [];
    
                    train_neu = tempneu;
                    mdl = fitcdiscr(train_neu,partner_tempseq);
                    ypred = predict(mdl,tempneu);
                    prec = ypred==partner_tempseq;
    
                    partner_seq_prec = -1*ones(size(unique_seq));
                    for a = 1:size(partner_seq_prec,1)
                        selprec = prec(...
                            unique_seq(a)==partner_tempseq,:);
                        if size(selprec,1) > 0
                            partner_seq_prec(a) = mean(selprec);
                        end
                    end
                    partner_seq_prec(partner_seq_prec==-1) = [];
    
                    
                    %% append data
                    temp_self_map_pose = [...
                        temp_self_map_pose;...
                        mean(self_pose_rlist)];
                    temp_partner_map_pose = [...
                        temp_partner_map_pose;...
                        mean(partner_pose_rlist)];
    
                    temp_self_map_mov = [...
                        temp_self_map_mov;...
                        mean(self_mov_prec)];
                    temp_partner_map_mov = [...
                        temp_partner_map_mov;...
                        mean(partner_mov_prec)];
    
                    temp_self_map_seq = [...
                        temp_self_map_seq;...
                        mean(self_seq_prec)];
                    temp_partner_map_seq = [...
                        temp_partner_map_seq;...
                        mean(partner_seq_prec)];
                end
            end
            %% append data
            self_map_pose_cell{m,n} = temp_self_map_pose;
            self_map_mov_cell{m,n} = temp_self_map_mov;
            self_map_seq_cell{m,n} = temp_self_map_seq;
            partner_map_pose_cell{m,n} = temp_partner_map_pose;
            partner_map_mov_cell{m,n} = temp_partner_map_mov;
            partner_map_seq_cell{m,n} = temp_partner_map_seq;
    
        end
        disp(m)
    end
    
    % save
    save([beh_neu_path,'\linear_mapping_cf_20240906.mat'],...
        'self_map_pose_cell',...
        'self_map_mov_cell',...
        'self_map_seq_cell',...
        'partner_map_pose_cell',...
        'partner_map_mov_cell',...
        'partner_map_seq_cell'...
        )
else
    load([beh_neu_path,'\linear_mapping_cf_20240906.mat']);
end

%% show mapping results
%% wash
wash_self_map_pose_cell = cellfun(@(x) x(~isnan(x)),...
    self_map_pose_cell,'UniformOutput',false);
wash_self_map_mov_cell = cellfun(@(x) x(~isnan(x)),...
    self_map_mov_cell,'UniformOutput',false);
wash_self_map_seq_cell = cellfun(@(x) x(~isnan(x)),...
    self_map_seq_cell,'UniformOutput',false);
wash_partner_map_pose_cell = cellfun(@(x) x(~isnan(x)),...
    partner_map_pose_cell,'UniformOutput',false);
wash_partner_map_mov_cell = cellfun(@(x) x(~isnan(x)),...
    partner_map_mov_cell,'UniformOutput',false);
wash_partner_map_seq_cell = cellfun(@(x) x(~isnan(x)),...
    partner_map_seq_cell,'UniformOutput',false);

mean_self_map_pose = cell2mat(cellfun(@(x) mean(x),...
    wash_self_map_pose_cell,'UniformOutput',false));
mean_self_map_mov = cell2mat(cellfun(@(x) mean(x),...
    wash_self_map_mov_cell,'UniformOutput',false));
mean_self_map_seq = cell2mat(cellfun(@(x) mean(x),...
    wash_self_map_seq_cell,'UniformOutput',false));
mean_partner_map_pose = cell2mat(cellfun(@(x) mean(x),...
    wash_partner_map_pose_cell,'UniformOutput',false));
mean_partner_map_mov = cell2mat(cellfun(@(x) mean(x),...
    wash_partner_map_mov_cell,'UniformOutput',false));
mean_partner_map_seq = cell2mat(cellfun(@(x) mean(x),...
    wash_partner_map_seq_cell,'UniformOutput',false));
%% show mappings, raw neural activity
start_x = 0.055;
start_y = 0.63;

box_x = 0.05;
box_y = box_x;

inter_x = 0.005;
inter_y = 0.005;

show_raw_cell = {...
    mean_self_map_pose,mean_partner_map_pose,...
    mean_self_map_mov,mean_partner_map_mov,...
    mean_self_map_seq,mean_partner_map_seq};

title_list = {...
    'Self';...
    'Partner';...
    };

y_label_list = {...
    'Pose';...
    'Movement';...
    'Sequence'};

show_brain_name_tick = {...
    '','','S1','','',...
    '','','dmPFC','','',...
    '','','M1','','',...
    };

mat_cmap = flipud(cbrewer2('Purples',1024));
mat_cmap = mat_cmap(1:800,:);

xy_grid = [5.5,10.5,0.5,15.5];
xy_tick = 1:15;%[3,8,13];

count = 1;

for m = 1:3
    for n = 1:2
        temph = subplot('Position',[...
            start_x+(n-1)*(box_x+inter_x),...
            start_y-(m-1)*(box_y+inter_y),...
             box_x,box_y]);
        imagesc(show_raw_cell{count},[0,1])
        colormap(temph,mat_cmap)
        hold on
        plot([xy_grid(4),xy_grid(4)],[0,16],'-k',...
            'LineWidth',0.25)
        hold on
        plot([xy_grid(1),xy_grid(1)],[0,16],'-k',...
            'LineWidth',0.25)
        hold on
        plot([xy_grid(2),xy_grid(2)],[0,16],'-k',...
            'LineWidth',0.25)
        hold on
        plot([0,16],[xy_grid(1),xy_grid(1)],'-k',...
            'LineWidth',0.25)
        hold on
        plot([0,16],[xy_grid(2),xy_grid(2)],'-k',...
            'LineWidth',0.25)
        hold on
        plot([0,16],[xy_grid(3),xy_grid(3)],'-k',...
            'LineWidth',0.25)
        hold off
        
        count = count+1;
        if n ~= 1
            set(gca,'YTickLabel',[])
        else
            set(gca,'YTickLabel',show_brain_name_tick)
            set(gca,'YTickLabelRotation',0)
        end
        
        % if m == 3
        %     set(gca,'XTickLabel',show_brain_name_tick,...
        %         'XTickLabelRotation',45)
        % else
        set(gca,'XTickLabel',[])
        % end
        
        box off

        if m == 1
            title(title_list{n})
        end

        if n == 1
            text(-14,8,y_label_list{m},'FontSize',6,...
                'Rotation',90,'HorizontalAlignment','center')
        end

        if m == 3
            set(gca,'XTickLabel',show_brain_name_tick,...
                'XTickLabelRotation',45)
        else
            set(gca,'XTickLabel',[])
        end

        set(gca,'FontSize',6)
        set(gca,'XTick',xy_tick)
        set(gca,'YTick',xy_tick)
        set(gca,'TickDir','out')
    end
end

% colorbar
cbar_box_x = 0.006;
cbar_box_y = 0.05;

cbar_inter_x = 0.00;

temph = subplot('Position',[...
    start_x+2*(box_x+inter_x)+cbar_inter_x,...
    start_y+box_y-cbar_box_y,...
    cbar_box_x,cbar_box_y]);
imagesc(flipud((1:256)'))
colormap(temph,mat_cmap)
set(gca,'XTick',[],'YTick',[])

text(0.5,280,'0','FontSize',6,'VerticalAlignment','middle')
text(0.5,-30,'1','FontSize',6,'VerticalAlignment','middle')

text(2.5,128,'Accuracy','FontSize',6,'Rotation',90,...
    'HorizontalAlignment','center')

%% dtak sparate two clusters of PC
pc_dist_mat = zeros(size(pca_cell,1),size(pca_cell,1));

sel_pc_dim = 3;

for m = 1:size(pc_dist_mat,1)
    temppc1 = pca_cell{m}{1}(:,1:sel_pc_dim)';
    for n = m:size(pc_dist_mat,2)
        temppc2 = pca_cell{n}{1}(:,1:sel_pc_dim)';
        condist_mat = conDist(temppc1,temppc2);
		Kdistmat = conKnl(...
            condist_mat, 'g', 'nei');

        wFs1 = ones(1,size(Kdistmat,1));
		wFs2 = ones(1,size(Kdistmat,2));
		[T,~,~] = dtakFord(Kdistmat,0,wFs1,wFs2);

        pc_dist_mat(m,n) = T;
    end

    disp(m)
end

% fill full matrix
pc_dist_mat_all = pc_dist_mat + triu(pc_dist_mat, 1)';

% %% dtak sparate two clusters of self mov
% self_mov_dist_mat = ...
%     zeros(size(sort_cf_cell,1),size(sort_cf_cell,1));
% 
% for m = 1:size(self_mov_dist_mat,1)
%     temppc1 = cell2mat(sort_cf_cell{m,4}(:,2))';
%     for n = m:size(self_mov_dist_mat,2)
%         temppc2 = cell2mat(sort_cf_cell{n,4}(:,2))';
%         condist_mat = conDist(temppc1,temppc2);
%         condist_mat(condist_mat>0) = 1;
% 		Kdistmat = conKnl(...
%             condist_mat, 'g', 'nei');
% 
%         wFs1 = ones(1,size(Kdistmat,1));
% 		wFs2 = ones(1,size(Kdistmat,2));
% 		[T,~,~] = dtakFord(Kdistmat,0,wFs1,wFs2);
% 
%         self_mov_dist_mat(m,n) = T;
%     end
% 
%     disp(m)
% end
% 
% % fill full matrix
% self_mov_dist_mat_all = ...
%     self_mov_dist_mat + triu(self_mov_dist_mat, 1)';
% 
% % dtak sparate two clusters of partner mov
% partner_mov_dist_mat = ...
%     zeros(size(sort_cf_cell,1),size(sort_cf_cell,1));
% 
% for m = 1:size(partner_mov_dist_mat,1)
%     temppc1 = cell2mat(sort_cf_cell{m,7}(:,2))';
%     for n = m:size(partner_mov_dist_mat,2)
%         temppc2 = cell2mat(sort_cf_cell{n,7}(:,2))';
%         condist_mat = conDist(temppc1,temppc2);
%         condist_mat(condist_mat>0) = 1;
% 		Kdistmat = conKnl(...
%             condist_mat, 'g', 'nei');
% 
%         wFs1 = ones(1,size(Kdistmat,1));
% 		wFs2 = ones(1,size(Kdistmat,2));
% 		[T,~,~] = dtakFord(Kdistmat,0,wFs1,wFs2);
% 
%         partner_mov_dist_mat(m,n) = T;
%     end
% 
%     disp(m)
% end
% 
% % fill full matrix
% partner_mov_dist_mat_all = ...
%     partner_mov_dist_mat + triu(partner_mov_dist_mat, 1)';

%% clustering
n_clus = 2;
D = pdist(pc_dist_mat_all,'seuclidean');
Z = squareform(D);
tree = linkage(Z, 'ward','euclidean');
T = cluster(tree,'maxclust',n_clus);

%% show
start_x = 0.19;
start_y = 0.52;

box_x_tree = 0.02;
box_x_bar = 0.01;
box_x_mat = 0.1;

box_y = 0.16;

neu_cmap = cbrewer2('Paired',12);

in_c = neu_cmap(5,:);
de_c = neu_cmap(1,:);
no_c = neu_cmap(3,:);

two_state_c = [...
    de_c;in_c;];


norm_pc_distmat = mat2gray(Z);

% tree
subplot('Position',[start_x,start_y,box_x_tree,box_y])
temph = dendrogram(tree,0,'Orientation','left');
for k = 1:size(tree,1)
    temph(k).Color = zeros(1,3);
end

set(gca,'YDir','reverse')
axis off
% bar
temph = subplot('Position',[start_x+box_x_tree,start_y,...
    box_x_bar,box_y]);
imagesc(T)

colormap(temph,two_state_c)

set(gca,'XTick',[],'YTick',[])

% mat
temph = subplot('Position',[start_x+box_x_tree+box_x_bar,...
    start_y,...
    box_x_mat,box_y]);
imagesc(norm_pc_distmat)
colormap(temph,cmap_neu)
hold on
plot([0,219],[0.5,0.5],'k','LineWidth',0.25)
hold on
plot([219,219],[0,219],'k','LineWidth',0.25)
hold off
box off

xlabel('Trials')

set(gca,'YTick',[])

set(gca,'XTick',[1,size(norm_pc_distmat,2)])

set(gca,'TickDir','out')

set(gca,'FontSize',6)

% color bar
box_x_cbar = 0.05;
box_y_cbar = 0.006;

inter_y_cbar = 0.004;

temph = subplot('Position',[...
    start_x+box_x_tree+box_x_bar,...
    start_y+box_y+inter_y_cbar,...
    box_x_cbar,box_y_cbar]);
imagesc(1:256)
colormap(temph,cmap_neu)

text(-40,0.5,'0','FontSize',6,'HorizontalAlignment','left')

text(275,0.5,'max','FontSize',6,'HorizontalAlignment','left')

title('Pairwise distance')

set(gca,'XTick',[],'YTick',[])

set(gca,'FontSize',6)

%% quantify the distance
self_mov_frac_mat = zeros(size(sort_cf_cell,1),...
    size(unique_mov,1));
partner_mov_frac_mat = zeros(size(sort_cf_cell,1),...
    size(unique_mov,1));

for k = 1:size(sort_cf_cell,1)
    selfmov = cell2mat(sort_cf_cell{k,4}(:,2));
    partnermov = cell2mat(sort_cf_cell{k,7}(:,2));

    selfmov_frac = zeros(1,size(unique_mov,1));
    partnermov_frac = zeros(1,size(unique_mov,1));

    for m = 1:size(unique_mov,1)
        selidx_self = unique_mov(m)==selfmov;
        selidx_partner = unique_mov(m)==partnermov;

        selfmov_frac(m) = mean(selidx_self);
        partnermov_frac(m) = mean(selidx_partner);
    end

    self_mov_frac_mat(k,:) = selfmov_frac;
    partner_mov_frac_mat(k,:) = partnermov_frac;
end

[~,sort_idx] = sort(T);
sort_T = T(sort_idx);

sort_self_mov_frac_mat = self_mov_frac_mat(sort_idx,:);
sort_partner_mov_frac_mat = partner_mov_frac_mat(sort_idx,:);

stat_self_mov_frac_mat = sort_self_mov_frac_mat';
stat_partner_mov_frac_mat = sort_partner_mov_frac_mat';
%% compare the movement of self and partner
% show
start_x = 0.37;
start_y = 0.61;

box_x = 0.61;
box_y = 0.07;

inter_y = 0.02;

sort_self_mov_frac_1 = sort_self_mov_frac_mat(sort_T==1,:);
sort_self_mov_frac_2 = sort_self_mov_frac_mat(sort_T==2,:);

sort_partner_mov_frac_1 = sort_partner_mov_frac_mat(sort_T==1,:);
sort_partner_mov_frac_2 = sort_partner_mov_frac_mat(sort_T==2,:);

mean_sort_self_mov_frac_1 = mean(sort_self_mov_frac_1);
mean_sort_self_mov_frac_2 = mean(sort_self_mov_frac_2);

mean_sort_partner_mov_frac_1 = mean(sort_partner_mov_frac_1);
mean_sort_partner_mov_frac_2 = mean(sort_partner_mov_frac_2);

std_sort_self_mov_frac_1 = std(sort_self_mov_frac_1)./...
    sqrt(size(sort_self_mov_frac_1,1));
std_sort_self_mov_frac_2 = std(sort_self_mov_frac_2)./...
    sqrt(size(sort_self_mov_frac_2,1));

std_sort_partner_mov_frac_1 = std(sort_partner_mov_frac_1)./...
    sqrt(size(sort_partner_mov_frac_1,1));
std_sort_partner_mov_frac_2 = std(sort_partner_mov_frac_2)./...
    sqrt(size(sort_partner_mov_frac_2,1));

xlist = 1:size(unique_mov,1);
xlist_bias = 0.22;

xlist_1 = xlist-xlist_bias;
xlist_2 = xlist+xlist_bias;

bar_w = 0.3;
cap_size = 0.5;
mk_size = 1;

x_dot_bias = 0.15;

subplot('Position',[start_x,start_y,box_x,box_y])
bar(xlist_1,mean_sort_self_mov_frac_1,bar_w,...
    'FaceColor',two_state_c(1,:))
hold on
bar(xlist_2,mean_sort_self_mov_frac_2,bar_w,...
    'FaceColor',two_state_c(2,:))
hold on
errorbar(xlist_1,mean_sort_self_mov_frac_1,...
    std_sort_self_mov_frac_1,'LineStyle','none',...
    'CapSize',cap_size,'Color','k')
hold on
errorbar(xlist_2,mean_sort_self_mov_frac_2,...
    std_sort_self_mov_frac_2,'LineStyle','none',...
    'CapSize',cap_size,'Color','k')
hold on
for k = 1:size(sort_self_mov_frac_1,1)
    plot(xlist_1+x_dot_bias,...
        sort_self_mov_frac_1(k,:),'o',...
        'MarkerSize',mk_size,...
        'MarkerFaceColor',two_state_c(1,:),...
        'MarkerEdgeColor',two_state_c(1,:),...
        'LineWidth',0.25)
    hold on
end
for k = 1:size(sort_self_mov_frac_2,1)
    plot(xlist_2+x_dot_bias,...
        sort_self_mov_frac_2(k,:),'o',...
        'MarkerSize',mk_size,...
        'MarkerFaceColor',two_state_c(2,:),...
        'MarkerEdgeColor',two_state_c(2,:),...
        'LineWidth',0.25)
    hold on
end

% show star
for k = 1:size(sign_self_mov_frac,1)
    if ~strcmp(sign_self_mov_frac{k},'ns')
        plot([xlist_1(k),xlist_2(k)],...
            [0.5,0.5],'-k','LineWidth',0.25)
        hold on
        text((xlist_1(k)+xlist_2(k))/2,...
            0.5,sign_self_mov_frac{k},...
            'HorizontalAlignment','center',...
            'VerticalAlignment','bottom')
    end
end

hold off

box off

axis([0.3,43.7,0,0.5])


set(gca,'TickDir','out')
set(gca,'XTick',xlist)
set(gca,'FontSize',6)
set(gca,'XTickLabel',[])
ylabel('Self fractions')

subplot('Position',[start_x,...
    start_y-box_y-inter_y,...
    box_x,box_y])
bar(xlist_1,mean_sort_partner_mov_frac_1,bar_w,...
    'FaceColor',two_state_c(1,:))
hold on
bar(xlist_2,mean_sort_partner_mov_frac_2,bar_w,...
    'FaceColor',two_state_c(2,:))
hold on
errorbar(xlist_1,mean_sort_partner_mov_frac_1,...
    std_sort_partner_mov_frac_1,'LineStyle','none',...
    'CapSize',cap_size,'Color','k')
hold on
errorbar(xlist_2,mean_sort_partner_mov_frac_2,...
    std_sort_partner_mov_frac_2,'LineStyle','none',...
    'CapSize',cap_size,'Color','k')
hold on
for k = 1:size(sort_partner_mov_frac_1,1)
    plot(xlist_1+x_dot_bias,...
        sort_partner_mov_frac_1(k,:),'o',...
        'MarkerSize',mk_size,...
        'MarkerFaceColor',two_state_c(1,:),...
        'MarkerEdgeColor',two_state_c(1,:),...
        'LineWidth',0.25)
    hold on
end
for k = 1:size(sort_partner_mov_frac_2,1)
    plot(xlist_2+x_dot_bias,...
        sort_partner_mov_frac_2(k,:),'o',...
        'MarkerSize',mk_size,...
        'MarkerFaceColor',two_state_c(2,:),...
        'MarkerEdgeColor',two_state_c(2,:),...
        'LineWidth',0.25)
    hold on
end

% show star
for k = 1:size(sign_partner_mov_frac,1)
    if ~strcmp(sign_partner_mov_frac{k},'ns')
        plot([xlist_1(k),xlist_2(k)],...
            [0.2,0.2],'-k','LineWidth',0.25)
        hold on
        text((xlist_1(k)+xlist_2(k))/2,...
            0.2,sign_partner_mov_frac{k},...
            'HorizontalAlignment','center',...
            'VerticalAlignment','bottom')
    end
end

hold off

box off

axis([0.3,43.7,0,0.2])

set(gca,'TickDir','out')
set(gca,'XTick',xlist)
set(gca,'FontSize',6)
set(gca,'XTickLabel',unique_mov_name)
set(gca,'TickLabelInterpreter','none')
ylabel('Partner fractions')

%% show three movs
sel_mov_idx = find(~(strcmp(sign_self_mov_frac,'ns')&...
    strcmp(sign_partner_mov_frac,'ns')));

sel_mov_class = unique_mov(sel_mov_idx);

all_pose = [...
    cell2mat(all_data_cell(:,3));...
    cell2mat(all_data_cell(:,6));...
    ];

all_mov_label = cell2mat([...
    cellfun(@(x) cell2mat(x(:,2)),...
    all_data_cell(:,4),'UniformOutput',false);...
    cellfun(@(x) cell2mat(x(:,2)),...
    all_data_cell(:,7),'UniformOutput',false);...
    ]);

% all_pose = [...
%     cell2mat(all_data_cell(:,3));...
%     cell2mat(all_data_cell(:,6));...
%     ];
% 
% all_mov_label = cell2mat([...
%     cellfun(@(x) cell2mat(x(:,2)),...
%     all_data_cell(:,4),'UniformOutput',false);...
%     cellfun(@(x) cell2mat(x(:,2)),...
%     all_data_cell(:,7),'UniformOutput',false);...
%     ]);


BA_X = all_pose(:,1:3:end)';
BA_Y = all_pose(:,2:3:end)';
BA_Z = all_pose(:,3:3:end)';

for k = 1:size(BA_X,1)
    BA_X(k,:) = smooth(BA_X(k,:),30);
    BA_Y(k,:) = smooth(BA_Y(k,:),30);
    BA_Z(k,:) = smooth(BA_Z(k,:),30);
end

all_v = sqrt(...
    ([zeros(size(BA_X,1),1),diff(BA_X,[],2)]).^2+...
    ([zeros(size(BA_Y,1),1),diff(BA_Y,[],2)]).^2+...
    ([zeros(size(BA_Z,1),1),diff(BA_Z,[],2)]).^2)*...
    30*0.088;



raw_XY = [];
for k = 1:size(BA_X,1)
    raw_XY = [raw_XY;BA_X(k,:);BA_Y(k,:)];	
end

CenIndex = 13;
VAIndex = 14;

white_XY = raw_XY;
back_X = white_XY((CenIndex*2-1),:);
back_Y = white_XY((CenIndex*2),:);
back_XY = white_XY;
back_XY(1:2:(end-1),:) = back_XY(1:2:(end-1),:)-back_X;
back_XY(2:2:end,:) = back_XY(2:2:end,:)-back_Y;
root_tail_X = back_XY((VAIndex*2-1),:);
root_tail_Y = back_XY((VAIndex*2),:);
rot_alpha = -atan2(root_tail_Y,root_tail_X);
rot_XY = zeros(size(back_XY));
for m = 1:size(rot_alpha,2)
    rot_mat = [cos(rot_alpha(1,m)),sin(rot_alpha(1,m)),0;...
                -1*sin(rot_alpha(1,m)),cos(rot_alpha(1,m)),0;...
                0,0,1];
    temp_rot = ...
        [back_XY(1:2:(end-1),m),back_XY(2:2:end,m),ones(size(rot_XY,1)/2,1)]*rot_mat;
    rot_XY(1:2:(end-1),m) = temp_rot(:,1);
    rot_XY(2:2:end,m) = temp_rot(:,2);
end
out_XY = rot_XY;

mean_Z = ones(16,1)*BA_Z(12,:);
white_Z = BA_Z;
out_XYZ = [];
for k = 1:size(BA_Z,1)
    out_XYZ = [out_XYZ;out_XY(k*2-1:k*2,:);white_Z(k,:)];	
end

delidx = out_XYZ(35,:)>0;

del_out_XYZ = out_XYZ;
del_out_XYZ(:,delidx) = [];
del_all_mov_label = all_mov_label;
del_all_mov_label(delidx) = [];


%%
start_x = 0.03;
start_y = 0.4;

box_x = 0.092;
box_y = 0.07;

inter_x = 0.006;
inter_y = 0.006;

for m = 1:size(sel_mov_idx,1)
    %
    
    selmovidx = sel_mov_class(m);
    selpose = out_XYZ(:,selmovidx==all_mov_label)';

    seldelpose = del_out_XYZ(:,...
        selmovidx==del_all_mov_label)';

    sel_v = all_v(:,selmovidx==all_mov_label)';

    sel_mov_name = unique_mov_name{sel_mov_idx(m)};

    round_selpose = round(selpose);

    mean_pose = mean(seldelpose);

    % create heatmap, xy
    x_min = -200;
    x_max = 200;

    y_min = -200;
    y_max = 200;

    bk_map = zeros(y_max-y_min+1,x_max-x_min+1);
    
    round_selpose(:,3:3:end) = [];
    round_selpose(:,1:2:end) = ...
        round_selpose(:,1:2:end)-x_min;
    round_selpose(:,2:2:end) = ...
        round_selpose(:,2:2:end)-y_min;

    min_zeros_idx = sum(round_selpose<=0,2)>0;
    max_zeros_idx = ...
        (sum(round_selpose(:,1:2:end)>(x_max-x_min),2)+...
        sum(round_selpose(:,2:2:end)>(y_max-y_min),2))>0;

    round_selpose(:,25:end) = [];

    sel_v(:,13:end) = [];

    round_selpose(...
        min_zeros_idx|max_zeros_idx,:) = [];
    sel_v(...
        min_zeros_idx|max_zeros_idx,:) = [];

    for k = 1:size(round_selpose,1)
        tempxlist = round_selpose(k,1:2:end);
        tempylist = round_selpose(k,2:2:end);

        ttv = sel_v(k,:);

        for n = 1:length(tempxlist)
            bk_map(tempylist(n),...
                tempxlist(n)) = ...
                bk_map(tempylist(n),...
                tempxlist(n))+ttv(n);

            % bk_map(tempylist(n),...
            %     tempxlist(n)) = ...
            %     bk_map(tempylist(n),...
            %     tempxlist(n))+1;
        end
    end

    bk_map = bk_map./size(round_selpose,1);


    % create heatmap, xz
    x_min = -200;
    x_max = 200;

    z_min = -200;
    z_max = 200;

    xz_bk_map = zeros(z_max-z_min+1,x_max-x_min+1);

    round_selpose = round(selpose);
    
    round_selpose(:,2:3:end) = [];
    round_selpose(:,1:2:end) = ...
        round_selpose(:,1:2:end)-x_min;
    round_selpose(:,2:2:end) = ...
        round_selpose(:,2:2:end)-z_min;

    min_zeros_idx = sum(round_selpose<=0,2)>0;
    max_zeros_idx = ...
        (sum(round_selpose(:,1:2:end)>(x_max-x_min),2)+...
        sum(round_selpose(:,2:2:end)>(z_max-z_min),2))>0;

    round_selpose(:,25:end) = [];

    sel_v = all_v(:,selmovidx==all_mov_label)';

    sel_v(:,13:end) = [];

    round_selpose(...
        min_zeros_idx|max_zeros_idx,:) = [];
    sel_v(...
        min_zeros_idx|max_zeros_idx,:) = [];

    for k = 1:size(round_selpose,1)
        tempxlist = round_selpose(k,1:2:end);
        tempylist = round_selpose(k,2:2:end);

        ttv = sel_v(k,:);

        for n = 1:length(tempxlist)
            xz_bk_map(tempylist(n),...
                tempxlist(n)) = ...
                xz_bk_map(tempylist(n),...
                tempxlist(n))+ttv(n);

            % bk_map(tempylist(n),...
            %     tempxlist(n)) = ...
            %     bk_map(tempylist(n),...
            %     tempxlist(n))+1;
        end
    end

    xz_bk_map = xz_bk_map./size(round_selpose,1);

    
    %
    X = mean_pose(1:3:end)';
    Y = mean_pose(2:3:end)';
    Z = mean_pose(3:3:end)';

    alpha_mouse = 0.05;
    clrstr_mouse = 0.7*ones(1,3);

    plotstr = 'k';
    linestr = 'k';
    mksize = 7;

    drawline = [ 1 2; 1 3;2 3; 4 5;4 6;5 7;...
        6 8;7 14;8 14;5 13;6 13;7 13;8 13;...
    5 9;7 11;6 10; 8 12;14 15; 15 16];

    c_lim = [0,0.5];

    cmap_heat = [1,1,1;cbrewer2('Oranges',256)];

    for n = 1:2
        if n == 1
            temph = subplot('Position',[...
                start_x+(m-1)*(box_x+inter_x),...
                start_y-(n-1)*(box_y+inter_y),...
                box_x,box_y]);
            imagesc(...
                [x_min,x_max],...
                [y_min,y_max],bk_map,c_lim)
            hold on
            colormap(temph,cmap_heat)
            hold on
            plot_skl_mk(X,Y,Z,plotstr,linestr,...
                drawline,mksize);
            hold on
            % new_mesh_mouse(mean_pose, alpha_mouse, clrstr_mouse)
            hold off
        else
            temph = subplot('Position',[...
                start_x+(m-1)*(box_x+inter_x),...
                start_y-(n-1)*(box_y+inter_y),...
                box_x,box_y]);
            imagesc(...
                [x_min,x_max],...
                [z_max,z_min],xz_bk_map,c_lim)
            hold on
            colormap(temph,cmap_heat)
            hold on
            plot_skl_mk(X,-1*Z,Y+30,plotstr,linestr,...
                drawline,mksize);
            hold on
            % new_mesh_mouse(mean_pose, alpha_mouse, clrstr_mouse)
            hold off
        end

        box on

        set(gca,'XTick',[],'YTick',[],'ZTick',[])

        if n == 1
            view(2)
            title(sel_mov_name,'Interpreter','none')
            axis([-65,100,-30,30,-15,50])
        else
            view(2)
            axis([-65,100,-50,20,-15,50])
        end

        if n == 1
            if m == 1
                ylabel('y')
            end
        else
            if m == 1
                ylabel('z')
            end
            xlabel('x')
        end

        set(gca,'FontSize',6)

        
    end
end

% color bar
cbar_inter_x = 0.005;
cbar_box_x = 0.006;
cbar_box_y = 0.05;

temph = subplot('Position',[...
    start_x+2*(inter_x+box_x)+box_x+cbar_inter_x,...
    start_y+box_y-cbar_box_y,...
    cbar_box_x,cbar_box_y]);
imagesc((1:256)')
colormap(temph,flipud(cmap_heat))
set(gca,'XTick',[],'YTick',[])
text(0.5,280,'0','FontSize',6,'VerticalAlignment','middle')
text(0.5,-30,'0.5','FontSize',6,'VerticalAlignment','middle')
text(2.5,128,'Speed (cm/s)','FontSize',6,'Rotation',90,...
    'HorizontalAlignment','center')
%% differences across three brain areas
unique_T = [1,2]';
splname = split(sort_cf_cell(:,1),'-');
all_brain_name = cellfun(@(x) x(2:end),...
    splname(:,3),'UniformOutput',false);
unique_brain = {...
    'tpmss';...
    'tpmpfc';...
    'tpmm'};

brain_T_cell = cell(size(unique_brain,1),size(unique_T,1));

for m = 1:size(brain_T_cell,1)
    for n = 1:size(brain_T_cell,2)
        sel_T_idx = unique_T(n)==T;
        sel_brain_idx = ...
            strcmp(unique_brain(m),all_brain_name);

        selidx = sel_T_idx&sel_brain_idx;

        sel_pc = cellfun(@(x) x{1},...
            pca_cell(selidx,:),'UniformOutput',false);

        brain_T_cell{m,n} = sel_pc;
    end
end

%% calculate mean
sel_pc_num = 1:10;
sel_frame = 1:330;

brain_T_trial_cell = cell(size(brain_T_cell));

for m = 1:size(brain_T_trial_cell,1)
    for n = 1:size(brain_T_trial_cell,2)
        selpc = cellfun(@(x) x(sel_frame,sel_pc_num)',...
            brain_T_cell{m,n},...
            'UniformOutput',false);

        reo_pc = cell(length(sel_pc_num),1);
        for k = 1:length(sel_pc_num)
            reo_pc{k,1} = cell2mat(...
                cellfun(@(x) mat2gray(x(k,:)),...
                selpc,'UniformOutput',false));
        end
        brain_T_trial_cell{m,n} = reo_pc;
    end
end

%% show pcs according to states and brain area
start_x = 0.03;
start_y = 0.21;

box_x = 0.092;
box_y = 0.08;

inter_x = 0.006;
inter_y = 0.008;

show_brain_name = {...
    'S1';...
    'dmPFC';...
    'M1'};


neu_cmap = cbrewer2('Paired',12);

in_c = neu_cmap(5,:);
de_c = neu_cmap(1,:);
no_c = neu_cmap(3,:);

brain_c = [...
    de_c;...
    in_c;...
    no_c];

for m = 1:3
    for n = 1:2
        subplot('Position',[...
            start_x+(m-1)*(box_x+inter_x),...
            start_y-(n-1)*(box_y+inter_y),...
            box_x,box_y])
        sel_cell = cell(size(brain_T_trial_cell,1),1);
        for k = 1:size(sel_cell,1)
            sel_cell{k,1} = brain_T_trial_cell{k,n}{m};
        end

        mean_sel_cell = cellfun(@(x) mean(x),...
            sel_cell,'UniformOutput',false);

        std_sel_cell = cellfun(@(x) std(x)./sqrt(size(x,1)),...
            sel_cell,'UniformOutput',false);

        legend_h = cell(size(brain_c,1),1);

        for k = 1:size(sel_cell,1)
            tempmean = mean_sel_cell{k};
            tempstd = std_sel_cell{k};
            temph = errorbar(...
                1:length(tempmean),...
                tempmean,...
                tempstd,'CapSize',0,...
                'LineWidth',1,...
                'LineStyle','none',...
                'Color',brain_c(k,:));
            set([temph.Bar, temph.Line], ...
                'ColorType', 'truecoloralpha', ...
                'ColorData', ...
                [temph.Line.ColorData(1:3); 255*0.1])
            hold on
            legend_h{k} = plot(1:length(tempmean),...
                mean_sel_cell{k},...
                '-','LineWidth',1,...
                'Color',brain_c(k,:));
            hold on
        end
       
        plot([30,30],[0,1],'--k')
        hold on
        plot([180,180],[0,1],'--k')
        hold off

        if n == 1
            title(['PC ',num2str(m)])
        end
        
        set(gca,'FontSize',6)

        set(gca,'TickDir','out')
        set(gca,'XTick',[0,30,180,330])
        if n == 1
            set(gca,'XTickLabel',[])
        else
            set(gca,'XTickLabel',[-1,0,5,10])
            xlabel('Time (s)')
        end



        axis([0,330,0,1])

        box off
        
        if m == 1
            if n == 1
                ylabel('Indipendent')
            else
                ylabel('Pre-social')
            end
        else
            set(gca,'YTickLabel',[])
        end

        if n == 1
            if m == 3
                legend(...
                    [legend_h{1},legend_h{2},legend_h{3}],...
                    show_brain_name,'Box','off',...
                    'Location','northeast')
            end
        end
    end
end

%% compare the changes
brain_T_list_cell = {};

for m = 1:size(brain_T_trial_cell,1)
    for n = 1:size(brain_T_trial_cell,2)
        temppc = brain_T_trial_cell{m,n};
        for k = 1:size(temppc,1)
            brain_T_list_cell = [brain_T_list_cell;...
                {temppc{k}(:,1:30),temppc{k}(:,31:end),...
                num2str(k),...
                show_brain_name{m},num2str(n),...
                mean(temppc{k}(:,1:30),2),...
                mean(temppc{k}(:,31:end),2),...
                mean(temppc{k}(:,31:end),2)-...
                mean(temppc{k}(:,1:30),2),...
                temppc{k},...
                mean(temppc{k}),...
                mean(temppc{k}(:,31:180),2),...
                mean(temppc{k}(:,181:330),2),...
                }];
        end
    end
end

%% show
start_x = 0.37;
start_y = 0.325;

box_x = 0.135;
box_y = 0.1;

inter_x = 0.01;

sel_pc_num = 3;

xlist_bias = 0.28;

bar_w = 0.18;

cap_size = 1;

mk_size = 1;

x_bias = 0.1;

show_x_tick = {...
    'PC 1';...
    'PC 2';...
    'PC 3';...
    'PC 4';...
    'PC 5';...
    'PC 6';...
    };

show_star_list = {...
    0.01,0.05,'*';...
    0.001,0.01,'**';...
    0.0001,0.001,'***';...
    0,0.0001,'****';...
    };

save_p_list = [];

for k = 1:2
    %%
    sel_state_idx = strcmp(num2str(k),...
        brain_T_list_cell(:,5));

    xlist = 1:sel_pc_num;
    xlist_left = xlist-xlist_bias;
    xlist_right = xlist+xlist_bias;

    xlist_all = {xlist_left;xlist;xlist_right};

    subplot('Position',[...
        start_x+(k-1)*(box_x+inter_x),...
        start_y,box_x,box_y])

    for p = 1:sel_pc_num
        stat_x = [];
        stat_y = {};
        stat_cell = {};
        for q = 1:size(show_brain_name,1)
            sel_pc_idx = strcmp(num2str(p),...
                brain_T_list_cell(:,3));
            sel_brain_idx = strcmp(show_brain_name{q},...
                brain_T_list_cell(:,4));

            selidx = sel_state_idx&sel_pc_idx&sel_brain_idx;

            seldata = brain_T_list_cell{selidx,8};

            selx = xlist_all{q};

            mean_data = mean(seldata);

            std_data = std(seldata)./sqrt(length(seldata));

            bar(selx(p),mean_data,bar_w,...
                'FaceColor',brain_c(q,:))
            hold on
            errorbar(selx(p),mean_data,std_data,...
                'Color','k','CapSize',cap_size)
            hold on
            plot(x_bias+selx(p)*ones(size(seldata)),...
                seldata,'o',...
                'MarkerFaceColor',brain_c(q,:),...
                'MarkerEdgeColor',brain_c(q,:),...
                'MarkerSize',mk_size)
            hold on

            stat_x = [stat_x;seldata];
            stat_cell = [stat_cell,seldata];

            for m = 1:size(seldata,1)
                stat_y = [stat_y;show_brain_name{q}];
            end

        end

        %% stat
        [~,~,stats] = anova1(stat_x,stat_y,'off');
        results = multcompare(stats,'Display','off');

        save_p_list = [save_p_list;results(:,end)];

        %% show stat
        for m = 1:size(results,1)
            tempp = results(m,end);

            for n = 1:size(show_star_list,1)
                if show_star_list{n,1}<=tempp &&...
                        tempp<show_star_list{n,2}
                    selstar = show_star_list{n,3};

                    p_start_x = xlist_all{results(m,1)}(p);
                    p_end_x = xlist_all{results(m,2)}(p);

                    plot([p_start_x,p_end_x],[0.7,0.7],'-k')
                    hold on
                    text(mean([p_start_x,p_end_x]),0.7,...
                        selstar,...
                        'HorizontalAlignment','center',...
                        'VerticalAlignment','bottom')
                end
            end
        end
    end

    hold off

    if k == 1
        title({'Independent',''})
    else
        title({'Pre-social',''})
    end

    axis([0.3,sel_pc_num+0.7,-0.7,0.7])

    box off
    set(gca,'TickDir','out')
    set(gca,'FontSize',6)

    set(gca,'XTick',xlist)
    set(gca,'XTickLabel',show_x_tick)

    if k == 2
        set(gca,'YTickLabel',[])
    else
        ylabel('PC coefficient')
    end
end

%% 和距离有关系
dist_pc_cell = {};

for k = 1:size(pca_cell,1)
    tempdist = sort_cf_cell{k,11};
    temppc = pca_cell{k}{1};

    r = corr(tempdist,temppc);
    
    for m = 1:10
        dist_pc_cell = [dist_pc_cell;...
            {r(m),num2str(m),...
            all_brain_name{k},num2str(T(k))}];
    end
end

%% show
start_x = 0.7;
start_y = 0.325;

box_x = 0.135;
box_y = 0.1;

inter_x = 0.01;

sel_pc_num = 3;

xlist_bias = 0.28;

bar_w = 0.18;

cap_size = 1;

mk_size = 1;

x_bias = 0.1;

show_x_tick = {...
    'PC 1';...
    'PC 2';...
    'PC 3';...
    'PC 4';...
    'PC 5';...
    'PC 6';...
    };

show_star_list = {...
    0.01,0.05,'*';...
    0.001,0.01,'**';...
    0.0001,0.001,'***';...
    0,0.0001,'****';...
    };


for k = 1:2
    sel_state_idx = strcmp(num2str(k),...
        dist_pc_cell(:,4));

    xlist = 1:sel_pc_num;
    xlist_left = xlist-xlist_bias;
    xlist_right = xlist+xlist_bias;

    xlist_all = {xlist_left;xlist;xlist_right};

    subplot('Position',[...
        start_x+(k-1)*(box_x+inter_x),...
        start_y,box_x,box_y])

    for p = 1:sel_pc_num
        stat_x = [];
        stat_y = {};
        stat_cell = {};
        for q = 1:size(unique_brain,1)
            sel_pc_idx = strcmp(num2str(p),...
                dist_pc_cell(:,2));
            sel_brain_idx = strcmp(unique_brain{q},...
                dist_pc_cell(:,3));

            selidx = sel_state_idx&sel_pc_idx&sel_brain_idx;

            seldata = cell2mat(dist_pc_cell(selidx,1));

            selx = xlist_all{q};

            mean_data = mean(seldata);

            std_data = std(seldata)./sqrt(length(seldata));

            bar(selx(p),mean_data,bar_w,...
                'FaceColor',brain_c(q,:))
            hold on
            errorbar(selx(p),mean_data,std_data,...
                'Color','k','CapSize',cap_size)
            hold on
            plot(x_bias+selx(p)*ones(size(seldata)),...
                seldata,'o',...
                'MarkerFaceColor',brain_c(q,:),...
                'MarkerEdgeColor',brain_c(q,:),...
                'MarkerSize',mk_size)
            hold on

            %% stat
            % test
            [h_dist,p_dist] =kstest(seldata);
            if h_dist==0
                % normal distribution
                [~,p_value] = ttest(seldata);
                disp('normal')
            else
                % not normal distribution
                p_value = signrank(seldata);
            end

            disp(p_value)

             %% show stat
            for n = 1:size(show_star_list,1)
                if show_star_list{n,1}<=p_value &&...
                        p_value<show_star_list{n,2}
                    selstar = show_star_list{n,3};
                    text(selx(p),0.7,...
                        selstar,...
                        'HorizontalAlignment','left',...
                        'VerticalAlignment','middle',...
                        'Rotation',90)
                end
            end
        end
    end
    hold off

    if k == 1
        title({'Independent',''})
    else
        title({'Pre-social',''})
    end

    axis([0.3,sel_pc_num+0.7,-0.7,0.7])

    box off
    set(gca,'TickDir','out')
    set(gca,'FontSize',6)

    set(gca,'XTick',xlist)
    set(gca,'XTickLabel',show_x_tick)

    if k == 2
        set(gca,'YTickLabel',[])
    else
        ylabel('Correlation coefficient')
    end
end

%% calculate the correlations between PC and mov
corr_cell = {};

corr_thres = 0.4;

for k = 1:size(sort_cf_cell,1)
    %% load data 
    tempmovself = cell2mat(sort_cf_cell{k,4}(:,2));
    tempmovpartner = cell2mat(sort_cf_cell{k,7}(:,2));

    temppc = pca_cell{k}{1};

    bw_pc = imbinarize(temppc);
    %% convert to G
    movself_G = zeros(size(unique_mov,1),...
        size(tempmovself,1));
    movpartner_G = zeros(size(unique_mov,1),...
        size(tempmovpartner,1));

    for m = 1:size(movself_G,1)
        movself_G(m,:) = tempmovself==m;
    end
    for m = 1:size(movpartner_G,1)
        movpartner_G(m,:) = tempmovpartner==m;
    end

    [r_self,p_self] = corr(movself_G',temppc);
    [r_partner,p_partner] = corr(movpartner_G',temppc);

    mov_pc_cell = cell(size(r_self,1),size(r_self,2));
    for m = 1:size(mov_pc_cell,1)
        for n = 1:size(mov_pc_cell,2)
            mov_pc_cell{m,n} = {unique_mov_name{m},n};
        end
    end

    p_self_idx = p_self<0.05;
    r_self_idx = abs(r_self)>corr_thres;
    p_partner_idx = p_partner<0.05;
    r_partner_idx = abs(r_partner)>corr_thres;

    self_idx = p_self_idx&r_self_idx;
    partner_idx = p_partner_idx&r_partner_idx;

    self_mov_pc_cell = mov_pc_cell(self_idx);
    sel_r_self = r_self(self_idx);
    partner_mov_pc_cell = mov_pc_cell(partner_idx);
    sel_r_partner = r_partner(partner_idx);

    %% append data
    for m = 1:size(self_mov_pc_cell,1)
        corr_cell = [corr_cell;...
            {self_mov_pc_cell{m}{1},...
            self_mov_pc_cell{m}{2},...
            sel_r_self(m),...
            all_brain_name{k},...
            T(k),'self',...
            sel_r_self(m)>0}];
    end
    for m = 1:size(partner_mov_pc_cell,1)
        corr_cell = [corr_cell;...
            {partner_mov_pc_cell{m}{1},...
            partner_mov_pc_cell{m}{2},...
            sel_r_partner(m),...
            all_brain_name{k},...
            T(k),'partner',...
            sel_r_partner(m)>0}];
    end

    disp(k)
end
%% unique wash data
wash_corr_cell = corr_cell;
wash_corr_cell(cell2mat(corr_cell(:,2))>6,:) = [];


merge_name = cellfun(@(a,b,c,d,e,f) ...
    [a,'-',num2str(b),'-',c,'-',num2str(d),...
    '-',e],...
    wash_corr_cell(:,1),...
    wash_corr_cell(:,2),...
    wash_corr_cell(:,4),...
    wash_corr_cell(:,5),...
    wash_corr_cell(:,6),...
    'UniformOutput',false...
    );

tbl_merge = tabulate(merge_name);
tbl_merge(cell2mat(tbl_merge(:,2))<3,:) = [];

spl_tbl_merge = split(tbl_merge(:,1),'-');

%% show word cloud
start_x = 0.37;
start_y = 0.23;

box_x = 0.1;
box_y = 0.06;

inter_x = 0.001;

inter_y = 0.001;


xlabel_list = {...
    'S1','dmPFC','M1','S1','dmPFC','M1'};

x_cmp_brain_list = {...
    'tpmss','tpmpfc','tpmm','tpmss','tpmpfc','tpmm'};

temp_cmp = cbrewer2('Set1',8);

three_state_c = [...
    temp_cmp(2,:);...
    temp_cmp(1,:);...
    temp_cmp(4,:)];

for m = 1:3
    sel_pc_idx = strcmp(spl_tbl_merge(:,2),num2str(m));
    for n = 1:6
        if n<=3
            big_inter_x = 0;
        else
            big_inter_x = 0.01;
        end
        subplot('Position',[...
            start_x+(n-1)*(box_x+inter_x)+big_inter_x,...
            start_y-(m-1)*(box_y+inter_y),...
            box_x,box_y])

        if n<=3
            sel_ind_idx = strcmp(spl_tbl_merge(:,5),'self');
        else
            sel_ind_idx = strcmp(spl_tbl_merge(:,5),'partner');
        end

        sel_brain_idx = strcmp(spl_tbl_merge(:,3),x_cmp_brain_list{n});
        
        selidx = sel_pc_idx&sel_ind_idx&sel_brain_idx;

        seltbl = spl_tbl_merge(selidx,:);

        show_word = lower(seltbl(:,1));

        spl_show_word = {};
        spl_state_idx = {};

        for k = 1:size(show_word,1)
            tempspl = split(show_word{k},'_');
            for p = 1:size(tempspl,1)
                spl_show_word = [spl_show_word;...
                    [tempspl{p}]];
                spl_state_idx = [spl_state_idx;...
                    seltbl{k,4}];
            end
        end

        unique_spl_show_word = unique(spl_show_word);
        unique_cmp = zeros(size(unique_spl_show_word,1),3);
        
        for k = 1:size(unique_spl_show_word,1)
            selidx = strcmp(unique_spl_show_word{k},...
                spl_show_word);
            sel_state = spl_state_idx(selidx);
            if size(sel_state,1) == 1
                if strcmp(sel_state{1},'1')
                    unique_cmp(k,:) = three_state_c(1,:);
                else
                    unique_cmp(k,:) = three_state_c(2,:);
                end
            else
                unique_cmp(k,:) = three_state_c(3,:);
            end
        end

        wordcloud(unique_spl_show_word,...
            'Color',unique_cmp,...
            'Shape','oval')

        if n == 1
            % ylabel(['PC', num2str(m)])
        end

        if m == 1
            if n == 2
                title('Self')
            elseif n == 5
                title('Partner')
            end
        elseif m == 6
            % xlabel(xlabel_list{n})
        end

        % set(gca,'FontSize',6)
        % set(gca,'XTick',[],'YTick',[])

        box on
    end
end












































