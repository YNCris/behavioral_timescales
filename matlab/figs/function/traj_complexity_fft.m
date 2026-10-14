function C = traj_complexity_fft(x)
X = abs(fft(x-mean(x)));
half = floor(length(X)/2);
power = X(2:half).^2;  % 去掉直流
freq_ratio = sum(power(round(end*0.25):end)) / sum(power);
C = freq_ratio;   % 高频能量比例
end