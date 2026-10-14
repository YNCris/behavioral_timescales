function F0 = tpm_rolling(stack, win)
% dff_max_projection - compute rolling ΔF/F max projection
%
% Usage:
%   dFF_max = dff_max_projection(stack, win)
%
% Inputs:
%   stack : [H x W x T] 3D array (双光子序列)
%   win   : scalar, baseline window size (e.g. 10)
%
% Output:
%   dFF_max : [H x W] ΔF/F max projection image
%
% Example:
%   stack = loadtiff('your_file.tif');
%   dFF_max = dff_max_projection(stack, 10);
%   imagesc(dFF_max); colormap hot; axis image;

    [H, W, T] = size(stack);

    % reshape stack -> (pixels × time)
    stack2D = reshape(stack, [], T);

    % rolling baseline (按时间维度)
    F0 = movmean(stack2D, win, 2);

    F0 = reshape(F0, H, W, T);
end