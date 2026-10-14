function [score, startPos, endPos, align1, align2] = ...
    smithWatermanCell(seq, tmpl, matchScore, mismatchPenalty, gapPenalty)
    % seq  : cell array，完整行为序列，如 mov_cell
    % tmpl : cell array，模板行为序列，如 ref_seq{k}
    % 返回 : 最佳得分，匹配区间 (startPos:endPos)，以及对齐后的两个序列
    
    n = numel(seq);
    m = numel(tmpl);
    H = zeros(n+1, m+1);  % DP 矩阵
    traceback = zeros(n+1, m+1); % 记录路径: 1=diag, 2=up, 3=left, 0=reset
    
    maxScore = 0;
    maxPos = [0,0];
    
    % 填 DP 矩阵
    for i = 2:n+1
        for j = 2:m+1
            if strcmp(seq{i-1}, tmpl{j-1})
                diagScore = H(i-1,j-1) + matchScore;
            else
                diagScore = H(i-1,j-1) + mismatchPenalty;
            end
            upScore   = H(i-1,j) + gapPenalty;
            leftScore = H(i,j-1) + gapPenalty;
            
            [H(i,j), tb] = max([0, diagScore, upScore, leftScore]);
            traceback(i,j) = tb-1;  % 0=reset,1=diag,2=up,3=left
            
            if H(i,j) > maxScore
                maxScore = H(i,j);
                maxPos = [i,j];
            end
        end
    end
    
    score = maxScore;
    
    % 回溯 (traceback)
    i = maxPos(1);
    j = maxPos(2);
    align1 = {};
    align2 = {};
    
    while i>1 && j>1 && H(i,j) > 0
        if traceback(i,j) == 1 % diag
            align1 = [{seq{i-1}}, align1];
            align2 = [{tmpl{j-1}}, align2];
            i = i-1; j = j-1;
        elseif traceback(i,j) == 2 % up
            align1 = [{seq{i-1}}, align1];
            align2 = [{'--'}, align2];
            i = i-1;
        elseif traceback(i,j) == 3 % left
            align1 = [{'--'}, align1];
            align2 = [{tmpl{j-1}}, align2];
            j = j-1;
        else
            break;
        end
    end
    
    startPos = i;
    endPos   = maxPos(1)-1;
end