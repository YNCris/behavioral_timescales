%% ================================================================
%  Odd/Even Noise2Noise 1D U-Net for TPM-like denoising (realistic sim)
%  - Realistic TPM Ca2+ trace with visible "fire peaks"
%  - Sequence input (cell arrays), 1D U-Net, odd/even bi-direction pairs
% ================================================================
clear; clc; rng(1);

%% -------------------- Config --------------------
T            = 2048;          % 原始长度 (≈ 68 s @30 Hz)
dt           = 0.033;         % 采样间隔 (~30 Hz)

Ntrain       = 4096; 
Nval         = 64;  
Ntest        = 5;

% 生理/成像仿真参数（可调来改变“火峰”显著度）
phys.tau_rise    = 0.06;      % s, 上升常数 (GCaMP6f 快)
phys.tau_decay   = 0.5;       % s, 衰减常数
phys.rate_low    = 0.10;      % Hz, 静息段发放率
phys.rate_high   = 2.50;      % Hz, 活动段发放率
phys.seg_mean    = 5.0;       % s, 速率分段平均时长 (高/低切换，telegraph-like)
phys.amp_logn_mu = -1.0;      % 对数正态幅度 μ
phys.amp_logn_sd = 0.55;      % 对数正态幅度 σ
phys.alpha_sat   = 1.0;       % 饱和非线性强度 (越大越明显)
phys.Kd_sat      = 0.35;      % 饱和半饱和常数
phys.F0          = 1000;      % 基线光子计数（决定绝对光子水平）
phys.bleach_frac = 0.05;      % 总时长上的线性漂白比例
phys.drift_amp   = 0.03;      % 慢漂移相对幅度 (对 F0)
phys.npil_amp    = 0.10;      % Neuropil (慢低频背景) 相对幅度

% 噪声（真实感：先转光子，再加泊松/读出噪声）
noise.poissonGain = 1.0;      % 光子增益已体现在 F0，无需再缩放，设 1.0
noise.readStd_rel = 0.5;     % 相对读出噪声，对应 F0*readStd_rel 绝对 σ

% 训练参数
miniBatchSize = 16;
maxEpochs     = 10;
learnRate     = 1e-4;

%% -------------------- Generate datasets --------------------
[Atr,Btr,GTtr] = gen_set_oddeven_realistic(Ntrain,T,dt,phys,noise);
[Ava,Bva,GTva] = gen_set_oddeven_realistic(Nval,  T,dt,phys,noise);
[Ate,Bte,GTte] = gen_set_oddeven_realistic(Ntest, T,dt,phys,noise);

L = length(Atr{1});  % 序列长度 (≈ T/2)

% 训练前预览，确认能看到清晰 fire peaks
figure('Name','Preview GT vs Noisy (odd/even)','Color','w'); 
for i=1:min(Ntest,3)
    subplot(3,1,i);
    plot(GTte{i},'k','LineWidth',1.2); hold on;
    plot(Bte{i},'r'); % 用偶序列当 noisy 参照
    grid on; ylabel(sprintf('#%d',i));
    if i==1, title('Clean (GT, odd index) vs Noisy target (even)'); end
end
xlabel('time (samples)');

%% -------------------- Convert to cell sequences [1×L] --------------------
toCell = @(C) cellfun(@(x) reshape(x, [1,numel(x)]), C, 'uni',0);

Xtrain = toCell(Atr); Ytrain = toCell(Btr);
Xval   = toCell(Ava); Yval   = toCell(Bva);
Xtest  = toCell(Ate); Ytest  = toCell(Bte);

%% -------------------- Build 1D U-Net (sequence) --------------------
lgraph = layerGraph();
lgraph = addLayers(lgraph, sequenceInputLayer(1, 'Name','input', 'MinLength',L));

% encoder1
enc1 = [
    convolution1dLayer(5,32,'Padding','same','Name','enc1_conv1')
    reluLayer('Name','enc1_relu1')
    convolution1dLayer(5,32,'Padding','same','Name','enc1_conv2')
    reluLayer('Name','enc1_relu2')
    maxPooling1dLayer(2,'Stride',2,'Name','pool1')];
lgraph = addLayers(lgraph, enc1);
lgraph = connectLayers(lgraph,'input','enc1_conv1');

% encoder2
enc2 = [
    convolution1dLayer(5,64,'Padding','same','Name','enc2_conv1')
    reluLayer('Name','enc2_relu1')
    convolution1dLayer(5,64,'Padding','same','Name','enc2_conv2')
    reluLayer('Name','enc2_relu2')
    maxPooling1dLayer(2,'Stride',2,'Name','pool2')];
lgraph = addLayers(lgraph, enc2);
lgraph = connectLayers(lgraph,'pool1','enc2_conv1');

% bottom
bottom = [
    convolution1dLayer(5,128,'Padding','same','Name','bottom_conv1')
    reluLayer('Name','bottom_relu1')
    convolution1dLayer(5,128,'Padding','same','Name','bottom_conv2')
    reluLayer('Name','bottom_relu2')];
lgraph = addLayers(lgraph, bottom);
lgraph = connectLayers(lgraph,'pool2','bottom_conv1');

% decoder2
up2   = transposedConv1dLayer(2,64,'Stride',2,'Name','up2');
cat2  = concatenationLayer(1,2,'Name','cat2'); % 按通道拼
dec2  = [
    convolution1dLayer(5,64,'Padding','same','Name','dec2_conv1')
    reluLayer('Name','dec2_relu1')
    convolution1dLayer(5,64,'Padding','same','Name','dec2_conv2')
    reluLayer('Name','dec2_relu2')];
lgraph = addLayers(lgraph, up2);   lgraph = addLayers(lgraph, cat2);  lgraph = addLayers(lgraph, dec2);
lgraph = connectLayers(lgraph, 'bottom_relu2','up2');
lgraph = connectLayers(lgraph, 'up2','cat2/in1');
lgraph = connectLayers(lgraph, 'enc2_relu2','cat2/in2');
lgraph = connectLayers(lgraph, 'cat2','dec2_conv1');

% decoder1
up1   = transposedConv1dLayer(2,32,'Stride',2,'Name','up1');
cat1  = concatenationLayer(1,2,'Name','cat1');
dec1  = [
    convolution1dLayer(5,32,'Padding','same','Name','dec1_conv1')
    reluLayer('Name','dec1_relu1')
    convolution1dLayer(5,32,'Padding','same','Name','dec1_conv2')
    reluLayer('Name','dec1_relu2')];
lgraph = addLayers(lgraph, up1);   lgraph = addLayers(lgraph, cat1);  lgraph = addLayers(lgraph, dec1);
lgraph = connectLayers(lgraph, 'dec2_relu2','up1');
lgraph = connectLayers(lgraph, 'up1','cat1/in1');
lgraph = connectLayers(lgraph, 'enc1_relu2','cat1/in2');
lgraph = connectLayers(lgraph, 'cat1','dec1_conv1');

% head
head = [
    convolution1dLayer(1,32,'Padding','same','Name','head_conv1')
    reluLayer('Name','head_relu')
    convolution1dLayer(1,1,'Padding','same','Name','head_conv2')
    regressionLayer('Name','out')];
lgraph = addLayers(lgraph, head);
lgraph = connectLayers(lgraph,'dec1_relu2','head_conv1');

%% -------------------- Train --------------------
opts = trainingOptions('adam', ...
    'InitialLearnRate',learnRate, ...
    'MaxEpochs',maxEpochs, ...
    'MiniBatchSize',miniBatchSize, ...
    'Shuffle','every-epoch', ...
    'ValidationData',{Xval,Yval}, ...
    'Plots','training-progress', ...
    'Verbose',true);

net = trainNetwork(Xtrain, Ytrain, lgraph, opts);

%% -------------------- Test --------------------
Yhat = predict(net, Xtest);

snr_db = @(ref,est) 10*log10(sum(ref.^2)/sum((ref-est).^2));
for i=1:Ntest
    gt   = GTte{i}; 
    noisy= Ytest{i};
    den  = Yhat{i};
    s0=snr_db(gt,noisy); s1=snr_db(gt,den);
    fprintf('Test %d: noisy %.2f dB -> denoised %.2f dB (Δ=%.2f)\n',i,s0,s1,s1-s0);
    figure('Color','w','Name',sprintf('Test #%d',i));
    plot(gt,'k','LineWidth',1.1); hold on; plot(noisy,'r'); plot(den,'b','LineWidth',1.0);
    legend('GT (clean odd)','Noisy target (even)','Denoised'); grid on;
    title(sprintf('Sample %d  SNR: %.2f → %.2f dB',i,s0,s1));
    xlabel('time (samples)'); ylabel('\DeltaF/F');
end

%% ============== Local functions (simulation & dataset) ==============
function [A,B,GT] = gen_set_oddeven_realistic(N,T,dt,phys,noise)
    A = cell(2*N,1); B = cell(2*N,1); GT = cell(2*N,1);
    for i=1:N
        [Fclean,dff_clean] = sim_tpm_trace(T,dt,phys);        % 干净光子轨迹 + ΔF/F
        noisy = add_tp_noise_photon(Fclean,noise);            % 光子域加噪返回“带噪光子值”
        % 用真实基线恢复成 ΔF/F 观测
        F0_t  = baseline_profile(T,phys);                     % 与 sim 中一致的基线/漂白
        dff_noisy = (noisy - F0_t)./max(F0_t,eps);

        % 奇偶分片（训练在 ΔF/F 空间里进行）
        oddIdx = 1:2:T; evenIdx = 2:2:T; 
        L = min(numel(oddIdx), numel(evenIdx));
        odd = dff_noisy(oddIdx(1:L));
        even= dff_noisy(evenIdx(1:L));
        clean_sub = dff_clean(oddIdx(1:L));   % 评估用 GT（与 odd 对齐）

        % 双向
        A{2*i-1} = single(odd(:)');  B{2*i-1} = single(even(:)'); GT{2*i-1} = single(clean_sub(:)');
        A{2*i}   = single(even(:)'); B{2*i}   = single(odd(:)');  GT{2*i}   = single(clean_sub(:)');
    end
end

function [Fclean, dff] = sim_tpm_trace(T,dt,p)
    % --- 基线/漂白/慢漂移 ---
    F0_t = baseline_profile(T,p); % 平滑慢变 + 轻度线性漂白

    % --- 速率分段（高/低） ---
    r = piecewise_rate(T,dt,p.rate_low,p.rate_high,p.seg_mean);

    % --- 生成 spike 幅度列（对数正态） ---
    amps = lognrnd(p.amp_logn_mu, p.amp_logn_sd, [T,1]); % 平均~0.37，重尾
    % Bernoulli inhomogeneous (<=1 spike / bin)，足够表现 ΔF/F
    spikeMask = rand(T,1) < (r*dt);
    a = amps .* spikeMask; % 每个时间点的等效幅度

    % --- 双指数核（起峰更锐利，类似 GCaMP6f）---
    t = (0:T-1)'*dt;
    k = exp(-t/p.tau_decay) - exp(-t/p.tau_rise);
    k(k<0) = 0;  k = k / sum(k + eps);

    Ca = conv(a, k, 'same');               % 钙瞬变（单位化）
    Ca = Ca / max(Ca+eps);                 % 归一后再缩放到可见 ΔF/F
    Ca = 0.8 * Ca;                         % 调整可见峰幅（0.5~1.0）

    % --- 饱和非线性（近似 GCaMP 饱和）---
    Ca_nl = p.alpha_sat * Ca ./ (p.Kd_sat + Ca);  % ∈[0, alpha_sat]

    % --- Neuropil 背景（低频、相关性）---
    np = p.npil_amp * smooth1D(randn(T,1), round(0.3/dt));

    % --- 干净光子轨迹 ---
    Fclean = F0_t .* (1 + Ca_nl + np);     % 物理上使用光子计数尺度
    % --- ΔF/F（可视化/评估）---
    dff = (Fclean - F0_t)./max(F0_t,eps);
end

function F0_t = baseline_profile(T,p)
    t = linspace(0,1,T)';                          % 归一化时间
    bleach = 1 - p.bleach_frac * t;                % 线性漂白
    slow   = 1 + p.drift_amp*( 0.5*sin(2*pi*0.02*(1:T))' + 0.3*sin(2*pi*0.005*(1:T))' );
    F0_t   = p.F0 * bleach .* slow;                % 平滑慢变基线
    F0_t   = smooth1D(F0_t, 51);
end

function r = piecewise_rate(T,dt,r_low,r_high,seg_mean_s)
    segMean = max(1, round(seg_mean_s/dt));
    r = zeros(T,1);
    i = 1;
    state = (rand<0.5); % 0->low, 1->high
    while i<=T
        len = max( round(segMean*(0.5+rand)), 5 );
        j = min(T, i+len-1);
        r(i:j) = state * r_high + (~state)*r_low;
        state = ~state;
        i = j+1;
    end
end

function y = add_tp_noise_photon(Fclean,noise)
    % Fclean 已是光子尺度（期望），进行泊松采样 + 读出噪声
    photons = poissrnd(max(Fclean,0));
    readSD  = noise.readStd_rel * max(median(Fclean),1);
    y = single( photons + readSD*randn(size(Fclean)) );
end

function y = smooth1D(x,win)
    w = max(3, 2*floor(win/2)+1);
    k = gausswin(w, 2.5); k = k/sum(k);
    y = conv(x, k, 'same');
end
