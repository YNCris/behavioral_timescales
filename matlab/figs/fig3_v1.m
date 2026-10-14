%{
    远近远（社交开始到结束），
    三层，三个脑区怎么处理，比较前后，同伴行为
    看能不能引出neural token的概念
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

box_x = 0.14;
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

%
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
    save([beh_neu_path,'\',fcf_mouse_cell{k,1},...
        '-neu_fcf_cas.mat'],'sel_fcf')
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
%% show trajectories according to brain area
start_x = 0.02;
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
%% calculate曲线曲率
cur_cell = cell(size(align_brain_cell));
for k = 1:size(cur_cell,1)
    tempcell = align_brain_cell{k,1};
    tempcur = cell(size(tempcell,1),1);
    for m = 1:size(tempcell,1)
        h = 1;
        r=tempcell{m}';                         %表示函数
        for n = 1:3
            r(n,:) = smooth(r(n,:),30);
        end
        r1=gradient(r)./h;            %求一阶导
        r2=gradient(r1)./h;           %二阶导
        r3=gradient(r2)./h;           %三阶导
        r1=r1';r2=r2';r3=r3';
        %% 曲率、挠率
        v=cross(r1,r2,2);              %一阶导与二阶导做外积
        e=dot(r3,v,2);                   %（r',r'',r'''）混合积
        c=zeros(length(r),1);        %定义矩阵c储存一阶导二阶导叉乘模长，d储存一阶导模长
        d=c;
        for i=1:length(r)
            c(i)=norm(v(i,:));           %一阶导二阶导外积的模长
            d(i)=norm(r1(i,:));          %一阶导模长
        end
        kk=c./(d.^3);                     %曲率
        plot(kk)
        axis([0,600,0,10000])
        pause
        tempcur{m,1} = kk;
    end
    cur_cell{k,1} = tempcur;
end
%% statistic start and end curve
bias_range = 45;%2s
start_end_cur = cell(size(cur_cell,1),2);
for k = 1:size(cur_cell,1)
    tempcur = cur_cell{k,1};
    tempcell = cell(size(tempcur,1),2);
    for m = 1:size(tempcur,1)
        ttcur = tempcur{m};
        tempstart_cur = smooth(medfilt1(ttcur(...
            (baseline_far_frame-bias_range):...
            (baseline_far_frame+bias_range)),3),5);
        tempend_cur = smooth(medfilt1(ttcur(...
            (end-after_far_frame-bias_range):...
            (end-after_far_frame+bias_range)),3),5);
        tempcell{m,1} = tempstart_cur';
        tempcell{m,2} = tempend_cur';
    end
    start_end_cur{k,1} = cell2mat(tempcell(:,1));
    start_end_cur{k,2} = cell2mat(tempcell(:,2));
end
%% start cur
neu_cmap = cbrewer2('Paired',12);

in_c = neu_cmap(5,:);
de_c = neu_cmap(1,:);
no_c = neu_cmap(3,:);

brain_c = [...
    de_c;...
    in_c;...
    no_c];

dark_brain_cmap = cbrewer2('Set1',3);
dark_brain_c = [...
    dark_brain_cmap(2,:);...
    dark_brain_cmap(1,:);...
    dark_brain_cmap(3,:);...
    ];

x_list = 1:(2*bias_range+1);

show_x_tick = [1,46,91];
show_x_ticklabel = [-1.5,0,1.5];

cap_size = 0;
alpha_line = 0.2;

big_inter_x = 0.01;
shr_box_rate = 2.5;

subplot('Position',[...
        start_x+(4-1)*(box_x+inter_x+big_inter_x),...
        start_y,box_x/shr_box_rate,box_y])
for k = 1:size(start_end_cur,1)
    tempstart = start_end_cur{k,1};
    mean_start = mean(tempstart);
    std_start = std(tempstart)./...
        sqrt(size(tempstart,1));
    tempe = errorbar(x_list,mean_start,std_start,...
        'CapSize',cap_size,...
        'Color',brain_c(k,:),...
        'LineWidth',1);
    set([tempe.Bar, tempe.Line], ...
        'ColorType', 'truecoloralpha', ...
        'ColorData', [tempe.Line.ColorData(1:3); ...
        255*alpha_line])
    hold on
    plot(x_list,mean_start,...
        'Color',brain_c(k,:),...
        'LineWidth',1.5)
    hold on
    plot([bias_range+1,bias_range+1],...
        [100,700],'--k')
    hold on  
end
hold off
axis([1,2*bias_range+1,100,700])
box off
set(gca,'TickDir','out')
set(gca,'XTick',show_x_tick)
set(gca,'XTickLabel',show_x_ticklabel)
set(gca,'FontSize',6)
ylabel('Curvature')
xlabel('Far to close time (s)')
% end cur
subplot('Position',[...
        start_x+(4-1)*(box_x+inter_x+big_inter_x)+...
        box_x/shr_box_rate+0.02,...
        start_y,box_x/shr_box_rate,box_y])
for k = 1:size(start_end_cur,1)
    tempstart = start_end_cur{k,2};
    mean_start = mean(tempstart);
    std_start = std(tempstart)./...
        sqrt(size(tempstart,1));
    tempe = errorbar(x_list,mean_start,std_start,...
        'CapSize',cap_size,...
        'Color',brain_c(k,:),...
        'LineWidth',1);
    set([tempe.Bar, tempe.Line], ...
        'ColorType', 'truecoloralpha', ...
        'ColorData', [tempe.Line.ColorData(1:3); ...
        255*alpha_line])
    hold on
    plot(x_list,mean_start,...
        'Color',brain_c(k,:),...
        'LineWidth',1.5)
    hold on
    plot([bias_range+1,bias_range+1],...
        [100,700],'--k')
    hold on   
end
hold off
axis([1,2*bias_range+1,100,700])
box off
set(gca,'TickDir','out')
set(gca,'XTick',show_x_tick)
set(gca,'XTickLabel',show_x_ticklabel)
set(gca,'YTickLabel',[])
set(gca,'FontSize',6)
xlabel('Close to far time (s)')
%% find max peak idx for statistics
start_end_maxidx = cell(size(start_end_cur));

for m = 1:size(start_end_maxidx,1)
    for n = 1:size(start_end_maxidx,2)
        tempcur = start_end_cur{m,n};
        tempmaxidx = zeros(size(tempcur,1),1);
        for k = 1:size(tempcur,1)
            ttcur = tempcur(k,:);
            [pks,locs] = findpeaks(ttcur);
            tempmaxidx(k,1) = locs(pks==max(pks));
        end
        start_end_maxidx{m,n} = tempmaxidx;
    end
end
%% find before peak idx for statistics
before_start_end_maxidx = cell(size(start_end_cur));

for m = 1:size(before_start_end_maxidx,1)
    for n = 1:size(before_start_end_maxidx,2)
        tempcur = start_end_cur{m,n};
        tempmaxidx = zeros(size(tempcur,1),1);
        for k = 1:size(tempcur,1)
            ttcur = tempcur(k,1:45);
            try
                [pks,locs] = findpeaks(ttcur);
                tempmaxidx(k,1) = locs(pks==max(pks));
            catch
            end
        end
        tempmaxidx(tempmaxidx==0) = [];
        before_start_end_maxidx{m,n} = tempmaxidx;
    end
end
% %% show umap 3d
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
%         plot3(score(:,1),score(:,2),score(:,3),'-k')
%         hold on
%         scatter3(score(:,1),score(:,2),score(:,3),...
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
% %% show umap 3d, align
% time_cmap = jet(256);%cbrewer2('Spectral',256);
% figure
% 
% for k = 1:size(fcf_mouse_cell,1)
%     tempembed = fcf_mouse_cell{k,6};
% 
%     for m = 1:size(tempembed,1)
%         score = tempembed{m,1};
%         show_cmap = mat2gray(...
%         imresize(time_cmap,[size(score,1),3]));
% 
%         subplot(3,5,k)
% 
%         plot3(score(:,1),score(:,2),score(:,3),'-k')
%         hold on
%         scatter3(score(:,1),score(:,2),score(:,3),...
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
% 
% %% show umap 3d, align brain
% time_cmap = jet(256);%cbrewer2('Spectral',256);
% figure
% 
% for k = 1:size(align_brain_cell,1)
%     tempembed = align_brain_cell{k,1};
% 
%     for m = 1:size(tempembed,1)
%         score = tempembed{m};
%         show_cmap = mat2gray(...
%         imresize(time_cmap,[size(score,1),3]));
% 
%         subplot(3,1,k)
% 
%         plot3(score(:,1),score(:,2),score(:,3),'-k')
%         hold on
%         scatter3(score(:,1),score(:,2),score(:,3),...
%             5*ones(size(score,1),1),show_cmap,'filled')
%         hold on
% 
% 
% 
%     end
%     hold off
%     title(brain_name{k,1})
%     disp(k)
% end
%% show brain area correlations
corr_cell = cell(size(align_beh_cell));

self_partner_name = {...
    'self';'partner'};

for m = 1:3
    tempneu = align_brain_cell{m,1};
    for n = 1:6
        %% load data
        tempbeh = align_beh_cell{m,n};
        %% calculate correlation
        %% pose
        if n == 1 || n == 4
            all_r_cell = cell(size(tempneu,1),1);
            for k = 1:size(tempneu,1)
                %
                temppose = tempbeh{k};
                rlist = zeros(size(temppose,2),1);
                for p = 1:size(temppose,2)
                    %
                    ttpose = temppose(:,p);
                    mdl = fitglm(tempneu{k},ttpose);
                    ypred = predict(mdl,tempneu{k});
                    [r,rp] = corr(ttpose,ypred);
                    rlist(p,1) = r;
                end
                all_r_cell{k,1} = rlist;
            end
        end
        %% mov
        if n == 2 || n == 5
            all_r_cell = cell(size(tempneu,1),1);
            for k = 1:size(tempneu,1)
                %
                tempmov = cell2mat(tempbeh{k,1}(:,2));
                train_neu = tempneu{k};
                mdl = fitcdiscr(train_neu,tempmov);
                ypred = predict(mdl,tempneu{k});
                prec = ypred==tempmov;
                
                unique_prec = -1*ones(size(unique_mov));
                for q = 1:size(unique_prec,1)
                    selprec = prec(...
                        unique_mov(q)==tempmov,:);
                    if size(selprec,1) > 0
                        unique_prec(q) = mean(selprec);
                    end
                end

                all_r_cell{k,1} = unique_prec;
            end
        end
        %% seq
        if n == 3 || n == 6
            all_r_cell = cell(size(tempneu,1),1);
            for k = 1:size(tempneu,1)
                %
                tempseq = tempbeh{k,1};
                train_neu = tempneu{k};
                mdl = fitcdiscr(train_neu,tempseq);
                ypred = predict(mdl,tempneu{k});
                prec = ypred==tempseq;

                unique_prec = -1*ones(size(unique_seq));
                for q = 1:size(unique_prec,1)
                    selprec = prec(...
                        unique_seq(q)==tempseq,:);
                    if size(selprec,1) > 0
                        unique_prec(q) = mean(selprec);
                    end
                end

                all_r_cell{k,1} = unique_prec;
            end
        end
        %% save
        corr_cell{m,n} = all_r_cell;
    end
    disp(m)
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
%% show mappings
start_x = 0.02;
start_y = 0.405;

box_x = 0.075;
box_y = box_x;

inter_x = 0.005;
inter_y = 0.005;

show_mat_cell = {...
    mean_self_map_pose,mean_self_map_mov,mean_self_map_seq,...
    mean_partner_map_pose,mean_partner_map_mov,mean_partner_map_seq};

show_raw_cell = {...
    mean_self_raw_pose,mean_self_raw_mov,mean_self_raw_seq,...
    mean_partner_raw_pose,mean_partner_raw_mov,mean_partner_raw_seq};

title_list = {...
    'Pose';...
    'Movement';...
    'Sequence';...
    'Pose';...
    'Movement';...
    'Sequence';...
    };

mat_cmap = flipud(cbrewer2('Purples',1024));
mat_cmap = mat_cmap(1:800,:);

xy_grid = [5.5,10.5,0.5,15.5];
xy_tick = [3,8,13];

for m = 1:6
    temph = subplot('Position',[...
        start_x+(m-1)*(box_x+inter_x),...
        start_y+box_y+inter_y,...
         box_x,box_y]);
    imagesc(show_raw_cell{m},[0,1])
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
    temph = subplot('Position',[...
        start_x+(m-1)*(box_x+inter_x),...
        start_y,...
         box_x,box_y]);
    imagesc(show_mat_cell{m},[0,1])
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

    if m ~= 1
        set(gca,'YTickLabel',[])
    else
        set(gca,'YTickLabel',show_brain_name)
        set(gca,'YTickLabelRotation',90)
    end

    set(gca,'XTickLabel',show_brain_name)
    
    box off
    title(title_list{m})
    set(gca,'FontSize',6)
    set(gca,'XTick',xy_tick)
    set(gca,'YTick',xy_tick)
    set(gca,'TickDir','out')
end
%% show pose predictions
start_x = 0.52;
start_y = 0.465;

box_x = 0.47;
box_y = 0.11;

inter_x = 0.02;

body_skl_3d = [...
    0,0,0;...%nose,1
    -1,1,0;...%left ear,2
    -1,-1,0;...%right ear,3
    -2,0,0;...%neck,4
    -3,1,0;...%left front limb,5
    -3,-1,0;...%right front limb,6
    -5,1,0;...%left hind limb,7
    -5,-1,0;...%right hind limb,8
    -2,1.5,0;...%left front paw,9
    -2,-1.5,0;...%right front paw,10
    -6,1.5,0;...%left hind paw,11
    -6,-1.5,0;...%right hind paw,12
    -4,0,0;...%back,13
    -6,0,0;...%root tail,14
    -7,0,0;...%mid tail,15
    -8,1,0;...%tip tail,16
    ]*2;

plotstr = 'k';
linestr = 0.7*ones(1,3);
drawline = [ 1 2; 1 3;2 3; 4 5;4 6;5 7;6 8;7 14;8 14;...
    5 9;7 11;6 10; 8 12;14 15; 15 16;2 4;3 4;...
    5 13;6 13;7 13;8 13];
mksize = 5;

xyz_edge = 1.5;

self_pose_s1 = corr_cell{1,1};
self_pose_pfc = corr_cell{2,1};
self_pose_m1 = corr_cell{3,1};
partner_pose_s1 = corr_cell{1,4};
partner_pose_pfc = corr_cell{2,4};
partner_pose_m1 = corr_cell{3,4};

% convert to axis
self_sim_s1 = pose2sim(self_pose_s1);
self_sim_pfc = pose2sim(self_pose_pfc);
self_sim_m1 = pose2sim(self_pose_m1);
partner_sim_s1 = pose2sim(partner_pose_s1);
partner_sim_pfc = pose2sim(partner_pose_pfc);
partner_sim_m1 = pose2sim(partner_pose_m1);

self_sim_s1_mean = mean(self_sim_s1,2);
self_sim_pfc_mean = mean(self_sim_pfc,2);
self_sim_m1_mean = mean(self_sim_m1,2);
partner_sim_s1_mean = mean(partner_sim_s1,2);
partner_sim_pfc_mean = mean(partner_sim_pfc,2);
partner_sim_m1_mean = mean(partner_sim_m1,2);

self_port = [...
    self_sim_s1_mean,...
    self_sim_pfc_mean,...
    self_sim_m1_mean];
self_port = self_port./...
    (sum(self_port,2)*ones(1,3));

partner_port = [...
    partner_sim_s1_mean,...
    partner_sim_pfc_mean,...
    partner_sim_m1_mean];
partner_port = partner_port./...
    (sum(partner_port,2)*ones(1,3));

subplot('Position',[...
    start_x,start_y,box_x,box_y])
X_self = body_skl_3d(:,1);
Y_self = body_skl_3d(:,2);
Z_self = body_skl_3d(:,3);

for k = 1:size(X_self,1)
    cent = [X_self(k),Y_self(k),Z_self(k)];
    start_vec = cent;
    start_vec(1) = start_vec(1)+1;
    rot_1 = self_port(k,1)*2*pi;
    rot_2 = sum(self_port(k,1:2),2)*2*pi;

    a = cent(1);
    b = cent(2);

    % show s1
    start_ang = 0;
    end_ang = rot_1;
    r_list = sort(self_sim_s1(k,:)');
    ang_list = ...
        start_ang:...
        (end_ang-start_ang)/length(r_list):...
        end_ang;
    ang_list = ang_list(2:end)';
    x = a+r_list.*cos(ang_list);
    y = b+r_list.*sin(ang_list);

    for m = 1:size(x,1)
        plot([cent(1),x(m)],[cent(2),y(m)],...
        '-','LineWidth',0.25,...
        'Color',brain_c(1,:))
        hold on
    end

    % show pfc
    start_ang = rot_1;
    end_ang = rot_2;
    r_list = sort(self_sim_pfc(k,:)');
    ang_list = ...
        start_ang:...
        (end_ang-start_ang)/length(r_list):...
        end_ang;
    ang_list = ang_list(2:end)';
    x = a+r_list.*cos(ang_list);
    y = b+r_list.*sin(ang_list);

    for m = 1:size(x,1)
        plot([cent(1),x(m)],[cent(2),y(m)],...
        '-','LineWidth',0.25,...
        'Color',brain_c(2,:))
        hold on
    end

    % show m1
    start_ang = rot_2;
    end_ang = 2*pi;
    r_list = sort(self_sim_m1(k,:)');
    ang_list = ...
        start_ang:...
        (end_ang-start_ang)/length(r_list):...
        end_ang;
    ang_list = ang_list(2:end)';
    x = a+r_list.*cos(ang_list);
    y = b+r_list.*sin(ang_list);

    for m = 1:size(x,1)
        plot([cent(1),x(m)],[cent(2),y(m)],...
        '-','LineWidth',0.25,...
        'Color',brain_c(3,:))
        hold on
    end

    plot3(...
        [cent(1),start_vec(1)],...
        [cent(2),start_vec(2)],...
        [cent(3),start_vec(3)],...
        '-k','LineWidth',0.25...
        )
    hold on
    r = 1;
    
    theta = 0:pi/100:2*pi;
    x = a+r*cos(theta);
    y = b+r*sin(theta);
    plot(x,y,'-k','LineWidth',0.25)
    hold on

    
    x_1 = a+r*cos(rot_1);
    y_1 = b+r*sin(rot_1);
    plot([cent(1),x_1],[cent(2),y_1],...
        '-k','LineWidth',0.25)
    hold on

    
    x_2 = a+r*cos(rot_2);
    y_2 = b+r*sin(rot_2);
    plot([cent(1),x_2],[cent(2),y_2],...
        '-k','LineWidth',0.25)
    hold on

    
end
hold on

plot_skl_mk(X_self,Y_self,Z_self,...
    plotstr,linestr,drawline,mksize)
hold on

X_partner = 3-1*body_skl_3d(:,1);
Y_partner = body_skl_3d(:,2);
Z_partner = body_skl_3d(:,3);

for k = 1:size(X_partner,1)
    cent = [X_partner(k),Y_partner(k),Z_partner(k)];
    start_vec = cent;
    start_vec(1) = start_vec(1)+1;
    rot_1 = self_port(k,1)*2*pi;
    rot_2 = sum(self_port(k,1:2),2)*2*pi;

    a = cent(1);
    b = cent(2);

    % show s1
    start_ang = 0;
    end_ang = rot_1;
    r_list = sort(partner_sim_s1(k,:)');
    ang_list = ...
        start_ang:...
        (end_ang-start_ang)/length(r_list):...
        end_ang;
    ang_list = ang_list(2:end)';
    x = a+r_list.*cos(ang_list);
    y = b+r_list.*sin(ang_list);

    for m = 1:size(x,1)
        plot([cent(1),x(m)],[cent(2),y(m)],...
        '-','LineWidth',0.25,...
        'Color',brain_c(1,:))
        hold on
    end

    % show pfc
    start_ang = rot_1;
    end_ang = rot_2;
    r_list = sort(partner_sim_pfc(k,:)');
    ang_list = ...
        start_ang:...
        (end_ang-start_ang)/length(r_list):...
        end_ang;
    ang_list = ang_list(2:end)';
    x = a+r_list.*cos(ang_list);
    y = b+r_list.*sin(ang_list);

    for m = 1:size(x,1)
        plot([cent(1),x(m)],[cent(2),y(m)],...
        '-','LineWidth',0.25,...
        'Color',brain_c(2,:))
        hold on
    end

    % show m1
    start_ang = rot_2;
    end_ang = 2*pi;
    r_list = sort(partner_sim_m1(k,:)');
    ang_list = ...
        start_ang:...
        (end_ang-start_ang)/length(r_list):...
        end_ang;
    ang_list = ang_list(2:end)';
    x = a+r_list.*cos(ang_list);
    y = b+r_list.*sin(ang_list);

    for m = 1:size(x,1)
        plot([cent(1),x(m)],[cent(2),y(m)],...
        '-','LineWidth',0.25,...
        'Color',brain_c(3,:))
        hold on
    end

    plot3(...
        [cent(1),start_vec(1)],...
        [cent(2),start_vec(2)],...
        [cent(3),start_vec(3)],...
        '-k','LineWidth',0.25...
        )
    hold on
    r = 1;
    
    theta = 0:pi/100:2*pi;
    x = a+r*cos(theta);
    y = b+r*sin(theta);
    plot(x,y,'-k','LineWidth',0.25)
    hold on

    
    x_1 = a+r*cos(rot_1);
    y_1 = b+r*sin(rot_1);
    plot([cent(1),x_1],[cent(2),y_1],...
        '-k','LineWidth',0.25)
    hold on

    
    x_2 = a+r*cos(rot_2);
    y_2 = b+r*sin(rot_2);
    plot([cent(1),x_2],[cent(2),y_2],...
        '-k','LineWidth',0.25)
    hold on

    
end
hold on


plot_skl_mk(X_partner,Y_partner,Z_partner,...
    plotstr,linestr,drawline,mksize)
hold off

all_x = [X_self;X_partner];
all_y = [Y_self;Y_partner];
all_z = [Z_self;Z_partner];

max_x = max(all_x);
min_x = min(all_x);

max_y = max(all_y);
min_y = min(all_y);

max_z = max(all_z);
min_z = min(all_z);

axis([...
    min_x-xyz_edge,max_x+xyz_edge,...
    min_y-xyz_edge,max_y+xyz_edge,...
    min_z-xyz_edge,max_z+xyz_edge...
    ])

axis on
set(gca,'XTick',[],'YTick',[])

box on

view(2)

title(['Self',...
    '       ',...
    '       ',...
    '       ',...
    '       ',...
    '       ',...
    '       ',...
    '       ',...
    '       ',...
    '          ',...
    'Partner'])
ylabel('Pose')
set(gca,'FontSize',6)

% show word cloud of mov
% start_x = 0.02;
start_y = 0.335;

box_x = 0.235;
box_y = 0.13;

inter_x = 0;

self_mov_s1 = corr_cell{1,2};
self_mov_pfc = corr_cell{2,2};
self_mov_m1 = corr_cell{3,2};
partner_mov_s1 = corr_cell{1,5};
partner_mov_pfc = corr_cell{2,5};
partner_mov_m1 = corr_cell{3,5};

self_mov_s1_mean = mov2mean(self_mov_s1);
self_mov_pfc_mean = mov2mean(self_mov_pfc);
self_mov_m1_mean = mov2mean(self_mov_m1);
partner_mov_s1_mean = mov2mean(partner_mov_s1);
partner_mov_pfc_mean = mov2mean(partner_mov_pfc);
partner_mov_m1_mean = mov2mean(partner_mov_m1);

% self
subplot('Position',[...
    start_x,start_y,box_x,box_y])
sel_self_mov_s1 = self_mov_s1_mean~=-1;
sel_self_mov_pfc = self_mov_pfc_mean~=-1;
sel_self_mov_m1 = self_mov_m1_mean~=-1;

sel_self_mov = ...
    sel_self_mov_s1&...
    sel_self_mov_pfc&...
    sel_self_mov_m1;

sel_self_mov_s1_mean = self_mov_s1_mean(sel_self_mov);
sel_self_mov_pfc_mean = self_mov_pfc_mean(sel_self_mov);
sel_self_mov_m1_mean = self_mov_m1_mean(sel_self_mov);

sel_self_mov_name = uniuqe_mov_name(sel_self_mov);

self_clr = zeros(size(sel_self_mov_name,1),3);
self_size = zeros(size(sel_self_mov_name,1),1);
for k = 1:size(self_clr,1)
    templist = [...
        sel_self_mov_s1_mean(k),...
        sel_self_mov_pfc_mean(k),...
        sel_self_mov_m1_mean(k),...
        ];
    maxidx = find(templist==max(templist));
    self_clr(k,:) = dark_brain_c(maxidx,:);
    self_size(k,1) = max(templist);
end

wordcloud(sel_self_mov_name,self_size,'Color',self_clr)

box on

%partner
subplot('Position',[...
    start_x+inter_x+box_x,start_y,box_x,box_y])
sel_partner_mov_s1 = partner_mov_s1_mean~=-1;
sel_partner_mov_pfc = partner_mov_pfc_mean~=-1;
sel_partner_mov_m1 = partner_mov_m1_mean~=-1;

sel_partner_mov = ...
    sel_partner_mov_s1&...
    sel_partner_mov_pfc&...
    sel_partner_mov_m1;

sel_partner_mov_s1_mean = partner_mov_s1_mean(sel_partner_mov);
sel_partner_mov_pfc_mean = partner_mov_pfc_mean(sel_partner_mov);
sel_partner_mov_m1_mean = partner_mov_m1_mean(sel_partner_mov);

sel_partner_mov_name = uniuqe_mov_name(sel_partner_mov);

partner_clr = zeros(size(sel_partner_mov_name,1),3);
partner_size = zeros(size(sel_partner_mov_name,1),1);
for k = 1:size(partner_clr,1)
    templist = [...
        sel_partner_mov_s1_mean(k),...
        sel_partner_mov_pfc_mean(k),...
        sel_partner_mov_m1_mean(k),...
        ];
    maxidx = find(templist==max(templist));
    partner_clr(k,:) = dark_brain_c(maxidx(1),:);
    partner_size(k,1) = max(templist);
end

wordcloud(sel_partner_mov_name,partner_size,'Color',partner_clr)

box on

% show seq by wordcloud
% start_x = 0.02;
start_y = 0.2;

box_x = 0.47;
box_y = 0.135;

small_box_y = box_y/3;

seq_len = 5;
small_box_x = box_x/seq_len;

inter_y = 0;

self_seq_s1 = corr_cell{1,3};
self_seq_pfc = corr_cell{2,3};
self_seq_m1 = corr_cell{3,3};
partner_seq_s1 = corr_cell{1,6};
partner_seq_pfc = corr_cell{2,6};
partner_seq_m1 = corr_cell{3,6};

self_seq_s1_mean = mov2mean(self_seq_s1);
self_seq_pfc_mean = mov2mean(self_seq_pfc);
self_seq_m1_mean = mov2mean(self_seq_m1);
partner_seq_s1_mean = mov2mean(partner_seq_s1);
partner_seq_pfc_mean = mov2mean(partner_seq_pfc);
partner_seq_m1_mean = mov2mean(partner_seq_m1);

%self
sel_self_seq_s1 = self_seq_s1_mean~=-1;
sel_self_seq_pfc = self_seq_pfc_mean~=-1;
sel_self_seq_m1 = self_seq_m1_mean~=-1;

sel_self_seq = ...
    sel_self_seq_s1&...
    sel_self_seq_pfc&...
    sel_self_seq_m1;

sel_self_seq_s1_mean = self_seq_s1_mean(sel_self_seq);
sel_self_seq_pfc_mean = self_seq_pfc_mean(sel_self_seq);
sel_self_seq_m1_mean = self_seq_m1_mean(sel_self_seq);

sel_self_seq_name = unique_seq(sel_self_seq);

sel_self_seqcell = seq_cell(sel_self_seq);

self_clr = zeros(size(sel_self_seq_name,1),3);
self_area = cell(size(self_clr,1),1);
for k = 1:size(self_clr,1)
    templist = [...
        sel_self_seq_s1_mean(k),...
        sel_self_seq_pfc_mean(k),...
        sel_self_seq_m1_mean(k),...
        ];
    maxidx = find(templist==max(templist));
    self_clr(k,:) = dark_brain_c(maxidx(1),:);
    self_area{k,1} = show_brain_name{maxidx(1),1};
end

for k = 1:3
    sel_self_seq = sel_self_seqcell(...
        strcmp(self_area,show_brain_name{k,1}),:);
    sel_self_clr = self_clr(...
        strcmp(self_area,show_brain_name{k,1}),:);

    reo_self_seq = {};
    for m = 1:size(sel_self_seq,1)
        reo_self_seq = [reo_self_seq;...
            sel_self_seq{m}];
    end

    reo_self_seq_cell = cell(...
        size(reo_self_seq,1),seq_len);
    for m = 1:size(reo_self_seq_cell,1)
        if size(reo_self_seq{m},2)<=seq_len
            reo_self_seq_cell(m,...
                1:size(reo_self_seq{m},2)) = ...
                reo_self_seq{m};
        else
            reo_self_seq_cell(m,...
                1:seq_len) = ...
                reo_self_seq{m}(1:seq_len);
        end
    end
    
    self_name_perc_cell = cell(2,seq_len);
    for m = 1:seq_len
        tempseg = reo_self_seq_cell(:,m);
        
        empty_idx = ~cell2mat(...
            cellfun(@(x) isempty(x),...
            tempseg,'UniformOutput',false));
        tempseg = tempseg(empty_idx);

        tblseg = tabulate(tempseg);
        self_name_perc_cell{1,m} = tblseg(:,1);
        self_name_perc_cell{2,m} = cell2mat(...
            tblseg(:,2));
    end

    for m = 1:seq_len
        subplot('Position',[...
            start_x+(m-1)*small_box_x,...
            start_y+(k-1)*small_box_y,...
            small_box_x,small_box_y])
        tempname = self_name_perc_cell{1,m};
        tempperc = self_name_perc_cell{2,m};

        wordcloud(tempname,...
            tempperc,'Color',...
            ones(size(tempname,1),1)*sel_self_clr(1,:))
        box on
    end

    
end


%partner
sel_partner_seq_s1 = partner_seq_s1_mean~=-1;
sel_partner_seq_pfc = partner_seq_pfc_mean~=-1;
sel_partner_seq_m1 = partner_seq_m1_mean~=-1;

sel_partner_seq = ...
    sel_partner_seq_s1&...
    sel_partner_seq_pfc&...
    sel_partner_seq_m1;

sel_partner_seq_s1_mean = partner_seq_s1_mean(sel_partner_seq);
sel_partner_seq_pfc_mean = partner_seq_pfc_mean(sel_partner_seq);
sel_partner_seq_m1_mean = partner_seq_m1_mean(sel_partner_seq);

sel_partner_seq_name = unique_seq(sel_partner_seq);

sel_partner_seqcell = seq_cell(sel_partner_seq);

partner_clr = zeros(size(sel_partner_seq_name,1),3);
partner_area = cell(size(partner_clr,1),1);
for k = 1:size(partner_clr,1)
    templist = [...
        sel_partner_seq_s1_mean(k),...
        sel_partner_seq_pfc_mean(k),...
        sel_partner_seq_m1_mean(k),...
        ];
    maxidx = find(templist==max(templist));
    partner_clr(k,:) = dark_brain_c(maxidx(1),:);
    partner_area{k,1} = show_brain_name{maxidx(1),1};
end

for k = 1:3

    sel_partner_seq = sel_partner_seqcell(...
        strcmp(partner_area,show_brain_name{k,1}),:);
    sel_partner_clr = partner_clr(...
        strcmp(partner_area,show_brain_name{k,1}),:);

    reo_partner_seq = {};
    for m = 1:size(sel_partner_seq,1)
        reo_partner_seq = [reo_partner_seq;...
            sel_partner_seq{m}];
    end

    reo_partner_seq_cell = cell(...
        size(reo_partner_seq,1),seq_len);
    for m = 1:size(reo_partner_seq_cell,1)
        if size(reo_partner_seq{m},2)<=seq_len
            reo_partner_seq_cell(m,...
                1:size(reo_partner_seq{m},2)) = ...
                reo_partner_seq{m};
        else
            reo_partner_seq_cell(m,...
                1:seq_len) = ...
                reo_partner_seq{m}(1:seq_len);
        end
    end
    
    partner_name_perc_cell = cell(2,seq_len);
    for m = 1:seq_len
        tempseg = reo_partner_seq_cell(:,m);
        
        empty_idx = ~cell2mat(...
            cellfun(@(x) isempty(x),...
            tempseg,'UniformOutput',false));
        tempseg = tempseg(empty_idx);

        tblseg = tabulate(tempseg);
        partner_name_perc_cell{1,m} = tblseg(:,1);
        partner_name_perc_cell{2,m} = cell2mat(...
            tblseg(:,2));
    end


    for m = 1:seq_len
        subplot('Position',[...
            start_x+(m-1)*small_box_x,...
            start_y-box_y+(k-1)*small_box_y,...
            small_box_x,small_box_y])

        tempname = partner_name_perc_cell{1,m};
        tempperc = partner_name_perc_cell{2,m};

        wordcloud(tempname,...
            tempperc,'Color',...
            ones(size(tempname,1),1)*sel_partner_clr(1,:))
        box on
    end
end









