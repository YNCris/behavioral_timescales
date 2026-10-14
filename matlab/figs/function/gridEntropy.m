function S = gridEntropy(poincare_points, numBins)
    % poincare_points: N x 2 的庞加莱截面点集
    % numBins: 网格划分数（每个维度的分区数）
    
    % 计算 X 和 Y 轴的范围
    minX = min(poincare_points(:,1));
    maxX = max(poincare_points(:,1));
    minY = min(poincare_points(:,2));
    maxY = max(poincare_points(:,2));

    % 创建网格划分
    edgesX = linspace(minX, maxX, numBins + 1);
    edgesY = linspace(minY, maxY, numBins + 1);

    % 计算 2D 直方图（统计每个网格中的点数）
    counts = histcounts2(poincare_points(:,1), poincare_points(:,2), edgesX, edgesY);

    % 归一化得到概率
    P = counts / sum(counts(:));  % 计算每个格子里点的占比

    % 计算 Shannon Entropy
    P_nonzero = P(P > 0);  % 避免 log(0) 问题
    S = -sum(P_nonzero .* log(P_nonzero));

    % 输出熵值
    fprintf('Grid Entropy: %.4f\n', S);
end
