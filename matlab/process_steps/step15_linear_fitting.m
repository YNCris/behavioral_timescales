%{
    fitting linear model of all mice
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

all_data_cell = cell(size(neuNames,1),11);
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
    disp(k)
end
%% create the unique_mov and unique_seq
all_mov = [];
all_mov_name = {};
for k = 1:size(all_data_cell,1)
    all_mov = [all_mov;...
        cell2mat(all_data_cell{k,4}(:,2));...
        cell2mat(all_data_cell{k,7}(:,2))];
    all_mov_name = [all_mov_name;...
        all_data_cell{k,4}(:,1);...
        all_data_cell{k,7}(:,1)];
end
unique_mov = unique(all_mov);
cmap_mov = cbrewer2('BuPu',length(unique_mov));

uniuqe_mov_name = cell(size(unique_mov));
for k = 1:size(unique_mov,1)
    tempname = all_mov_name(unique_mov(k)==all_mov);
    uniuqe_mov_name{k} = tempname{1};
end

all_seq = [];
for k = 1:size(all_data_cell,1)
    all_seq = [all_seq;...
        all_data_cell{k,5};...
        all_data_cell{k,8}];
end
unique_seq = unique(all_seq);
unique_seq = unique_seq(2:end);
cmap_seq = cbrewer2('BuPu',length(unique_seq));
%% mapping pca inside the same individual
pred_cell = cell(size(all_data_cell,1),6);

for k = 1:size(all_data_cell,1)
    %%
    temppca = all_data_cell{k,11}{1};

    self_temppose = all_data_cell{k,3};
    partner_temppose = all_data_cell{k,6};

    self_tempmov = cell2mat(all_data_cell{k,4}(:,2));
    partner_tempmov = cell2mat(all_data_cell{k,7}(:,2));

    self_tempseq = all_data_cell{k,5};
    partner_tempseq = all_data_cell{k,8};

    %% pose
    self_pose_rlist = ...
        zeros(size(self_temppose,2),1);
    for a = 1:size(self_temppose,2)
        %
        ttpose = self_temppose(:,a);
        mdl = fitglm(temppca,ttpose);
        ypred = predict(mdl,temppca);
        [r,rp] = corr(ttpose,ypred);
        self_pose_rlist(a,1) = r;
    end

    partner_pose_rlist = ...
        zeros(size(partner_temppose,2),1);
    for a = 1:size(partner_temppose,2)
        %
        ttpose = partner_temppose(:,a);
        mdl = fitglm(temppca,ttpose);
        ypred = predict(mdl,temppca);
        [r,rp] = corr(ttpose,ypred);
        partner_pose_rlist(a,1) = r;
    end

    %% mov
    mdl = fitcdiscr(temppca,self_tempmov);
    ypred = predict(mdl,temppca);
    prec = ypred==self_tempmov;
    
    self_mov_prec = -1*ones(size(unique_mov));
    for a = 1:size(self_mov_prec,1)
        selprec = prec(...
            unique_mov(a)==self_tempmov,:);
        if size(selprec,1) > 0
            self_mov_prec(a) = mean(selprec);
        end
    end
    self_mov_prec(self_mov_prec==-1) = [];

    mdl = fitcdiscr(temppca,partner_tempmov);
    ypred = predict(mdl,temppca);
    prec = ypred==partner_tempmov;
    
    partner_mov_prec = -1*ones(size(unique_mov));
    for a = 1:size(partner_mov_prec,1)
        selprec = prec(...
            unique_mov(a)==partner_tempmov,:);
        if size(selprec,1) > 0
            partner_mov_prec(a) = mean(selprec);
        end
    end
    partner_mov_prec(partner_mov_prec==-1) = [];

    %% seq
    mdl = fitcdiscr(temppca,self_tempseq);
    ypred = predict(mdl,temppca);
    prec = ypred==self_tempseq;

    self_seq_prec = -1*ones(size(unique_seq));
    for a = 1:size(self_seq_prec,1)
        selprec = prec(...
            unique_seq(a)==self_tempseq,:);
        if size(selprec,1) > 0
            self_seq_prec(a) = mean(selprec);
        end
    end
    self_seq_prec(self_seq_prec==-1) = [];

    mdl = fitcdiscr(temppca,partner_tempseq);
    ypred = predict(mdl,temppca);
    prec = ypred==partner_tempseq;

    partner_seq_prec = -1*ones(size(unique_seq));
    for a = 1:size(partner_seq_prec,1)
        selprec = prec(...
            unique_seq(a)==partner_tempseq,:);
        if size(selprec,1) > 0
            partner_seq_prec(a) = mean(selprec);
        end
    end
    partner_seq_prec(partner_seq_prec==-1) = [];

    %% save
    pred_cell{k,1} = self_pose_rlist;
    pred_cell{k,2} = partner_pose_rlist;
    pred_cell{k,3} = self_mov_prec;
    pred_cell{k,4} = partner_mov_prec;
    pred_cell{k,5} = self_seq_prec;
    pred_cell{k,6} = partner_seq_prec;

    disp(k)
end
%% save
for k = 1:size(pred_cell,1)
    rootname = all_data_cell{k,1};
    linear_pred = pred_cell(k,:);

    save([beh_neu_path,'\',rootname,...
        '-neu_linear_pred.mat'],'linear_pred')

    disp(k)
end

























