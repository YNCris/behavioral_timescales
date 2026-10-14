function [Atr,Btr,GTtr,Ava,Bva,GTva,Ate,Bte,GTte] = ...
    make_dataset_from_filtF_tshift_multichan(filt_F_cell, ratioTrain, ratioVal, ratioTest)

N = numel(filt_F_cell);

Atr={}; Btr={}; Ava={}; Bva={}; Ate={}; Bte={};
GTtr={}; GTva={}; GTte={};

for i = 1:N
    X = filt_F_cell{i};  % [Ncell × T]
    if isempty(X), continue; end

    % 构造 (t → t+1)
    inputSeq  = X(:,1:end-1);   % [Ncell × (T-1)]
    targetSeq = X(:,2:end);     % [Ncell × (T-1)]

    % 按比例划分
    L = size(inputSeq,2);
    i1 = floor(L*ratioTrain);
    i2 = floor(L*(ratioTrain+ratioVal));

    Atr{end+1} = inputSeq(:,1:i1);
    Btr{end+1} = targetSeq(:,1:i1);

    Ava{end+1} = inputSeq(:,i1+1:i2);
    Bva{end+1} = targetSeq(:,i1+1:i2);

    Ate{end+1} = inputSeq(:,i2+1:end);
    Bte{end+1} = targetSeq(:,i2+1:end);
end
end