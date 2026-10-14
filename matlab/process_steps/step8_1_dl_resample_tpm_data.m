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
%% load low pass data
raw_filt_F_cell = cell(size(rootnames,1),1);
idx_cell = cell(size(rootnames,1),1);
for k = 1:size(rootnames,1)
    %% load name
    rootname = rootnames{k,1};

    idx_name = [rootname,'-event\beh_tpm_idx.mat'];

    raw_tpm_name = [rootname,'-tpm\raw_sep_suite2p.mat'];

    idx_mat = load([tpm_path,'\sep\',idx_name]);

    idx_cell{k,1} = idx_mat.behavior_tpm_idx;
    %% load data
    raw_tpm_mat = load([tpm_path,'\sep\',raw_tpm_name]);

    Fc_all = raw_tpm_mat.newtpmdata.F-...
        0.7*raw_tpm_mat.newtpmdata.Fneu;
    Fc_neu = Fc_all(raw_tpm_mat.newtpmdata.iscell(:,1)==1,:);

    raw_filt_F_cell{k,1} = Fc_neu;%cut for network

    disp(k)
end
%% create dataset
train_len = 4096;

filt_F_cell = cellfun(@(x) x(:,1:train_len),...
    raw_filt_F_cell,'UniformOutput',false);

size_F = cell2mat(cellfun(@(x) size(x,1),...
    filt_F_cell,'UniformOutput',false));

Atr = {};
Btr = {};

Atr_idx = [];
for k = 1:size(filt_F_cell,1)
    %%
    tempneu = filt_F_cell{k,1};

    neu_odd = tempneu(:,1:2:end);
    neu_even = tempneu(:,2:2:end);

    for m = 1:size(tempneu,1)
        Atr = [Atr;{neu_odd(m,:);neu_even(m,:)}];
        Btr = [Btr;{neu_even(m,:);neu_odd(m,:)}];

        Atr_idx = [Atr_idx;[k,m,1];[k,m,2]];
    end
end

%% -------------------- Convert to cell sequences [1×L] --------------------
toCell = @(C) cellfun(@(x) reshape(x, [1,numel(x)]), C, 'uni',0);

Xtrain = toCell(Atr); Ytrain = toCell(Btr);
Xval   = toCell(Atr); Yval   = toCell(Btr);
Xtest  = toCell(Atr); Ytest  = toCell(Btr);

L = train_len/2;
%% -------------------- Build 1D U-Net (sequence) --------------------
lgraph = layerGraph();
lgraph = addLayers(lgraph, sequenceInputLayer(1,...
    'Name','input', 'MinLength',L));

% encoder1
enc1 = [
    convolution1dLayer(5,32,'Padding','same','Name','enc1_conv1')
    reluLayer('Name','enc1_relu1')
    convolution1dLayer(5,32,'Padding','same','Name','enc1_conv2')
    reluLayer('Name','enc1_relu2')
    maxPooling1dLayer(2,'Stride',2,'Name','pool1')];
lgraph = addLayers(lgraph, enc1);
lgraph = connectLayers(lgraph,'input','enc1_conv1');

% encoder2
enc2 = [
    convolution1dLayer(5,64,'Padding','same','Name','enc2_conv1')
    reluLayer('Name','enc2_relu1')
    convolution1dLayer(5,64,'Padding','same','Name','enc2_conv2')
    reluLayer('Name','enc2_relu2')
    maxPooling1dLayer(2,'Stride',2,'Name','pool2')];
lgraph = addLayers(lgraph, enc2);
lgraph = connectLayers(lgraph,'pool1','enc2_conv1');

% bottom
bottom = [
    convolution1dLayer(5,128,'Padding','same','Name','bottom_conv1')
    reluLayer('Name','bottom_relu1')
    convolution1dLayer(5,128,'Padding','same','Name','bottom_conv2')
    reluLayer('Name','bottom_relu2')];
lgraph = addLayers(lgraph, bottom);
lgraph = connectLayers(lgraph,'pool2','bottom_conv1');

% decoder2
up2   = transposedConv1dLayer(2,64,'Stride',2,'Name','up2');
cat2  = concatenationLayer(1,2,'Name','cat2'); % 按通道拼
dec2  = [
    convolution1dLayer(5,64,'Padding','same','Name','dec2_conv1')
    reluLayer('Name','dec2_relu1')
    convolution1dLayer(5,64,'Padding','same','Name','dec2_conv2')
    reluLayer('Name','dec2_relu2')];
lgraph = addLayers(lgraph, up2);   lgraph = addLayers(lgraph, cat2);  lgraph = addLayers(lgraph, dec2);
lgraph = connectLayers(lgraph, 'bottom_relu2','up2');
lgraph = connectLayers(lgraph, 'up2','cat2/in1');
lgraph = connectLayers(lgraph, 'enc2_relu2','cat2/in2');
lgraph = connectLayers(lgraph, 'cat2','dec2_conv1');

% decoder1
up1   = transposedConv1dLayer(2,32,'Stride',2,'Name','up1');
cat1  = concatenationLayer(1,2,'Name','cat1');
dec1  = [
    convolution1dLayer(5,32,'Padding','same','Name','dec1_conv1')
    reluLayer('Name','dec1_relu1')
    convolution1dLayer(5,32,'Padding','same','Name','dec1_conv2')
    reluLayer('Name','dec1_relu2')];
lgraph = addLayers(lgraph, up1);   lgraph = addLayers(lgraph, cat1);  lgraph = addLayers(lgraph, dec1);
lgraph = connectLayers(lgraph, 'dec2_relu2','up1');
lgraph = connectLayers(lgraph, 'up1','cat1/in1');
lgraph = connectLayers(lgraph, 'enc1_relu2','cat1/in2');
lgraph = connectLayers(lgraph, 'cat1','dec1_conv1');

% head
head = [
    convolution1dLayer(1,32,'Padding','same','Name','head_conv1')
    reluLayer('Name','head_relu')
    convolution1dLayer(1,1,'Padding','same','Name','head_conv2')
    regressionLayer('Name','out')];
lgraph = addLayers(lgraph, head);
lgraph = connectLayers(lgraph,'dec1_relu2','head_conv1');

%% -------------------- Train --------------------
% 训练参数
miniBatchSize = 16;
maxEpochs     = 20;
learnRate     = 1e-4;

opts = trainingOptions('adam', ...
    'InitialLearnRate',learnRate, ...
    'MaxEpochs',maxEpochs, ...
    'MiniBatchSize',miniBatchSize, ...
    'Shuffle','every-epoch', ...
    'ValidationData',{Xval,Yval}, ...
    'Plots','training-progress', ...
    'Verbose',true);

net = trainNetwork(Xtrain, Ytrain, lgraph, opts);

%% -------------------- Test & Visualization --------------------
% 假设你已经有:
%   net     : 训练好的网络
%   Xtest   : cell array，每个 cell = [1 × L]
%   Ytest   : cell array，对应目标 (noisy target)
%   GTte    : cell array，干净 GT（实验数据没有GT时可忽略/传空）

NtestShow = min(5, numel(Xtest)); % 随机选5条可视化
idxShow = randperm(numel(Xtest), NtestShow);

snr_db = @(ref,est) 10*log10(sum(ref.^2)/sum((ref-est).^2));

for ii = 1:NtestShow
    i = idxShow(ii);

    % 输入/目标/预测
    noisy  = Xtest{i};             % 输入 (odd or even)
    target = Ytest{i};             % 训练时的目标 (另一半)
    den    = predict(net, {noisy}); den = den{1}; % 网络输出

    % 如果有GT，就算 SNR
    if exist('GTte','var') && ~isempty(GTte) && length(GTte)>=i
        gt = GTte{i};
        s0 = snr_db(gt, noisy);
        s1 = snr_db(gt, den);
        fprintf('Sample %d: noisy %.2f dB -> denoised %.2f dB\n', i, s0, s1);
    else
        gt = [];
    end

    % ----------- 可视化 -----------
    figure('Color','w','Name',sprintf('Test sample %d',i));
    hold on;
    if ~isempty(gt)
        plot(gt,'k','LineWidth',1.2); 
    end
    plot(noisy,'r'); 
    plot(den,'b','LineWidth',1.1);
    if ~isempty(gt)
        legend('GT','Noisy input','Denoised');
    else
        legend('Noisy input','Denoised');
    end
    xlabel('Time (frames)'); ylabel('\DeltaF/F');
    grid on;
    title(sprintf('Sample %d denoising',i));
end

%% predict
den = predict(net, Xtrain);

%% restore the data
res_filt_F_cell = raw_filt_F_cell;
for k = 1:size(den,1)
    %%
    tempden = den{k,1};
    den_idx = Atr_idx(k,:);
    
    x = 1:length(tempden);
    xq = linspace(1, length(tempden), train_len);
    tempden_interp = interp1(x, tempden, xq, 'spline');

    res_filt_F_cell{...
        den_idx(1),1}(...
        den_idx(2),1:train_len) = ...
        tempden_interp;
end
%% resample
for k = 1:size(rootnames,1)
    %% load name
    rootname = rootnames{k,1};

    idx_name = [rootname,'-event\beh_tpm_idx.mat'];

    raw_tpm_name = [rootname,'-tpm\raw_sep_suite2p.mat'];

    idx_mat = load([tpm_path,'\sep\',idx_name]);

    raw_tpm_mat = load([tpm_path,'\sep\',raw_tpm_name]);
    %% resample
    idx_list = idx_mat.behavior_tpm_idx(:,2);

    resample_tpm_data.stat = raw_tpm_mat.newtpmdata.stat;
    resample_tpm_data.ops = raw_tpm_mat.newtpmdata.ops;
    resample_tpm_data.F = raw_tpm_mat.newtpmdata.F(:,idx_list);
    resample_tpm_data.Fneu = raw_tpm_mat.newtpmdata.Fneu(:,idx_list);
    resample_tpm_data.spks = raw_tpm_mat.newtpmdata.spks(:,idx_list);
    resample_tpm_data.iscell = raw_tpm_mat.newtpmdata.iscell;
    resample_tpm_data.redcell = raw_tpm_mat.newtpmdata.redcell;
    resample_tpm_data.sep_idx_all = raw_tpm_mat.newtpmdata.sep_idx_all;
    resample_tpm_data.sep_idx_all_norm = raw_tpm_mat.newtpmdata.sep_idx_all_norm;
    resample_tpm_data.idx_resample = raw_tpm_mat.newtpmdata.sep_idx_all(idx_list);
    resample_tpm_data.beh_tpm_idx = idx_mat.behavior_tpm_idx;
    resample_tpm_data.filt_F = res_filt_F_cell{k,1}(:,idx_list);

    %% save data
    sep_tpm_path = [tpm_path,'\sep\',...
        rootname,'-tpm'];

    save([sep_tpm_path,'\resample_sep_suite2p.mat'],'resample_tpm_data')

    disp(k)
end
disp('save!')

























