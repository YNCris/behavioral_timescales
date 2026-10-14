%{
    pca拓展到更广泛的情况
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

load([beh_neu_path,'\dist_mat_all_20240822.mat'])
load([beh_neu_path,'\embedding_20240822.mat'])
load([beh_neu_path,'\data_sample_cell_20240822.mat'])
%% create the unique_mov and unique_seq
all_mov = [];
all_mov_name = {};
for k = 1:size(all_data_cell,1)
    all_mov = [all_mov;...
        cell2mat(all_data_cell{k,4}(:,2));...
        cell2mat(all_data_cell{k,7}(:,2))];
    all_mov_name = [all_mov_name;...
        all_data_cell{k,4}(:,1);...
        all_data_cell{k,7}(:,1)];
end
unique_mov = unique(all_mov);
cmap_mov = cbrewer2('BuPu',length(unique_mov));

uniuqe_mov_name = cell(size(unique_mov));
for k = 1:size(unique_mov,1)
    tempname = all_mov_name(unique_mov(k)==all_mov);
    uniuqe_mov_name{k} = tempname{1};
end

all_seq = [];
for k = 1:size(all_data_cell,1)
    all_seq = [all_seq;all_data_cell{k,5};all_data_cell{k,8}];
end
unique_seq = unique(all_seq);
unique_seq = unique_seq(2:end);
cmap_seq = cbrewer2('BuPu',length(unique_seq));
%% plot canvas
hall = figure(1);
set(hall,'Position',[680,0,800,800])
set(hall,'color','white');
%% split name
splname = split(all_data_cell(:,1),'-');
all_mouse_idx = cellfun(@(x) x(1),...
    splname(:,3),'UniformOutput',false);

all_brain_name = cellfun(@(x) x(2:end),...
    splname(:,3),'UniformOutput',false);
%% show variance explained
start_x = 0.04;
start_y = 0.87;

box_x = 0.12;
box_y = box_x;

show_brain_list = {...
    'tpmss';...
    'tpmpfc';...
    'tpmm'};

neu_cmap = cbrewer2('Paired',12);

in_c = neu_cmap(5,:);
de_c = neu_cmap(1,:);
no_c = neu_cmap(3,:);

brain_c = [...
    de_c;...
    in_c;...
    no_c];

show_exp_len = 150;

error_bar_width = 2;

alpha_line = 0.2;

subplot('Position',...
    [start_x,start_y,box_x,box_y])

temph_cell = cell(size(show_brain_list,1),1);
for k = 1:size(show_brain_list,1)
    selidx = strcmp(show_brain_list{k},all_brain_name);
    seldata = cell2mat(...
        cellfun(@(x) x{7}(1:show_exp_len)',...
        all_data_cell(selidx,11),...
        'UniformOutput',false));

    mean_seldata = mean(seldata);
    std_seldata = std(seldata)./sqrt(size(seldata,1));

    tempe = errorbar(1:length(mean_seldata),...
        mean_seldata,std_seldata,...
        'CapSize',0,'LineWidth',error_bar_width,...
        'Color',brain_c(k,:));
    set([tempe.Bar, tempe.Line], ...
        'ColorType', 'truecoloralpha', ...
        'ColorData', [tempe.Line.ColorData(1:3); ...
        255*alpha_line])
    hold on
    temph_cell{k} = plot(mean_seldata,'Color',brain_c(k,:),...
        'LineWidth',1.5);
    hold on
end
hold on
plot([0,150],[90,90],'-k')
hold off

box off

legend([temph_cell{1},temph_cell{2},temph_cell{3}],...
    {'S1','dmPFC','M1'},'box','off',...
    'Location','northwest')

ylabel('Variance explained (%)')
xlabel('Principal components')

set(gca,'TickDir','out')

set(gca,'FontSize',6)

%% show pca accuracy
brain_beh_prec_cell = cell(...
    size(show_brain_list,1)*...
    size(all_data_cell{1,12},2),1);

sel_cell = {...
    'tpmss',1;...
    'tpmss',2;...
    'tpmss',3;...
    'tpmss',4;...
    'tpmss',5;...
    'tpmss',6;...
    'tpmpfc',1;...
    'tpmpfc',2;...
    'tpmpfc',3;...
    'tpmpfc',4;...
    'tpmpfc',5;...
    'tpmpfc',6;...
    'tpmm',1;...
    'tpmm',2;...
    'tpmm',3;...
    'tpmm',4;...
    'tpmm',5;...
    'tpmm',6;...
    };

show_tick = {...
    'S1-Self-Pose';...
    'S1-Partner-Pose';...
    'S1-Self-Movement';...
    'S1-Self-Movement';...
    'S1-Partner-Sequence';...
    'S1-Self-Sequence';...
    'dmPFC-Self-Pose';...
    'dmPFC-Partner-Pose';...
    'dmPFC-Self-Movement';...
    'dmPFC-Self-Movement';...
    'dmPFC-Partner-Sequence';...
    'dmPFC-Self-Sequence';...
    'M1-Self-Pose';...
    'M1-Partner-Pose';...
    'M1-Self-Movement';...
    'M1-Self-Movement';...
    'M1-Partner-Sequence';...
    'M1-Self-Sequence';...
    };

for k = 1:size(brain_beh_prec_cell,1)
    selbrainidx = strcmp(...
        sel_cell{k,1},...
        all_brain_name);
    selbehidx = sel_cell{k,2};

    seldata = cell2mat(...
        cellfun(@(x) mean(x{selbehidx}),...
        all_data_cell(selbrainidx,12),...
        'UniformOutput',false));

    brain_beh_prec_cell{k,1} = seldata;
end

mean_brain_beh_prec = cellfun(@(x) mean(x),...
    brain_beh_prec_cell);

[~,sortidx] = sort(mean_brain_beh_prec,'descend');

sort_brain_beh_prec_cell = ...
    brain_beh_prec_cell(sortidx,:);
sort_show_tick = show_tick(sortidx,:);
%% show
start_x = 0.19;
start_y = 0.87;

box_x = 0.3;
box_y = 0.12;


star_first_3 = {...
    'ns';...%self
    'ns';...
    'ns';...
    'ns';...
    'ns';...
    'ns';...
    'ns';...
    'ns';...
    'ns';...
    '*';...
    '**';...
    '**';...
    '**';...
    '**';...
    '**';...
    '***';...
    '****';...
    '****';...
    };

bar_w = 0.6;

cap_size = 2;

x_bias = 0.3;

max_y = 1.2;

sel_show = sort_brain_beh_prec_cell;
x_list = 1:size(sel_show,1);
mean_show = cell2mat(cellfun(@(x) mean(x),...
    sel_show(:,1),'UniformOutput',false));
std_show = cell2mat(cellfun(@(x) std(x)./sqrt(length(x)),...
    sel_show(:,1),'UniformOutput',false));

subplot('Position',[...
    start_x,start_y,box_x,box_y])
for k = 1:size(sel_show,1)
    tempname = sort_show_tick{k,1};
    splname = split(tempname,'-');
    if strcmp(splname{1},'S1')
        bar_c = brain_c(1,:);
    end
    if strcmp(splname{1},'dmPFC')
        bar_c = brain_c(2,:);
    end
    if strcmp(splname{1},'M1')
        bar_c = brain_c(3,:);
    end
    bar(x_list(k),mean_show(k),bar_w,...
        'FaceColor',bar_c)
    hold on
    errorbar(x_list(k),mean_show(k),std_show(k),...
        'CapSize',cap_size,'Color','k')
    hold on
    for m = 1:size(sel_show,1)
        tempy = sel_show{m,1};
        tempx = m*ones(size(tempy));
        plot(x_bias+tempx,tempy,'o','MarkerSize',2,...
            'MarkerFaceColor','w','MarkerEdgeColor','k',...
            'LineWidth',0.25)
        hold on
    end   
    
    if ~strcmp(star_first_3{k},'ns')
        text(x_list(k),1.05,star_first_3{k},...
            'Rotation',90,...
            'VerticalAlignment','top')
    end
end
plot([0,20],[mean(sel_show{1,1}),mean(sel_show{1,1})],...
        '--k','LineWidth',0.25)
hold off

box off

axis([0.3,18.7,0,max_y])

set(gca,'TickDir','Out')
set(gca,'XTick',x_list)
set(gca,'YTick',[0,1])
set(gca,'XTickLabel',sort_show_tick)
set(gca,'FontSize',6)
set(gca,'XTickLabelRotation',60)
ylabel('Accuracy')

%% cluster number calculate
T = cell2mat(data_sample_cell(:,4));

n_clus = length(unique(T));

%% show cluster
neu_clus_cmap = cbrewer2('Paired',n_clus);

neu_clus_cmaplist = neu_clus_cmap(T,:);

start_x = 0.52;
start_y = 0.87;

box_x = 0.12;
box_y = box_x;

xy_edge = 0.5;

max_x = max(embedding(:,1));
max_y = max(embedding(:,2));
min_x = min(embedding(:,1));
min_y = min(embedding(:,2));


subplot('Position',[start_x,start_y,box_x,box_y])
scatter(embedding(:,1),embedding(:,2),...
    3*ones(size(embedding,1),1),neu_clus_cmaplist,...
    'filled')

axis([min_x-xy_edge,max_x+xy_edge,...
    min_y-xy_edge,max_y+xy_edge,...
    ])

set(gca,'TickDir','out')
set(gca,'FontSize',6)
set(gca,'XTick',[],'YTick',[])

xlabel('UMAP 1')
ylabel('UMAP 2')

% colorbar
cbar_box_x = 0.006;
cbar_box_y = 0.05;

cbar_inter_x = 0.005;

temph = subplot('Position',[...
    start_x+1*(box_x)+cbar_inter_x,...
    start_y+box_y-cbar_box_y,...
    cbar_box_x,cbar_box_y]);
imagesc((1:size(neu_clus_cmap,1))')
colormap(temph,neu_clus_cmap)
set(gca,'XTick',[],'YTick',[])
text(2.5,4.5,'Neural motifs','FontSize',6,'Rotation',90,...
    'HorizontalAlignment','center')

%% show mouse cluster
start_x = 0.68;
start_y = 0.87;

box_x = 0.12;
box_y = box_x;

sel_dsc = data_sample_cell;


mouse_cmap = cbrewer2('Spectral',size(all_data_cell,1));

mouse_cmaplist = zeros(size(sel_dsc,1),3);
mouse_class = zeros(size(sel_dsc,1),1);
for k = 1:size(mouse_cmap,1)
    tempname = all_data_cell{k,1};

    selidx = strcmp(tempname,sel_dsc(:,3));
    mouse_class(selidx,:) = k;
    mouse_cmaplist(selidx,:) = ones(sum(selidx),1)*...
        mouse_cmap(k,:);
end

subplot('Position',[start_x,start_y,box_x,box_y])
scatter(embedding(:,1),embedding(:,2),...
    1*ones(size(embedding,1),1),mouse_cmaplist,...
    'filled','MarkerFaceAlpha','flat','AlphaData',...
    0.1*ones(size(embedding,1),1))

axis([min_x-xy_edge,max_x+xy_edge,...
    min_y-xy_edge,max_y+xy_edge,...
    ])

set(gca,'TickDir','out')
set(gca,'FontSize',6)
set(gca,'XTick',[],'YTick',[])

xlabel('UMAP 1')
% ylabel('UMAP 2')

% colorbar
cbar_box_x = 0.006;
cbar_box_y = 0.05;

cbar_inter_x = 0.005;

temph = subplot('Position',[...
    start_x+1*(box_x)+cbar_inter_x,...
    start_y+box_y-cbar_box_y,...
    cbar_box_x,cbar_box_y]);
imagesc((1:size(mouse_cmap,1))')
colormap(temph,mouse_cmap)
set(gca,'XTick',[],'YTick',[])
text(2.5,7.5,'No. mouse','FontSize',6,'Rotation',90,...
    'HorizontalAlignment','center')

%% compare the Silhouette Coefficient
s_neu = silhouette(embedding,T);
s_mouse = silhouette(embedding,mouse_class);

T_s_neu = zeros(size(unique(T),1),1);
for k = 1:size(T_s_neu,1)
    T_s_neu(k,1) = mean(s_neu(T==k,:));
end

T_s_mouse = zeros(size(unique(mouse_class),1),1);
for k = 1:size(T_s_mouse,1)
    T_s_mouse(k,1) = mean(s_mouse(mouse_class==k,:));
end

%% show
start_x = 0.87;
start_y = 0.87;

box_x = 0.12;
box_y = box_x;

bar_w = 0.6;

cap_size = 2;

x_bias = 0.3;

bar_c = 0.8*ones(1,3);

mean_T_s_neu = mean(T_s_neu);
std_T_s_neu = std(T_s_neu)./sqrt(length(T_s_neu));

mean_T_s_mouse = mean(T_s_mouse);
std_T_s_mouse = std(T_s_mouse)./sqrt(length(T_s_mouse));

subplot('Position',[start_x,start_y,box_x,box_y])
bar(1,mean_T_s_neu,bar_w,...
    'FaceColor',bar_c)
hold on
bar(2,mean_T_s_mouse,bar_w,...
    'FaceColor',bar_c)
hold on
errorbar(1,mean_T_s_neu,std_T_s_neu,...
    'CapSize',cap_size,'Color','k')
hold on
errorbar(2,mean_T_s_mouse,std_T_s_mouse,...
    'CapSize',cap_size,'Color','k')
hold on
plot(x_bias+ones(size(T_s_neu)),T_s_neu,'o',...
    'MarkerEdgeColor','k',...
    'MarkerFaceColor','w',...
    'LineWidth',0.25,...
    'MarkerSize',2)
hold on
plot(x_bias+2*ones(size(T_s_mouse)),T_s_mouse,'o',...
    'MarkerEdgeColor','k',...
    'MarkerFaceColor','w',...
    'LineWidth',0.25,...
    'MarkerSize',2)
hold on
plot([1,2],[1.05,1.05],'-k')
hold on
text(1.5,1.05,'****',...
    'HorizontalAlignment','center',...
    'VerticalAlignment','bottom')
hold off

box off

axis([0.3,2.7,-0.5,1.2])

set(gca,'XTick',[1,2])
set(gca,'XTickLabel',{'Neural motifs','Mice'})
set(gca,'XTickLabelRotation',0)

set(gca,'FontSize',6)
set(gca,'TickDir','out')

ylabel('Silhouette coefficient')
%% show gtw
start_x = 0.03;
start_y = 0.73;

box_x = 0.1;
box_y = box_x;

inter_x = 0.005;
inter_y = 0.005;

xyz_size = 0.013;

for k = 1:size(gtw_cell,1)
    tempgtw = gtw_cell{k,1};
    if k<=6
        subplot('Position',[...
            start_x,start_y-(k-1)*(box_y+inter_y),...
            box_x,box_y])
    else
        subplot('Position',[...
            start_x+box_x+inter_x,...
            start_y-(k-6)*(box_y+inter_y),...
            box_x,box_y])
    end
    for m = 1:size(tempgtw,1)
        plot3(...
            tempgtw{m}(1,:),...
            tempgtw{m}(2,:),...
            tempgtw{m}(3,:),'-',...
            'Color',[neu_clus_cmap(k,:),0.1])
        hold on
    end
    hold off

    if k<=6
        zlabel('UMAP 3')
    end

    if k == 6
        xlabel('UMAP 1')
        ylabel('UMAP 2')
    end

    if k == 11
        xlabel('UMAP 1')
        ylabel('UMAP 2')
    end
    
    grid on

    set(gca,'FontSize',6)
    set(gca,'TickLength',[0,0])
    set(gca,'XTickLabel',[])
    set(gca,'YTickLabel',[])
    set(gca,'ZTickLabel',[])

    axis([...
        -1*xyz_size,xyz_size,...
        -1*xyz_size,xyz_size,...
        -1*xyz_size,xyz_size,])

    view(10,10)
end
%% calculate the fractions in different brain area, ns
splallname = split(data_sample_cell(:,3),'-');
all_brain_name = cellfun(@(x) x(2:end),...
    splallname(:,3),'UniformOutput',false);

brain_name = {...
    'tpmss';...
    'tpmpfc';...
    'tpmm'};

brain_frac_cell = cell(size(brain_name,1),1);

for k = 1:size(brain_name,1)
    tempname = brain_name{k};
    selbrainidx = strcmp(all_brain_name,tempname);
    sel_dsc = data_sample_cell(selbrainidx,:);
    tempuniquemousename = unique(sel_dsc(:,3));

    tempfrac = zeros(n_clus,size(tempuniquemousename,1));

    for m = 1:size(tempuniquemousename,1)
        selmouseidx = strcmp(sel_dsc(:,3),...
            tempuniquemousename{m});
        sel_T = cell2mat(sel_dsc(selmouseidx,4));
        for n = 1:size(tempfrac,1)
            frac_class = mean(n==sel_T);
            tempfrac(n,m) = frac_class;
        end
    end

    brain_frac_cell{k} = tempfrac;
end
%% calculate how they match behaviors
mov_dsc = cell(size(data_sample_cell,1),2);

for k = 1:size(data_sample_cell,1)
    tempname = data_sample_cell{k,3};
    selmouseidx = strcmp(tempname,all_data_cell(:,1));
    tempsavelist = data_sample_cell{k,2};


    selmov_self = cell2mat(all_data_cell{selmouseidx,4}(...
        tempsavelist(1):tempsavelist(2),2));
    selmov_partner = cell2mat(all_data_cell{selmouseidx,7}(...
        tempsavelist(1):tempsavelist(2),2));

    mov_dsc{k,1} = cellfun(@(x) num2str(x),...
        num2cell(selmov_self'),'UniformOutput',false);
    mov_dsc{k,2} = cellfun(@(x) num2str(x),...
        num2cell(selmov_partner'),'UniformOutput',false);
end
%% calculate mov distance matrix
distmat_mov_self = zeros(size(mov_dsc,1),size(mov_dsc,1));

tic
for m = 1:size(mov_dsc,1)
    seg1 = mov_dsc{m,1};
    % speed up
    % create seg_cell
    seg1_cell = cell(size(mov_dsc,1)-m+1,1);
    for n = 1:size(seg1_cell,1)
        seg1_cell{n} = seg1;
    end

    seg2_cell = mov_dsc(m:end,1);
    
    v_list = cellfun(@(x,y) ...
        bleuEvaluationScore(x,y,'NgramWeights',1),...
        seg1_cell,seg2_cell,'UniformOutput',false);%bleu 1

    distmat_mov_self(m,m:end) = cell2mat(v_list);

    % for n = m:size(mov_dsc,1)
    %     seg2 = mov_dsc{n,1};
    % 
    %     v = bleuEvaluationScore(seg1,seg2,'NgramWeights',1);
    % 
    %     % tempdist = conDst(seg1, seg2);
    %     % tempdist(tempdist>0) = 1;
    %     % [v, S, DC] = dtwFord(tempdist);
    %     distmat_mov_self(m,n) = v;
    % end
    disp(m)
    toc
end

% fill full matrix
distmat_mov_self_all = distmat_mov_self + ...
    triu(distmat_mov_self, 1)';

save([beh_neu_path,'\distmat_mov_self_all_20240828.mat'],...
    'distmat_mov_self_all')
%%
distmat_mov_partner = zeros(size(mov_dsc,1),size(mov_dsc,1));
tic
for m = 1:size(mov_dsc,1)
    seg1 = mov_dsc{m,2};
    seg1_cell = cell(size(mov_dsc,1)-m+1,1);
    for n = 1:size(seg1_cell,1)
        seg1_cell{n} = seg1;
    end

    seg2_cell = mov_dsc(m:end,2);
    
    v_list = cellfun(@(x,y) ...
        bleuEvaluationScore(x,y,'NgramWeights',1),...
        seg1_cell,seg2_cell,'UniformOutput',false);%bleu 1

    distmat_mov_partner(m,m:end) = cell2mat(v_list);
    disp(m)
    toc
end

% fill full matrix
distmat_mov_partner_all = distmat_mov_partner + ...
    triu(distmat_mov_partner, 1)';

save([beh_neu_path,'\distmat_mov_partner_all_20240828.mat'],...
    'distmat_mov_partner_all')
%% merge brain label name
brain_label_name = cellfun(...
    @(x,y) [x,'_',num2str(y)],...
    all_brain_name,data_sample_cell(:,4),...
    'UniformOutput',false);

unique_brain_label_name = unique(brain_label_name);

in_out_cell = cell(size(unique_brain_label_name,1),4);

for k = 1:size(unique_brain_label_name,1)
    tempname = unique_brain_label_name{k,1};
    selidx = strcmp(tempname,brain_label_name);
    selmatidx = selidx*selidx';
    in_mat_self = distmat_mov_self_all(selmatidx==1);
    out_mat_self = distmat_mov_self_all(selmatidx~=1);
    in_mat_partner = distmat_mov_partner_all(selmatidx==1);
    out_mat_partner = distmat_mov_partner_all(selmatidx~=1);

    in_out_cell{k,1} = in_mat_self;
    in_out_cell{k,2} = out_mat_self;
    in_out_cell{k,3} = in_mat_partner;
    in_out_cell{k,4} = out_mat_partner;
end

mean_in_out = cell2mat(cellfun(@(x) mean(x),...
    in_out_cell,'UniformOutput',false));

%% calculate the best match time, use the switch point comparison
% generate the all_neusyn_cell


all_neusyn_cell = cell(size(all_data_cell,1),7);

for k = 1:size(all_data_cell,1)
    %% select names
    tempname = all_data_cell{k,1};

    selidx = strcmp(tempname,data_sample_cell(:,3));

    %% create neu_savelist

    sel_dsc = data_sample_cell(selidx,:);

    neu_savelist = cell2mat(sel_dsc(:,2));

    neu_savelist = [neu_savelist(:,1:2),...
        cell2mat(sel_dsc(:,4))];

    %% create mov_savelist
    mov_self_list = cell2mat(all_data_cell{k,4}(:,2));
    
    mov_self_savelist = idx2savelist(mov_self_list);

    mov_partner_list = cell2mat(all_data_cell{k,7}(:,2));
    
    mov_partner_savelist = idx2savelist(mov_partner_list);

    %% use neusyn as the reference, calculate the start and end distance
    ref_savelist_start = neu_savelist(:,1);
    ref_savelist_end = neu_savelist(:,2);
    
    obj_self_start = mov_self_savelist(:,1);
    obj_self_end = mov_self_savelist(:,2);

    obj_partner_start = mov_partner_savelist(:,1);
    obj_partner_end = mov_partner_savelist(:,2);

    dist_mat_self = pdist2(ref_savelist_start,obj_self_start);
    dist_mat_partner = pdist2(ref_savelist_start,obj_partner_start);

    min_dist_self = min(dist_mat_self,[],2);
    min_dist_partner = min(dist_mat_partner,[],2);

    match_savelist_self = zeros(size(ref_savelist_start,1),2);
    match_savelist_partner = zeros(size(ref_savelist_start,1),2);

    match_savelist_self(:,1) = ref_savelist_start;
    match_savelist_partner(:,1) = ref_savelist_start;

    for m = 1:size(match_savelist_self,1)
        match_savelist_self(m,2) = obj_self_start(...
            find(dist_mat_self(m,:)==min_dist_self(m),...
            1,'first'),1);
        match_savelist_partner(m,2) = obj_partner_start(...
            find(dist_mat_partner(m,:)==min_dist_partner(m),...
            1,'first'),1);
    end

    diff_match_savelist_self = ...
        match_savelist_self(:,1)-match_savelist_self(:,2);
    diff_match_savelist_partner = ...
        match_savelist_partner(:,1)-match_savelist_partner(:,2);

    %% calculate the specific mappings
    neusyn_time_self = cell(8,1);

    for m = 1:size(neusyn_time_self,1)
        selidx = m== neu_savelist(:,3);
        neusyn_time_self{m,1} = ...
            diff_match_savelist_self(selidx,:)';
    end

    neusyn_time_partner = cell(8,1);

    for m = 1:size(neusyn_time_partner,1)
        selidx = m== neu_savelist(:,3);
        neusyn_time_partner{m,1} = ...
            diff_match_savelist_partner(selidx,:)';
    end
    %% append data
    all_neusyn_cell{k,1} = diff_match_savelist_self;
    all_neusyn_cell{k,2} = diff_match_savelist_partner;

    all_neusyn_cell{k,3} = match_savelist_self;
    all_neusyn_cell{k,4} = match_savelist_partner;

    all_neusyn_cell{k,5} = neu_savelist(:,3);
    
    all_neusyn_cell{k,6} = neusyn_time_self;
    all_neusyn_cell{k,7} = neusyn_time_partner;

    
    %% temp show
    % for m = 1:8
    %     subplot(121)
    %     hist(neusyn_time_self{m},10)
    %     axis([-100,100,0,50])
    %     title(m)
    %     subplot(122)
    %     hist(neusyn_time_partner{m},10)
    %     axis([-100,100,0,50])
    %     title(tempname)
    %     pause
    % end
    % subplot(121)
    % hist(diff_match_savelist_self,128)
    % subplot(122)
    % hist(diff_match_savelist_partner,128)
    % title(tempname)
    % pause
end

%% calculate the median and mean value
median_mat = cell2mat(cellfun(@(x) median(x),...
    all_neusyn_cell(:,1:2),'UniformOutput',false));

mean_mat = cell2mat(cellfun(@(x) mean(x),...
    all_neusyn_cell(:,1:2),'UniformOutput',false));









































