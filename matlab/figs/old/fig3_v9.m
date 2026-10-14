%{
    fig2, identify body language
    use pose as alphabet to identify inner patterns
%}
clear all
close all
addpath(genpath(pwd))
%% plot canvas
hall = figure(1);
set(hall,'Position',[0,0,800,800])
set(hall,'color','white');
%% set path
rootpath = ['E:\MTPM_body_language\tst_revise'];
datapath = [rootpath,'\recluster_data'];
%% load data
load([datapath,'\group_compare_20230301.mat']);
load([datapath,'\embedding_20230301.mat']);
load([datapath,'\data_sample_cell_20230301.mat']);
ctn = load([datapath,'\cnt_body_language_20230425.mat']);
beh_class = readcell([datapath,'\cut_beh_20230301_classes.xlsx']);
%% model and data design
% subplot('Position',[0.03,0.68,0.3,0.3])
% box on
% set(gca,'XTick',[],'YTick',[])
% title('Body language extraction framework')
subplot('Position',[0.03,0.83,0.12,0.12])
cmaplist3 = best_label_embedding(:,4);
cmapcolor3 = mat2gray(imresize(cbrewer2('Spectral',256), ...
    [length(unique(cmaplist3)),3]));
cmap3 = zeros(size(cmaplist3,1),3);
for k = 1:size(cmap3,1)
    cmap3(k,:) = cmapcolor3(cmaplist3(k,1),:);
end
scatter3(best_label_embedding(:,1),best_label_embedding(:,2),best_label_embedding(:,3),...
    5*ones(size(best_label_embedding(:,1))),cmap3,'filled');
axis square
set(gca,'XTickLabel',[],'YTickLabel',[],'ZTickLabel',[])
title('Behavior atlas')

show_len = 200;
box_x = 0.12;
box_y = 0.015;
start_x = 0.22;
start_y = 0.855;
inter_y = 0.015;
repeat_show_num = 3;
all_beh_idx = cell2mat(cellfun(@(x,y) y(1,4)*ones(size(x,2),1),...
    data_sample_cell(:,1),data_sample_cell(:,2),'UniformOutput',false));
for k = 1:repeat_show_num
    temph = subplot('Position',...
        [start_x,start_y+(k-1)*(inter_y+box_y),box_x,box_y]);
    imagesc(all_beh_idx((show_len*(k-1)+1):show_len*k)')
    colormap(temph,cmapcolor3)
    set(gca,'XTick',[],'YTick',[])
    if k == repeat_show_num
        title('Behavior sequences')
    end
end


%% state transition
% mean states
unique_groups = unique(cell2mat(group_compare(:,2)));
mean_states_cell = cell(size(unique_groups,1),1);
sep_states_cell = cell(size(unique_groups,1),1);
for k = 1:size(unique_groups,1)
    tempgroup = unique_groups(k);
    selgcp = group_compare(...
        tempgroup==cell2mat(group_compare(:,2)),5);
    sum_tm = zeros(size(selgcp{1}));
    cat_mat = [];
    for n = 1:size(selgcp,1)
        sum_tm = sum_tm+selgcp{n};
        cat_mat = cat(3,cat_mat,selgcp{n});
    end
    mean_tm = sum_tm./size(selgcp,1);
    mean_states_cell{k} = mean_tm;
    sep_states_cell{k} = cat_mat;
end

% calculate differences
p_mat = zeros(size(mean_states_cell{1}));

for m = 1:size(p_mat,1)
    for n = 1:size(p_mat,2)
        sel_g1 = reshape(sep_states_cell{1}(m,n,:),1,[]);
        sel_g2 = reshape(sep_states_cell{2}(m,n,:),1,[]);
        p_list = g2_ht(sel_g1,sel_g2);
        p_mat(m,n) = p_list(1);
    end
end

p_mat(isnan(p_mat)) = 1;

h_mat = p_mat<0.05;


%% transition matrix
start_x = 0.39;
start_y = 0.83;
box_xy = 0.15;
inter_x = 0.06;
inter_y = 0.02;

c_box_x = 0.005;
c_box_y = 0.05;
c_inter_x = 0.005;

cmap_tm_fix = cbrewer2('Reds',256);
cmap_tm_free = cbrewer2('Blues',256);
cmap_p = cbrewer2('RdBu',256);
h1 = subplot('Position',[start_x,start_y,box_xy,box_xy]);
imagesc(mean_states_cell{1})
min_c = min(mean_states_cell{1}(:));
max_c = max(mean_states_cell{1}(:));
colormap(h1,cmap_tm_fix)
set(gca,'XTick',[1,41],'YTick',[1,41])
title('Trapped partner')
ylabel('Past states')
xlabel('Current states')

h11 = subplot('Position',[start_x+box_xy+c_inter_x,...
    start_y+box_xy-c_box_y,c_box_x,c_box_y]);
imagesc(flipud((1:256)'))
colormap(h11,cmap_tm_fix)
set(gca,'XTick',[],'YTick',[])



h2 = subplot('Position',[start_x+box_xy+inter_x,start_y,box_xy,box_xy]);
imagesc(mean_states_cell{2})
min_c = min(mean_states_cell{2}(:));
max_c = max(mean_states_cell{2}(:));
colormap(h2,cmap_tm_free)
set(gca,'XTick',[1,41],'YTick',[1,41])
title('Free partner')
ylabel('Past states')
xlabel('Current states')

h21 = subplot('Position',[start_x+box_xy+inter_x+box_xy+c_inter_x,...
    start_y+box_xy-c_box_y,c_box_x,c_box_y]);
imagesc(flipud((1:256)'))
colormap(h21,cmap_tm_free)
set(gca,'XTick',[],'YTick',[])


h3 = subplot('Position',...
    [start_x+2*(box_xy+inter_x),start_y,box_xy,box_xy]);

comp_idx_mat = ones(size(mean_states_cell{1}))-2*...
    (mean_states_cell{1}>mean_states_cell{2});


show_p_mat = (1-p_mat).*comp_idx_mat;

imagesc(show_p_mat)
colormap(h3,cmap_p)
set(gca,'XTick',[1,41],'YTick',[1,41])
title('Differences')
ylabel('Past states')
xlabel('Current states')

h31 = subplot('Position',[start_x+2*(box_xy+inter_x)+box_xy+c_inter_x,...
    start_y+box_xy-c_box_y,c_box_x,c_box_y]);
imagesc(flipud((1:256)'))
colormap(h31,cmap_tm_fix)
set(gca,'XTick',[],'YTick',[])

h32 = subplot('Position',[...
    start_x+2*(box_xy+inter_x)+box_xy+c_inter_x+0.01,...
    start_y+box_xy-c_box_y,c_box_x,c_box_y]);
imagesc(flipud((1:256)'))
colormap(h32,cmap_tm_free)
set(gca,'XTick',[],'YTick',[])


% transition graph
filt_thres = 0.05;
filt_p_thres = 0.95;

[sL_fix,tL_fix,weightL_fix,GN_fix,GA_fix] = ...
    PGM_GraphPre(mean_states_cell{1});
[sL_free,tL_free,weightL_free,GN_free,GA_free] = ...
    PGM_GraphPre(mean_states_cell{2});

filt_idx_fix = weightL_fix>filt_thres;
filt_sL_fix = sL_fix(filt_idx_fix);
filt_tL_fix = tL_fix(filt_idx_fix);
filt_weightL_fix = weightL_fix(filt_idx_fix);


filt_idx_free = weightL_free>filt_thres;
filt_sL_free = sL_free(filt_idx_free);
filt_tL_free = tL_free(filt_idx_free);
filt_weightL_free = weightL_free(filt_idx_free);


fix_p_mat = -1*(show_p_mat<(-0.95)).*show_p_mat;
free_p_mat = (show_p_mat>0.95).*show_p_mat;

[sL_fix_p,tL_fix_p,weightL_fix_p,GN_fix_p,GA_fix_p] = ...
    PGM_GraphPre(fix_p_mat);
[sL_free_p,tL_free_p,weightL_free_p,GN_free_p,GA_free_p] = ...
    PGM_GraphPre(free_p_mat);

filt_idx_fix_p = weightL_fix_p>filt_p_thres;
filt_sL_fix_p = sL_fix_p(filt_idx_fix_p);
filt_tL_fix_p = tL_fix_p(filt_idx_fix_p);
filt_weightL_fix_p = weightL_fix_p(filt_idx_fix_p);


filt_idx_free_p = weightL_free_p>filt_p_thres;
filt_sL_free_p = sL_free_p(filt_idx_free_p);
filt_tL_free_p = tL_free_p(filt_idx_free_p);
filt_weightL_free_p = weightL_free_p(filt_idx_free_p);

pt_list = 1:41;
alpha = pt_list/max(pt_list)*2*pi;
r = 50;
x = r*cos(alpha);
y = r*sin(alpha);

% quantify line width
line_width_list = (1:5)/5;
node_size_index = 3;
show_edge = 3;
line_alpha = 0.5;

all_free_fix_weights = [filt_weightL_fix,filt_weightL_free];
[B,I] = sort(all_free_fix_weights);
all_lw_free_fix_list = zeros(size(all_free_fix_weights));
seg_len = round(length(all_lw_free_fix_list)/length(line_width_list));
for k = 1:length(line_width_list)
    all_lw_free_fix_list(((k-1)*seg_len+1):(k*seg_len)) = ...
        line_width_list(k);
end
all_lw_free_fix_list = all_lw_free_fix_list(1:length(all_free_fix_weights));
all_lw_free_fix_list(I) = all_lw_free_fix_list;

fix_line_width = all_lw_free_fix_list(1:length(filt_weightL_fix));
free_line_width = all_lw_free_fix_list((1+length(filt_weightL_fix)):...
    end);


all_free_fix_p_weights = [filt_weightL_fix_p,filt_weightL_free_p];
[B,I] = sort(all_free_fix_p_weights);
all_lw_free_fix_p_list = zeros(size(all_free_fix_p_weights));
seg_len = round(length(all_lw_free_fix_p_list)/length(line_width_list));
for k = 1:length(line_width_list)
    all_lw_free_fix_p_list(((k-1)*seg_len+1):(k*seg_len)) = ...
        line_width_list(k);
end
all_lw_free_fix_p_list = all_lw_free_fix_p_list(1:length(all_free_fix_p_weights));
all_lw_free_fix_p_list(I) = all_lw_free_fix_p_list;

fix_p_line_width = all_lw_free_fix_p_list(1:length(filt_weightL_fix_p));
free_p_line_width = all_lw_free_fix_p_list((1+length(filt_weightL_fix_p)):...
    end);

subplot('Position',[start_x,start_y-inter_y-box_xy,box_xy,box_xy])
% plot transition
for k = 1:length(filt_weightL_fix)
    temp_start_x = x(filt_sL_fix(k));
    temp_start_y = y(filt_sL_fix(k));
    temp_end_x = x(filt_tL_fix(k));
    temp_end_y = y(filt_tL_fix(k));
    if filt_sL_fix(k)~=filt_tL_fix(k) % transition
        tempp = plot([temp_start_x,temp_end_x],[temp_start_y,temp_end_y],'-',...
            'LineWidth',fix_line_width(k),'Color',cmap_tm_fix(128,:));
        tempp.Color(4) = line_alpha;
    else
        
    end
    hold on
end
% plot basic node
for k = pt_list
    plot(x(k),y(k),'o','MarkerEdgeColor','k',...
        'MarkerFaceColor',cmap_tm_fix(192,:),'MarkerSize',3)
%     text(x(k),y(k),num2str(k))
    hold on
end
% plot transition node
for k = 1:length(filt_weightL_fix)
    temp_start_x = x(filt_sL_fix(k));
    temp_start_y = y(filt_sL_fix(k));
    temp_end_x = x(filt_tL_fix(k));
    temp_end_y = y(filt_tL_fix(k));
    if filt_sL_fix(k)~=filt_tL_fix(k) % transition
    else
        plot(temp_start_x,temp_start_y,'o','MarkerEdgeColor','k',...
        'MarkerFaceColor',cmap_tm_fix(192,:),...
        'MarkerSize',fix_line_width(k)*node_size_index+3)
    end
    hold on
end

hold off
axis([min(x)-show_edge,max(x)+show_edge,...
    min(y)-show_edge,max(y)+show_edge])
axis off


subplot('Position',[start_x+box_xy+inter_x,start_y-inter_y-box_xy,box_xy,box_xy])
% plot transition
for k = 1:length(filt_weightL_free)
    temp_start_x = x(filt_sL_free(k));
    temp_start_y = y(filt_sL_free(k));
    temp_end_x = x(filt_tL_free(k));
    temp_end_y = y(filt_tL_free(k));
    if filt_sL_free(k)~=filt_tL_free(k) % transition
        tempp = plot([temp_start_x,temp_end_x],[temp_start_y,temp_end_y],'-',...
            'LineWidth',free_line_width(k),'Color',cmap_tm_free(128,:));
        tempp.Color(4) = line_alpha;
    else
        
    end
    hold on
end
% plot basic node
for k = pt_list
    plot(x(k),y(k),'o','MarkerEdgeColor','k',...
        'MarkerFaceColor',cmap_tm_free(192,:),'MarkerSize',3)
    hold on
end
% plot transition node
for k = 1:length(filt_weightL_free)
    temp_start_x = x(filt_sL_free(k));
    temp_start_y = y(filt_sL_free(k));
    temp_end_x = x(filt_tL_free(k));
    temp_end_y = y(filt_tL_free(k));
    if filt_sL_free(k)~=filt_tL_free(k) % transition
    else
        plot(temp_start_x,temp_start_y,'o','MarkerEdgeColor','k',...
        'MarkerFaceColor',cmap_tm_free(192,:),...
        'MarkerSize',free_line_width(k)*node_size_index+3)
    end
    hold on
end

hold off
axis([min(x)-show_edge,max(x)+show_edge,...
    min(y)-show_edge,max(y)+show_edge])
axis off



subplot('Position',[start_x+2*(box_xy+inter_x),start_y-inter_y-box_xy,box_xy,box_xy])
% plot transition
for k = 1:length(filt_weightL_fix_p)
    temp_start_x = x(filt_sL_fix_p(k));
    temp_start_y = y(filt_sL_fix_p(k));
    temp_end_x = x(filt_tL_fix_p(k));
    temp_end_y = y(filt_tL_fix_p(k));
    if filt_sL_fix_p(k)~=filt_tL_fix_p(k) % transition
        tempp = plot([temp_start_x,temp_end_x],[temp_start_y,temp_end_y],'-',...
            'LineWidth',fix_p_line_width(k),'Color',cmap_tm_fix(128,:));
        tempp.Color(4) = line_alpha;
    else
        
    end
    hold on
end

for k = 1:length(filt_weightL_free_p)
    temp_start_x = x(filt_sL_free_p(k));
    temp_start_y = y(filt_sL_free_p(k));
    temp_end_x = x(filt_tL_free_p(k));
    temp_end_y = y(filt_tL_free_p(k));
    if filt_sL_free_p(k)~=filt_tL_free_p(k) % transition
        tempp = plot([temp_start_x,temp_end_x],[temp_start_y,temp_end_y],'-',...
            'LineWidth',free_p_line_width(k),'Color',cmap_tm_free(128,:));
        tempp.Color(4) = line_alpha;
    else
        
    end
    hold on
end

% plot basic node
for k = pt_list
    plot(x(k),y(k),'o','MarkerEdgeColor','k',...
        'MarkerFaceColor','k','MarkerSize',3)
%     text(x(k),y(k),num2str(k))
    hold on
end

% plot transition node
for k = 1:length(filt_weightL_fix_p)
    temp_start_x = x(filt_sL_fix_p(k));
    temp_start_y = y(filt_sL_fix_p(k));
    temp_end_x = x(filt_tL_fix_p(k));
    temp_end_y = y(filt_tL_fix_p(k));
    if filt_sL_fix_p(k)~=filt_tL_fix_p(k) % transition
    else
        plot(temp_start_x,temp_start_y,'o','MarkerEdgeColor','k',...
        'MarkerFaceColor',cmap_tm_fix(192,:),...
        'MarkerSize',fix_p_line_width(k)*node_size_index+3)
    end
    hold on
end


% plot transition node
for k = 1:length(filt_weightL_free_p)
    temp_start_x = x(filt_sL_free_p(k));
    temp_start_y = y(filt_sL_free_p(k));
    temp_end_x = x(filt_tL_free_p(k));
    temp_end_y = y(filt_tL_free_p(k));
    if filt_sL_free_p(k)~=filt_tL_free_p(k) % transition
    else
        plot(temp_start_x,temp_start_y,'o','MarkerEdgeColor','k',...
        'MarkerFaceColor',cmap_tm_free(192,:),...
        'MarkerSize',free_p_line_width(k)*node_size_index+3)
    end
    hold on
end

hold off
axis([min(x)-show_edge,max(x)+show_edge,...
    min(y)-show_edge,max(y)+show_edge])
axis off

%% plot continous body language
clus_clr = cbrewer2('Spectral',ctn.clus_num);
heat_clr = cbrewer2('BuPu',256);
start_x = 0.03;
start_y = 0.03;
box_y = 0.62;
inter_x = 0.002;
% dendrogram
den_x = 0.02;
subplot('Position',[start_x,start_y,den_x,box_y]);
new_Z = ctn.Z;
new_Z(:,3) = 1:size(new_Z,1);
[~,~,P_sort] = dendrogram(new_Z,0);
view(-90,-90)
axis off
axis([0.5,max(new_Z(:,3))+1.5,0.5,size(new_Z,1)+1.5])

% clus index
clus_x = 0.008;
temph = subplot('Position',[start_x+inter_x+den_x,start_y,clus_x,box_y]);
imagesc(ctn.T_sort)
clus_diff = [diff(ctn.T_sort);0];
bk_line_pos = find(clus_diff~=0);
hold on
for k = 1:size(bk_line_pos,1)
    plot([-5,5],[bk_line_pos(k),bk_line_pos(k)],'-k')
end
box on
set(gca,'XTick',[],'YTick',[])
colormap(temph,clus_clr)

% body language matrix
mat_x = 0.15;
temph = subplot('Position',[start_x+2*inter_x+den_x+clus_x,...
    start_y,mat_x,box_y]);
imagesc(ctn.sort_sel_show_ctn_count_mat);
colormap(temph,heat_clr)
box off
hold on
plot([0.5,30.5],[1,1],'k-','LineWidth',0.25)
hold on
plot([15.5,15.5],[1,size(ctn.sort_sel_show_ctn_count_mat,1)],...
    'k-','LineWidth',0.25)
hold on
plot([30.5,30.5],[1,size(ctn.sort_sel_show_ctn_count_mat,1)],...
    'k-','LineWidth',0.25)
hold off
set(gca,'YTick',[])
set(gca,'XTick',[0.5,15.5,30.5])
set(gca,'TickDir','out')
set(gca,"XTickLabel",[])
xlabel('Trapped         Free  ')

min_mat = min(ctn.sort_sel_show_ctn_count_mat(:));
max_mat = max(ctn.sort_sel_show_ctn_count_mat(:));
% colorbar
temph = subplot('Position',[start_x+2*inter_x+den_x+clus_x,...
    start_y+box_y+inter_x,mat_x/2,0.005]);
imagesc(1:256)
colormap(temph,heat_clr)
box on
title('Fractions')
set(gca,'XTick',[],'YTick',[])

% body language word cloud
each_box_y = box_y/size(ctn.sort_sel_show_ctn_count_mat,1);
top_start_y = start_y+box_y;

add_diff_t = diff([0;ctn.T_sort]);
unsort_unique_T = ctn.T_sort(add_diff_t~=0);

sub_box_x = 0.35;
last_pos_y = top_start_y;

trap_ctn = ctn.sort_sel_show_ctn_count_mat(:,1:15);
free_ctn = ctn.sort_sel_show_ctn_count_mat(:,16:end);
mean_trap_ctn = zeros(size(ctn.mean_ctn_cell,1),1);
mean_free_ctn = zeros(size(ctn.mean_ctn_cell,1),1);

end_T = [bk_line_pos;length(ctn.T_sort)];
start_T = [0;(end_T(1:(end-1)))]+1;
for k = 1:size(mean_trap_ctn,1)
    mean_trap_ctn(k) = mean(mean(trap_ctn(start_T(k):end_T(k),:)));
    mean_free_ctn(k) = mean(mean(free_ctn(start_T(k):end_T(k),:)));
end

prob_seq_cell = cell(size(ctn.mean_ctn_cell,1),3);

for k = 1:size(ctn.mean_ctn_cell,1)
    %%
    temp_ctn = ctn.mean_ctn_cell{k};
    num_y = sum(unsort_unique_T(k)==ctn.T_sort);
    pos_y = last_pos_y-num_y*each_box_y;
    sub_box_y = num_y*each_box_y;
    each_box_x = sub_box_x/size(temp_ctn,2);

    tempprobcell = cell(1,size(temp_ctn,2));
    tempnamecell = cell(1,size(temp_ctn,2));
    
    for m = 1:size(temp_ctn,2)
        tt_ctn = temp_ctn{m};
        sel_beh = beh_class(tt_ctn(:,1));
        size_beh = tt_ctn(:,2);
        % transform to quantity size
        unique_size = unique(size_beh);
        qs_list = 1+(1:length(unique_size))/10;
        qs_size_beh = size_beh;
        for n = 1:length(unique_size)
            sel_idx = unique_size(n)==size_beh;
            qs_size_beh(sel_idx) = qs_list(n);
        end
        subplot('Position',...
        [start_x+3*inter_x+den_x+clus_x+mat_x+(m-1)*each_box_x,...
        pos_y,each_box_x,sub_box_y])
        %%
%         figure
        % use my own word cloud
%         [sort_size_beh,sort_size_I] = sort(size_beh,'descend');
%         sort_size_beh = sqrt(sort_size_beh)/sum(sort_size_beh);
%         sort_sel_beh = sel_beh(sort_size_I);
%         
%         text_start_x = 0;
%         text_start_y = 1;
%         start_size_beh = 0;
%         for n = 1:size(sort_size_beh,1)
%             text(text_start_x,...
%                 text_start_y-start_size_beh-sort_size_beh(n)/3,...
%                 sort_sel_beh{n},'Interpreter','none',...
%                 'FontUnits','normalized',...
%                 'FontSize',sort_size_beh(n)/1.1)
% %             disp(start_size_beh)
%             start_size_beh = start_size_beh+sort_size_beh(n);
%         end
%         axis([0,1,-0.1,1])

        if mean_trap_ctn(k)>mean_free_ctn(k)
            wordcloud(sel_beh,qs_size_beh,'Shape','rectangle',...
                'LayoutNum',3,'HighlightColor',cmap_tm_fix(end,:))
            group_idx = 'fix';
        else
            wordcloud(sel_beh,qs_size_beh,'Shape','rectangle',...
                'LayoutNum',3,'HighlightColor',cmap_tm_free(end,:))
            group_idx = 'free';
        end

        %% append data
        tempprobcell{m} = size_beh;
        tempnamecell{m} = sel_beh;
    end
    % iterate
    last_pos_y = pos_y;

    prob_seq_cell{k,1} = tempprobcell;
    prob_seq_cell{k,2} = tempnamecell;
    prob_seq_cell{k,3} = group_idx;
end

%% separately compare the motifs with sequences
all_diff_idx = [...
    29,23,30,34,35,36]';%第一个是all的

all_diff_name = {...
    'Rising';...
    'Rearing';...
    'Right turning';...
    'Left turning';...
    'Approaching';...
    'Walking sniffing'};

%% plot canvas
hall = figure(2);
set(hall,'Position',[0,0,800,800])
set(hall,'color','white');

%% 序列分布，分fix和free


free_prob_seq_cell = prob_seq_cell(...
    strcmp(prob_seq_cell(:,3),'free'),:);
fix_prob_seq_cell = prob_seq_cell(...
    strcmp(prob_seq_cell(:,3),'fix'),:);

free_pos_prob_diff = cell(size(all_diff_idx,1),3);

for m = 1:size(free_pos_prob_diff,1)
    tempidx = all_diff_idx(m);
    free_pos_prob_diff{m,1} = tempidx;
    tempname = beh_class{tempidx};
    free_pos_prob_diff{m,2} = tempname;

    %% 
    tempmat = [];
    for n = 1:size(free_prob_seq_cell,1)
        tempprob = free_prob_seq_cell{n,1};
        tempname = free_prob_seq_cell{n,2};

        for k = 1:length(tempname)
            ttname = tempname{k};
            ttprob = tempprob{k};
            selidx = strcmp(ttname,free_pos_prob_diff{m,2});
            for p = 1:size(selidx,1)
                if selidx(p) == 1
                    tempmat = [tempmat;...
                        [k,ttprob(p)]];
                end
            end
        end
    end

    free_pos_prob_diff{m,3} = tempmat;
end

fix_pos_prob_diff = cell(size(all_diff_idx,1),3);

for m = 1:size(fix_pos_prob_diff,1)
    tempidx = all_diff_idx(m);
    fix_pos_prob_diff{m,1} = tempidx;
    tempname = beh_class{tempidx};
    fix_pos_prob_diff{m,2} = tempname;

    %% 
    tempmat = [];
    for n = 1:size(fix_prob_seq_cell,1)
        tempprob = fix_prob_seq_cell{n,1};
        tempname = fix_prob_seq_cell{n,2};

        for k = 1:length(tempname)
            ttname = tempname{k};
            ttprob = tempprob{k};
            selidx = strcmp(ttname,fix_pos_prob_diff{m,2});
            for p = 1:size(selidx,1)
                if selidx(p) == 1
                    tempmat = [tempmat;...
                        [k,ttprob(p)]];
                end
            end
        end
    end

    fix_pos_prob_diff{m,3} = tempmat;
end

%% 
x_list = 1:6;
show_free = zeros(size(x_list,2),size(free_pos_prob_diff,1));
for k = 1:size(show_free,2)
    tempmat = free_pos_prob_diff{k,3};
    for m = x_list
        selidx = tempmat(:,1)==m;
        seldata = tempmat(selidx,2);
        show_free(m,k) = mean(seldata);
    end
end

show_fix = zeros(size(x_list,2),size(fix_pos_prob_diff,1));
for k = 1:size(show_fix,2)
    tempmat = fix_pos_prob_diff{k,3};
    for m = x_list
        selidx = tempmat(:,1)==m;
        seldata = tempmat(selidx,2);
        show_fix(m,k) = mean(seldata);
    end
end

show_free(isnan(show_free)) = 0;
show_fix(isnan(show_fix)) = 0;
%% show
start_x = 0.08;
start_y = 0.8;

box_x = 0.2;
box_y = 0.15;

inter_x = 0.0;

temph = subplot('Position',[start_x,start_y,box_x,box_y]);
imagesc(show_free')
set(gca,'XTick',x_list)
set(gca,'YTick',x_list)
set(gca,'YTickLabel',all_diff_name,...
    'TickLabelInterpreter','none')
set(gca,'TickDir','out')
set(gca,'FontSize',6)
box off
colormap(temph,[1,1,1;cmap_tm_free])
colorbar

title('Sequences in trapped group')
xlabel('Time step')

temph = subplot('Position',[start_x+box_x+inter_x,...
    start_y,box_x,box_y]);
imagesc(show_fix')
set(gca,'XTick',x_list)
set(gca,'YTick',x_list)
set(gca,'YTickLabel',[])
set(gca,'TickDir','out')
set(gca,'FontSize',6)
box off
colormap(temph,[1,1,1;cmap_tm_fix])
colorbar

title('Sequences in free group')
xlabel('Time step')

%% 序列中出现的平均概率，分free和fix
start_x = 0.49;
start_y = 0.8;

box_x = 0.15;
box_y = 0.15;

prob_cell = cell(size(free_pos_prob_diff,1),3);
prob_cell(:,1) = all_diff_name;

for k = 1:size(prob_cell,1)
    prob_cell{k,2} = free_pos_prob_diff{k,3}(:,2);
    prob_cell{k,3} = fix_pos_prob_diff{k,3}(:,2);
end

stat_prob_cell = cellfun(@(x) x',...
    prob_cell(:,2:3),'UniformOutput',false);

mean_prob = cell2mat(cellfun(@(x) mean(x),...
    prob_cell(:,2:3),'UniformOutput',false));

std_prob = cell2mat(cellfun(@(x) std(x)./sqrt(length(x)),...
    prob_cell(:,2:3),'UniformOutput',false));

x_bias = 0.2;

bar_w = 0.25;

dot_bias = bar_w/2;

bar_c = [cmap_tm_free(128,:);...
    cmap_tm_fix(128,:)];

x_list_cell = {x_list-x_bias;x_list+x_bias};
subplot('Position',[start_x,start_y,box_x,box_y])
for k = 1:2
    bar(x_list_cell{k},mean_prob(:,k),bar_w,...
        'FaceColor',bar_c(k,:))
    hold on
    errorbar(x_list_cell{k},mean_prob(:,k),...
        std_prob(:,k),...
        'LineStyle','none',...
        'CapSize',2,...
        'Color','k')
    hold on
    selprob = prob_cell(:,k+1);
    for m = 1:size(selprob,1)
        plot(dot_bias+x_list_cell{k}(m)*...
            ones(length(selprob{m}),1),...
            selprob{m},'o',...
            'MarkerFaceColor','w',...
            'MarkerEdgeColor','k',...
            'LineWidth',0.25,...
            'MarkerSize',2)
        hold on
    end
end
hold off

box off
set(gca,'TickDir','out')
set(gca,'FontSize',6)
set(gca,'XTick',x_list)
set(gca,'XTickLabel',all_diff_name)
set(gca,'XTickLabelRotation',45)
ylabel('Probability')

axis([0.3,6.7,0,1.2])

%% 序列中出现的位置，分free和fix
start_x = 0.66;
start_y = 0.8;

box_x = 0.15;
box_y = 0.15;

seq_cell = cell(size(free_pos_prob_diff,1),3);
seq_cell(:,1) = all_diff_name;

for k = 1:size(seq_cell,1)
    seq_cell{k,2} = free_pos_prob_diff{k,3}(:,1);
    seq_cell{k,3} = fix_pos_prob_diff{k,3}(:,1);
end

stat_seq_cell = cellfun(@(x) x',...
    seq_cell(:,2:3),'UniformOutput',false);

mean_prob = cell2mat(cellfun(@(x) mean(x),...
    seq_cell(:,2:3),'UniformOutput',false));

std_prob = cell2mat(cellfun(@(x) std(x)./sqrt(length(x)),...
    seq_cell(:,2:3),'UniformOutput',false));

x_bias = 0.2;

bar_w = 0.25;

dot_bias = bar_w/2;

bar_c = [cmap_tm_free(128,:);...
    cmap_tm_fix(128,:)];

x_list_cell = {x_list-x_bias;x_list+x_bias};
subplot('Position',[start_x,start_y,box_x,box_y])
for k = 1:2
    bar(x_list_cell{k},mean_prob(:,k),bar_w,...
        'FaceColor',bar_c(k,:))
    hold on
    errorbar(x_list_cell{k},mean_prob(:,k),...
        std_prob(:,k),...
        'LineStyle','none',...
        'CapSize',2,...
        'Color','k')
    hold on
    selprob = seq_cell(:,k+1);
    for m = 1:size(selprob,1)
        plot(dot_bias+x_list_cell{k}(m)*...
            ones(length(selprob{m}),1),...
            selprob{m},'o',...
            'MarkerFaceColor','w',...
            'MarkerEdgeColor','k',...
            'LineWidth',0.25,...
            'MarkerSize',2)
        hold on
    end
end
hold off

box off
set(gca,'TickDir','out')
set(gca,'FontSize',6)
set(gca,'XTick',x_list)
set(gca,'YTick',x_list)
set(gca,'XTickLabel',all_diff_name)
set(gca,'XTickLabelRotation',45)
ylabel('Time step')

axis([0.3,6.7,0,6.2])

%% 序列中出现相应行为模块百分比
start_x = 0.85;
start_y = 0.8;

box_x = 0.15;
box_y = 0.15;

free_perc_cell = cell(size(all_diff_name,1),1);

for k = 1:size(free_perc_cell,1)
    selname = beh_class(all_diff_idx(k));
    cmp_list = zeros(size(free_prob_seq_cell,1),1);
    for m = 1:size(free_prob_seq_cell,1)
        tempname = free_prob_seq_cell{m,2};
        cmpnum = 0;
        allnum = 0;
        for n = 1:size(tempname,2)
            cmpnum = cmpnum+sum(strcmp(selname,tempname{n}));
            allnum = allnum+length(tempname{n});
        end
        cmp_list(m,1) = cmpnum/allnum;
    end
    free_perc_cell{k,1} = cmp_list';
end

free_perc_mat = cell2mat(free_perc_cell);

fix_perc_cell = cell(size(all_diff_name,1),1);

for k = 1:size(fix_perc_cell,1)
    selname = beh_class(all_diff_idx(k));
    cmp_list = zeros(size(fix_prob_seq_cell,1),1);
    for m = 1:size(fix_prob_seq_cell,1)
        tempname = fix_prob_seq_cell{m,2};
        cmpnum = 0;
        allnum = 0;
        for n = 1:size(tempname,2)
            cmpnum = cmpnum+sum(strcmp(selname,tempname{n}));
            allnum = allnum+length(tempname{n});
        end
        cmp_list(m,1) = cmpnum/allnum;
    end
    fix_perc_cell{k,1} = cmp_list';
end

fix_perc_mat = cell2mat(fix_perc_cell);

perc_cell = {free_perc_mat,fix_perc_mat};

mean_perc = [mean(free_perc_mat,2),mean(fix_perc_mat,2)];
std_perc = [std(free_perc_mat,[],2)./sqrt(12),...
    std(fix_perc_mat,[],2)./sqrt(6)];

subplot('Position',[start_x,start_y,box_x,box_y])
for k = 1:2
    bar(x_list_cell{k},mean_perc(:,k),bar_w,...
        'FaceColor',bar_c(k,:))
    hold on
    errorbar(x_list_cell{k},mean_perc(:,k),...
        std_perc(:,k),...
        'LineStyle','none',...
        'CapSize',2,...
        'Color','k')
    hold on
    selperc = perc_cell{k}';
    for m = 1:size(selperc,2)
        plot(dot_bias+x_list_cell{k}(m)*...
            ones(size(selperc,1),1),...
            selperc(:,m),'o',...
            'MarkerFaceColor','w',...
            'MarkerEdgeColor','k',...
            'LineWidth',0.25,...
            'MarkerSize',2)
        hold on
    end
end
hold off

box off
set(gca,'TickDir','out')
set(gca,'FontSize',6)
set(gca,'XTick',x_list)
set(gca,'XTickLabel',all_diff_name)
set(gca,'XTickLabelRotation',45)
ylabel('Ratio')

axis([0.3,6.7,0,0.5])


































