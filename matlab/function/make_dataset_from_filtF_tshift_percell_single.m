function [Atr,Btr,GTtr,Ava,Bva,GTva,Ate,Bte,GTte] = ...
    make_dataset_from_filtF_tshift_percell_single(filt_F_cell, ratioTrain, ratioVal, ratioTest, varargin)
% 将每个 [Ncell × T] 的矩阵，拆成 Ncell 条 [1 × L] 序列，
% 做 (t → t+1) 监督：输入 x(1:L)，输出 x(2:L+1)。
% 为避免两次池化(×2×2)与反卷积尺寸对不齐，L 会裁到 4 的倍数。

% 可选参数
p = inputParser;
addParameter(p,'CropMultipleOf',4,@(x)isnumeric(x)&&isscalar(x)&&x>0);
parse(p,varargin{:});
m = p.Results.CropMultipleOf;

Atr={}; Btr={}; Ava={}; Bva={}; Ate={}; Bte={};
GTtr={}; GTva={}; GTte={};

for k = 1:numel(filt_F_cell)
    X = filt_F_cell{k};          % [Ncell × T]
    if isempty(X), continue; end
    [Nc, T] = size(X);

    for r = 1:Nc
        x = X(r, :);             % 该细胞的时间序列，[1 × T]
        if numel(x) < 2, continue; end

        % (t → t+1)
        L = numel(x) - 1;        % 原始长度
        L = floor(L/m) * m;      % 裁到 m(=4) 的倍数，避免 U-Net 尺寸对齐问题
        if L < 4, continue; end  % 太短就跳过

        inputSeq  = x(1:L);      % [1 × L]
        targetSeq = x(2:L+1);    % [1 × L]

        % 按比例划分
        i1 = floor(L*ratioTrain);
        i2 = floor(L*(ratioTrain+ratioVal));
        % 防止空片段
        i1 = max(i1,1);
        i2 = max(i2,i1+1);

        Atr{end+1} = inputSeq(1:i1);
        Btr{end+1} = targetSeq(1:i1);

        Ava{end+1} = inputSeq(i1+1:i2);
        Bva{end+1} = targetSeq(i1+1:i2);

        Ate{end+1} = inputSeq(i2+1:end);
        Bte{end+1} = targetSeq(i2+1:end);
    end
end
end
