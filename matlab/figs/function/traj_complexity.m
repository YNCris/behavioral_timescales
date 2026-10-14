function C = traj_complexity(X)
% TRAJ_COMPLEXITY 计算轨迹复杂度 (路径长度 / 直线距离)
% X: [T x D] 矩阵, T=时间点, D=维度 (比如PC投影)
%
% 返回: C, 越大说明轨迹越复杂

% 轨迹长度
diffs = diff(X,1,1);              % [T-1 x D]
step_lengths = sqrt(sum(diffs.^2,2));
L = sum(step_lengths);

% 起点到终点距离
D = sqrt(sum((X(end,:) - X(1,:)).^2));

C = L / (D + eps); % 防止除零
end