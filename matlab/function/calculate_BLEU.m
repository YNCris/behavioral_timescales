function score_list = calculate_BLEU(raw_strTranslated,strTarget)
strTranslated = cell(size(raw_strTranslated,1),1);
for k = 1:size(strTranslated,1)
    strTranslated{k} = char(raw_strTranslated{k});
end

candidates = strTranslated;
references = strTarget;

parfor k = 1:size(candidates,1)
    candidates{k} = ...
    string(mat2cell( ...
    candidates{k},1,ones(1,length(candidates{k}))));

    references{k} = ...
    string(mat2cell( ...
    references{k},1,ones(1,length(references{k}))));
end

% 4-gram BLEU
score_list = zeros(size(candidates,1),1);
parfor k = 1:size(candidates,1)
    score_list(k,1) = bleuEvaluationScore( ...
    candidates{k}, ...
    references{k},...
    NgramWeights=[0.25,0.25,0.25,0.25]);

    % show steps    
    if rem(k,1000) == 0
        disp(k/size(candidates,1))
    end
end