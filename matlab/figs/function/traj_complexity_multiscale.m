function C = traj_complexity_multiscale(X, win, step)
% X: [T x D] 轨迹（如 PC10-30 的投影或前几PC）
% win: 窗口长度(点数)，step: 步长(点数)
% 返回 C: 多尺度复杂度的中位数（也可改 mean）
if nargin<3, step = floor(win/2); end
T = size(X,1); vals = [];
for s = 1:step:(T-win)
    seg = X(s:s+win-1,:);
    diffs = diff(seg,1,1);
    L = sum(sqrt(sum(diffs.^2,2)));
    D = norm(seg(end,:) - seg(1,:));
    vals(end+1) = L / max(D, eps); %#ok<AGROW>
end
C = median(vals);
end