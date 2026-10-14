function [Atr,Btr,GTtr,Ava,Bva,GTva,Ate,Bte,GTte] = ...
    make_dataset_from_filtF_fix2000(filt_F_cell, ratioTrain, ratioVal, ratioTest)

targetLen = 3200;   % 目标序列长度

Atr={}; Btr={}; Ava={}; Bva={}; Ate={}; Bte={};
GTtr={}; GTva={}; GTte={};

for k = 1:numel(filt_F_cell)
    X = filt_F_cell{k};   % [Ncell × T]
    if isempty(X), continue; end
    [Nc, T] = size(X);

    for r = 1:Nc
        x = X(r,:);   % 单细胞轨迹

        % ---- (t -> t+1) 构造 ----
        inputSeq  = x(1:end-1);
        targetSeq = x(2:end);

        % ---- 截断/补零到 targetLen ----
        L = min(numel(inputSeq), targetLen);
        in_fix  = zeros(1, targetLen, 'like', x);
        out_fix = zeros(1, targetLen, 'like', x);

        in_fix(1:L)  = inputSeq(1:L);
        out_fix(1:L) = targetSeq(1:L);

        % ---- 按比例划分 ----
        i1 = floor(targetLen*ratioTrain);
        i2 = floor(targetLen*(ratioTrain+ratioVal));
        if i1 < 1, i1 = 1; end
        if i2 <= i1, i2 = i1+1; end

        Atr{end+1} = in_fix(1:i1);
        Btr{end+1} = out_fix(1:i1);

        Ava{end+1} = in_fix(1:i1);
        Bva{end+1} = out_fix(1:i1);

        Ate{end+1} = in_fix(1:i1);
        Bte{end+1} = out_fix(1:i1);
    end
end
end
