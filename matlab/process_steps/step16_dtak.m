%{
    dtak神经序列
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

all_data_cell = cell(size(neuNames,1),12);
%{rootname,neudata,pose_self,mov_self,seq_self,
% pose_partner,mov_partner,seq_partner, distance,
% umap_embedding,pca_embedding}

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

    tempdata = load([beh_neu_path,'\',rootname,...
        '-neu_umap.mat']);
    all_data_cell{k,10} = tempdata.umap_embedding;

    tempdata = load([beh_neu_path,'\',rootname,...
        '-neu_pca.mat']);
    all_data_cell{k,11} = tempdata.pca_embedding;

    tempdata = load([beh_neu_path,'\',rootname,...
        '-neu_linear_pred.mat']);
    all_data_cell{k,12} = tempdata.linear_pred;
    disp(k)
end
%% dtak
for k = 1:size(all_data_cell,1)
    tempumap = all_data_cell{k,2}';
    rootname = all_data_cell{k,1};
    %% time reduction
    kf = 3;
    redL = 5;
    
    X0 = tempumap;
    [dim, n0] = size(X0);

    G0 = kmean(X0, kf);
    XD0 = G2L_Slow(G0);

    % insert a useless sample at the end
    XD0(n0 + 1) = -1;
    
    sR = ones(1, 10000);
    m = 0;
    for i = 2 : n0 + 1
        if i - sR(m + 1) >= redL || XD0(i) ~= XD0(i - 1)
            m = m + 1;
            sR(m + 1) = i;
        end
    end
    sR(m + 2 : end) = [];
    XD0(n0 + 1) = [];

    % fetch the part
    X = sPick(X0, sR);
    G = sPick(G0, sR);
    XD = sPick(XD0, sR);
    %% K
    k_sigma = 15;
    K = conKnl_DTAK(conDist(X, X), ...
        'g', 'nei', k_sigma);
    %% decomposition
    fs = 30;
    
    BeA_DecParam.L2.k = 20; % Cluster number
    BeA_DecParam.L2.nMi = 1000; % Minimum lengths (ms),raw 100
    BeA_DecParam.L2.nMa = 2000; % Maximum lengths (ms)
    BeA_DecParam.L2.Ini = 'p'; % Initialization method
    
    paraM.k = BeA_DecParam.L2.k;
    paraM.kF = 'f';
    paraM.nMi = round((fs*BeA_DecParam.L2.nMi/1000) / (redL));
    paraM.nMa = round((fs*BeA_DecParam.L2.nMa/1000) / (redL));
    paraM.ini = BeA_DecParam.L2.Ini;
    paraM.nIni = 1;
    segDM = decompose_Movement(K, paraM);

    %% Results transfer
    decBehavior = segDM; % initialize decBehavior
    decBehavior(2) = segDM;
    decBehavior(1).s = sR;
    decBehavior(1).sH = sR;
    decBehavior(1).G = G;
    decBehavior(1).tim = [];
    decBehavior(1).obj = [];
    decBehavior(1).T = K;
    
    Seg_cell = cell(2,1);
    Seglist = XD0;
    Seg_cell{1,1} = Seglist;
    
    TRL = segDM.s;
    MapFL = sR;
    TFL = 0.*TRL;
    for m = 1:size(TRL,2)
        for n = 1:size(MapFL,2)
            if n == TRL(1,m)
                TFL(1,m) = MapFL(1,n);
            end
        end
    end
    decBehavior(2).s = TFL;
    decBehavior(2).G = segDM.G;
    Seglist = SegBarTrans(decBehavior(2));
    Seg_cell{2,1} = Seglist;
    
    %% Save results

    % BeA_DecData.K = K;
    BeA_DecData.DP_X = X;
    BeA_DecData.L1.ReMap = decBehavior(1).s;
    BeA_DecData.L1.Seglist = Seg_cell{1};
    BeA_DecData.L1.MedData = decBehavior(1);
    BeA_DecData.L2.ReMap = decBehavior(2).s;
    BeA_DecData.L2.Seglist = Seg_cell{2};
    BeA_DecData.L2.MedData = decBehavior(2);
    %% save
    save([beh_neu_path,'\',rootname,...
        '-neu_dtak.mat'],'BeA_DecData')
    disp(k)
end


















