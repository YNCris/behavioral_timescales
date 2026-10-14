%{
    split close and far using distance
%}
clear all
close all
addpath(genpath(pwd))
%% set path
rootpath = ['E:\MTPM_body_language'];

beh_video_path = [rootpath,'\raw_data\behavior_all'];

bea_path = [beh_video_path,'\BeA_path'];

process_tpm_path = [rootpath,...
    '\raw_data\tpm_suite2p\process'];

beh_neu_path = [rootpath,'\beh_neu_20240412'];
%% load data
fileFolder = fullfile(beh_neu_path);
dirOutput = dir(fullfile(fileFolder,'*pose*-cebra.mat'));
cebraNames = {dirOutput.name}';

cebra_cell = cell(size(cebraNames,1),13);
cebra_cell(:,1) = cebraNames;

smo_win = 60;

for k = 1:size(cebra_cell,1)
    tempdata = load([beh_neu_path,'\',cebraNames{k}]);
    cebra_cell{k,2} = tempdata.cebra;
    cebra_cell(k,3:10) = split(cebra_cell{k,1},'-');
    cebra_cell{k,11} = cebra_cell{k,5}(2:end);

    labelname = [cebra_cell{k,1}(1:(end-10)),'.mat'];

    templabel = load([beh_neu_path,'\',labelname]);

    neuname = [...
        cebra_cell{k,3},'-',...
        cebra_cell{k,4},'-',...
        cebra_cell{k,5},'-',...
        cebra_cell{k,6},'-',...
        cebra_cell{k,7},'-neu.mat',...
        ];

    tempneu = load([beh_neu_path,'\',neuname]);

    if strcmp(cebra_cell{k,8},'pose')
        temppose = templabel.coords3d;
        for m = 1:size(temppose,2)
            temppose(:,m) = smooth(...
                templabel.coords3d(:,m),smo_win);
        end
        cebra_cell{k,12} = temppose;
        cebra_cell{k,13} = tempneu.dff_smo_Fc';
    end
    disp(k)
end
%% separate far and close to calcualte the correlation
dist_thres = 50;%pixels

dist_cell = cell(size(cebra_cell,1),3);
for k = 1:size(cebra_cell,1)
    %%
    tempuniquename = [...
        cebra_cell{k,3},'-',...
        cebra_cell{k,4},'-',...
        cebra_cell{k,5},'-',...
        cebra_cell{k,6},'-',...
        cebra_cell{k,7}...
        ];

    selidx = cell2mat(...
        cellfun(@(x) strcmp(x(1:length(tempuniquename)),...
        tempuniquename),cebra_cell(:,1),'UniformOutput',false));

    sel_cebra_cell = cebra_cell(selidx,:);
    %% calculate distance
    m1 = sel_cebra_cell{1,12};
    m2 = sel_cebra_cell{2,12};

    all_d = zeros(size(m1,1),size(m2,2)/3);
    for m = 1:size(all_d,2)
        %%
        sel_m1 = m1(:,((m-1)*3+1):(m*3));
        sel_m2 = m2(:,((m-1)*3+1):(m*3));
        tempd = sqrt(sum((sel_m1-sel_m2).^2,2));
        all_d(:,m) = tempd;
    end
    raw_min_d = min(all_d,[],2);
    %% close idx
    close_idx = raw_min_d<dist_thres;
    %% close str
    close_str = cell(size(close_idx,1),1);
    for m = 1:size(close_str,1)
        if close_idx(m) == 0
            close_str{m,1} = 'far';
        else
            close_str{m,1} = 'close';
        end
    end
    %% append data
    dist_cell{k,1} = raw_min_d;
    dist_cell{k,2} = close_idx;
    dist_cell{k,3} = close_str;
    %% save
    savename = [...
        cebra_cell{k,3},'-',...
        cebra_cell{k,4},'-',...
        cebra_cell{k,5},'-',...
        cebra_cell{k,6},'-',...
        cebra_cell{k,7},'-',...
        'distance','-',...
        cebra_cell{k,9},'.mat'...
        ];

    dist_data = dist_cell(k,:);
    save([beh_neu_path,'\',...
        savename],'dist_data')

    disp(k)
end
