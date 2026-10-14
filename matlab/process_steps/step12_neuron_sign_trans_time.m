%{
    calculate the significant trans of neurons
%}
clear all
close all
genPath = genpath('./');
addpath(genPath)
%% set path
rootpath = 'E:\MTPM_body_language\';
beh_neu_path = [rootpath,'\beh_neu_20240412'];
%% load names
fileFolder = fullfile(beh_neu_path);
dirOutput = dir(fullfile(fileFolder,'free*-neu.mat'));
neuNames = {dirOutput.name}';
%% load all data
all_neu_cell = cell(size(neuNames,1),2);
for k = 1:size(all_neu_cell,1)
    tempdata = load([beh_neu_path,'\',neuNames{k,1}]);
    all_neu_cell{k,1} = neuNames{k,1};
    all_neu_cell{k,2} = tempdata.dff_smo_Fc;
    disp(k)
end
%% process
for k = 1:size(all_neu_cell,1)
    %%
    dff_F = all_neu_cell{k,2};
    %%  significant transients select
    time_thres = 0.75;
    fs = 30;
    time_win = 30;
    frame_win = fs*time_win;

    frame_thres = round(time_thres*fs);

    dff_local_std = ...
        zeros(size(dff_F,1),(size(dff_F,2)-frame_win));
    for m = 1:size(dff_F,1)
        temptrace = dff_F(m,:);
        for n = 1:(length(temptrace)-frame_win)
            win_trace = temptrace(n:(n+frame_win-1));
            dff_local_std(m,n) = std(win_trace);
        end
    end

    min_dff_local_std = min(dff_local_std,[],2)*...
        ones(1,size(dff_F,2));

    temp_sign_trans = dff_F>(2*min_dff_local_std);
    sign_trans = zeros(size(temp_sign_trans));
    for m = 1:size(temp_sign_trans,1)
        tempsign = temp_sign_trans(m,:);
        diffsign = diff([0,tempsign]);
        start_list = find(diffsign==1)';
        end_list = find(diffsign==-1)';
        if length(end_list)<length(start_list)
            end_list = [end_list;length(tempsign)];
        end
        translen = end_list-start_list;
        sign_list = [...
            start_list(translen>=frame_thres),...
            end_list(translen>=frame_thres)];
        for n = 1:size(sign_list,1)
            sign_trans(m,...
                sign_list(n,1):sign_list(n,2)) = 1;
        end
    end
    % %% temp show
    % plot(dff_F(1,:))
    % hold on
    % plot(sign_trans(1,:))
    % hold off
    %% calculate the time latency of each fire
    diff_sign_trans = diff(...
        [zeros(size(sign_trans,1),1),...
        sign_trans,...
        zeros(size(sign_trans,1),1)],[],2);

    sign_time_cell = cell(size(diff_sign_trans,1),3);
    for m = 1:size(sign_time_cell,1)
        tempdiff = diff_sign_trans(m,:);
        start_pos = find(tempdiff==1)';
        end_pos = find(tempdiff==-1)';
        tempsavelist = [start_pos,end_pos-1];
        sign_time_cell{m,1} = tempsavelist;
        sign_time_cell{m,2} = diff(tempsavelist,[],2);
        sign_time_cell{m,3} = mean(sign_time_cell{m,2});
    end
    %% save 
    save([beh_neu_path,'\',...
        all_neu_cell{k,1}(1,1:(end-4)),...
        '-sign_time.mat'],'sign_time_cell')
    disp(k)
end
disp('save!')