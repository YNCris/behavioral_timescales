%{
    Supplementary fig 1, the comparison of transformers
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
mask_grad_name = {...
    'same';
    '0.1';
    '0.2';
    '0.3';
    '0.4';
    '0.5';
    '0.6';
    '0.7';
    '0.8';
    '0.9'};
mg_data_cell = cell(size(mask_grad_name,1),2);
for k = 1:size(mg_data_cell,1)
    tempname = ['train_save_',mask_grad_name{k},'.mat'];
    tempdata = load([datapath,'\',tempname]);
    mg_data_cell{k,1} = tempname;
    mg_data_cell{k,2} = tempdata;
end

mg_prec_cell = cell(size(mask_grad_name,1),2);
for k = 1:size(mg_prec_cell,1)
    tempname = ['precision_',mask_grad_name{k},'.mat'];
    tempdata = load([datapath,'\',tempname]);
    mg_prec_cell{k,1} = tempname;
    mg_prec_cell{k,2} = tempdata;
end


shuffle_name = {...
    '0.2';
    '0.2_shuffle';
    '0.2_wrong_answer'};
s_data_cell = cell(size(shuffle_name,1),2);
for k = 1:size(s_data_cell,1)
    tempname = ['train_save_',shuffle_name{k},'.mat'];
    tempdata = load([datapath,'\',tempname]);
    s_data_cell{k,1} = tempname;
    s_data_cell{k,2} = tempdata;
end

s_prec_cell = cell(size(shuffle_name,1),2);
for k = 1:size(s_prec_cell,1)
    tempname = ['precision_',shuffle_name{k},'.mat'];
    tempdata = load([datapath,'\',tempname]);
    s_prec_cell{k,1} = tempname;
    s_prec_cell{k,2} = tempdata;
end
%% training loss
start_x = 0.08;

cmaplist_fix_msk = cbrewer2('Spectral',size(mask_grad_name,1));
subplot('Position',[start_x,0.8,0.2,0.15])
for k = 1:size(mg_data_cell,1)
    epoch_list = double(mg_data_cell{k,2}.Epoch_Num)+1;
    train_loss_list = double(mg_data_cell{k,2}.Train_Loss);
    iter_len = length(train_loss_list)/length(epoch_list);
    loss_list = zeros(size(epoch_list));
    for m = 1:size(loss_list,2)
        epoch_loss = mean(train_loss_list(...
            (m-1)*iter_len+1:m*iter_len));
        loss_list(m) = log10(epoch_loss);
    end
    plot(epoch_list,loss_list,'-','Color',cmaplist_fix_msk(k,:))
    hold on
end
hold off
ylabel('Training loss (Log_1_0)')
box off
set(gca,'TickDir','out')
legend_list = {...
    'mask 0%';
    'mask 10%';
    'mask 20%';
    'mask 30%';
    'mask 40%';
    'mask 50%';
    'mask 60%';
    'mask 70%';
    'mask 80%';
    'mask 90%';};
% legend(legend_list,'Location','NorthEastOutside')
set(gca,'XTickLabel',[])
%% validation loss
subplot('Position',[start_x,0.63,0.2,0.15])
for k = 1:size(mg_data_cell,1)
    epoch_list = double(mg_data_cell{k,2}.Epoch_Num)+1;
    valid_loss_list = log10(...
        double(mg_data_cell{k,2}.Valid_Loss));
    plot(epoch_list,valid_loss_list,'-','Color',cmaplist_fix_msk(k,:))
    hold on
end
hold off
% xlabel('Epochs')
ylabel('Validation loss (Log_1_0)')
box off
set(gca,'TickDir','out')
set(gca,'XTickLabel',[])
%% random control, training loss
cmaplist_random = cbrewer2('Set2',size(shuffle_name,1));
subplot('Position',[start_x,0.46,0.2,0.15])
for k = 1:size(s_data_cell,1)
    epoch_list = double(s_data_cell{k,2}.Epoch_Num)+1;
    train_loss_list = double(s_data_cell{k,2}.Train_Loss);
    iter_len = length(train_loss_list)/length(epoch_list);
    loss_list = zeros(size(epoch_list));
    for m = 1:size(loss_list,2)
        epoch_loss = mean(train_loss_list(...
            (m-1)*iter_len+1:m*iter_len));
        loss_list(m) = log10(epoch_loss);
    end
    plot(epoch_list,loss_list,'-','Color',cmaplist_random(k,:))
    hold on
end
hold off
box off
ylabel('Training loss (Log_1_0)')
set(gca,'TickDir','out')
set(gca,'XTickLabel',[])

%% random control, validation loss
subplot('Position',[start_x,0.29,0.2,0.15])
for k = 1:size(s_data_cell,1)
    epoch_list = double(s_data_cell{k,2}.Epoch_Num)+1;
    valid_loss_list = log10(...
        double(s_data_cell{k,2}.Valid_Loss));
    plot(epoch_list,valid_loss_list,'-','Color',cmaplist_random(k,:))
    hold on
end
hold off
box off
set(gca,'TickDir','out')
xlabel('Epochs')
ylabel('Validation loss (Log_1_0)')

%% precision, fix mask, training
x_bias = 0.26;
resample_num = 100;
inter_x = 0.3;
subplot('Position',[start_x+x_bias,0.8,0.2,0.15])
for k = 1:size(mg_prec_cell,1)
    temp_prec = double(mg_prec_cell{k,2}.train_prec);
    res_inter = length(temp_prec)/resample_num;
    show_prec = zeros(1,resample_num);
    for m = 1:resample_num
        show_prec(1,m) = mean( ...
            temp_prec(((m-1)*res_inter+1):m*res_inter));
    end
    random_x = k+unifrnd(-1*inter_x,inter_x,[1,resample_num]);
    plot(show_prec,random_x,'o','MarkerFaceColor','w',...
        'MarkerEdgeColor',cmaplist_fix_msk(k,:),...
        'MarkerSize',2)
    hold on
end
hold off
box off
ylabel('Training mask (%)')
set(gca,'TickDir','out')
set(gca,'XTickLabel',[])
set(gca,'YTick',1:size(mg_prec_cell,1))
set(gca,'YTickLabel',0:10:90)
axis([0,1.05,0.3,10.7])
%% precision, fix mask, validation
subplot('Position',[start_x+x_bias,0.63,0.2,0.15])
for k = 1:size(mg_prec_cell,1)
    temp_prec = double(mg_prec_cell{k,2}.valid_prec);
    res_inter = length(temp_prec)/resample_num;
    show_prec = zeros(1,resample_num);
    for m = 1:resample_num
        show_prec(1,m) = mean( ...
            temp_prec(((m-1)*res_inter+1):m*res_inter));
    end
    random_x = k+unifrnd(-1*inter_x,inter_x,[1,resample_num]);
    plot(show_prec,random_x,'o','MarkerFaceColor','w',...
        'MarkerEdgeColor',cmaplist_fix_msk(k,:),...
        'MarkerSize',2)
    hold on
end
hold off
box off
ylabel('Validation mask (%)')
set(gca,'TickDir','out')
set(gca,'XTickLabel',[])
set(gca,'YTick',1:size(mg_prec_cell,1))
set(gca,'YTickLabel',0:10:90)
axis([0,1.05,0.3,10.7])
%% precision, random, training
x_bias = 0.26;
subplot('Position',[start_x+x_bias,0.46,0.2,0.15])
for k = 1:size(s_prec_cell,1)
    temp_prec = double(s_prec_cell{k,2}.train_prec);
    res_inter = length(temp_prec)/resample_num;
    show_prec = zeros(1,resample_num);
    for m = 1:resample_num
        show_prec(1,m) = mean( ...
            temp_prec(((m-1)*res_inter+1):m*res_inter));
    end
    random_x = k+unifrnd(-1*inter_x,inter_x,[1,resample_num]);
    plot(show_prec,random_x,'o','MarkerFaceColor','w',...
        'MarkerEdgeColor',cmaplist_random(k,:),...
        'MarkerSize',2)
    hold on
end
hold off
box off
% ylabel('Validation mask (%)')
set(gca,'TickDir','out')
set(gca,'XTickLabel',[])
set(gca,'YTick',1:size(s_prec_cell,1))
set(gca,'YTickLabel',{'Mask','Shuffle','Wrong'})
axis([0,1.05,0.3,3.7])
%% precision, random, validation
subplot('Position',[start_x+x_bias,0.29,0.2,0.15])
for k = 1:size(s_prec_cell,1)
    temp_prec = double(s_prec_cell{k,2}.valid_prec);
    res_inter = length(temp_prec)/resample_num;
    show_prec = zeros(1,resample_num);
    for m = 1:resample_num
        show_prec(1,m) = mean( ...
            temp_prec(((m-1)*res_inter+1):m*res_inter));
    end
    random_x = k+unifrnd(-1*inter_x,inter_x,[1,resample_num]);
    plot(show_prec,random_x,'o','MarkerFaceColor','w',...
        'MarkerEdgeColor',cmaplist_random(k,:),...
        'MarkerSize',2)
    hold on
end
hold off
box off
set(gca,'TickDir','out')
set(gca,'YTick',1:size(s_prec_cell,1))
set(gca,'YTickLabel',{'Mask','Shuffle','Wrong'})
xlabel('Precision')
axis([0,1.05,0.3,3.7])
%% hard precision, fix mask, training
x_bias = 0.48;
resample_num = 100;
inter_x = 0.3;
subplot('Position',[start_x+x_bias,0.8,0.2,0.15])
for k = 1:size(mg_prec_cell,1)
    temp_prec = double(mg_prec_cell{k,2}.train_prec_vh);
    mean_prec = mean(temp_prec);
    barh(k,mean_prec,'FaceColor',cmaplist_fix_msk(k,:))
    hold on
end
hold off
box off
% ylabel('Training mask (%)')
set(gca,'TickDir','out')
set(gca,'XTickLabel',[])
set(gca,'YTick',1:size(mg_prec_cell,1))
set(gca,'YTickLabel',[])
axis([0,1.05,0.3,10.7])
%% hard precision, fix mask, validation
subplot('Position',[start_x+x_bias,0.63,0.2,0.15])
for k = 1:size(mg_prec_cell,1)
    temp_prec = double(mg_prec_cell{k,2}.valid_prec_vh);
    mean_prec = mean(temp_prec);
    barh(k,mean_prec,'FaceColor',cmaplist_fix_msk(k,:))
    hold on
end
hold off
box off
% ylabel('Training mask (%)')
set(gca,'TickDir','out')
set(gca,'XTickLabel',[])
set(gca,'YTick',1:size(mg_prec_cell,1))
set(gca,'YTickLabel',[])
axis([0,1.05,0.3,10.7])
%% hard precision, random, training
% x_bias = 0.52;
subplot('Position',[start_x+x_bias,0.46,0.2,0.15])
for k = 1:size(s_prec_cell,1)
    temp_prec = double(s_prec_cell{k,2}.train_prec_vh);
    mean_prec = mean(temp_prec);
    barh(k,mean_prec,'FaceColor',cmaplist_random(k,:))
    hold on
end
hold off
box off
% ylabel('Validation mask (%)')
set(gca,'TickDir','out')
set(gca,'XTick',[])
set(gca,'YTick',1:size(s_prec_cell,1))
set(gca,'YTickLabel',[])
axis([0,1.05,0.3,3.7])
%% hard precision, random, validation
subplot('Position',[start_x+x_bias,0.29,0.2,0.15])
for k = 1:size(s_prec_cell,1)
    temp_prec = double(s_prec_cell{k,2}.valid_prec_vh);
    mean_prec = mean(temp_prec);
    barh(k,mean_prec,'FaceColor',cmaplist_random(k,:))
    hold on
end
hold off
box off
set(gca,'TickDir','out')
set(gca,'YTick',1:size(s_prec_cell,1))
set(gca,'YTickLabel',[])
xlabel('Hard precision')
axis([0,1.05,0.3,3.7])







































