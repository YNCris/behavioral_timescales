function S = knn_entropy(points, k)
    N = size(points, 1);
    D = pdist(points); % 计算点间距离
    D(D == 0) = Inf;
    D = sort(D, 2); % 对每个点排序
    r_k = D(:, k+1); % 取第 k 近邻距离

    % 计算概率密度估计
    V = pi * r_k.^2; % 假设局部区域为圆形，计算面积
    P = 1 ./ (N * V); % 概率密度

    % 避免 log(0)
    P(P == 0) = 1e-10;

    % 计算熵
    S = -mean(log(P));
end