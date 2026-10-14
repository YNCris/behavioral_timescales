function [Atr,Btr,GTtr,Ava,Bva,GTva,Ate,Bte,GTte] = ...
    make_dataset_from_filtF_tshift(filt_F_cell, ratioTrain, ratioVal, ratioTest)

% 输入:
%   filt_F_cell: {N × 1}，每个元素 = [C × T] (神经元数 × 时间点)
% 输出:
%   Atr/Btr: 输入序列 & 输出序列 (cell)，每个元素 [1 × L]
%   GTxx:    这里没 GT，可传空

N = numel(filt_F_cell);

Atr={}; Btr={}; Ava={}; Bva={}; Ate={}; Bte={};
GTtr={}; GTva={}; GTte={};

for i = 1:N
    X = filt_F_cell{i};  % C × T
    if isempty(X), continue; end
    
    % 这里只取单通道 (你原来就是 sequenceInputLayer(1))
    x = mean(X,1);   % 平均一个细胞群，也可以挑选单个ROI
    
    % 构造 (t → t+1) 对
    inputSeq  = x(1:end-1);
    targetSeq = x(2:end);
    
    % 按比例划分 train/val/test
    L = length(inputSeq);
    i1 = floor(L*ratioTrain);
    i2 = floor(L*(ratioTrain+ratioVal));
    
    Atr{end+1} = inputSeq(1:i1);
    Btr{end+1} = targetSeq(1:i1);
    
    Ava{end+1} = inputSeq(i1+1:i2);
    Bva{end+1} = targetSeq(i1+1:i2);
    
    Ate{end+1} = inputSeq(i2+1:end);
    Bte{end+1} = targetSeq(i2+1:end);
end
end
