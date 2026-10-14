function D = fractal_dimension(points)
    % 计算点的范围
    minX = min(points(:,1)); maxX = max(points(:,1));
    minY = min(points(:,2)); maxY = max(points(:,2));

    % 定义不同的网格尺度
    epsilons = logspace(-2, 0, 10); % 10 个尺度从 0.01 到 1
    N = zeros(size(epsilons));

    for i = 1:length(epsilons)
        eps = epsilons(i);
        % 计算网格索引
        x_idx = floor((points(:,1) - minX) / eps);
        y_idx = floor((points(:,2) - minY) / eps);
        
        % 统计网格中的唯一点数
        N(i) = numel(unique(sub2ind([ceil((maxX-minX)/eps), ceil((maxY-minY)/eps)], x_idx+1, y_idx+1)));
    end

    % 线性拟合 log(N) ~ log(1/ε) 斜率即为分形维数
    coeffs = polyfit(log(1./epsilons), log(N), 1);
    D = coeffs(1);
end
