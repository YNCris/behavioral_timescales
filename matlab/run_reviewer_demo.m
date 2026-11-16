function [episodes, elapsedSeconds] = run_reviewer_demo(dataDir, outputDir)
%RUN_REVIEWER_DEMO Extract far-close-far episodes and plot their temporal PCs.
%   RUN_REVIEWER_DEMO() uses the bundled synthetic recording.
%   RUN_REVIEWER_DEMO(DATADIR, OUTPUTDIR) reads processed recording pairs
%   (*-neu.mat and *-distance-free.mat) and writes a CSV and PNG.
%   Pass [] as DATADIR to use the bundled recording with a custom output folder.

arguments
    dataDir = []
    outputDir (1,1) string = fullfile(pwd, "reviewer_demo_output")
end

timer = tic;
if isempty(which('pca'))
    error('reviewer_demo:MissingPCA', ...
        'Install MATLAB Statistics and Machine Learning Toolbox (pca).');
end

fs = 30;
flank = 5 * fs;
if isempty(dataDir)
    repoDir = fileparts(fileparts(mfilename('fullpath')));
    fixture = readmatrix(fullfile(repoDir, 'demo', 'reviewer_demo_data.csv'), ...
        'NumHeaderLines', 1);
    frameTime = (fixture(1,1):1/fs:fixture(end,1))';
    neural = interp1(fixture(:,1), fixture(:,3:end), frameTime);
    closeMask = interp1(fixture(:,1), fixture(:,2), frameTime, 'previous');
    [episodes, traces] = analyzeRecording('synthetic', neural, closeMask, fs, flank);
else
    files = dir(fullfile(dataDir, 'free*-neu.mat'));
    if isempty(files)
        error('reviewer_demo:NoRecordings', ...
            'No free*-neu.mat files found in %s.', string(dataDir));
    end
    perRecording = cell(numel(files), 1);
    perRecordingTraces = cell(numel(files), 1);
    for i = 1:numel(files)
        name = erase(string(files(i).name), '-neu.mat');
        recording = load(fullfile(files(i).folder, files(i).name), 'dff_smo_Fc');
        distance = load(fullfile(files(i).folder, name + "-distance-free.mat"), 'dist_data');
        [perRecording{i}, perRecordingTraces{i}] = analyzeRecording( ...
            name, recording.dff_smo_Fc', distance.dist_data{2}, fs, flank);
    end
    episodes = vertcat(perRecording{:});
    traces = vertcat(perRecordingTraces{:});
end

if isempty(episodes)
    error('reviewer_demo:NoEpisodes', 'No complete far-close-far episodes found.');
end
if ~isfolder(outputDir)
    [ok, message] = mkdir(outputDir);
    if ~ok
        error('reviewer_demo:OutputFolder', '%s', message);
    end
end

figureHandle = figure('Visible', 'off', 'Color', 'w');
cleanupFigure = onCleanup(@() close(figureHandle));
layout = tiledlayout(figureHandle, 2, 3);
nTime = max(cellfun(@(x) size(x,1), traces));
time = ((0:nTime-1) - flank) / fs;
for pc = 1:6
    ax = nexttile(layout);
    heatmapValues = nan(height(episodes), nTime);
    for i = 1:height(episodes)
        if size(traces{i}, 2) >= pc
            heatmapValues(i, 1:size(traces{i},1)) = traces{i}(:,pc);
        end
    end
    imagesc(ax, time, 1:height(episodes), heatmapValues, ...
        'AlphaData', isfinite(heatmapValues));
    clim(ax, [0 1]);
    hold(ax, 'on');
    xline(ax, 0, 'k:');
    plot(ax, episodes.CloseDuration_s, 1:height(episodes), 'k.');
    title(ax, sprintf('PC %d', pc));
    xlabel(ax, 'Time from close onset (s)');
    ylabel(ax, 'Episode');
end
title(layout, 'Far-close-far episodes, normalized temporal PCs');
colorbarHandle = colorbar(ax);
colorbarHandle.Layout.Tile = 'east';

writetable(episodes, fullfile(outputDir, 'episodes.csv'));
exportgraphics(figureHandle, fullfile(outputDir, 'temporal_pcs.png'), 'Resolution', 150);
elapsedSeconds = toc(timer);
fprintf('Analyzed %d episodes in %.2f s. Output: %s\n', ...
    height(episodes), elapsedSeconds, outputDir);
end

function [episodes, traces] = analyzeRecording(name, neural, closeMask, fs, flank)
closeMask = closeMask(:);
if size(neural,1) ~= numel(closeMask) || size(neural,2) < 2 || ...
        any(~isfinite(neural(:))) || any(~ismember(closeMask, [0 1]))
    error('reviewer_demo:InvalidRecording', ...
        '%s requires aligned finite neural activity and binary proximity labels.', name);
end
edges = diff([0; closeMask; 0]);
starts = find(edges == 1);
ends = find(edges == -1) - 1;
duration = (ends - starts + 1) / fs;
% Match the original analysis, which thresholds the endpoint difference.
frameSpan = ends - starts;
eligible = find(frameSpan >= 2 * fs & frameSpan <= 10 * fs & ...
    starts > flank & ends + flank <= numel(closeMask));
keep = false(size(starts));
traces = cell(numel(starts), 1);
pc1Variance = nan(size(starts));
for i = eligible'
    if any(closeMask(starts(i)-flank:starts(i)-1)) || ...
            any(closeMask(ends(i)+1:ends(i)+flank))
        continue
    end
    keep(i) = true;
    episodeFrames = starts(i)-flank:ends(i)+flank;
    nComponents = min([6, size(neural,2)-1, numel(episodeFrames)]);
    [coeff, ~, ~, ~, explained] = pca(neural(episodeFrames,:)', ...
        'NumComponents', nComponents);
    low = min(coeff, [], 1);
    span = max(coeff, [], 1) - low;
    span(span == 0) = 1;
    traces{i} = (coeff - low) ./ span;
    pc1Variance(i) = explained(1);
end
traces = traces(keep);
episodes = table(repmat(string(name), nnz(keep), 1), starts(keep), ...
    ends(keep), duration(keep), pc1Variance(keep), 'VariableNames', ...
    {'Recording', 'CloseStartFrame', 'CloseEndFrame', 'CloseDuration_s', 'PC1Explained_pct'});
end
