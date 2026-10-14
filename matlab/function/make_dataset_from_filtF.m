function [Atr,Btr,GTtr,Ava,Bva,GTva,Ate,Bte,GTte] = make_dataset_from_filtF(filt_F_cell, ...
    fracTrain, fracVal, fracTest)
% ----------------------------------------------------------
% 输入:
%   filt_F_cell : cell数组，每个元素 neuron×time (double)
%   fracTrain, fracVal, fracTest : 数据集比例 (加起来=1)
%
% 输出:
%   Atr,Btr,GTtr : 训练集 (cell数组, 每条 trace 奇偶对)
%   Ava,Bva,GTva : 验证集
%   Ate,Bte,GTte : 测试集
% ----------------------------------------------------------

%% 1. 把所有 neuron trace 收集成一个 cell
allTraces = {};
for f = 1:numel(filt_F_cell)
    mat = filt_F_cell{f}; % neuron × time
    [nNeuron,T] = size(mat);
    for n = 1:nNeuron
        allTraces{end+1,1} = mat(n,:); %#ok<AGROW>
    end
end
N = numel(allTraces);

%% 2. 随机打乱 & 划分
idx = randperm(N);
nTrain = round(fracTrain*N);
nVal   = round(fracVal*N);
nTest  = N - nTrain - nVal;
idxTrain = idx(1:nTrain);
idxVal   = idx(nTrain+1 : nTrain+nVal);
idxTest  = idx(nTrain+nVal+1 : end);

%% 3. 构造奇偶分片
[Atr,Btr,GTtr] = odd_even_pairs(allTraces(idxTrain));
[Ava,Bva,GTva] = odd_even_pairs(allTraces(idxVal));
[Ate,Bte,GTte] = odd_even_pairs(allTraces(idxTest));

end

%% ================= local helper =================
function [A,B,GT] = odd_even_pairs(traces)
% traces : cell数组，每个元素 1×T
A={}; B={}; GT={};
for i=1:numel(traces)
    x = traces{i};
    T = length(x);
    oddIdx = 1:2:T; evenIdx = 2:2:T;
    L = min(numel(oddIdx),numel(evenIdx));
    odd = x(oddIdx(1:L));
    even= x(evenIdx(1:L));
    % 这里 GT 只存 odd 对齐的 clean trace（注意: 实验数据没GT, 这里只是方便接口）
    clean = (odd+even)/2; 

    % 奇->偶
    A{end+1,1} = single(reshape(odd,[1,L]));
    B{end+1,1} = single(reshape(even,[1,L]));
    GT{end+1,1}= single(reshape(clean,[1,L]));
    % 偶->奇
    A{end+1,1} = single(reshape(even,[1,L]));
    B{end+1,1} = single(reshape(odd,[1,L]));
    GT{end+1,1}= single(reshape(clean,[1,L]));
end
end
