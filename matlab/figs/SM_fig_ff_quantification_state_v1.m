%{
    flow field quantification
    
    只有日期的：far close far
    far_baseline_time = 2
    far_after_time = 2
    close_min_time = 2

    close_far: close far
    close_baseline_time = 1
    close_after_time = 0
    far_min_time = 5
    
    
    all:一万八一分，90000/5，每个脑区10分钟数据
%}
clear all
close all
addpath(genpath(pwd))
%% set path
rootpath = ['X:\hanyaning\MTPM_body_language'];
beh_neu_path = [rootpath,'\beh_neu_20240412'];
dy_path = [rootpath,'\dynamic_model_data_20241113'];
%% load dynamics
load_brain_name = {...
    'tpmss';...
    'tpmpfc';...
    'tpmm'};

brain_dy_cell = cell(3,size(load_brain_name,1));

for k = 1:size(brain_dy_cell,1)
    %%
    all_name = [load_brain_name{k,1},'_all_20241113.mat'];
    close_name = [load_brain_name{k,1},'_20241113.mat'];
    far_name = [load_brain_name{k,1},'_close_far_20241113.mat'];

    tempmat_all = load([dy_path,'\',all_name]);
    tempmat_close = load([dy_path,'\',close_name]);
    tempmat_far = load([dy_path,'\',far_name]);

    brain_dy_cell{1,k} = tempmat_close;
    brain_dy_cell{2,k} = tempmat_far;
    brain_dy_cell{3,k} = tempmat_all;
end

%% plot canvas
hall = figure(1);
set(hall,'Position',[680,0,800,800])
set(hall,'color','white');

%% show
fs = 30;

time_len = 60*10;

frame_len = fs*time_len;

far_baseline_time = 2;
far_after_time = 2;
close_min_time = 2;

close_baseline_time = 1;
close_after_time = 0;
far_min_time = 5;

start_x = 0.08;
start_y = 0.96;

box_x = 0.9;
box_y = 0.02;

inter_y = 0.02;

small_inter_y = 0.002;

big_inter_y = 0.01;

quv_cmap = cbrewer2('Paired',10);

quv_cmap_list = [quv_cmap(3,:);quv_cmap(2,:)*0.8];

show_title = {...
    'S1';...
    'dmPFC';...
    'M1'};

x_unit_fcf = fs*10;
x_unit_cf = fs*120;
x_unit_all = fs*60*10;

for m = 1:size(brain_dy_cell,1)
    for n = 1:size(brain_dy_cell,2)
        %%
        temps = brain_dy_cell{m,n};

        temp_dist = double(temps.z_dist)';
        temp_state = double(temps.ms_state)';

        temph = subplot('Position',[...
            start_x,...
            start_y-(m-1)*(2*box_y+inter_y+small_inter_y)-...
            (n-1)*(6*box_y+3*small_inter_y+3*inter_y+big_inter_y),...
            box_x,box_y]);
        imagesc(temp_dist')
        colormap(quv_cmap_list)

        set(gca,'TickDir','out')
        set(gca,'YTick',[])
        set(gca,'FontSize',6)
        box off

        ylabel('Distance','Rotation',0)

        set(gca,'TickLength',[0.002,0.002])
        
        if m == 1
            x_unit = x_unit_fcf;
        elseif m == 2
            x_unit = x_unit_cf;
        elseif m == 3
            x_unit = x_unit_all;
        end
        set(gca,'XTick',0:x_unit:length(temp_dist))
        set(gca,'XTickLabel',[])
        
        if m == 1
            title(show_title{n});
        end

        subplot('Position',[...
            start_x,...
            start_y-(m-1)*(2*box_y+inter_y+small_inter_y)-...
            box_y-small_inter_y-...
            (n-1)*(6*box_y+3*small_inter_y+3*inter_y+big_inter_y),...
            box_x,box_y])
        plot(1.5*(1-temp_state),'Color',[0.7,0,0])
        axis([0,length(temp_state),0,1])

        set(gca,'YTick',[0,1])
        ylabel('State','Rotation',0)
        set(gca,'TickDir','out')
        set(gca,'FontSize',6)
        box off

        set(gca,'XTick',0:x_unit:length(temp_dist))

        set(gca,'TickLength',[0.002,0.002])

        if m == 1
            set(gca,'XTickLabel',(0:x_unit:length(temp_dist))/...
                (fs))
        else
            set(gca,'XTickLabel',(0:x_unit:length(temp_dist))/...
                (fs*60))
        end
    end
end

%% quantification of state change
state_change_cell = cell(size(brain_dy_cell));

for m = 1:size(brain_dy_cell,1)
    for n = 1:size(brain_dy_cell,2)
        %%
        temps = brain_dy_cell{m,n};

        temp_dist = double(temps.z_dist)';
        temp_state = double(temps.ms_state)';

        start_state_idx = find([0;diff(temp_state)]~=0);

        end_state_idx = [start_state_idx(2:end)-1;length(temp_state)];

        temp_dist_cell = cell(size(start_state_idx,1),1);

        for k = 1:size(temp_dist_cell,1)
            temp_dist_cell{k,1} = temp_dist(...
                start_state_idx(k,1):end_state_idx(k,1));
        end

        len_temp_dist = cellfun(@(x) size(x,1),...
            temp_dist_cell);

        temp_dist_cell(...
            (len_temp_dist<=60)) = [];

        for k = 1:size(temp_dist_cell,1)
            if length(temp_dist_cell{k,1})>=600
                temp_dist_cell{k,1} = ...
                    temp_dist_cell{k,1}(1:600);
            end
        end

        state_change_cell{m,n} = temp_dist_cell;
    end
end

%% show state consistent
start_x = 0.06;
start_y = 0.3;

box_x = 0.11;
box_y = 0.08;

inter_x = 0.01;
inter_y = 0.01;

for m = 1:size(state_change_cell,1)
    for n = 1:size(state_change_cell,2)
        tempstate = state_change_cell{m,n};

        len_tempstate = cellfun(@(x) size(x,1),...
            tempstate);

        state_mat = zeros(size(len_tempstate,1),...
            max(len_tempstate));

        for k = 1:size(state_mat,1)
            state_mat(k,1:length(tempstate{k})) = ...
                tempstate{k};
        end

        mean_state_mat = mean(state_mat);

        subplot('Position',[...
            start_x+(m-1)*(box_x+inter_x),...
            start_y-(n-1)*(box_y+inter_y),...
            box_x,box_y])
        for k = 1:size(tempstate,1)
            plot(tempstate{k},'Color',0.7*ones(1,3))
            hold on
        end
        plot(mean_state_mat,'Color',[0.7,0,0])
        hold off

        box off
        set(gca,'FontSize',6)
        set(gca,'TickDir','out')

        set(gca,'XTick',0:(5*fs):600)
        set(gca,'XTickLabel',(0:(5*fs):600)/fs)

        set(gca,'YTick',[0,1])

        if n == 3
            xlabel('Time (s)')
        else
            set(gca,'XTickLabel',[])
        end

        if m == 1
            ylabel({show_title{n},'State'})
        else
            set(gca,'YTickLabel',[])
        end
    end
end

%% compare the number of 0 and 1
start_x = 0.46;
start_y = 0.3;

box_x = 0.08;
box_y = 0.08;

inter_x = 0.005;
inter_y = 0.01;

bar_w = 0.6;

x_bias = 0.3;

mk_size = 2;

show_star = {...
    0.05,1.1,'ns';...
    0.01,0.05,'*';...
    0.001,0.01,'**';...
    0.0001,0.001,'***';...
    0,0.0001,'****'};

stat_1_cell = cell(size(state_change_cell,1),size(state_change_cell,2));

for m = 1:size(state_change_cell,1)
    for n = 1:size(state_change_cell,2)
        tempstate = state_change_cell{m,n};
        
        tt01 = zeros(size(tempstate,1),2);
        for k = 1:size(tempstate,1)
            ttt01 = tabulate(tempstate{k}(1:60));
            tt01(k,ttt01(:,1)+1) = ttt01(:,3)/100;
        end

        mean_tt01 = mean(tt01);
        std_tt01 = std(tt01)./sqrt(size(tt01,1));

        % test
        seldata = tt01;

        disp(length(seldata))
         
        [h_dist,p_dist] =kstest([seldata(:,1),seldata(:,2)]);
        p_var = vartestn(...
            [seldata(:,1),seldata(:,2)]','Display','off');
        if p_var>=0.05 && h_dist==0
            % normal distribution, equal variances
            [~,p_value] = ttest(seldata(:,1),seldata(:,2));
            disp('t-test')
        else
            % not normal distribution, not equal variances
            p_value = ranksum(seldata(:,1),seldata(:,2));
            disp('rank sum')
        end

        stat_1_cell{m,n} = p_value;

        sel_star_idx = (cell2mat(show_star(:,1))<=p_value)&...
                        (p_value<cell2mat(show_star(:,2)));
            
        selstar = show_star{sel_star_idx,3};

        subplot('Position',[...
            start_x+(m-1)*(box_x+inter_x),...
            start_y-(n-1)*(box_y+inter_y),...
            box_x,box_y])
        bar(1:2,mean_tt01,bar_w,...
            'FaceColor',0.7*ones(1,3))
        hold on
        errorbar(1:2,mean_tt01,std_tt01,...
            'LineStyle','none',...
            'CapSize',2,...
            'Color','k')
        hold on
        for k = 1:size(tt01,1)
            plot([1,2]+x_bias,tt01(k,:),'-k')
            hold on
            plot([1,2]+x_bias,tt01(k,:),'o',...
                'MarkerFaceColor','w',...
                'MarkerEdgeColor','k',...
                'LineWidth',0.25,...
                'MarkerSize',mk_size)
            hold on
        end

        plot([1,2],[1.05,1.05],'-k')
        hold on

        text(1.5,1,selstar,...
                    'HorizontalAlignment','center',...
                    'VerticalAlignment','bottom',...
                    'Rotation',0,'FontSize',6)

        hold off

        axis([0.3,2.7,0,1.05])

        box off
        set(gca,'FontSize',6)
        set(gca,'TickDir','out')
        set(gca,'YTick',[0,1])
        set(gca,'XTick',[1,2])
        set(gca,'XTickLabel',[0,1])
        
        
        if n == 3
            xlabel('State')
        else
            set(gca,'XTickLabel',[])
        end

        if m == 1
            ylabel('Ratio')
        else
            set(gca,'YTickLabel',[])
        end
    end
end

%% compare the number of 0 and 1
start_x = 0.73;
start_y = 0.3;

box_x = 0.08;
box_y = 0.08;

inter_x = 0.005;
inter_y = 0.01;

bar_w = 0.6;

x_bias = 0.3;

mk_size = 2;

show_star = {...
    0.05,1.1,'ns';...
    0.01,0.05,'*';...
    0.001,0.01,'**';...
    0.0001,0.001,'***';...
    0,0.0001,'****'};

stat_2_cell = cell(size(state_change_cell,1),size(state_change_cell,2));

for m = 1:size(state_change_cell,1)
    for n = 1:size(state_change_cell,2)
        tempstate = state_change_cell{m,n};
        
        tt01 = zeros(size(tempstate,1),2);
        for k = 1:size(tempstate,1)
            ttt01 = tabulate(tempstate{k});
            tt01(k,ttt01(:,1)+1) = ttt01(:,3)/100;
        end

        mean_tt01 = mean(tt01);
        std_tt01 = std(tt01)./sqrt(size(tt01,1));

        % test
        seldata = tt01;

        disp(length(seldata))
         
        [h_dist,p_dist] =kstest([seldata(:,1),seldata(:,2)]);
        p_var = vartestn(...
            [seldata(:,1),seldata(:,2)]','Display','off');
        if p_var>=0.05 && h_dist==0
            % normal distribution, equal variances
            [~,p_value] = ttest(seldata(:,1),seldata(:,2));
            disp('t-test')
        else
            % not normal distribution, not equal variances
            p_value = ranksum(seldata(:,1),seldata(:,2));
            disp('rank sum')
        end

        stat_2_cell{m,n} = p_value;

        sel_star_idx = (cell2mat(show_star(:,1))<=p_value)&...
                        (p_value<cell2mat(show_star(:,2)));
            
        selstar = show_star{sel_star_idx,3};

        subplot('Position',[...
            start_x+(m-1)*(box_x+inter_x),...
            start_y-(n-1)*(box_y+inter_y),...
            box_x,box_y])
        bar(1:2,mean_tt01,bar_w,...
            'FaceColor',0.7*ones(1,3))
        hold on
        errorbar(1:2,mean_tt01,std_tt01,...
            'LineStyle','none',...
            'CapSize',2,...
            'Color','k')
        hold on
        for k = 1:size(tt01,1)
            plot([1,2]+x_bias,tt01(k,:),'-k')
            hold on
            plot([1,2]+x_bias,tt01(k,:),'o',...
                'MarkerFaceColor','w',...
                'MarkerEdgeColor','k',...
                'LineWidth',0.25,...
                'MarkerSize',mk_size)
            hold on
        end

        plot([1,2],[1.05,1.05],'-k')
        hold on

        text(1.5,1,selstar,...
                    'HorizontalAlignment','center',...
                    'VerticalAlignment','bottom',...
                    'Rotation',0,'FontSize',6)

        hold off

        axis([0.3,2.7,0,1.05])

        box off
        set(gca,'FontSize',6)
        set(gca,'TickDir','out')
        set(gca,'YTick',[0,1])
        set(gca,'XTick',[1,2])
        set(gca,'XTickLabel',[0,1])
        
        
        if n == 3
            xlabel('State')
        else
            set(gca,'XTickLabel',[])
        end

        set(gca,'YTickLabel',[])
    end
end

% %% compare change
% start_x = 0.74;
% start_y = 0.3;
% 
% box_x = 0.04;
% box_y = 0.08;
% 
% inter_x = 0.005;
% inter_y = 0.01;
% 
% bar_w = 0.6;
% 
% x_bias = 0.3;
% 
% mk_size = 2;
% 
% show_star = {...
%     0.05,1.1,'ns';...
%     0.01,0.05,'*';...
%     0.001,0.01,'**';...
%     0.0001,0.001,'***';...
%     0,0.0001,'****'};
% 
% for m = 1:size(state_change_cell,1)
%     for n = 1:size(state_change_cell,2)
%         %%
%         tempstate = state_change_cell{m,n};
% 
%         tt_mat = zeros(size(tempstate,1),...
%             size(tempstate,1));
%         for p = 1:size(tempstate,1)
%             for q = 1:size(tempstate,1)
%                 tt1 = tempstate{p};
%                 tt2 = tempstate{q};
% 
%                 tt_mat(p,q) = mean(mean(pdist2(tt1,tt2)));
%             end
%         end
% 
%         tt_list = mean(tt_mat);
% 
%         mean_tt_list = mean(tt_list);
%         %%
% 
%         subplot('Position',[...
%             start_x+(m-1)*(box_x+inter_x),...
%             start_y-(n-1)*(box_y+inter_y),...
%             box_x,box_y])
%         bar(mean_tt_list)
%         axis([0,2,0,0.5])
%     end
%     disp(m)
% end

















