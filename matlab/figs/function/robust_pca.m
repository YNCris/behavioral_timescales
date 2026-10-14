function [L, S] = robust_pca(X, lambda, mu, tol, max_iter)
    % 默认参数
    if nargin < 2 || isempty(lambda), lambda = 1/sqrt(max(size(X))); end
    if nargin < 3 || isempty(mu), mu = 1.25/norm(X,2); end
    if nargin < 4, tol = 1e-7; end
    if nargin < 5, max_iter = 1000; end

    % 初始化
    [m, n] = size(X);
    L = zeros(m, n);
    S = zeros(m, n);
    Y = X / max(norm(X,2), norm(X(:),Inf)/lambda);

    for iter = 1:max_iter
        % --- 更新低秩部分 L ---
        [U, Sigma, V] = svd(X - S + (1/mu)*Y, 'econ');
        Sigma = diag(Sigma);
        r = sum(Sigma > 1/mu);
        L = U(:,1:r) * diag(Sigma(1:r) - 1/mu) * V(:,1:r)';

        % --- 更新稀疏部分 S ---
        X_L = X - L + (1/mu)*Y;
        S = sign(X_L) .* max(abs(X_L) - lambda/mu, 0);

        % --- 更新 Y ---
        Z = X - L - S;
        Y = Y + mu * Z;

        % --- 收敛判断 ---
        err = norm(Z, 'fro') / norm(X, 'fro');
        if err < tol
            fprintf('Converged at iteration %d, error = %.2e\n', iter, err);
            break;
        end
    end
end