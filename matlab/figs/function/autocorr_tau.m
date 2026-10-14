function tau = autocorr_tau(trace, fs, maxLagSec)
% trace: 时间序列 (1 x T)
% fs: 采样率 (Hz)
% maxLagSec: 最大拟合延迟 (秒)

if nargin < 3
    maxLagSec = 2; % 默认只拟合前2秒
end

% 去均值
trace = trace - mean(trace);

% 自相关
[acf, lags] = xcorr(trace, 'coeff'); 
mid = ceil(length(lags)/2);
acf = acf(mid:end);       % 只取正延迟
lags = lags(mid:end)/fs;  % 转换成秒

% 拟合指数衰减
idx = lags > 0 & lags < maxLagSec;
fitFun = fittype('exp(-x/tau)','independent','x','coefficients','tau');
fitObj = fit(lags(idx)', acf(idx)', fitFun, 'StartPoint', 0.5);

tau = fitObj.tau;
end