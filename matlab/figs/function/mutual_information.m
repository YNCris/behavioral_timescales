function MI = mutual_information(x, y, nbin)
% MUTUAL_INFORMATION 计算两个连续变量的互信息 I(X;Y)
% ----------------------------------------------------------
% 输入:
%   x, y   : 两个向量 (长度相同)
%   nbin   : 分箱数（可选，默认 20）
%
% 输出:
%   MI     : 互信息 (单位: nats)
%
% 示例:
%   MI = mutual_information(speed, power, 20);

if nargin < 3
    nbin = 20;
end

% 去除 NaN
mask = ~(isnan(x) | isnan(y));
x = x(mask);
y = y(mask);

% 离散化为相同数量的bin
edges_x = linspace(min(x), max(x), nbin+1);
edges_y = linspace(min(y), max(y), nbin+1);
id_x = discretize(x, edges_x);
id_y = discretize(y, edges_y);

% 构建联合频数表
joint = accumarray([id_x(:), id_y(:)], 1, [nbin, nbin]);
joint = joint / sum(joint(:));     % 联合概率
px = sum(joint, 2);                % 边缘分布 P(X)
py = sum(joint, 1);                % 边缘分布 P(Y)

% 计算互信息
eps = 1e-12;
PxPy = px * py;                    % 独立假设下的联合分布
ratio = joint ./ (PxPy + eps);
MI = nansum(joint(:) .* log(ratio(:) + eps));

end