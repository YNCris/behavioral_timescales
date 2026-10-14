function [mean_BLEU,BLEU_list] = BLEU(candidate_token, reference_token)
%{
    计算序列的BLEU
    candidate_token：计算结果
    reference_token：ground truth
%}
% clear all
% [ndata, text, alldata] = xlsread('test_BLEU.xls');
% candidate_token = text(:,2);
% reference_token_1 = 'ABCDEF';
% reference_token_2 = 'A D B C D';
% reference_token = text(:,1);

BLEU_list = zeros(size(candidate_token));
for k = 1:size(candidate_token,1)
    try
        samelist = double(candidate_token{k}==reference_token{k});
    catch
        disp('E')
    end
    BLEU_list(k,1) = sum(samelist)/length(samelist);
end
mean_BLEU = mean(BLEU_list(:));
