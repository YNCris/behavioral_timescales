function H = spectral_entropy(eigvals, normalize)
% SPECTRAL_ENTROPY 计算协方差特征值谱的熵
%   H = spectral_entropy(eigvals, normalize)
%
%   eigvals   : 协方差矩阵的特征值向量 (必须非负)
%   normalize : 是否归一化到 [0,1]（true/false, 默认true）
%
%   H         : 谱熵值

if nargin < 2
    normalize = true;
end

eigvals = eigvals(:);
eigvals = eigvals(eigvals > 0);   % 去掉0或负数（数值误差）

p = eigvals / sum(eigvals);       % 概率分布
H = -sum(p .* log(p + eps));      % Shannon entropy

if normalize
    H = H / log(length(p));       % 归一化到 [0,1]
end
end