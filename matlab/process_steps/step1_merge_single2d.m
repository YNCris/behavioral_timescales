%{
    merge single 2d trajectories to multi for 3D reconstruction
%}
clear all
close all
%% set path
datapath = ['H:\MTPM_body_language\' ...
    'raw_data\behavior_op_20250915'];
%% load data
dataFolder = fullfile(datapath);
dataOutput = dir(fullfile(dataFolder,...
    '*.mat'));
caliNames = {dataOutput.name}';
splname = split(caliNames,'-cali');
rootnames = splname(:,1);

cam_num = 4;

%% process
for k = 7:size(rootnames,1)
    %% load csv
    rootname = rootnames{k,1};
    splrootname = split(rootname,'-');
    if strcmp(splrootname{1},'fix')
        disp('fix')
        csvname_seg = {'tpm';'trap'};
    elseif strcmp(splrootname{1},'free')
        disp('free')
        csvname_seg = {'tpm';'free'};
    elseif strcmp(splrootname{1},'op')
        disp('op')
        csvname_seg = {'tpm';'free'};
    else
        disp('error')
    end

    for m = 1:cam_num
        camname = [rootname,'-camera-',num2str(m)];
        raw_data_cell = cell(size(csvname_seg,1),1);
        for n = 1:size(csvname_seg,1)
            csvname = [camname,'_',csvname_seg{n},'.csv'];
            disp(csvname)
            tempdata = readcell([datapath,'\',csvname]);
            raw_data_cell{n,1} = tempdata;
            for p = 2:size(raw_data_cell{n,1},2)
                raw_data_cell{n,1}{1,p} = csvname_seg{n};
            end
        end

        newdata = [raw_data_cell{1,1},raw_data_cell{2,1}(:,2:end)];
        %% write
        writecell(newdata,[datapath,'\',camname,'.csv'])
        disp('save!')
    end
    disp(k)
end
























