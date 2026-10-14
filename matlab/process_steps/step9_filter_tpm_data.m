%{
    filter tpm data using Weijian zong's methods
%}
clear all
close all
genPath = genpath('./');
addpath(genPath)
%% set path
rootpath = ['H:\MTPM_body_language\' ...
    'raw_data'];
beh_path = [rootpath,'\behavior_op_20250915'];
tpm_path = [rootpath,'\tpm_suite2p'];
%% load names
fileFolder = fullfile(beh_path);
dirOutput = dir(fullfile(fileFolder,'*caliParas.mat'));
behNames = {dirOutput.name}';
temprootnames = split(behNames,'-caliParas');
rootnames = temprootnames(:,1);
%% process
for k = 1:size(rootnames,1)
    %% load name
    rootname = rootnames{k,1};

    sep_tpm_path = [tpm_path,'\sep\',...
        rootname,'-tpm'];
    %% load data
    tempdata = load([sep_tpm_path,'\resample_sep_suite2p.mat']);

    Fc_all = tempdata.resample_tpm_data.F-0.7*tempdata.resample_tpm_data.Fneu;
    Fc_neu = Fc_all(tempdata.resample_tpm_data.iscell(:,1)==1,:);

    %% filtering
    smo_win = 30;

    filt_F = zeros(size(Fc_neu));
    for m = 1:size(filt_F,1)
        filt_F(m,:) = neu_filter(Fc_neu(m,:));
    end

    %% calculate F0
    fs = 30;
    time_win = 30;
    frame_win = fs*time_win;
    half_frame_win = round(frame_win/2);
    
    fst = zeros(size(filt_F));

    pad_filt_F = padarray(filt_F',half_frame_win,...
        "replicate",'both')';

    for m = 1:size(fst,1)
        temptrace = pad_filt_F(m,:);
        for n = 1:size(fst,2)
            win_trace = temptrace(n:(n+half_frame_win-1));
            fst(m,n) = prctile(win_trace,8);
        end
    end
    
    local_std = zeros(size(filt_F,1),...
        (size(filt_F,2)-frame_win));
    for m = 1:size(filt_F,1)
        temptrace = filt_F(m,:);
        for n = 1:(length(temptrace)-frame_win)
            win_trace = temptrace(n:(n+frame_win-1));
            local_std(m,n) = std(win_trace);
        end
    end

    baseline_m = zeros(size(fst));
    for m = 1:size(fst,1)
        min_std = min(local_std(m,:));
        max_std = max(local_std(m,:));
        tempm = min_std+0.1*(min_std+max_std);
        baseline_m(m,:) = tempm;
    end
    
    F0t = fst+baseline_m;

    %% calculate dF/F
    dff_F = (filt_F-F0t)./F0t;  

    %% extract final cells
    up_thres = 10;
    down_thres = -5;
    cell_idx = zeros(size(dff_F,1),1);
    for m = 1:size(dff_F,1)
        temptrace = dff_F(m,:);
        min_trace = min(temptrace);
        max_trace = max(temptrace);
        if (up_thres>max_trace)&&(min_trace>down_thres)
            cell_idx(m,1) = 1;
        end
    end
    final_dff_F = dff_F(cell_idx==1,:);
    % final_dff_F = dff_F;
    
    %% save data
    dff_smo_Fc = final_dff_F;

    figure
    imagesc(dff_smo_Fc)
    title(k)
    pause(0.00000001)
    
    save([sep_tpm_path,'\final_filter_tpm.mat'],'dff_smo_Fc')
    disp(k)
end
disp('save!')
























