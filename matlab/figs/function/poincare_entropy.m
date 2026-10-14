function S = poincare_entropy(points, num_bins)
    % 计算点的范围
    minX = min(points(:,1)); maxX = max(points(:,1));
    minY = min(points(:,2)); maxY = max(points(:,2));

    % 在 [minX, maxX] x [minY, maxY] 上划分网格
    [counts, ~, ~] = histcounts2(points(:,1), points(:,2), num_bins);

    % 归一化，计算概率
    P = counts / sum(counts(:));
    P(P == 0) = [];  % 避免 log(0)

    % 计算 Shannon 熵
    S = -sum(P .* log(P));
end