%{
    分far-close-二态行为，用储池计算模拟fitting，
    每只老鼠一个trial
%}
clear all
close all
addpath(genpath(pwd))
%% set path
rootpath = ['E:\MTPM_body_language'];
beh_neu_path = [rootpath,'\beh_neu_20240412'];
net_param_path = [beh_neu_path,'\test_20241015_laptop_3'];
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

%% load network param list
net_param_cell = cell(size(all_data_cell,1),1);

time_list = {...
    '0';...
    '150';...
    '450';...
    '5400';...
    };

for k = 1:size(net_param_cell,1)
    %% load data
    tempcell = cell(size(time_list,1),1);
    for m = 1:size(time_list,1)
        tempname = [all_data_cell{k,1},...
            '-cut-delayframe_',time_list{m}];
        tempfolder = [net_param_path,'\',...
            tempname];

        tempimgnames = dir(fullfile(tempfolder,'*.png'));
        splname1 = split({tempimgnames.name}','.p');
        splname2 = split(splname1(:,1),'_');

        netvaluecell = cellfun(@(a,b,c,d,e) ...
            [str2double(time_list{m}),...
            str2double(a),...
            str2double(b),...
            str2double(c),...
            str2double(d),...
            str2double(e)],...
            splname2(:,2),...
            splname2(:,3),...
            splname2(:,4),...
            splname2(:,5),...
            splname2(:,7),...
            'UniformOutput',false);

        netvaluemat = cell2mat(netvaluecell);

        tempcell{m,1} = netvaluemat;
    end

    tempmat = cell2mat(tempcell);

    net_param_cell{k,1} = tempmat;
end

net_param_mat = cell2mat(net_param_cell);
%% split mouse trial from the first far-close
fs = 30;
baseline_far_time = 15;%s
cut_all_time = 10*60;%s

baseline_far_frame = baseline_far_time*fs;
cut_all_frame = cut_all_time*fs;

raw_trial_cell = {};

for k = 1:size(all_data_cell,1)
    %% load data
    tempdist = all_data_cell{k,9};
    
    %% select trials
    distsavelist = idx2savelist(tempdist{2});

    diff_len = distsavelist(:,2)-distsavelist(:,1)+1;

    far_idx = distsavelist(:,3)==0;

    diff_len_idx = diff_len>=baseline_far_frame;

    selidx = (diff_len_idx.*far_idx)==1;

    find_save_list = find(selidx,1,'first');

    sel_save_list = distsavelist(find_save_list:end,:);
    
    % modify to the same lengh of baseline
    sel_save_list(1,1) = sel_save_list(1,2)-baseline_far_frame+1;
    %% append data
    tempstart = sel_save_list(1,1);
    tempend = sel_save_list(1,1)+cut_all_frame-1;

    newname = [all_data_cell{k,1},'-cut'];
    all_data_2 = all_data_cell{k,2}(tempstart:tempend,:);
    all_data_3 = all_data_cell{k,3}(tempstart:tempend,:);
    all_data_4 = all_data_cell{k,4}(tempstart:tempend,:);
    all_data_5 = all_data_cell{k,5}(tempstart:tempend,:);
    all_data_6 = all_data_cell{k,6}(tempstart:tempend,:);
    all_data_7 = all_data_cell{k,7}(tempstart:tempend,:);
    all_data_8 = all_data_cell{k,8}(tempstart:tempend,:);
    all_data_9 = all_data_cell{k,9}{3}(tempstart:tempend,:);

    raw_trial_cell = [raw_trial_cell;...
        {newname,all_data_2,all_data_3,all_data_4,...
        all_data_5,all_data_6,all_data_7,all_data_8,...
        all_data_9,all_data_cell{k,1}}];

    unique(all_data_5)
    %%
    disp(k)
end
%% create the unique_mov and unique_seq
all_mov = [];
all_mov_name = {};
for k = 1:size(raw_trial_cell,1)
    all_mov = [all_mov;...
        cell2mat(raw_trial_cell{k,4}(:,2));...
        cell2mat(raw_trial_cell{k,7}(:,2))];
    all_mov_name = [all_mov_name;...
        raw_trial_cell{k,4}(:,1);...
        raw_trial_cell{k,7}(:,1)];
end
unique_mov = unique(all_mov);
cmap_mov = cbrewer2('BuPu',length(unique_mov));

uniuqe_mov_name = cell(size(unique_mov));
for k = 1:size(unique_mov,1)
    tempname = all_mov_name(unique_mov(k)==all_mov);
    uniuqe_mov_name{k} = tempname{1};
end

all_seq = [];
for k = 1:size(raw_trial_cell,1)
    all_seq = [all_seq;raw_trial_cell{k,5};raw_trial_cell{k,8}];
end
unique_seq = unique(all_seq);
unique_seq = unique_seq(2:end);
cmap_seq = cbrewer2('BuPu',length(unique_seq));
%% sort data by brain areas
sort_brain_name_list = {...
    '1tpmss';...
    '2tpmss';...
    '3tpmss';...
    '4tpmss';...
    '5tpmss';...
    '1tpmpfc';...
    '2tpmpfc';...
    '3tpmpfc';...
    '4tpmpfc';...
    '5tpmpfc';...
    '1tpmm';...
    '2tpmm';...
    '3tpmm';...
    '4tpmm';...
    '5tpmm';...
    };

splname1 = split(raw_trial_cell(:,1),'-');


sort_trial_cell = raw_trial_cell;

for k = 1:size(sort_brain_name_list,1)
    tempname = sort_brain_name_list{k,1};
    selidx = strcmp(tempname,splname1(:,3));
    sort_trial_cell(k,:) = raw_trial_cell(selidx,:);
end

%% load state
state_cell = cell(size(sort_trial_cell,1),1);

for k = 1:size(state_cell,1)
    rootname = sort_trial_cell{k,1};
    tempdata = load([beh_neu_path,'\',rootname,...
        '-rnn_state.mat']);
    state_cell{k,1} = tempdata.state;
end

%% load demo prediction data
fileFolder = fullfile(beh_neu_path);
dirOutput = dir(fullfile(fileFolder,'*cut-rnn_yp*.mat'));
demoNames = {dirOutput.name}';

demo_cell = cell(size(demoNames,1),1);

for k = 1:size(demo_cell,1)
    tempdata = load([beh_neu_path,'\',demoNames{k}]);
    demo_cell{k,1} = tempdata.y_p;
end

%% plot canvas
hall = figure(1);
set(hall,'Position',[680,0,800,800])
set(hall,'color','white');

%% draw demo and data
start_x = 0.04;
start_y = 0.88;

box_x = 0.3;
box_y = 0.1;

inter_y = 0.01;

x_tick = [1,450,18000];
x_tick_label = [-15,0,585];

show_x_len = 18000;

% demo
subplot('Position',[start_x,start_y,box_x,box_y])

% % self mov
% 
% % create mov mat
pad_len = 27000;
self_mov_mat = -1*ones(size(sort_trial_cell,1),pad_len);
start_list = zeros(size(self_mov_mat,1),2);
end_list = zeros(size(self_mov_mat,1),2);

for k = 1:size(self_mov_mat,1)
    tempmov = cell2mat(sort_trial_cell{k,4}(:,2))';
    self_mov_mat(k,1:length(tempmov)) = tempmov;
    start_list(k,:) = [baseline_far_frame,k];
    end_list(k,:) = [length(tempmov),k];
end
% 
% temph = subplot('Position',[start_x,...
%     start_y-box_y-inter_y,box_x,box_y]);
% 
% imagesc(self_mov_mat)
% colormap(temph,[1,1,1;cmap_mov])
% hold on
% plot(start_list(:,1),start_list(:,2),'-k')
% % hold on
% % plot(end_list(:,1),end_list(:,2),'-k')
% hold off
% 
% box off
% % title('Self')
% 
% axis([0,show_x_len,0,size(self_mov_mat,1)])
% 
% ylabel('Self movements')
% 
% set(gca,'XTick',x_tick)
% set(gca,'XTickLabel',[])
% % set(gca,'XTickLabel',x_tick_label)
% 
% set(gca,'YTick',[1,size(self_mov_mat,1)])
% 
% set(gca,'TickDir','out')
% set(gca,'FontSize',6)
% xlabel('Time (s)')
% 
% % colorbar, mov
% cbar_box_x = 0.006;
% cbar_box_y = 0.05;
% 
% cbar_inter_x = 0.01;
% 
% temph = subplot('Position',[...
%     start_x+box_x+cbar_inter_x,...
%     start_y-box_y-inter_y+cbar_box_y,...
%     cbar_box_x,cbar_box_y]);
% imagesc(flipud((1:max(unique_mov))'))
% colormap(temph,cmap_mov)
% set(gca,'XTick',[],'YTick',[])
% 
% text(0.5,50,'1','FontSize',6,'VerticalAlignment','middle')
% text(0.5,-1,'49','FontSize',6,'VerticalAlignment','middle')
% 
% text(2.5,25,{'Movement','categories'},...
%     'FontSize',6,'Rotation',90,...
%     'HorizontalAlignment','center')
% 
% 
% 
% % partner mov
% 
% part_mov_mat = -1*ones(size(sort_trial_cell,1),pad_len);
% start_list = zeros(size(part_mov_mat,1),2);
% end_list = zeros(size(part_mov_mat,1),2);
% 
% for k = 1:size(part_mov_mat,1)
%     tempmov = cell2mat(sort_trial_cell{k,7}(:,2))';
%     part_mov_mat(k,1:length(tempmov)) = tempmov;
%     start_list(k,:) = [baseline_far_frame,k];
%     end_list(k,:) = [length(tempmov),k];
% end
% 
% temph = subplot('Position',[start_x,...
%     start_y-2*(box_y+inter_y),box_x,box_y]);
% 
% imagesc(part_mov_mat)
% colormap(temph,[1,1,1;cmap_mov])
% hold on
% plot(start_list(:,1),start_list(:,2),'-k')
% % hold on
% % plot(end_list(:,1),end_list(:,2),'-k')
% hold off
% 
% box off
% 
% axis([0,show_x_len,0,size(part_mov_mat,1)])
% 
% ylabel('Partner movements')
% 
% set(gca,'XTick',x_tick)
% set(gca,'XTickLabel',[])
% 
% set(gca,'YTick',[1,size(part_mov_mat,1)])
% % set(gca,'YTickLabel',[])
% 
% % title('Partner')
% set(gca,'TickDir','out')
% set(gca,'FontSize',6)
% xlabel('Time (s)')
%% pc 1
pca_cell = cell(size(sort_trial_cell,1),5);

for k = 1:size(pca_cell,1)
    tempneu = sort_trial_cell{k,2};
    [coeff, score, ~, ~, explained] = pca(tempneu');
    pca_cell{k,1} = coeff;
    pca_cell{k,2} = score;
    pca_cell{k,3} = explained;
    pca_cell{k,4} = cumsum(explained);
    pca_cell{k,5} = explained;
    disp(k)
end

sel_pc = cellfun(@(x) mat2gray(x(:,1)'),...
        pca_cell(:,1),'UniformOutput',false);

pad_pc_mat = nan(size(sel_pc,1),pad_len);
start_list = zeros(size(pad_pc_mat,1),2);
end_list = zeros(size(pad_pc_mat,1),2);

for k = 1:size(pad_pc_mat,1)
    temppca = sel_pc{k};
    pad_pc_mat(k,1:length(temppca)) = temppca;
    start_list(k,:) = [baseline_far_frame,k];
    end_list(k,:) = [length(tempmov),k];
end

raw_pc_mat = pad_pc_mat(:,1:18000);

%%
temph = subplot('Position',[start_x,...
    start_y-2*(box_y+inter_y),box_x,box_y]);
imagesc(pad_pc_mat)

hold on
for k = 1:2
    plot([0,18000],[k*5+0.5,k*5+0.5],'-k')
    hold on
end
hold on

cmap_neu = flipud(cbrewer2('RdBu',256));

colormap(temph,[1,1,1;cmap_neu])

hold on
plot(start_list(:,1),start_list(:,2)-0.5,'-k')
% hold on
% plot(end_list(:,1),end_list(:,2),'-k')
hold off

axis([0,show_x_len,0,size(pad_pc_mat,1)+0.5])

box off

ylabel('PC 1')
xlabel('Time (s)')

set(gca,'XTick',x_tick)
set(gca,'XTickLabel',x_tick_label)

set(gca,'YTick',[3,8,13])
set(gca,'YTickLabel',{'S1','dmPFC','M1'})
set(gca,'YTickLabelRotation',90)

set(gca,'FontSize',6)
set(gca,'TickDir','out')

% colorbar
cbar_box_x = 0.006;
cbar_box_y = 0.05;

cbar_inter_x = 0.01;

temph = subplot('Position',[...
    start_x+box_x+cbar_inter_x,...
    start_y-1*(box_y+inter_y)-inter_y-cbar_box_y,...
    cbar_box_x,cbar_box_y]);
imagesc(fliplr((1:256))')
colormap(temph,cmap_neu)
set(gca,'XTick',[],'YTick',[])

text(0.5,280,'0','FontSize',6,'VerticalAlignment','middle')
text(0.5,-30,'1','FontSize',6,'VerticalAlignment','middle')

text(2.5,128,'PC coefficient','FontSize',6,'Rotation',90,...
    'HorizontalAlignment','center')

set(gca,'FontSize',6)

%% neu (really slow)

neu_mat = [];
neu_start_list = [];
neu_end_list = [];

neu_idx = [];

count = 1;

for k = 1:size(sort_trial_cell,1)
    tempneu = sort_trial_cell{k,2}';
    padneu = nan(size(tempneu,1),pad_len);

    for m = 1:size(padneu,1)
        ttneu = tempneu(m,:);
        padneu(m,1:length(ttneu)) = ttneu;
        neu_start_list = [neu_start_list;...
            [baseline_far_frame,count]];
        neu_end_list = [neu_end_list;...
            [length(ttneu),count]];

        count = count+1;
    end
    
    neu_mat = [neu_mat;padneu];
    neu_idx = [neu_idx;k*ones(size(padneu,1),1)];
end

%% show neu
diff_neu_idx = [1;diff(neu_idx)];

seg1_idx = find(((neu_idx==6).*diff_neu_idx)==1);
seg2_idx = find(((neu_idx==11).*diff_neu_idx)==1);

show_range = [-0.5,0.5];

cmap_neu = flipud(cbrewer2('RdBu',256));

temph = subplot('Position',[start_x,...
    start_y-1*(box_y+inter_y),box_x,box_y]);
imagesc(neu_mat,show_range)

hold on
plot([0,18000],[seg1_idx,seg1_idx],'-k')
hold on
plot([0,18000],[seg2_idx,seg2_idx],'-k')

colormap(temph,[1,1,1;cmap_neu])
hold on
plot(neu_start_list(:,1),neu_start_list(:,2),'-k')
% hold on
% plot(neu_end_list(:,1),neu_end_list(:,2),'-k')
hold off

box off

axis([0,show_x_len,0,size(neu_mat,1)])

set(gca,'FontSize',6)
set(gca,'TickDir','out')
set(gca,'XTick',x_tick)
set(gca,'XTickLabel',[])

ytick_list = [...
    (0+seg1_idx)/2,...
    (seg1_idx+seg2_idx)/2,...
    (seg2_idx+size(neu_mat,1))/2];

set(gca,'YTick',ytick_list)
set(gca,'YTickLabel',{'S1','dmPFC','M1'})
set(gca,'YTickLabelRotation',90)
% xlabel('Time (s)')
ylabel('Neural activities')

% colorbar
cbar_box_x = 0.006;
cbar_box_y = 0.05;

cbar_inter_x = 0.01;

temph = subplot('Position',[...
    start_x+box_x+cbar_inter_x,...
    start_y-0*(box_y+inter_y)-inter_y-cbar_box_y,...
    cbar_box_x,cbar_box_y]);
imagesc(flipud((1:256)'))
colormap(temph,cmap_neu)
set(gca,'XTick',[],'YTick',[])

text(0.5,280,'-0.5','FontSize',6,'VerticalAlignment','middle')
text(0.5,-30,'0.5','FontSize',6,'VerticalAlignment','middle')

text(2.5,128,'ΔF/F','FontSize',6,'Rotation',90,...
    'HorizontalAlignment','center')

%% process the parameters of network
sort_net_mat = sortrows(net_param_mat,6);

unique_param = unique(sort_net_mat(:,1:5),'rows');

unique_param_err = zeros(size(unique_param,1),1);

unique_param_err_all = [];

for k = 1:size(unique_param,1)
    tempparam = unique_param(k,:);

    selidx = mean((ones(size(sort_net_mat,1),1)...
        *tempparam)==sort_net_mat(:,1:5),2)==1;

    selerr = sort_net_mat(selidx,6);

    unique_param_err(k,:) = mean(selerr);

    unique_param_err_all = [...
        unique_param_err_all;...
        selerr'];
end

unique_param_mat = [unique_param,unique_param_err_all];

mean_err_list = mean(unique_param_mat(:,6:end),2);

[~,sortidx] = sort(mean_err_list);

sort_unique_param_mat = unique_param_mat(sortidx,:);

%% plot psth
cumsum_cell = cell(5,3);

for k = 1:size(cumsum_cell,1)
    %%
    templist = sort_unique_param_mat(:,k);
    unique_data = unique(templist);

    cumsum_cell{k,1} = unique_data;

    idxmat = zeros(size(templist,1),size(unique_data,1));
    cumsum_mat = idxmat;

    for m = 1:size(unique_data,1)
        tempdata = unique_data(m);
        tempidx = tempdata==templist;
        idxmat(:,m) = tempidx;

        cumsum_mat(:,m) = cumsum(tempidx);
    end

    cumsum_cell{k,1} = unique_data;
    cumsum_cell{k,2} = idxmat;
    cumsum_cell{k,3} = cumsum_mat;
end

psth_win = 20;

psth_cell = cell(size(cumsum_cell,1),2);

for k = 1:size(cumsum_cell,1)
    %%
    tempidx = cumsum_cell{k,2};

    psth_mat = zeros(size(tempidx));

    for m = 1:size(tempidx,2)
        selidx = tempidx(:,m);
        padidx = [selidx;zeros(psth_win,1)];
        
        temp_psth = zeros(size(selidx,1),1);
        for n = 1:size(selidx,1)
            seldata = padidx(n:(n+psth_win-1),:);
            temp_psth(n,1) = sum(seldata);
        end

        psth_mat(:,m) = temp_psth;
    end

    psth_cell{k,1} = psth_mat';

    psth_cell{k,2} = psth_cell{k,1}./...
    (max(psth_cell{k,1},[],2)*...
    ones(1,size(psth_cell{k,1},2)));
end

% show reservoir
start_x = 0.41;
start_y = 0.901;

box_x = 0.2;
box_y = 0.08;

error_box_y = 0.036;

% reservoir network demo
subplot('Position',[start_x,start_y,box_x,box_y])

% show error
sort_err_mat = sort_unique_param_mat(:,6:20)';

temph = subplot('Position',[start_x,...
    start_y-(error_box_y+inter_y),box_x,error_box_y]);
imagesc(sort_err_mat,[0,100])

err_cmap = cbrewer2('Blues',256);
colormap(temph,err_cmap)

box off
set(gca,'TickDir','out')

set(gca,'YTick',[1,15])

set(gca,'XTick',[])

set(gca,'FontSize',6)

ylabel('Mouse')


% show colorbar
cbar_box_x = 0.006;
cbar_box_y = 0.02;

cbar_inter_x = 0.01;

temph = subplot('Position',[...
    start_x+box_x+cbar_inter_x,...
    start_y-inter_y-cbar_box_y,...
    cbar_box_x,cbar_box_y]);
imagesc(flipud((1:256)'))
colormap(temph,err_cmap)
set(gca,'XTick',[],'YTick',[])

text(0.5,330,'0','FontSize',6,'VerticalAlignment','middle')
text(0,-80,'100','FontSize',6,'VerticalAlignment','middle')

text(2.5,128,'MSE','FontSize',6,'Rotation',90,...
    'HorizontalAlignment','center')

% show parameters

ylabel_list = {...
    'Delay (s)';...
    'Leak rate';...
    'In connectivity';...
    'Neuron number';...
    'Out connectivity';...
    };

ylabel_list_short = {...
    'Del. (s)';...
    'L.R.';...
    'In. C.';...
    'Num.';...
    'Out. C.';...
    };

small_box_y = error_box_y;
small_inter_y = 0.003;

show_list = [4,2,1,3,5];

for k = 1:size(psth_cell,1)
    tempmat = psth_cell{show_list(k),2};
    temph = subplot('Position',[...
        start_x,...
        start_y-(error_box_y+inter_y)-...
        k*(small_box_y+small_inter_y),...
        box_x,small_box_y]);
    imagesc(tempmat)
    colormap(temph,err_cmap)
    box off

    set(gca,'TickDir','out')
    
    set(gca,'YTick',1:size(tempmat,1))

    if show_list(k) == 1
        set(gca,'YTickLabel',cumsum_cell{show_list(k),1}/30)
    else
        set(gca,'YTickLabel',cumsum_cell{show_list(k),1})
    end

    ylabel(ylabel_list_short{show_list(k)},'Rotation',90)

    set(gca,'FontSize',6)
    
    if k ~= size(psth_cell,1)
        set(gca,'XTick',[])
    else
        set(gca,'XTick',[1,size(tempmat,2)])
        xlabel('Parameter groups')
    end
end

% show colorbar
cbar_box_x = 0.006;
cbar_box_y = 0.03;

cbar_inter_x = 0.01;

temph = subplot('Position',[...
    start_x+box_x+cbar_inter_x,...
    start_y-inter_y-cbar_box_y-...
    1.1*(small_box_y+small_inter_y),...
    cbar_box_x,cbar_box_y]);
imagesc(flipud((1:256)'))
colormap(temph,err_cmap)
set(gca,'XTick',[],'YTick',[])

text(0.5,300,'0','FontSize',6,'VerticalAlignment','middle')
text(0,-50,'1','FontSize',6,'VerticalAlignment','middle')

text(3.5,128,{'Normalized','frequency'},...
    'FontSize',6,'Rotation',90,...
    'HorizontalAlignment','center')

%% calculate rnn pca
rnn_pca_cell = cell(size(state_cell,1),5);

for k = 1:size(rnn_pca_cell,1)
    tempneu = state_cell{k,1};
    [coeff, score, ~, ~, explained] = pca(tempneu');
    rnn_pca_cell{k,1} = coeff;
    rnn_pca_cell{k,2} = score;
    rnn_pca_cell{k,3} = explained;
    rnn_pca_cell{k,4} = cumsum(explained);
    rnn_pca_cell{k,5} = explained;
    disp(k)
end

%% show pose prediction
start_x = 0.69;
start_y = 0.925;

box_x = 0.29;
box_y = 0.06;

inter_y = 0.005;

show_cell = cell(5,1);

show_cell{1,1} = sort_trial_cell{1,3};

show_cell(2:end,:) = demo_cell;

x_list_cell = {...
    1:18000;...
    1:18000;...
    1:18000;...
    451:18000;...
    5401:18000};

ds_rate = 1;

overlapidx = 0.1;

edge_size = 0.5;

xtick_list = [0,450,5400,18000];

xtick_label_list = {-15,0,165,585};

ylabel_list = {...
    'Subject pose x';...
    {'Prediction pose x','Best params'};...
    'L.R. = 0.5';...
    'Del. = 3 s';...
    'Del. = 180 s'};

setcolor = cbrewer2('Spectral',11);
mouse_tpm_c = setcolor(3,:);
mouse_free_c = setcolor(9,:);

for k = 1:5
    temptraj = show_cell{k,1}';
    subplot('Position',[start_x,...
        start_y-(k-1)*(box_y+inter_y),...
        box_x,box_y])

    if k == 1
        show_c = mouse_tpm_c;
    else
        show_c = mean(err_cmap);
    end

    for m = 1:3:size(temptraj,1)
        plot(x_list_cell{k},...
            mat2gray(temptraj(m,1:ds_rate:end))+...
            overlapidx*m,...
            'LineWidth',0.25,'Color',show_c)
        hold on
    end

    for m = 2:(length(xtick_list)-1)
        plot([xtick_list(m),xtick_list(m)],...
            [0-edge_size,...
            edge_size+overlapidx*(size(temptraj,1)+4)],...
            '--k','LineWidth',0.25)
        hold on
    end
    hold off

    axis([0,18000,0-edge_size,...
        edge_size+overlapidx*(size(temptraj,1)+4)])

    box off

    set(gca,'XTick',xtick_list)

    set(gca,'YTick',[])
    
    if k==5
        set(gca,'XTickLabel',xtick_label_list)
        xlabel('Time (s)')
    else
        set(gca,'XTickLabel',[])
    end

    set(gca,'TickDir','out')

    set(gca,'FontSize',6)

    ylabel(ylabel_list{k})
    
end

%% show state and pc
start_x = 0.04;
start_y = 0.88;

box_x = 0.3;
box_y = 0.1;

inter_y = 0.01;

%% state neu
state_neu_mat = cell2mat(cellfun(@(x) x',...
    state_cell,'UniformOutput',false));

zs_state_neu_mat = state_neu_mat;
for k = 1:size(zs_state_neu_mat,1)
    zs_state_neu_mat(k,:) = zscore(state_neu_mat(k,:));
end

temph = subplot('Position',[start_x,...
    start_y-3*(box_y+inter_y),...
    box_x,box_y]);

show_zs = 3;

imagesc(zs_state_neu_mat,show_zs*[-1,1])
colormap(temph,cmap_neu)



%% state pc
%% find the most similar PC to show
pc_corr_list = zeros(100,1);
for k = 1:100
    show_state_pc = cell2mat(...
        cellfun(@(x) mat2gray(x(:,k)'),...
    rnn_pca_cell(:,1),'UniformOutput',false));
    
    corr_list = zeros(size(raw_pc_mat,1),2);
    for m = 1:size(raw_pc_mat,1)
        tempref = raw_pc_mat(m,:);
        tempcmp = show_state_pc(m,:);

        [r,p] = corrcoef(tempref,tempcmp);
        corr_list(m,1) = r(1,2);
        corr_list(m,2) = p(1,2);
    end

    mean_corr = mean(corr_list(:,1));
    pc_corr_list(k,1) = mean_corr;
end




temph = subplot('Position',[start_x,...
    start_y-4*(box_y+inter_y),...
    box_x,box_y]);
imagesc(-1*show_state_pc)

colormap(temph,[1,1,1;cmap_neu])

%% calculate correlations
raw_pose = sort_trial_cell{1, 3}';
raw_pc = pca_cell{1,1}';

pose_pc_mat = zeros(size(raw_pose,1),size(raw_pc,1));

for m = 1:size(raw_pose,1)
    for n = 1:size(raw_pc,1)
        [r,p] = corrcoef(raw_pose(m,:),raw_pc(n,:));
        pose_pc_mat(m,n) = r(1,2);
    end
end







































