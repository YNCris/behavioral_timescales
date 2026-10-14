%{
    fig2, identify body language
    use pose as alphabet to identify inner patterns
%}
clear all
close all
addpath(genpath(pwd))
%% plot canvas
hall = figure(1);
set(hall,'Position',[900,100,800,800])
set(hall,'color','white');
%% set path
rootpath = ['X:\hanyaning\multi_mice_test\Social_analysis\' ...
    'data\MTPM_social_20220228_all'];
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

for k = 1:size(ctn.mean_ctn_cell,1)
    %%
    temp_ctn = ctn.mean_ctn_cell{k};
    num_y = sum(unsort_unique_T(k)==ctn.T_sort);
    pos_y = last_pos_y-num_y*each_box_y;
    sub_box_y = num_y*each_box_y;
    each_box_x = sub_box_x/size(temp_ctn,2);
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
        else
            wordcloud(sel_beh,qs_size_beh,'Shape','rectangle',...
                'LayoutNum',3,'HighlightColor',cmap_tm_free(end,:))
        end
    end
    % iterate
    last_pos_y = pos_y;
end

%% compare methods
% show increase fix and free transitions
p_sign_mat = show_p_mat;
p_sign_mat(p_sign_mat>-0.95&p_sign_mat<0.95) = 0;
[sL_p_sign,tL_p_sign,weightL_p_sign,GN_p_sign,GA_p_sign] = ...
    PGM_GraphPre(p_sign_mat);
sel_weightL_p_sign = weightL_p_sign~=0;
sel_sL_p_sign = sL_p_sign(sel_weightL_p_sign);
sel_tL_p_sign = tL_p_sign(sel_weightL_p_sign);
sel_weightL_p_sign = weightL_p_sign(sel_weightL_p_sign);
sel_sL_p_sign_beh = beh_class(sel_sL_p_sign);
sel_tL_p_sign_beh = beh_class(sel_tL_p_sign);
same_idx = sel_sL_p_sign==sel_tL_p_sign;
sel_weightL_p_sign(same_idx~=0) = [];
sel_sL_p_sign_beh(same_idx~=0) = [];
sel_tL_p_sign_beh(same_idx~=0) = [];

all_lw_p_sign_list = 2*quantify_weights2line(...
    abs(sel_weightL_p_sign),line_width_list);

GN = graph(sel_sL_p_sign_beh,sel_tL_p_sign_beh,all_lw_p_sign_list);%无向图
GA = digraph(sel_sL_p_sign_beh,sel_tL_p_sign_beh,all_lw_p_sign_list);%无向图
subplot('Position',[0.58,0.42,0.39,0.24])
newh = plot(GA,'Layout','layered','LineWidth',all_lw_p_sign_list);
fix_trans_idx = sel_weightL_p_sign<0;
free_trans_idx = sel_weightL_p_sign>0;
fix_sel_sL_p_sign_beh = sel_sL_p_sign_beh(fix_trans_idx);
fix_sel_tL_p_sign_beh = sel_tL_p_sign_beh(fix_trans_idx);
free_sel_sL_p_sign_beh = sel_sL_p_sign_beh(free_trans_idx);
free_sel_tL_p_sign_beh = sel_tL_p_sign_beh(free_trans_idx);
highlight(newh,fix_sel_sL_p_sign_beh,fix_sel_tL_p_sign_beh,...
    'EdgeColor',cmap_tm_fix(128,:))
highlight(newh,free_sel_sL_p_sign_beh,free_sel_tL_p_sign_beh,...
    'EdgeColor',cmap_tm_free(128,:))
newh.NodeFontSize = 0.1;
newh.NodeColor = 'k';
newh.MarkerSize = 2;
newh.Interpreter = 'none';
getx = newh.XData;
gety = newh.YData;
get_text = newh.NodeLabel;

for k = 1:length(get_text)
    text(getx(k),gety(k),get_text{k},'FontSize',8,'Interpreter','none')
end

axis off

%% compare the resolution of methods
class_label = {'Trapped','Free'};
class_cmap_fix = cmap_tm_fix(192,:);
class_cmap_free = cmap_tm_free(192,:);
class_cmap_all = [...
    ones(15,1)*class_cmap_fix;...
    ones(15,1)*class_cmap_free];

class_list = [...
    ones(15,1);...
    2*ones(15,1)];


tm_feat_mat = zeros(size(group_compare,1),...
    size(group_compare{1,5},1)*size(group_compare{1,5},2))';
for k = 1:size(tm_feat_mat,2)
    temp_tm = group_compare{k,5};
    res_tm = reshape(temp_tm,[size(tm_feat_mat,1),1]);
    tm_feat_mat(:,k) = res_tm;
end
tm_p_sign_mat = reshape(p_sign_mat~=0,[size(tm_feat_mat,1),1]);
tm_feat_mat_sign = tm_feat_mat(tm_p_sign_mat,:);

ctn_feat_mat = ctn.sort_sel_show_ctn_count_mat;


holdout = 0.4;
rand_list = 1:100;

X_tm = tm_feat_mat_sign';
X_ctn = ctn_feat_mat';
y_tm = logical(class_list-1);
y_ctn = y_tm;

cm_tm_cell = cell(size(rand_list))';
cm_ctn_cell = cell(size(rand_list))';

precision_tm_cell = cell(size(rand_list))';
recall_tm_cell = cell(size(rand_list))';
f1score_tm_cell = cell(size(rand_list))';
accuracy_tm_cell = cell(size(rand_list))';

precision_ctn_cell = cell(size(rand_list))';
recall_ctn_cell = cell(size(rand_list))';
f1score_ctn_cell = cell(size(rand_list))';
accuracy_ctn_cell = cell(size(rand_list))';

cm_tm_sum = zeros(2,2);
cm_ctn_sum = zeros(2,2);

for k = rand_list
    rng(k) % for reproducibility
    
    % transition matrix (tm)
    [XTrain_tm,yTrain_tm,XTest_tm,yTest_tm] = sep_train_test(...
        X_tm,y_tm,holdout);
    [coef_tm,dev_tm] = glmfit(XTrain_tm,yTrain_tm,'binomial','logit');
%     coef_tm = lasso_rg_glm(XTrain_tm,yTrain_tm,3);
    yhat_tm = glmval(coef_tm,XTest_tm,'logit');
    yhatBinom_tm = (yhat_tm>=0.5);
    % figure
    % c_tm = confusionchart(yTest_tm,yhatBinom_tm);
    c_tm = confusionmat(yTest_tm,yhatBinom_tm);

    TP0 = c_tm(1,1);
    FP0 = c_tm(2,1);
    FN0 = c_tm(1,2);
    TN0 = c_tm(2,2);

    [precision0_tm,recall0_tm,f1score0_tm,accuracy0_tm] = ...
    pr_f1_acc(TP0,FP0,FN0,TN0);

    
    TP1 = c_tm(2,2);
    FP1 = c_tm(1,2);
    FN1 = c_tm(2,1);
    TN1 = c_tm(1,1);

    [precision1_tm,recall1_tm,f1score1_tm,accuracy1_tm] = ...
    pr_f1_acc(TP1,FP1,FN1,TN1);

    precision_tm_cell{k} = [precision0_tm,precision1_tm];
    recall_tm_cell{k} = [recall0_tm,recall1_tm];
    f1score_tm_cell{k} = [f1score0_tm,f1score1_tm];
    accuracy_tm_cell{k} = accuracy0_tm;
    

    % continous transformer (ctn)
    [XTrain_ctn,yTrain_ctn,XTest_ctn,yTest_ctn] = sep_train_test(...
        X_ctn,y_ctn,holdout);
%     coef_ctn = lasso_rg_glm(XTrain_ctn,yTrain_ctn,3);
    [coef_ctn,dev_ctn] = glmfit(XTrain_ctn,yTrain_ctn,'binomial','logit');
    yhat_ctn = glmval(coef_ctn,XTest_ctn,'logit');
    yhatBinom_ctn = (yhat_ctn>=0.5);
%     figure
%     c_ctn = confusionchart(yTest_ctn,yhatBinom_ctn);
    c_ctn = confusionmat(yTest_ctn,yhatBinom_ctn);

    
    TP0 = c_ctn(1,1);
    FP0 = c_ctn(2,1);
    FN0 = c_ctn(1,2);
    TN0 = c_ctn(2,2);

    [precision0_ctn,recall0_ctn,f1score0_ctn,accuracy0_ctn] = ...
    pr_f1_acc(TP0,FP0,FN0,TN0);

    
    TP1 = c_ctn(2,2);
    FP1 = c_ctn(1,2);
    FN1 = c_ctn(2,1);
    TN1 = c_ctn(1,1);

    [precision1_ctn,recall1_ctn,f1score1_ctn,accuracy1_ctn] = ...
    pr_f1_acc(TP1,FP1,FN1,TN1);

    precision_ctn_cell{k} = [precision0_ctn,precision1_ctn];
    recall_ctn_cell{k} = [recall0_ctn,recall1_ctn];
    f1score_ctn_cell{k} = [f1score0_ctn,f1score1_ctn];
    accuracy_ctn_cell{k} = accuracy0_ctn;


    %
    cm_tm_cell{k} = c_tm;
    cm_ctn_cell{k} = c_ctn;

    cm_tm_sum = c_tm+cm_tm_sum;
    cm_ctn_sum = c_ctn+cm_ctn_sum;

    disp(k)
end

cm_tm_sum_norm = cm_tm_sum./sum(cm_tm_sum(1,:));
cm_ctn_sum_norm = cm_ctn_sum./sum(cm_ctn_sum(1,:));

%% show confusion matrix
group_labels = {'Markov','BL-BERT'};
cm_cmap = flipud(cbrewer2('RdBu'));
mk_clr = cmap_tm_free(128,:);
tr_clr = cmap_tm_fix(128,:);
start_x = 0.6;
start_y = 0.27;
box_size = 0.115;
inter_x = 0.006;
temph_tm = subplot('Position',[start_x,start_y,box_size,box_size]);
imagesc(cm_tm_sum_norm,[0,1])
for m = 1:size(cm_tm_sum_norm,1)
    for n = 1:size(cm_tm_sum_norm,2)
        text(m-0.3,n,num2str(cm_tm_sum_norm(n,m),'%.2f'))
    end
end
colormap(temph_tm,cm_cmap)
title(group_labels{1})
set(gca,'XTick',[1,2],'YTick',[1,2])
set(gca,'XTickLabel',class_label)
set(gca,'YTickLabel',class_label,'YTickLabelRotation',90)
set(gca,'TickLength',[0,0])

temph_ctn = subplot('Position',[start_x+box_size+inter_x,start_y,box_size,box_size]);
imagesc(cm_ctn_sum_norm,[0,1])
for m = 1:size(cm_ctn_sum_norm,1)
    for n = 1:size(cm_ctn_sum_norm,2)
        text(m-0.3,n,num2str(cm_ctn_sum_norm(n,m),'%.2f'))
    end
end
colormap(temph_ctn,cm_cmap)
title(group_labels{2})
set(gca,'XTick',[1,2],'YTick',[])
set(gca,'XTickLabel',class_label)
% set(gca,'YTickLabel',class_label,'YTickLabelRotation',90)
set(gca,'TickLength',[0,0])

cmap_bar_h = 0.05;
temph = subplot('Position',[start_x+2*box_size+inter_x+0.005,...
    start_y+box_size-cmap_bar_h,0.005,cmap_bar_h]);
imagesc(flipud((1:256)'))
colormap(temph,cm_cmap)
set(gca,'XTick',[],'YTick',[])

% compare accuracy
accuracy_tm_list = cell2mat(accuracy_tm_cell);
accuracy_ctn_list = cell2mat(accuracy_ctn_cell);
mean_accuracy_tm = mean(accuracy_tm_list);
mean_accuracy_ctn = mean(accuracy_ctn_list);
std_accuracy_tm = std(accuracy_tm_list);
std_accuracy_ctn = std(accuracy_ctn_list);
subplot('Position',[start_x+2*box_size+inter_x+0.06,start_y,...
    0.08,0.15]);
bar(1,mean_accuracy_tm,'FaceColor',mk_clr)
hold on
bar(2,mean_accuracy_ctn,'FaceColor',tr_clr)
hold on
errorbar(1,mean_accuracy_tm,std_accuracy_tm,'Color','k')
hold on
errorbar(2,mean_accuracy_ctn,std_accuracy_ctn,'Color','k')
hold on
rng('default')
for k = 1:length(accuracy_tm_list)
    plot(1+(rand(1)-0.5)/3,accuracy_tm_list(k),'ko','MarkerSize',2,...
        'MarkerFaceColor','w','LineWidth',0.25)
end
hold on
rng('default')
for k = 1:length(accuracy_ctn_list)
    plot(2+(rand(1)-0.5)/3,accuracy_ctn_list(k),'ko','MarkerSize',2,...
        'MarkerFaceColor','w','LineWidth',0.25)
end
hold off
ylabel('Accuracy')
set(gca,'XTick',[1,2])
set(gca,'TickDir','out')
set(gca,'XTickLabel',group_labels)
set(gca,'YTick',[0,1])
axis([0.3,2.7,0,1])
box off
%% compare each class (precision, recall, f1score)
precision_tm_mat = cell2mat(precision_tm_cell);
recall_tm_mat = cell2mat(recall_tm_cell);
f1score_tm_mat = cell2mat(f1score_tm_cell);

mean_precision_tm = mean(precision_tm_mat);
mean_recall_tm = mean(recall_tm_mat);
mean_f1score_tm = mean(f1score_tm_mat);
std_precision_tm = std(precision_tm_mat);
std_recall_tm = std(recall_tm_mat);
std_f1score_tm = std(f1score_tm_mat);

precision_ctn_mat = cell2mat(precision_ctn_cell);
recall_ctn_mat = cell2mat(recall_ctn_cell);
f1score_ctn_mat = cell2mat(f1score_ctn_cell);

mean_precision_ctn = mean(precision_ctn_mat);
mean_recall_ctn = mean(recall_ctn_mat);
mean_f1score_ctn = mean(f1score_ctn_mat);
std_precision_ctn = std(precision_ctn_mat);
std_recall_ctn = std(recall_ctn_mat);
std_f1score_ctn = std(f1score_ctn_mat);


precision_x = [1,2,3,4];
recall_x = precision_x+5;
f1score_x = recall_x+5;
xtick_list = [mean(precision_x),mean(recall_x),mean(f1score_x)];
xticklabel_list = {'Precision','Recall','F1-score'};
inter_x_space = '                ';
subplot('Position',[0.6,0.05,0.38,0.15])
bar(precision_x(1),mean_precision_tm(1),'FaceColor',mk_clr)
hold on
bar(precision_x(2),mean_precision_ctn(1),'FaceColor',tr_clr)
hold on
bar(precision_x(3),mean_precision_tm(2),'FaceColor',mk_clr)
hold on
bar(precision_x(4),mean_precision_ctn(2),'FaceColor',tr_clr)
hold on
errorbar(precision_x(1),mean_precision_tm(1),std_precision_tm(1),...
    'Color','k')
hold on
errorbar(precision_x(2),mean_precision_ctn(1),std_precision_ctn(1),...
    'Color','k')
hold on
errorbar(precision_x(3),mean_precision_tm(2),std_precision_tm(2),...
    'Color','k')
hold on
errorbar(precision_x(4),mean_precision_ctn(2),std_precision_ctn(2),...
    'Color','k')
hold on
rng('default')
for k = 1:length(accuracy_tm_list)
    plot(precision_x(1)+(rand(1)-0.5)/3,precision_tm_mat(k,1),...
        'ko','MarkerSize',2,...
        'MarkerFaceColor','w','LineWidth',0.25)
end
hold on
rng('default')
for k = 1:length(accuracy_tm_list)
    plot(precision_x(2)+(rand(1)-0.5)/3,precision_ctn_mat(k,1),...
        'ko','MarkerSize',2,...
        'MarkerFaceColor','w','LineWidth',0.25)
end
hold on
rng('default')
for k = 1:length(accuracy_tm_list)
    plot(precision_x(3)+(rand(1)-0.5)/3,precision_tm_mat(k,2),...
        'ko','MarkerSize',2,...
        'MarkerFaceColor','w','LineWidth',0.25)
end
hold on
rng('default')
for k = 1:length(accuracy_tm_list)
    plot(precision_x(4)+(rand(1)-0.5)/3,precision_ctn_mat(k,2),...
        'ko','MarkerSize',2,...
        'MarkerFaceColor','w','LineWidth',0.25)
end
hold on


bar(recall_x(1),mean_recall_tm(1),'FaceColor',mk_clr)
hold on
bar(recall_x(2),mean_recall_ctn(1),'FaceColor',tr_clr)
hold on
bar(recall_x(3),mean_recall_tm(2),'FaceColor',mk_clr)
hold on
bar(recall_x(4),mean_recall_ctn(2),'FaceColor',tr_clr)
hold on
errorbar(recall_x(1),mean_recall_tm(1),std_recall_tm(1),...
    'Color','k')
hold on
errorbar(recall_x(2),mean_recall_ctn(1),std_recall_ctn(1),...
    'Color','k')
hold on
errorbar(recall_x(3),mean_recall_tm(2),std_recall_tm(2),...
    'Color','k')
hold on
errorbar(recall_x(4),mean_recall_ctn(2),std_recall_ctn(2),...
    'Color','k')
hold on
rng('default')
for k = 1:length(accuracy_tm_list)
    plot(recall_x(1)+(rand(1)-0.5)/3,recall_tm_mat(k,1),...
        'ko','MarkerSize',2,...
        'MarkerFaceColor','w','LineWidth',0.25)
end
hold on
rng('default')
for k = 1:length(accuracy_tm_list)
    plot(recall_x(2)+(rand(1)-0.5)/3,recall_ctn_mat(k,1),...
        'ko','MarkerSize',2,...
        'MarkerFaceColor','w','LineWidth',0.25)
end
hold on
rng('default')
for k = 1:length(accuracy_tm_list)
    plot(recall_x(3)+(rand(1)-0.5)/3,recall_tm_mat(k,2),...
        'ko','MarkerSize',2,...
        'MarkerFaceColor','w','LineWidth',0.25)
end
hold on
rng('default')
for k = 1:length(accuracy_tm_list)
    plot(recall_x(4)+(rand(1)-0.5)/3,recall_ctn_mat(k,2),...
        'ko','MarkerSize',2,...
        'MarkerFaceColor','w','LineWidth',0.25)
end
hold on

bar(f1score_x(1),mean_f1score_tm(1),'FaceColor',mk_clr)
hold on
bar(f1score_x(2),mean_f1score_ctn(1),'FaceColor',tr_clr)
hold on
bar(f1score_x(3),mean_f1score_tm(2),'FaceColor',mk_clr)
hold on
bar(f1score_x(4),mean_f1score_ctn(2),'FaceColor',tr_clr)
hold on
errorbar(f1score_x(1),mean_f1score_tm(1),std_f1score_tm(1),...
    'Color','k')
hold on
errorbar(f1score_x(2),mean_f1score_ctn(1),std_f1score_ctn(1),...
    'Color','k')
hold on
errorbar(f1score_x(3),mean_f1score_tm(2),std_f1score_tm(2),...
    'Color','k')
hold on
errorbar(f1score_x(4),mean_f1score_ctn(2),std_f1score_ctn(2),...
    'Color','k')
hold on
rng('default')
for k = 1:length(accuracy_tm_list)
    plot(f1score_x(1)+(rand(1)-0.5)/3,f1score_tm_mat(k,1),...
        'ko','MarkerSize',2,...
        'MarkerFaceColor','w','LineWidth',0.25)
end
hold on
rng('default')
for k = 1:length(accuracy_tm_list)
    plot(f1score_x(2)+(rand(1)-0.5)/3,f1score_ctn_mat(k,1),...
        'ko','MarkerSize',2,...
        'MarkerFaceColor','w','LineWidth',0.25)
end
hold on
rng('default')
for k = 1:length(accuracy_tm_list)
    plot(f1score_x(3)+(rand(1)-0.5)/3,f1score_tm_mat(k,2),...
        'ko','MarkerSize',2,...
        'MarkerFaceColor','w','LineWidth',0.25)
end
hold on
rng('default')
for k = 1:length(accuracy_tm_list)
    plot(f1score_x(4)+(rand(1)-0.5)/3,f1score_ctn_mat(k,2),...
        'ko','MarkerSize',2,...
        'MarkerFaceColor','w','LineWidth',0.25)
end
hold off
% axis([0.3,6.7,0,1])
set(gca,'XTick',[1.5,3.5,6.5,8.5,11.5,13.5])
set(gca,'TickDir','out')
set(gca,'XTickLabel',...
    {'Trapped','Free'})
set(gca,'XTickLabelRotation',0)
box off
xlabel([xticklabel_list{1},inter_x_space,...
        xticklabel_list{2},inter_x_space,...
        xticklabel_list{3}])
% set(gca,'YTick',[0,1])




































