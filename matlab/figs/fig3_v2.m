%{
    远近远（社交开始到结束），
    三层，三个脑区怎么处理，比较前后，同伴行为
    看能不能引出neural token的概念
%}
clear all
close all
addpath(genpath(pwd))
%% set path
rootpath = ['H:\MTPM_body_language'];
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
%% plot canvas
hall = figure(1);
set(hall,'Position',[680,0,800,800])
set(hall,'color','white');
%% draw two mice far-close-far
start_x = 0.02;
start_y = 0.94;

box_x = 0.1;
box_y = 0.1;

% % two mice
% subplot('Position',[start_x,start_y,box_x,box_y])
% box on
% set(gca,'XTick',[],'YTick',[])

% distance, 二次函数表示远近远
% start_x = 0.01;
start_y = 0.88;

box_x = 0.1;
box_y = 0.1;
subplot('Position',[start_x,start_y,box_x,box_y])
x = 0:0.1:20;
a = 1;
b = -1*(10*2*a);
y = a.*x.*x+b.*x;
plot(x,y,'-k')
xlabel('Time')
ylabel('Distance')
box off
set(gca,'XTick',[],'YTick',[])
set(gca,'FontSize',6)
%% show mov and seq of all the trials
% sort data by length
fcf_length = cell2mat(cellfun(@(x) size(x,1),fcf_cell(:,2),...
    'UniformOutput',false));

[~,sortidx] = sort(fcf_length,'descend');

sort_fcf_cell = fcf_cell(sortidx,:);

%% extract seq
seq_cell = cell(size(unique_seq,1),1);
for k = 1:size(unique_seq,1)
    tempseq = unique_seq(k,1);
    saveseqlist = {};
    for m = 1:size(sort_fcf_cell,1)
        seqlist_1 = sort_fcf_cell{m,5};
        seqlist_2 = sort_fcf_cell{m,8};
        movlist_1 = sort_fcf_cell{m,4}(:,1);
        movlist_2 = sort_fcf_cell{m,7}(:,1);
        movidxlist_1 = cell2mat(...
            sort_fcf_cell{m,4}(:,2));
        movidxlist_2 = cell2mat(...
            sort_fcf_cell{m,7}(:,2));

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
start_x = 0.16;
start_y = 0.88;

box_x = 0.138;
box_y = 0.1;

inter_x = 0.03;
inter_y = 0.01;

x_tick = [1,150,300,450,600];
x_tick_label = [-5,0,5,10,15];

% create mov mat
pad_len = 600;
self_mov_mat = -1*ones(size(sort_fcf_cell,1),pad_len);
start_list = zeros(size(self_mov_mat,1),2);
end_list = zeros(size(self_mov_mat,1),2);

for k = 1:size(self_mov_mat,1)
    tempmov = cell2mat(sort_fcf_cell{k,4}(:,2))';
    self_mov_mat(k,1:length(tempmov)) = tempmov;
    start_list(k,:) = [baseline_far_frame,k];
    end_list(k,:) = [length(tempmov)-after_far_frame,k];
end

temph = subplot('Position',[start_x,start_y,box_x,box_y]);
imagesc(self_mov_mat)
colormap(temph,[1,1,1;cmap_mov])
hold on
plot(start_list(:,1),start_list(:,2),'-k')
hold on
plot(end_list(:,1),end_list(:,2),'-k')
hold off

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
pad_len = 600;
self_seq_mat = -1*ones(size(sort_fcf_cell,1),pad_len);
start_list = zeros(size(self_seq_mat,1),2);
end_list = zeros(size(self_seq_mat,1),2);

for k = 1:size(self_seq_mat,1)
    tempseq = sort_fcf_cell{k,5}';
    self_seq_mat(k,1:length(tempseq)) = tempseq;
    start_list(k,:) = [baseline_far_frame,k];
    end_list(k,:) = [length(tempseq)-after_far_frame,k];
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
pad_len = 600;
part_mov_mat = -1*ones(size(sort_fcf_cell,1),pad_len);
start_list = zeros(size(part_mov_mat,1),2);
end_list = zeros(size(part_mov_mat,1),2);

for k = 1:size(part_mov_mat,1)
    tempmov = cell2mat(sort_fcf_cell{k,7}(:,2))';
    part_mov_mat(k,1:length(tempmov)) = tempmov;
    start_list(k,:) = [baseline_far_frame,k];
    end_list(k,:) = [length(tempmov)-after_far_frame,k];
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
pad_len = 600;
part_seq_mat = -1*ones(size(sort_fcf_cell,1),pad_len);
start_list = zeros(size(part_seq_mat,1),2);
end_list = zeros(size(part_seq_mat,1),2);

for k = 1:size(part_seq_mat,1)
    tempseq = sort_fcf_cell{k,8}';
    part_seq_mat(k,1:length(tempseq)) = tempseq;
    start_list(k,:) = [baseline_far_frame,k];
    end_list(k,:) = [length(tempseq)-after_far_frame,k];
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
pad_len = 600;
start_list = [];
end_list = [];

count = 1;

for k = 1:size(sort_fcf_cell,1)
    tempneu = sort_fcf_cell{k,2}';
    padneu = nan(size(tempneu,1),pad_len);

    for m = 1:size(padneu,1)
        ttneu = tempneu(m,:);
        padneu(m,1:length(ttneu)) = ttneu;
        start_list = [start_list;[baseline_far_frame,count]];
        end_list = [end_list;[length(ttneu)-after_far_frame,count]];

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
plot(start_list(:,1),start_list(:,2),'-k')
hold on
plot(end_list(:,1),end_list(:,2),'-k')
hold off

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

cbar_inter_x = -0.03;

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
    %% align by gtw
    Xs = cellfun(@(x) x',spl_embed,...
        'UniformOutput',false)';
    l = 300;
    ns = cellDim(Xs, 2);
    bas = baTems(l, ns, 'pol', ...
        [3 .4], 'tan', [3 .6 1]);
    aliT = [];

    inp = 'linear'; qp = 'matlab'; dp = 'c';

    parGtw = st('nItMa', 50, 'th', 0);
    parCca = st('d', 3, 'lams', 0);
    parFtw = st('nItMa', 2, 'th', 0, ...
        'lam', 0, 'nor', 'n', 'qp', qp, 'inp', inp);

    % utw (initialization)
    aliUtw = utw(Xs, bas, aliT);
    %
    ali = gtw( ...
        Xs, ...
        bas, ...
        aliUtw, ...
        aliT, ...
        parGtw, ...
        parCca, ...
        parFtw);
    %% reconstruction
    % parameter
    parPca = st('d', 3, 'homo', 'y');
    parMk = st('mkSiz', 3, 'lnWid', 1, 'ln', '-');

    % current
    homo_Xs = homoX(Xs);
    [Ys, ~, Us] = gtwTra(homo_Xs, ali, parCca, parFtw);
    new_Ys = Ys;
    for m = 1:size(new_Ys,2)
        new_Ys{m} = Ys{m}(1:3,:)';
    end
    fcf_mouse_cell{k,6} = new_Ys';
    %% save
    % save([beh_neu_path,'\',fcf_mouse_cell{k,1},...
    %     '-neu_fcf_cas.mat'],'sel_fcf')
    disp(k)
end

%% show umap 2d
% time_cmap = jet(256);%cbrewer2('Spectral',256);
% figure
% 
% for k = 1:size(fcf_mouse_cell,1)
%     tempembed = fcf_mouse_cell{k,5};
% 
%     for m = 1:size(tempembed,1)
%         score = tempembed{m,1};
%         show_cmap = mat2gray(...
%         imresize(time_cmap,[size(score,1),3]));
% 
%         subplot(3,5,k)
% 
%         plot(score(:,1),score(:,2),'-k')
%         hold on
%         scatter(score(:,1),score(:,2),...
%             5*ones(size(score,1),1),show_cmap,'filled')
%         hold on
% 
% 
% 
%     end
%     hold off
%     title(fcf_mouse_cell{k,1})
%     disp(k)
% end
%% align according to brain area
brain_name = {...
    'tpmss';...
    'tpmpfc';...
    'tpmm'};

spl_fcf_mouse_name = split(fcf_mouse_cell(:,1),'-');
fcf_mouse_brain_name = cellfun(@(x) x(2:end),...
    spl_fcf_mouse_name(:,3),'UniformOutput',false);

align_brain_cell = cell(size(brain_name,1),1);
for k = 1:size(align_brain_cell,1)
    %% load data
    tempbrain = brain_name{k,1};
    selidx = strcmp(tempbrain,fcf_mouse_brain_name);
    sel_fcf = fcf_mouse_cell(selidx,:);
    %% align
    Xs = {};
    for m = 1:size(sel_fcf,1)
        tempx = sel_fcf{m,5};
        for n = 1:size(tempx,1)
            Xs = [Xs,tempx{n}'];
        end
    end

    l = 600;
    ns = cellDim(Xs, 2);
    bas = baTems(l, ns, 'pol', ...
        [3 .4], 'tan', [3 .6 1]);
    aliT = [];

    inp = 'linear'; qp = 'matlab'; dp = 'c';

    parGtw = st('nItMa', 50, 'th', 0);
    parCca = st('d', 3, 'lams', 0);
    parFtw = st('nItMa', 2, 'th', 0, ...
        'lam', 0, 'nor', 'n', 'qp', qp, 'inp', inp);

    % utw (initialization)
    aliUtw = utw(Xs, bas, aliT);
    %
    ali = gtw( ...
        Xs, ...
        bas, ...
        aliUtw, ...
        aliT, ...
        parGtw, ...
        parCca, ...
        parFtw);

    % reconstruction
    % parameter
    parPca = st('d', 3, 'homo', 'y');
    parMk = st('mkSiz', 3, 'lnWid', 1, 'ln', '-');
    
    % current
    homo_Xs = homoX(Xs);
    [Ys, ~, Us] = gtwTra(homo_Xs, ali, parCca, parFtw);
    new_Ys = Ys;
    for m = 1:size(new_Ys,2)
        new_Ys{m} = Ys{m}(1:3,:)';
    end

    align_brain_cell{k,1} = new_Ys';
end
%% append the align_brain_cell
fcf_beh_cell = cell(size(unique_fcf_name,1),2);

for k = 1:size(fcf_beh_cell,1)
    %% load
    fcf_beh_cell{k,1} = unique_fcf_name{k};
    selidx = strcmp(fcf_beh_cell{k,1},...
        sort_fcf_name_list);
    sel_fcf = sort_fcf_cell(selidx,:);
    fcf_beh_cell{k,2} = sel_fcf;
end
%%
align_beh_cell = cell(size(align_brain_cell,1),9);
for k = 1:size(align_brain_cell,1)
    %% load data
    tempbrain = brain_name{k,1};
    selidx = strcmp(tempbrain,fcf_mouse_brain_name);
    sel_fcf = fcf_beh_cell(selidx,:);
    %% append data
    tempalign = align_brain_cell{k,1};
    %% align
    Xs_self_pose = {};
    for m = 1:size(sel_fcf,1)
        tempx = sel_fcf{m,2}(:,3);
        for n = 1:size(tempx,1)
            Xs_self_pose = [Xs_self_pose;tempx{n}];
        end
    end

    Xs_self_mov = {};
    for m = 1:size(sel_fcf,1)
        tempx = sel_fcf{m,2}(:,4);
        for n = 1:size(tempx,1)
            Xs_self_mov = [Xs_self_mov;tempx(n)];
        end
    end

    Xs_self_seq = {};
    for m = 1:size(sel_fcf,1)
        tempx = sel_fcf{m,2}(:,5);
        for n = 1:size(tempx,1)
            Xs_self_seq = [Xs_self_seq;tempx(n)];
        end
    end

    Xs_partner_pose = {};
    for m = 1:size(sel_fcf,1)
        tempx = sel_fcf{m,2}(:,6);
        for n = 1:size(tempx,1)
            Xs_partner_pose = [Xs_partner_pose;tempx{n}];
        end
    end

    Xs_partner_mov = {};
    for m = 1:size(sel_fcf,1)
        tempx = sel_fcf{m,2}(:,7);
        for n = 1:size(tempx,1)
            Xs_partner_mov = [Xs_partner_mov;tempx(n)];
        end
    end

    Xs_partner_seq = {};
    for m = 1:size(sel_fcf,1)
        tempx = sel_fcf{m,2}(:,8);
        for n = 1:size(tempx,1)
            Xs_partner_seq = [Xs_partner_seq;tempx(n)];
        end
    end

    Xs_name = {};
    for m = 1:size(sel_fcf,1)
        tempx = sel_fcf{m,2}(:,1);
        for n = 1:size(tempx,1)
            Xs_name = [Xs_name;tempx(n)];
        end
    end

    spl_Xs_name = split(Xs_name,'-');
    Xs_unique_name = cellfun(@(a,b,c,d,e) ...
        [a,'-',b,'-',c,'-',d,'-',e],...
        spl_Xs_name(:,1),...
        spl_Xs_name(:,2),...
        spl_Xs_name(:,3),...
        spl_Xs_name(:,4),...
        spl_Xs_name(:,5),...
        'UniformOutput',false...
        );

    Xs_raw_neu = {};
    for m = 1:size(sel_fcf,1)
        tempx = sel_fcf{m,2}(:,2);
        for n = 1:size(tempx,1)
            Xs_raw_neu = [Xs_raw_neu;tempx(n)];
        end
    end

    align_beh_cell{k,1} = Xs_self_pose;
    align_beh_cell{k,2} = Xs_self_mov;
    align_beh_cell{k,3} = Xs_self_seq;
    align_beh_cell{k,4} = Xs_partner_pose;
    align_beh_cell{k,5} = Xs_partner_mov;
    align_beh_cell{k,6} = Xs_partner_seq;
    align_beh_cell{k,7} = Xs_name;
    align_beh_cell{k,8} = Xs_unique_name;
    align_beh_cell{k,9} = Xs_raw_neu;
end
%% fit transition plane
tran_plane_cell = cell(size(align_brain_cell,1),4);
for k = 1:size(tran_plane_cell,1)
    tempdata = align_brain_cell{k,1};

    start_point = cell2mat(cellfun(@(x) ...
        x(baseline_far_frame,:),...
        tempdata,'UniformOutput',false));

    A = [start_point(:,1),start_point(:,2),...
        ones(size(start_point,1),1)];  
    b = start_point(:,3);  
    aa = inv(A'*A)*A'*b;  
    
    x = start_point(:,1);
    y = start_point(:,2);
    z = start_point(:,3);
     
    start_c = 1;
    start_a=-1*aa(1);
    start_b=-1*aa(2);
    start_d=-1*aa(3);

    % 图形绘制
    % figure
    % xfit = min(x):0.001:max(x);
    % yfit = min(y):0.001:max(y);
    % [XFIT,YFIT]= meshgrid (xfit,yfit);
    % ZFIT = -(d + a * XFIT + b * YFIT)/c;
    % 
    % scatter3(x,y,z,'filled')
    % hold on
    % mesh(XFIT,YFIT,ZFIT)
    % hold off

    end_point = cell2mat(cellfun(@(x) ...
        x(end-after_far_frame,:),...
        tempdata,'UniformOutput',false));

    A = [end_point(:,1),end_point(:,2),...
        ones(size(end_point,1),1)];  
    b = end_point(:,3);  
    aa = inv(A'*A)*A'*b;  
    
    x = end_point(:,1);
    y = end_point(:,2);
    z = end_point(:,3);
     
    end_c = 1;
    end_a=-1*aa(1);
    end_b=-1*aa(2);
    end_d=-1*aa(3);

    % 图形绘制
    % figure
    % xfit = min(x):0.001:max(x);
    % yfit = min(y):0.001:max(y);
    % [XFIT,YFIT]= meshgrid (xfit,yfit);
    % ZFIT = -(d + a * XFIT + b * YFIT)/c;
    % 
    % scatter3(x,y,z,'filled')
    % hold on
    % mesh(XFIT,YFIT,ZFIT)
    % hold off

    tran_plane_cell{k,1} = ...
        [start_a,start_b,start_c,start_d];
    tran_plane_cell{k,2} = ...
        [end_a,end_b,end_c,end_d];
    tran_plane_cell{k,3} = start_point;
    tran_plane_cell{k,4} = end_point;
end
%% calculate mean trajectories
mean_align_brain_cell = cell(...
    size(align_brain_cell,1),1);

res_size = 600;

for k = 1:size(mean_align_brain_cell,1)
    tempembed = align_brain_cell{k,1};
    resembed = cellfun(@(x) ...
        imresize(x,[res_size,3]),...
        tempembed, 'UniformOutput', false);

    sumembed = zeros(size(resembed{1}));
    for m = 1:size(resembed,1)
        sumembed = sumembed+resembed{m};
    end
    meanembed = sumembed./size(resembed,1);
    mean_align_brain_cell{k,1} = meanembed;
end
%% align mean trajctories
Xs = cellfun(@(x) x',...
    mean_align_brain_cell,...
    'UniformOutput',false)';

l = 600;
ns = cellDim(Xs, 2);
bas = baTems(l, ns, 'pol', ...
    [3 .4], 'tan', [3 .6 1]);
aliT = [];

inp = 'linear'; qp = 'matlab'; dp = 'c';

parGtw = st('nItMa', 50, 'th', 0);
parCca = st('d', 3, 'lams', 0);
parFtw = st('nItMa', 2, 'th', 0, ...
    'lam', 0, 'nor', 'n', 'qp', qp, 'inp', inp);

% utw (initialization)
aliUtw = utw(Xs, bas, aliT);
%
ali = gtw( ...
    Xs, ...
    bas, ...
    aliUtw, ...
    aliT, ...
    parGtw, ...
    parCca, ...
    parFtw);

% reconstruction
% parameter
parPca = st('d', 3, 'homo', 'y');
parMk = st('mkSiz', 3, 'lnWid', 1, 'ln', '-');

% current
homo_Xs = homoX(Xs);
[Ys, ~, Us] = gtwTra(homo_Xs, ali, parCca, parFtw);
new_Ys = Ys;
for m = 1:size(new_Ys,2)
    new_Ys{m} = Ys{m}(1:3,:)';
end

mean_align_cell = new_Ys';
%% calculate the distance
dist_mat = zeros(3,3);
for m = 1:size(dist_mat,1)
    data1 = mean_align_cell{m};
    for n = 1:size(dist_mat,2)
        data2 = mean_align_cell{n};
        tempdist = pdist2(data1,data2);
        dist_mat(m,n) = mean(tempdist(:));
    end
end

%% mapping across animals
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

% reorganize data
reo_brain_cell = {};
for k = 1:size(align_brain_cell,1)
    tempbrain = align_brain_cell{k,1};
    temprawneu = align_beh_cell{k,9};
    reo_brain_cell = [reo_brain_cell;...
        [tempbrain,temprawneu]];
end

reo_beh_cell = {};
for k = 1:size(align_beh_cell,1)
    tempbeh1 = align_beh_cell{k,1};
    tempbeh2 = align_beh_cell{k,2};
    tempbeh3 = align_beh_cell{k,3};
    tempbeh4 = align_beh_cell{k,4};
    tempbeh5 = align_beh_cell{k,5};
    tempbeh6 = align_beh_cell{k,6};
    tempbeh7 = align_beh_cell{k,7};
    tempbeh8 = align_beh_cell{k,8};

    reo_beh_cell = [reo_beh_cell;...
        [tempbeh1,tempbeh2,tempbeh3,tempbeh4,...
        tempbeh5,tempbeh6,tempbeh7,tempbeh8,...
        ]];
end

% cross mapping
map_len = 300;%10s
for m = 1:size(self_map_pose_cell,1)
    for n = 1:size(self_map_pose_cell,2)
        %% load data
        tempname1 = map_name_list{m,1};% brain
        tempname2 = map_name_list{n,1};% behavior

        selidx1 = strcmp(tempname1,reo_beh_cell(:,8));
        selidx2 = strcmp(tempname2,reo_beh_cell(:,8));

        selbrain = reo_brain_cell(selidx1,:);
        selbeh = reo_beh_cell(selidx2,:);
        %% cross mapping
        temp_self_map_pose = [];
        temp_self_map_mov = [];
        temp_self_map_seq = [];
        temp_partner_map_pose = [];
        temp_partner_map_mov = [];
        temp_partner_map_seq = [];

        temp_self_raw_pose = [];
        temp_self_raw_mov = [];
        temp_self_raw_seq = [];
        temp_partner_raw_pose = [];
        temp_partner_raw_mov = [];
        temp_partner_raw_seq = [];

        for p = 1:size(selbrain,1)
            for q = 1:size(selbeh,1)
                tempneu = selbrain{p,1}(1:map_len,:);
                temprawneu = selbrain{p,2}(1:map_len,:);
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
                self_pose_rlist_raw = ...
                    zeros(size(self_temppose,2),1);
                for a = 1:size(self_temppose,2)
                    %
                    ttpose = self_temppose(:,a);
                    mdl = fitglm(tempneu,ttpose);
                    ypred = predict(mdl,tempneu);
                    [r,rp] = corr(ttpose,ypred);
                    self_pose_rlist(a,1) = r;

                    mdl = fitglm(temprawneu,ttpose);
                    ypred = predict(mdl,temprawneu);
                    [r,rp] = corr(ttpose,ypred);
                    self_pose_rlist_raw(a,1) = r;
                end

                partner_pose_rlist = ...
                    zeros(size(partner_temppose,2),1);
                partner_pose_rlist_raw = ...
                    zeros(size(partner_temppose,2),1);
                for a = 1:size(partner_temppose,2)
                    %
                    ttpose = partner_temppose(:,a);
                    mdl = fitglm(tempneu,ttpose);
                    ypred = predict(mdl,tempneu);
                    [r,rp] = corr(ttpose,ypred);
                    partner_pose_rlist(a,1) = r;

                    mdl = fitglm(temprawneu,ttpose);
                    ypred = predict(mdl,temprawneu);
                    [r,rp] = corr(ttpose,ypred);
                    partner_pose_rlist_raw(a,1) = r;
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

                train_neu = temprawneu;
                mdl = fitcdiscr(train_neu,self_tempmov);
                ypred = predict(mdl,temprawneu);
                prec = ypred==self_tempmov;
                
                self_mov_prec_raw = -1*ones(size(unique_mov));
                for a = 1:size(self_mov_prec_raw,1)
                    selprec = prec(...
                        unique_mov(a)==self_tempmov,:);
                    if size(selprec,1) > 0
                        self_mov_prec_raw(a) = mean(selprec);
                    end
                end
                self_mov_prec_raw(self_mov_prec_raw==-1) = [];

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

                train_neu = temprawneu;
                mdl = fitcdiscr(train_neu,partner_tempmov);
                ypred = predict(mdl,temprawneu);
                prec = ypred==partner_tempmov;
                
                partner_mov_prec_raw = -1*ones(size(unique_mov));
                for a = 1:size(partner_mov_prec_raw,1)
                    selprec = prec(...
                        unique_mov(a)==partner_tempmov,:);
                    if size(selprec,1) > 0
                        partner_mov_prec_raw(a) = mean(selprec);
                    end
                end
                partner_mov_prec_raw(partner_mov_prec_raw==-1) = [];

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

                train_neu = temprawneu;
                mdl = fitcdiscr(train_neu,self_tempseq);
                ypred = predict(mdl,temprawneu);
                prec = ypred==self_tempseq;

                self_seq_prec_raw = -1*ones(size(unique_seq));
                for a = 1:size(self_seq_prec_raw,1)
                    selprec = prec(...
                        unique_seq(a)==self_tempseq,:);
                    if size(selprec,1) > 0
                        self_seq_prec_raw(a) = mean(selprec);
                    end
                end
                self_seq_prec_raw(self_seq_prec_raw==-1) = [];

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

                train_neu = temprawneu;
                mdl = fitcdiscr(train_neu,partner_tempseq);
                ypred = predict(mdl,temprawneu);
                prec = ypred==partner_tempseq;

                partner_seq_prec_raw = -1*ones(size(unique_seq));
                for a = 1:size(partner_seq_prec_raw,1)
                    selprec = prec(...
                        unique_seq(a)==partner_tempseq,:);
                    if size(selprec,1) > 0
                        partner_seq_prec_raw(a) = mean(selprec);
                    end
                end
                partner_seq_prec_raw(partner_seq_prec_raw==-1) = [];
                
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

                temp_self_raw_pose = [...
                    temp_self_raw_pose;...
                    mean(self_pose_rlist_raw)];
                temp_partner_raw_pose = [...
                    temp_partner_raw_pose;...
                    mean(partner_pose_rlist_raw)];

                temp_self_raw_mov = [...
                    temp_self_raw_mov;...
                    mean(self_mov_prec_raw)];
                temp_partner_raw_mov = [...
                    temp_partner_raw_mov;...
                    mean(partner_mov_prec_raw)];

                temp_self_raw_seq = [...
                    temp_self_raw_seq;...
                    mean(self_seq_prec_raw)];
                temp_partner_raw_seq = [...
                    temp_partner_raw_seq;...
                    mean(partner_seq_prec_raw)];
            end
        end
        %% append data
        self_map_pose_cell{m,n} = temp_self_map_pose;
        self_map_mov_cell{m,n} = temp_self_map_mov;
        self_map_seq_cell{m,n} = temp_self_map_seq;
        partner_map_pose_cell{m,n} = temp_partner_map_pose;
        partner_map_mov_cell{m,n} = temp_partner_map_mov;
        partner_map_seq_cell{m,n} = temp_partner_map_seq;

        self_raw_pose_cell{m,n} = temp_self_raw_pose;
        self_raw_mov_cell{m,n} = temp_self_raw_mov;
        self_raw_seq_cell{m,n} = temp_self_raw_seq;
        partner_raw_pose_cell{m,n} = temp_partner_raw_pose;
        partner_raw_mov_cell{m,n} = temp_partner_raw_mov;
        partner_raw_seq_cell{m,n} = temp_partner_raw_seq;
    end
    disp(m)
end
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

wash_self_raw_pose_cell = cellfun(@(x) x(~isnan(x)),...
    self_raw_pose_cell,'UniformOutput',false);
wash_self_raw_mov_cell = cellfun(@(x) x(~isnan(x)),...
    self_raw_mov_cell,'UniformOutput',false);
wash_self_raw_seq_cell = cellfun(@(x) x(~isnan(x)),...
    self_raw_seq_cell,'UniformOutput',false);
wash_partner_raw_pose_cell = cellfun(@(x) x(~isnan(x)),...
    partner_raw_pose_cell,'UniformOutput',false);
wash_partner_raw_mov_cell = cellfun(@(x) x(~isnan(x)),...
    partner_raw_mov_cell,'UniformOutput',false);
wash_partner_raw_seq_cell = cellfun(@(x) x(~isnan(x)),...
    partner_raw_seq_cell,'UniformOutput',false);

mean_self_raw_pose = cell2mat(cellfun(@(x) mean(x),...
    wash_self_raw_pose_cell,'UniformOutput',false));
mean_self_raw_mov = cell2mat(cellfun(@(x) mean(x),...
    wash_self_raw_mov_cell,'UniformOutput',false));
mean_self_raw_seq = cell2mat(cellfun(@(x) mean(x),...
    wash_self_raw_seq_cell,'UniformOutput',false));
mean_partner_raw_pose = cell2mat(cellfun(@(x) mean(x),...
    wash_partner_raw_pose_cell,'UniformOutput',false));
mean_partner_raw_mov = cell2mat(cellfun(@(x) mean(x),...
    wash_partner_raw_mov_cell,'UniformOutput',false));
mean_partner_raw_seq = cell2mat(cellfun(@(x) mean(x),...
    wash_partner_raw_seq_cell,'UniformOutput',false));
%% show mappings, raw neural activity
start_x = 0.06;
start_y = 0.765;

box_x = 0.075;
box_y = box_x;

inter_x = 0.005;
inter_y = 0.005;

show_raw_cell = {...
    mean_self_raw_pose,mean_partner_raw_pose,...
    mean_self_raw_mov,mean_partner_raw_mov,...
    mean_self_raw_seq,mean_partner_raw_seq};

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
            text(-9,8,y_label_list{m},'FontSize',6,...
                'Rotation',90,'HorizontalAlignment','center')
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
%% show trajectories according to brain area
start_x = 0.25;
start_y = 0.61;

box_x = 0.23;
box_y = box_x;

inter_x = 0.015;

time_cmap = flipud(cbrewer2('Spectral',256));

view_list = [...
    169,-1;...
    112,-7;...
    185,-4];

show_brain_name = {...
    'S1';...
    'dmPFC';...
    'M1'};

alpha_surf = 0.3;

bias_xy = 0.005;

for k = 1:size(align_brain_cell,1)
    temph = subplot('Position',[...
        start_x+(k-1)*(box_x+inter_x),...
        start_y,box_x,box_y]);
    %%
    tempembed = align_brain_cell{k,1};

    all_embed = cell2mat(tempembed);
    min_x = min(all_embed(:,1));
    max_x = max(all_embed(:,1));
    min_y = min(all_embed(:,2));
    max_y = max(all_embed(:,3));
    min_z = min(all_embed(:,3));
    max_z = max(all_embed(:,3));

    %% show plane
    start_point = tran_plane_cell{k,3};
    end_point = tran_plane_cell{k,4};

    a = tran_plane_cell{k,1}(1);
    b = tran_plane_cell{k,1}(2);
    c = tran_plane_cell{k,1}(3);
    d = tran_plane_cell{k,1}(4);

    xfit = min(start_point(:,1)-bias_xy):0.001:...
        max(start_point(:,1)+bias_xy);
    yfit = min(start_point(:,2)-bias_xy):0.001:...
        max(start_point(:,2)+bias_xy);
    [XFIT,YFIT]= meshgrid (xfit,yfit);
    ZFIT = -(d + a * XFIT + b * YFIT)/c;
    temps = surf(XFIT,YFIT,ZFIT);
    alpha(temps,alpha_surf)
    shading interp
    hold on

    a = tran_plane_cell{k,2}(1);
    b = tran_plane_cell{k,2}(2);
    c = tran_plane_cell{k,2}(3);
    d = tran_plane_cell{k,2}(4);

    xfit = min(end_point(:,1)-bias_xy):0.001:...
        max(end_point(:,1)+bias_xy);
    yfit = min(end_point(:,2)-bias_xy):0.001:...
        max(end_point(:,2)+bias_xy);
    [XFIT,YFIT]= meshgrid (xfit,yfit);
    ZFIT = -(d + a * XFIT + b * YFIT)/c;
    temps = surf(XFIT,YFIT,ZFIT);
    alpha(temps,alpha_surf)
    shading interp
    hold on

    colormap(temph,0.1*ones(256,3))
    %% show trajectory
    for m = 1:size(tempembed,1)
        score = tempembed{m};
        show_cmap = mat2gray(...
        imresize(time_cmap,[size(score,1),3]));

        plot3(score(:,1),score(:,2),score(:,3),'-',...
            'LineWidth',0.25,'Color',0.8*ones(1,3))
        hold on
        scatter3(score(:,1),score(:,2),score(:,3),...
            2*ones(size(score,1),1),show_cmap,'filled')
        hold on
    end
    hold off

    axis([min_x,max_x,min_y,max_y,min_z,max_z])

    view(view_list(k,1),view_list(k,2))
    % axis off
    grid on
    set(gca,'XTickLabel',[],'YTickLabel',[],'ZTickLabel',[])
    xlabel('UMAP 1')
    ylabel('UMAP 2')
    zlabel('UMAP 3')
    set(gca,'FontSize',6)
    set(gca,'TickLength',[0,0])
    title(show_brain_name{k})
end

% colorbar
cbar_box_x = 0.006;
cbar_box_y = 0.05;

cbar_inter_x = -0.01;

temph = subplot('Position',[...
    start_x+3*(box_x+inter_x)+cbar_inter_x,...
    start_y+box_y-cbar_box_y,...
    cbar_box_x,cbar_box_y]);
imagesc(flipud((1:256)'))
colormap(temph,time_cmap)
set(gca,'XTick',[],'YTick',[])

text(0.5,280,'-5','FontSize',6,'VerticalAlignment','middle')
text(0.5,-30,'max','FontSize',6,'VerticalAlignment','middle')

text(2.5,128,'Time (s)','FontSize',6,'Rotation',90,...
    'HorizontalAlignment','center')
%% show embedding mapping
start_x = 0.06;
start_y = 0.52;

box_x = 0.075;
box_y = box_x;

inter_x = 0.005;
inter_y = 0.005;

show_mat_cell = {...
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
        imagesc(show_mat_cell{count},[0,1])
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
        
        if m == 3
            set(gca,'XTickLabel',show_brain_name_tick,...
                'XTickLabelRotation',45)
        else
            set(gca,'XTickLabel',[])
        end
        
        box off

        % if m == 1
        %     title(title_list{n})
        % end

        if n == 1
            text(-9,8,y_label_list{m},'FontSize',6,...
                'Rotation',90,'HorizontalAlignment','center')
        end

        set(gca,'FontSize',6)
        set(gca,'XTick',xy_tick)
        set(gca,'YTick',xy_tick)
        set(gca,'TickDir','out')
    end
end

%% compare all neuron with embedding
start_x = 0.25;
start_y = 0.48;

box_x = 0.23;
box_y = 0.09;

inter_y = 0.03;

bar_w = 0.6;
cap_size = 2;

x_bias = 0.3;

bar_c_raw = mat_cmap(end,:);
bar_c_embed = mat_cmap(400,:);

% same mapping, all neuron vs embedding
subplot('Position',[start_x,start_y,box_x,box_y])

cmp_cell = {...
    mean_self_raw_pose,mean_self_map_pose,...
    mean_partner_raw_pose,mean_partner_map_pose,...
    mean_self_raw_mov,mean_self_map_mov,...
    mean_partner_raw_mov,mean_partner_map_mov,...
    mean_self_raw_seq,mean_self_map_seq,...
    mean_partner_raw_seq,mean_partner_map_seq,...
    };

eye_cell = cellfun(@(x) diag(x),...
    cmp_cell,'UniformOutput',false);
beye_cell = cellfun(@(x) [...
    reshape(triu(x,1),[],1);...
    reshape(tril(x,-1),[],1);...
    ],...
    cmp_cell,'UniformOutput',false);
beye_cell = cellfun(@(x) x(x~=0),...
    beye_cell,'UniformOutput',false);

stat_mat = cell2mat(eye_cell);

mean_stat_mat = mean(stat_mat);
std_stat_mat = std(stat_mat)./sqrt(size(stat_mat,1));

xlist = [1,2,3,4,6,7,8,9,11,12,13,14];

show_xlist = [1.5,3.5,6.5,8.5,11.5,13.5];

show_big_xlist = [2.5,7.5,12.5];

show_xticklabel = {...
    'Self','Partner',...
    'Self','Partner',...
    'Self','Partner',...
    };

show_star = {...
    '****','****',...
    '****','****',...
    '***','****'};

for k = 1:size(mean_stat_mat,2)
    if rem(k,2) ~= 0
        bar_c = bar_c_raw;
        plot([xlist(k),xlist(k+1)],[1.1,1.1],'-k')
        hold on
        text(show_xlist((1+k)/2),1.0,show_star{(1+k)/2},...
            'HorizontalAlignment','center',...
            'VerticalAlignment','bottom'...
            )
    else
        bar_c = bar_c_embed;
    end

    if k == 1
        templ1 = bar(xlist(k),mean_stat_mat(k),bar_w,...
                'FaceColor',bar_c);
    elseif k == 2
        templ2 = bar(xlist(k),mean_stat_mat(k),bar_w,...
            'FaceColor',bar_c);
    else
        bar(xlist(k),mean_stat_mat(k),bar_w,...
            'FaceColor',bar_c)
    end
    hold on
    errorbar(xlist(k),mean_stat_mat(k),std_stat_mat(k),...
        'Color','k','CapSize',cap_size)
    hold on
    
    tempy = stat_mat(:,k);
    plot(x_bias+xlist(k)*ones(size(tempy)),tempy,...
        'o','MarkerSize',2,...
        'MarkerEdgeColor','k','MarkerFaceColor','w',...
        'LineWidth',0.25)
    hold on
end
hold off

box off

axis([0.3,14.7,0,1.1])

set(gca,'TickDir','out')
set(gca,'XTick',show_xlist)
set(gca,'XTickLabel',show_xticklabel)
set(gca,'XTickLabelRotation',0)
set(gca,'FontSize',6)
set(gca,'YTick',[0,1])

legend([templ1,templ2],...
    {'Neurons','Embeddings'},'box','off')

for k = 1:length(show_big_xlist)
    text(show_big_xlist(k),-0.25,y_label_list(k),...
        'FontSize',6,'HorizontalAlignment','center')
end

ylabel('Accuracy')

% different individual mapping
eye_mat = cell2mat(eye_cell);
beye_mat = cell2mat(beye_cell);

%[raw_inner_individual_pose,raw_across_individual_pose,...
% map_inner_individual_pose,map_across_individual_pose,...
%raw_inner_individual_mov,raw_across_individual_mov,...
% map_inner_individual_mov,map_across_individual_mov,...
%raw_inner_individual_pose,raw_across_individual_pose,...
% map_inner_individual_pose,map_across_individual_pose,...
% ]
show_mat = {...
    [eye_mat(:,1);eye_mat(:,3)],[beye_mat(:,1);beye_mat(:,3)],...
    [eye_mat(:,2);eye_mat(:,4)],[beye_mat(:,2);beye_mat(:,4)],...
    [eye_mat(:,5);eye_mat(:,7)],[beye_mat(:,5);beye_mat(:,7)],...
    [eye_mat(:,6);eye_mat(:,8)],[beye_mat(:,6);beye_mat(:,8)],...
    [eye_mat(:,9);eye_mat(:,11)],[beye_mat(:,9);beye_mat(:,11)],...
    [eye_mat(:,10);eye_mat(:,12)],[beye_mat(:,10);beye_mat(:,12)],...
    };

bar_c_list = [...
    bar_c_raw;bar_c_raw;...
    bar_c_embed;bar_c_embed;...
    bar_c_raw;bar_c_raw;...
    bar_c_embed;bar_c_embed;...
    bar_c_raw;bar_c_raw;...
    bar_c_embed;bar_c_embed;...
    ];

mean_show_mat = cell2mat(cellfun(@(x) mean(x),...
    show_mat,'UniformOutput',false));

std_show_mat = cell2mat(cellfun(@(x) std(x)./sqrt(length(x)),...
    show_mat,'UniformOutput',false));

subplot('Position',[start_x,...
    start_y-(box_y+inter_y),box_x,box_y])

for k = 1:size(mean_show_mat,2)

    % if rem(k,2) ~= 0
    %     bar_c = bar_c_raw;
    %     plot([xlist(k),xlist(k+1)],[1.1,1.1],'-k')
    %     hold on
    % end
    
    if k == 1
        templ1 = bar(xlist(k),mean_show_mat(k),bar_w,...
                'FaceColor',bar_c_list(k,:));
    elseif k == 2
        templ2 = bar(xlist(k),mean_show_mat(k),bar_w,...
            'FaceColor',bar_c_list(k,:));
    else
        bar(xlist(k),mean_show_mat(k),bar_w,...
            'FaceColor',bar_c_list(k,:))
    end
    hold on
    errorbar(xlist(k),mean_show_mat(k),std_show_mat(k),...
        'Color','k','CapSize',cap_size)
    hold on
    
    tempy = show_mat{k};
    plot(x_bias+xlist(k)*ones(size(tempy)),tempy,...
        'o','MarkerSize',2,...
        'MarkerEdgeColor','k','MarkerFaceColor','w',...
        'LineWidth',0.25)
    hold on
end
hold off

box off

axis([0.3,14.7,0,1.1])

set(gca,'TickDir','out')
set(gca,'XTick',xlist)

show_xticklabel = {...
    'Intra','Extra','Intra','Extra',...
    'Intra','Extra','Intra','Extra',...
    'Intra','Extra','Intra','Extra',...
    };

set(gca,'XTickLabel',show_xticklabel)
set(gca,'XTickLabelRotation',45)
set(gca,'FontSize',6)
set(gca,'YTick',[0,1])

for k = 1:length(show_big_xlist)
    text(show_big_xlist(k),-0.45,y_label_list(k),...
        'FontSize',6,'HorizontalAlignment','center')
end

ylabel('Accuracy')

%% use pca to do the linear component analysis
pca_cell = cell(size(reo_brain_cell,1),5);

for k = 1:size(pca_cell,1)
    tempneu = reo_brain_cell{k,2};
    [coeff, score, ~, ~, explained] = pca(tempneu');
    pca_cell{k,1} = coeff;
    pca_cell{k,2} = score;
    pca_cell{k,3} = explained;
    pca_cell{k,4} = cumsum(explained);

    norm_coeff = zeros(size(coeff));
    for m = 1:size(coeff,2)
        norm_coeff(:,m) = mat2gray(coeff(:,m));
    end
    pca_cell{k,5} = norm_coeff;
end

tempsplname = split(reo_beh_cell(:,8),'-');
reo_brain_name = cellfun(@(x) x(2:end),...
    tempsplname(:,3),'UniformOutput',false);

%% show explained, get data
show_reo_brain_name = {...
    'tpmss';...
    'tpmpfc';...
    'tpmm'};


sel_exp_len = 100;

group_explain_cell = cell(size(show_reo_brain_name,1),1);
for k = 1:size(group_explain_cell,1)
    selidx = strcmp(show_reo_brain_name{k,1},reo_brain_name);
    sel_exp = pca_cell(selidx,4);
    group_explain_cell{k,1} = cell2mat(cellfun(...
        @(x) x(1:sel_exp_len)',sel_exp,...
        'UniformOutput',false));
end


exp_90_95_cell = cell(size(group_explain_cell,1),2);
for k = 1:size(group_explain_cell,1)
    tempexp = group_explain_cell{k};
    expidx_90 = tempexp>90;
    expidx_95 = tempexp>95;

    exp_num_90 = zeros(size(expidx_90,1),1);
    exp_num_95 = zeros(size(expidx_95,1),1);
    for m = 1:size(expidx_90,1)
        ttexp = expidx_90(m,:);
        exp_num_90(m,1) = find(ttexp==1, 1);
        ttexp = expidx_95(m,:);
        exp_num_95(m,1) = find(ttexp==1, 1);
    end

    exp_90_95_cell{k,1} = exp_num_90;
    exp_90_95_cell{k,2} = exp_num_95;
end
%% show explained, show
start_x = 0.52;
start_y = 0.48;

box_x = 0.12;
box_y = 0.1;

error_bar_width = 6;

alpha_line = 0.2;

neu_cmap = cbrewer2('Paired',12);

in_c = neu_cmap(5,:);
de_c = neu_cmap(1,:);
no_c = neu_cmap(3,:);

brain_c = [...
    de_c;...
    in_c;...
    no_c];

subplot('Position',[start_x,start_y,box_x,box_y])

temph_cell = cell(size(group_explain_cell,1),1);

for k = 1:size(group_explain_cell,1)
    tempexp = group_explain_cell{k};
    mean_exp = mean(tempexp);
    std_exp = std(tempexp)./sqrt(size(tempexp,1));
    tempe = errorbar(1:length(mean_exp),mean_exp,std_exp,...
        'CapSize',0,'LineWidth',error_bar_width,...
        'Color',brain_c(k,:));
    set([tempe.Bar, tempe.Line], ...
        'ColorType', 'truecoloralpha', ...
        'ColorData', [tempe.Line.ColorData(1:3); ...
        255*alpha_line])
    hold on
    temph_cell{k} = plot(mean(tempexp),'Color',brain_c(k,:),...
        'LineWidth',1.5);
    hold on
    % for m = 1:size(tempexp,1)
    %     plot(tempexp(m,:),'Color',brain_c(k,:))
    %     hold on
    % end
end
plot([0,100],[90,90],'-k')
hold on
plot([0,100],[95,95],'-k')
hold off

axis([0,40,85,100])

box off

legend([temph_cell{1},temph_cell{2},temph_cell{3}],...
    {'S1','dmPFC','M1'},'box','off',...
    'Location','northwest')

ylabel('Variance explained (%)')
xlabel('Principal components')

set(gca,'TickDir','out')

set(gca,'FontSize',6)

%% show quantification, components to 90% and 95%
start_x = 0.52;
start_y = 0.36;

box_x = 0.12;
box_y = 0.09;

show_cell = {...
    exp_90_95_cell{1,1},exp_90_95_cell{2,1},exp_90_95_cell{3,1},...
    exp_90_95_cell{1,2},exp_90_95_cell{2,2},exp_90_95_cell{3,2},...
    };

mean_mat = cell2mat(cellfun(@(x) mean(x),...
    show_cell,'UniformOutput',false));

std_mat = cell2mat(cellfun(@(x) std(x)./sqrt(length(x)),...
    show_cell,'UniformOutput',false));

xlist = [1,2,3,5,6,7];

show_xlist = [2,6];

show_c = [...
    brain_c(1,:);brain_c(2,:);brain_c(3,:);...
    brain_c(1,:);brain_c(2,:);brain_c(3,:);...
    ];

show_star = {...
    [xlist(1),xlist(2)],[40,40],'**';...
    [xlist(4),xlist(5)],[45,45],'**';...
    [xlist(4),xlist(6)],[55,55],'*';...
    };

subplot('Position',[start_x,start_y,box_x,box_y])

for k = 1:size(mean_mat,2)    
    bar(xlist(k),mean_mat(k),bar_w,...
        'FaceColor',show_c(k,:))
    hold on
    errorbar(xlist(k),mean_mat(k),std_mat(k),...
        'Color','k','CapSize',cap_size)
    hold on
    
    tempy = show_cell{k};
    plot(x_bias+xlist(k)*ones(size(tempy)),tempy,...
        'o','MarkerSize',2,...
        'MarkerEdgeColor','k','MarkerFaceColor','w',...
        'LineWidth',0.25)
    hold on
end

% show star
for k = 1:size(show_star,1)
    plot(show_star{k,1},show_star{k,2},'-k')
    hold on
    text(mean(show_star{k,1}),show_star{k,2}(1)+2,...
        show_star{k,3},...
        'HorizontalAlignment','center')
end

hold off

box off

set(gca,'TickDir','out')
set(gca,'XTick',show_xlist)
set(gca,'YTick',[0,10,20,30,40,50,60])

axis([0.3,7.7,0,60])

set(gca,'XTickLabel',{'90%','95%'})
xlabel('Variance explained')
ylabel('Principal components')

set(gca,'FontSize',6)

%% show components
start_x = 0.67;
start_y = 0.47;

box_x = 0.1;
box_y = 0.1;

inter_x = 0.01;
inter_y = 0.02;

count = 1;

for m = 1:2
    for n = 1:3
        temph = subplot('Position',[...
            start_x+(n-1)*(box_x+inter_x),...
            start_y-(m-1)*(box_y+inter_y),...
            box_x,box_y]);

        sel_pc_idx = count;

        pc_mat = zeros(size(pca_cell,1),pad_len);

        start_list = zeros(size(pc_mat,1),2);
        end_list = zeros(size(pc_mat,1),2);
        
        for k = 1:size(pca_cell,1)
            temppc = pca_cell{k,1}(:,sel_pc_idx);
            pc_mat(k,1:length(temppc)) = mat2gray(temppc);
            start_list(k,:) = [baseline_far_frame,k];
            end_list(k,:) = [length(temppc)-after_far_frame,k];
        end
        
        len_idx = cell2mat(cellfun(@(x) size(x,1),...
            pca_cell(:,1),'UniformOutput',false));
        
        [~,sort_idx] = sort(len_idx,'descend');
        
        sort_pc_mat = pc_mat(sort_idx,:);
        start_list = start_list(sort_idx,:);
        end_list = end_list(sort_idx,:);
        end_list(:,2) = 1:size(end_list,1);
        
        count = count+1;

        imagesc(sort_pc_mat)


        hold on
        plot(start_list(:,1),start_list(:,2),'-k')
        hold on
        plot(end_list(:,1),end_list(:,2),'-k')
        hold off

        title(['PC ',num2str(sel_pc_idx)])

        set(gca,'FontSize',6)
        set(gca,'TickDir','out')

        set(gca,'XTick',x_tick)

        if m == 1
            set(gca,'XTickLabel',[])
        else
            set(gca,'XTickLabel',x_tick_label)
            set(gca,'XTickLabelRotation',0)
            xlabel('Time (s)')
        end
        
        set(gca,'YTick',[1,98])
        if n == 1
            ylabel('Neural PC')
        else
            set(gca,'YTickLabel',[])
        end

        colormap(temph,[1,1,1;cmap_neu])

        box off
    end
end

% colorbar
cbar_box_x = 0.05;
cbar_box_y = 0.006;

cbar_inter_y = 0.012;

temph = subplot('Position',[...
    start_x+2*(box_x+inter_x)-cbar_box_x+box_x,...
    start_y+box_y+cbar_box_y+cbar_inter_y,...
    cbar_box_x,cbar_box_y]);
imagesc(flipud((1:256)))
colormap(temph,cmap_neu)
set(gca,'XTick',[],'YTick',[])

text(-1,0.5,'0','FontSize',6,'VerticalAlignment','middle')
text(260,0.5,'1','FontSize',6,'VerticalAlignment','middle')

title('Coefficient')
set(gca,'FontSize',6)
%% compare changes of PC in far-close-far
sep_pca_cell = cell(size(pca_cell,1),3);

first_num = 5;%only calculate first pc to acc the process

for k = 1:size(sep_pca_cell,1)
    normpc = pca_cell{k,5}';

    before_pc = normpc(1:first_num,1:baseline_far_frame);
    during_pc = normpc(1:first_num,(baseline_far_frame+1):...
        (size(normpc,2)-after_far_frame));
    after_pc = normpc(1:first_num,...
        (size(normpc,2)-after_far_frame+1):end);

    mean_before_pc = mean(before_pc,2);
    mean_during_pc = mean(during_pc,2);
    mean_after_pc = mean(after_pc,2);
    
    sep_pca_cell{k,1} = mean_before_pc';
    sep_pca_cell{k,2} = mean_during_pc';
    sep_pca_cell{k,3} = mean_after_pc';
end

pca_before_mat = cell2mat(sep_pca_cell(:,1));
pca_during_mat = cell2mat(sep_pca_cell(:,2));
pca_after_mat = cell2mat(sep_pca_cell(:,3));

%% show differences of pcs of different brain area
start_x = 0.03;
start_y = 0.25;

box_x = 0.27;
box_y = 0.06;

inter_y = 0.01;

x_list = 1:(4*size(pca_before_mat,2));

x_list(4:4:end) = [];

x_ticklist = x_list(2:3:end);

bar_w = 0.6;
cap_size = 1;

before_c = mean(time_cmap(1:85,:));
during_c = mean(time_cmap(86:172,:));
after_c = mean(time_cmap(173:end,:));

show_cmap = [];
for k = 1:size(pca_before_mat,2)
    show_cmap = [show_cmap;...
        before_c;during_c;after_c];
end

show_star_list = {...
    0.01,0.05,'*';...
    0.001,0.01,'**';...
    0.0001,0.001,'***';...
    0,0.0001,'****';...
    };

show_star_y_1 = 1.05;
show_star_y_2 = 1.2;

for k = 1:size(brain_name,1)

    selidx = strcmp(brain_name{k},reo_brain_name);

    sel_before = pca_before_mat(selidx,:);
    sel_during = pca_during_mat(selidx,:);
    sel_after = pca_after_mat(selidx,:);

    p_mat = zeros(size(sel_before,2),2);

    for m = 1:size(sel_before,2)
        tempbefore = sel_before(:,m);
        tempduring = sel_during(:,m);
        tempafter = sel_after(:,m);

        [p_before,h_before] = ranksum(tempbefore,tempduring);
        [p_after,h_after] = ranksum(tempafter,tempduring);

        p_mat(m,1) = p_before;
        p_mat(m,2) = p_after;
    end

    show_mat = zeros(size(sel_before,1),3*size(sel_before,2));
    
    show_mat(:,1:3:end) = sel_before;
    show_mat(:,2:3:end) = sel_during;
    show_mat(:,3:3:end) = sel_after;
    
    mean_mat = mean(show_mat);
    std_mat = std(show_mat)./sqrt(size(show_mat,1));

    subplot('Position',[...
        start_x,start_y-(k-1)*(box_y+inter_y),...
        box_x,box_y])

    tempbar_h = cell(length(x_list),1);

    for m = 1:length(x_list)
        tempbar_h{m} = bar(x_list(m),mean_mat(m),bar_w,...
            'FaceColor',show_cmap(m,:));
        hold on
        plot(x_bias+x_list(m)*ones(1,size(show_mat,1)),...
            show_mat(:,m),'o',...
            'LineWidth',0.25,'MarkerSize',2,...
            'MarkerFaceColor','w',...
            'MarkerEdgeColor','k')
        hold on
    end
    
    for m = 1:size(p_mat,1)
        % show star
        if p_mat(m,1) < 0.05
            plot([x_list(3*(m-1)+1),x_list(3*(m-1)+2)],...
                [show_star_y_1,show_star_y_1],...
                '-k')
            hold on
            for n = 1:size(show_star_list,1)
                if p_mat(m,1)>=show_star_list{n,1} && ...
                        p_mat(m,1)<show_star_list{n,2}
                    show_star_star = show_star_list{n,3};
                end
            end
            text(sum([x_list(3*(m-1)+1),x_list(3*(m-1)+2)])/2,...
                show_star_y_1,show_star_star,...
                'HorizontalAlignment','center',...
                'VerticalAlignment','bottom')
            hold on
        end

        if p_mat(m,2) < 0.05
            plot([x_list(3*(m-1)+2),x_list(3*(m-1)+3)],...
                [show_star_y_2,show_star_y_2],...
                '-k')
            hold on
            for n = 1:size(show_star_list,1)
                if p_mat(m,2)>=show_star_list{n,1} && ...
                        p_mat(m,2)<show_star_list{n,2}
                    show_star_star = show_star_list{n,3};
                end
            end
            text(sum([x_list(3*(m-1)+2),x_list(3*(m-1)+3)])/2,...
                show_star_y_2,show_star_star,...
                'HorizontalAlignment','center',...
                'VerticalAlignment','bottom')
            hold on
        end
    end

    hold on
    errorbar(x_list,mean_mat,std_mat,...
        'LineStyle','none',...
        'Color','k','CapSize',cap_size)
    hold off

    axis([0.3,19.7,0,1.3])

    box off

    ylabel(show_brain_name{k})

    set(gca,'TickDir','out')
    set(gca,'FontSize',6)
    set(gca,'XTick',x_ticklist)
    set(gca,'YTick',[0,1])

    if k == 1
        legend([tempbar_h{1},tempbar_h{2},tempbar_h{3}],...
            'Before','During','After',...
            'box','off')
    end

    if k == 3
        set(gca,'XTickLabel', ...
            {...
            'PC 1',...
            'PC 2',...
            'PC 3',...
            'PC 4',...
            'PC 5',...
            'PC 6',...
            'PC 7',...
            'PC 8',...
            'PC 9',...
            'PC 10',...
            })
    else
        set(gca,'XTickLabel',[])
    end
end

%% mapping using different dimensions
pca_map_cell = cell(size(pca_cell,1),6);
% sel_dim_num = 50;
for k = 1:size(pca_cell,1)
    temppca = pca_cell{k,1}(1:map_len,:);

    tempselfpose = reo_beh_cell{k,1}(1:map_len,:);
    temppartnerpose = reo_beh_cell{k,4}(1:map_len,:);

    tempselfmov = cell2mat(reo_beh_cell{k,2}(1:map_len,2));
    temppartnermov = cell2mat(reo_beh_cell{k,5}(1:map_len,2));

    tempselfseq = reo_beh_cell{k,3}(1:map_len,:);
    temppartnerseq = reo_beh_cell{k,6}(1:map_len,:);

    % map pose
    self_pose_rlist = ...
        zeros(size(tempselfpose,2),1);
    self_pose_weight = cell(size(tempselfpose,2),1);

    for a = 1:size(tempselfpose,2)
        %
        ttpose = tempselfpose(:,a);
        mdl = fitglm(temppca,ttpose);
        ypred = predict(mdl,temppca);
        [r,rp] = corr(ttpose,ypred);
        self_pose_rlist(a,1) = r;
        self_pose_weight{a,1} = mdl.Coefficients.Estimate;
    end

    partner_pose_rlist = ...
        zeros(size(temppartnerpose,2),1);
    partner_pose_weight = cell(size(temppartnerpose,2),1);
    
    for a = 1:size(temppartnerpose,2)
        %
        ttpose = temppartnerpose(:,a);
        mdl = fitglm(temppca,ttpose);
        ypred = predict(mdl,temppca);
        [r,rp] = corr(ttpose,ypred);
        partner_pose_rlist(a,1) = r;
        partner_pose_weight{a,1} = mdl.Coefficients.Estimate;
    end

    % map mov
    mdl = fitcdiscr(temppca,tempselfmov);
    ypred = predict(mdl,temppca);
    prec = ypred==tempselfmov;

    self_mov_weight = mdl.Coeffs;
    
    self_mov_prec = -1*ones(size(unique_mov));
    for a = 1:size(self_mov_prec,1)
        selprec = prec(...
            unique_mov(a)==tempselfmov,:);
        if size(selprec,1) > 0
            self_mov_prec(a) = mean(selprec);
        end
    end
    self_mov_prec(self_mov_prec==-1) = [];

    mdl = fitcdiscr(temppca,temppartnermov);
    ypred = predict(mdl,temppca);
    prec = ypred==temppartnermov;

    partner_mov_weight = mdl.Coeffs;
    
    partner_mov_prec = -1*ones(size(unique_mov));
    for a = 1:size(partner_mov_prec,1)
        selprec = prec(...
            unique_mov(a)==temppartnermov,:);
        if size(selprec,1) > 0
            partner_mov_prec(a) = mean(selprec);
        end
    end
    partner_mov_prec(partner_mov_prec==-1) = [];

    % map seq
    mdl = fitcdiscr(temppca,tempselfseq);
    ypred = predict(mdl,temppca);
    prec = ypred==tempselfseq;

    self_seq_weight = mdl.Coeffs;

    self_seq_prec = -1*ones(size(unique_seq));
    for a = 1:size(self_seq_prec,1)
        selprec = prec(...
            unique_seq(a)==tempselfseq,:);
        if size(selprec,1) > 0
            self_seq_prec(a) = mean(selprec);
        end
    end
    self_seq_prec(self_seq_prec==-1) = [];

    mdl = fitcdiscr(temppca,temppartnerseq);
    ypred = predict(mdl,temppca);
    prec = ypred==temppartnerseq;

    partner_seq_weight = mdl.Coeffs;

    partner_seq_prec = -1*ones(size(unique_seq));
    for a = 1:size(partner_seq_prec,1)
        selprec = prec(...
            unique_seq(a)==temppartnerseq,:);
        if size(selprec,1) > 0
            partner_seq_prec(a) = mean(selprec);
        end
    end
    partner_seq_prec(partner_seq_prec==-1) = [];

    pca_map_cell{k,1} = self_pose_weight;
    pca_map_cell{k,2} = partner_pose_weight;
    pca_map_cell{k,3} = self_mov_weight;
    pca_map_cell{k,4} = partner_mov_weight;
    pca_map_cell{k,5} = self_seq_weight;
    pca_map_cell{k,6} = partner_seq_weight;

    disp(k)
end

%% process to abs weight
pca_abs_weight_cell = cell(size(pca_map_cell,1),6);

for k = 1:size(pca_abs_weight_cell,1)
    % pose
    for m = 1:2
        tempweight = pca_map_cell{k,m};
        norm_cell = cellfun(@(x) ...
            abs(x(2:end))./sum(abs(x(2:end))),...
            tempweight,'UniformOutput',false);

        norm_list = cell2mat(norm_cell');
        mean_norm_list = mean(norm_list,2)';

        pca_abs_weight_cell{k,m} = mean_norm_list;
    end

    % mov and seq
    for m = 3:6
        tempweight = pca_map_cell{k,m};
        if size(tempweight,1) == 1
            pca_abs_weight_cell{k,m} = -1;
        else
            weightmat = [];
            for p = 1:size(tempweight,1)
                for q = 1:size(tempweight,2)
                    if p ~= q
                        weightmat = [weightmat,...
                            abs(...
                            tempweight(p,q).Linear)./...
                            sum(abs(...
                            tempweight(p,q).Linear))];
                    end
                end
            end
            mean_weightmat = mean(weightmat,2)';
            pca_abs_weight_cell{k,m} = mean_weightmat;
        end
    end

    disp(k)
end

%% show 
wash_idx = sum(cell2mat(cellfun(@(x) size(x,2)==1,...
    pca_abs_weight_cell,'UniformOutput',false)),2)==0;

wash_pca_abs_weight_cell = pca_abs_weight_cell(wash_idx,:);

wash_reo_brain_name = reo_brain_name(wash_idx,:);

cut_thres = 100;
weight_cut_cell = cellfun(@(x) ...
    [x(1:cut_thres),sum(x((1+cut_thres):end))],...
    wash_pca_abs_weight_cell,'UniformOutput',false);

first_pc_num = 5;
% first 3
self_s1_pose_first3 = sum(cell2mat(cellfun(@(x) x(1:first_pc_num),...
    weight_cut_cell(strcmp(wash_reo_brain_name,'tpmss'),1),...
    'UniformOutput',false)),2);
self_s1_mov_first3 = sum(cell2mat(cellfun(@(x) x(1:first_pc_num),...
    weight_cut_cell(strcmp(wash_reo_brain_name,'tpmss'),3),...
    'UniformOutput',false)),2);
self_s1_seq_first3 = sum(cell2mat(cellfun(@(x) x(1:first_pc_num),...
    weight_cut_cell(strcmp(wash_reo_brain_name,'tpmss'),5),...
    'UniformOutput',false)),2);

self_pfc_pose_first3 = sum(cell2mat(cellfun(@(x) x(1:first_pc_num),...
    weight_cut_cell(strcmp(wash_reo_brain_name,'tpmpfc'),1),...
    'UniformOutput',false)),2);
self_pfc_mov_first3 = sum(cell2mat(cellfun(@(x) x(1:first_pc_num),...
    weight_cut_cell(strcmp(wash_reo_brain_name,'tpmpfc'),3),...
    'UniformOutput',false)),2);
self_pfc_seq_first3 = sum(cell2mat(cellfun(@(x) x(1:first_pc_num),...
    weight_cut_cell(strcmp(wash_reo_brain_name,'tpmpfc'),5),...
    'UniformOutput',false)),2);

self_m1_pose_first3 = sum(cell2mat(cellfun(@(x) x(1:first_pc_num),...
    weight_cut_cell(strcmp(wash_reo_brain_name,'tpmm'),1),...
    'UniformOutput',false)),2);
self_m1_mov_first3 = sum(cell2mat(cellfun(@(x) x(1:first_pc_num),...
    weight_cut_cell(strcmp(wash_reo_brain_name,'tpmm'),3),...
    'UniformOutput',false)),2);
self_m1_seq_first3 = sum(cell2mat(cellfun(@(x) x(1:first_pc_num),...
    weight_cut_cell(strcmp(wash_reo_brain_name,'tpmm'),5),...
    'UniformOutput',false)),2);

partner_s1_pose_first3 = sum(cell2mat(cellfun(@(x) x(1:first_pc_num),...
    weight_cut_cell(strcmp(wash_reo_brain_name,'tpmss'),2),...
    'UniformOutput',false)),2);
partner_s1_mov_first3 = sum(cell2mat(cellfun(@(x) x(1:first_pc_num),...
    weight_cut_cell(strcmp(wash_reo_brain_name,'tpmss'),4),...
    'UniformOutput',false)),2);
partner_s1_seq_first3 = sum(cell2mat(cellfun(@(x) x(1:first_pc_num),...
    weight_cut_cell(strcmp(wash_reo_brain_name,'tpmss'),6),...
    'UniformOutput',false)),2);

partner_pfc_pose_first3 = sum(cell2mat(cellfun(@(x) x(1:first_pc_num),...
    weight_cut_cell(strcmp(wash_reo_brain_name,'tpmpfc'),2),...
    'UniformOutput',false)),2);
partner_pfc_mov_first3 = sum(cell2mat(cellfun(@(x) x(1:first_pc_num),...
    weight_cut_cell(strcmp(wash_reo_brain_name,'tpmpfc'),4),...
    'UniformOutput',false)),2);
partner_pfc_seq_first3 = sum(cell2mat(cellfun(@(x) x(1:first_pc_num),...
    weight_cut_cell(strcmp(wash_reo_brain_name,'tpmpfc'),6),...
    'UniformOutput',false)),2);

partner_m1_pose_first3 = sum(cell2mat(cellfun(@(x) x(1:first_pc_num),...
    weight_cut_cell(strcmp(wash_reo_brain_name,'tpmm'),2),...
    'UniformOutput',false)),2);
partner_m1_mov_first3 = sum(cell2mat(cellfun(@(x) x(1:first_pc_num),...
    weight_cut_cell(strcmp(wash_reo_brain_name,'tpmm'),4),...
    'UniformOutput',false)),2);
partner_m1_seq_first3 = sum(cell2mat(cellfun(@(x) x(1:first_pc_num),...
    weight_cut_cell(strcmp(wash_reo_brain_name,'tpmm'),6),...
    'UniformOutput',false)),2);

% after 100
self_s1_pose_after100 = cell2mat(cellfun(@(x) x(end),...
    weight_cut_cell(strcmp(wash_reo_brain_name,'tpmss'),1),...
    'UniformOutput',false));
self_s1_mov_after100 = cell2mat(cellfun(@(x) x(end),...
    weight_cut_cell(strcmp(wash_reo_brain_name,'tpmss'),3),...
    'UniformOutput',false));
self_s1_seq_after100 = cell2mat(cellfun(@(x) x(end),...
    weight_cut_cell(strcmp(wash_reo_brain_name,'tpmss'),5),...
    'UniformOutput',false));

self_pfc_pose_after100 = cell2mat(cellfun(@(x) x(end),...
    weight_cut_cell(strcmp(wash_reo_brain_name,'tpmpfc'),1),...
    'UniformOutput',false));
self_pfc_mov_after100 = cell2mat(cellfun(@(x) x(end),...
    weight_cut_cell(strcmp(wash_reo_brain_name,'tpmpfc'),3),...
    'UniformOutput',false));
self_pfc_seq_after100 = cell2mat(cellfun(@(x) x(end),...
    weight_cut_cell(strcmp(wash_reo_brain_name,'tpmpfc'),5),...
    'UniformOutput',false));

self_m1_pose_after100 = cell2mat(cellfun(@(x) x(end),...
    weight_cut_cell(strcmp(wash_reo_brain_name,'tpmm'),1),...
    'UniformOutput',false));
self_m1_mov_after100 = cell2mat(cellfun(@(x) x(end),...
    weight_cut_cell(strcmp(wash_reo_brain_name,'tpmm'),3),...
    'UniformOutput',false));
self_m1_seq_after100 = cell2mat(cellfun(@(x) x(end),...
    weight_cut_cell(strcmp(wash_reo_brain_name,'tpmm'),5),...
    'UniformOutput',false));

partner_s1_pose_after100 = cell2mat(cellfun(@(x) x(end),...
    weight_cut_cell(strcmp(wash_reo_brain_name,'tpmss'),2),...
    'UniformOutput',false));
partner_s1_mov_after100 = cell2mat(cellfun(@(x) x(end),...
    weight_cut_cell(strcmp(wash_reo_brain_name,'tpmss'),4),...
    'UniformOutput',false));
partner_s1_seq_after100 = cell2mat(cellfun(@(x) x(end),...
    weight_cut_cell(strcmp(wash_reo_brain_name,'tpmss'),6),...
    'UniformOutput',false));

partner_pfc_pose_after100 = cell2mat(cellfun(@(x) x(end),...
    weight_cut_cell(strcmp(wash_reo_brain_name,'tpmpfc'),2),...
    'UniformOutput',false));
partner_pfc_mov_after100 = cell2mat(cellfun(@(x) x(end),...
    weight_cut_cell(strcmp(wash_reo_brain_name,'tpmpfc'),4),...
    'UniformOutput',false));
partner_pfc_seq_after100 = cell2mat(cellfun(@(x) x(end),...
    weight_cut_cell(strcmp(wash_reo_brain_name,'tpmpfc'),6),...
    'UniformOutput',false));

partner_m1_pose_after100 = cell2mat(cellfun(@(x) x(end),...
    weight_cut_cell(strcmp(wash_reo_brain_name,'tpmm'),2),...
    'UniformOutput',false));
partner_m1_mov_after100 = cell2mat(cellfun(@(x) x(end),...
    weight_cut_cell(strcmp(wash_reo_brain_name,'tpmm'),4),...
    'UniformOutput',false));
partner_m1_seq_after100 = cell2mat(cellfun(@(x) x(end),...
    weight_cut_cell(strcmp(wash_reo_brain_name,'tpmm'),6),...
    'UniformOutput',false));

%% show weights by sorting
show_first3 = {...
    self_s1_pose_first3,'S1-Self-Pose';...
    self_s1_mov_first3,'S1-Self-Movement';...
    self_s1_seq_first3,'S1-Self-Sequence';...
    self_pfc_pose_first3,'dmPFC-Self-Pose';...
    self_pfc_mov_first3,'dmPFC-Self-Movement';...
    self_pfc_seq_first3,'dmPFC-Self-Sequence';...
    self_m1_pose_first3,'M1-Self-Pose';...
    self_m1_mov_first3,'M1-Self-Movement';...
    self_m1_seq_first3,'M1-Self-Sequence';...
    partner_s1_pose_first3,'S1-Partner-Pose';...
    partner_s1_mov_first3,'S1-Partner-Movement';...
    partner_s1_seq_first3,'S1-Partner-Sequence';...
    partner_pfc_pose_first3,'dmPFC-Partner-Pose';...
    partner_pfc_mov_first3,'dmPFC-Partner-Movement';...
    partner_pfc_seq_first3,'dmPFC-Partner-Sequence';...
    partner_m1_pose_first3,'M1-Partner-Pose';...
    partner_m1_mov_first3,'M1-Partner-Movement';...
    partner_m1_seq_first3,'M1-Partner-Sequence';...
    };

mean_show_first3 = cell2mat(cellfun(@(x) mean(x),...
    show_first3(:,1),'UniformOutput',false));

[sort_mean_show_first3,sort_idx] = sort(mean_show_first3,...
    'descend');

sort_show_first3 = show_first3(sort_idx,:);



show_after100 = {...
    self_s1_pose_after100,'S1-Self-Pose';...
    self_s1_mov_after100,'S1-Self-Movement';...
    self_s1_seq_after100,'S1-Self-Sequence';...
    self_pfc_pose_after100,'dmPFC-Self-Pose';...
    self_pfc_mov_after100,'dmPFC-Self-Movement';...
    self_pfc_seq_after100,'dmPFC-Self-Sequence';...
    self_m1_pose_after100,'M1-Self-Pose';...
    self_m1_mov_after100,'M1-Self-Movement';...
    self_m1_seq_after100,'M1-Self-Sequence';...
    partner_s1_pose_after100,'S1-Partner-Pose';...
    partner_s1_mov_after100,'S1-Partner-Movement';...
    partner_s1_seq_after100,'S1-Partner-Sequence';...
    partner_pfc_pose_after100,'dmPFC-Partner-Pose';...
    partner_pfc_mov_after100,'dmPFC-Partner-Movement';...
    partner_pfc_seq_after100,'dmPFC-Partner-Sequence';...
    partner_m1_pose_after100,'M1-Partner-Pose';...
    partner_m1_mov_after100,'M1-Partner-Movement';...
    partner_m1_seq_after100,'M1-Partner-Sequence';...
    };

mean_show_after100 = cell2mat(cellfun(@(x) mean(x),...
    show_after100(:,1),'UniformOutput',false));

[sort_mean_show_after100,sort_idx] = sort(mean_show_after100,...
    'descend');

sort_show_after100 = show_after100(sort_idx,:);


%% show
start_x = 0.35;
start_y = 0.2;

box_x = 0.3;
box_y = 0.1;

inter_x = 0.04;

bar_w = 0.6;

cap_size = 2;

x_bias = 0.3;

max_y = 0.6;

% first 3
sel_show = sort_show_first3;
x_list = 1:size(sel_show,1);
mean_show = cell2mat(cellfun(@(x) mean(x),...
    sel_show(:,1),'UniformOutput',false));
std_show = cell2mat(cellfun(@(x) std(x)./sqrt(length(x)),...
    sel_show(:,1),'UniformOutput',false));

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
    'ns';...
    'ns';...
    'ns';...
    '*';...
    '*';...
    '**';...
    '***';...
    '****';...
    '****';...
    };

subplot('Position',[start_x,start_y,box_x,box_y])
for k = 1:size(sel_show,1)
    tempname = sel_show{k,2};
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
        text(x_list(k),0.6,star_first_3{k},...
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
set(gca,'XTickLabel',sel_show(:,2))
set(gca,'FontSize',6)
set(gca,'XTickLabelRotation',60)
ylabel(['Weights of first ',num2str(first_pc_num), ' PCs'])

% after 100
sel_show = sort_show_after100;
x_list = 1:size(sel_show,1);
mean_show = cell2mat(cellfun(@(x) mean(x),...
    sel_show(:,1),'UniformOutput',false));

star_after_100 = {...
    'ns';...%self
    'ns';...
    'ns';...
    'ns';...
    'ns';...
    'ns';...
    '*';...
    '*';...
    '**';...
    '**';...
    '**';...
    '**';...
    '****';...
    '****';...
    '****';...
    '****';...
    '****';...
    '****';...
};

subplot('Position',[start_x+inter_x+box_x,...
    start_y,box_x,box_y])
temph_bar = cell(size(sel_show,1),1);
for k = 1:size(sel_show,1)
    tempname = sel_show{k,2};
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
    temph_bar{k,1} = bar(x_list(k),mean_show(k),bar_w,...
        'FaceColor',bar_c);
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

    if ~strcmp(star_after_100{k},'ns')
        text(x_list(k),0.6,star_after_100{k},...
            'Rotation',90,...
            'VerticalAlignment','top')
    end
end
plot([0,20],[mean(sel_show{1,1}),mean(sel_show{1,1})],...
        '--k','LineWidth',0.25)
hold off

box off

axis([0.3,18.7,0,max_y])

legend([temph_bar{3},temph_bar{end},temph_bar{1}],...
    {'S1','dmPFC','M1'},'box','off')

set(gca,'TickDir','Out')
set(gca,'XTick',x_list)
set(gca,'XTickLabel',sel_show(:,2))
set(gca,'FontSize',6)
set(gca,'XTickLabelRotation',60)
ylabel('Weights of after 100 PCs')



