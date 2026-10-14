function p_list = g2_ht(g1,g2)
% 两组假设检验

p_list = zeros(1,3);

group_idx = [ones(1,length(g1)),2*ones(1,length(g2))]';


[h_dist,p_dist] =kstest([g1,g2]);
p_var = vartestn([g1,g2]',group_idx,'Display','off');
p_list(1,2) = p_dist;
p_list(1,3) = p_var;
if p_var>=0.05 && h_dist==0
    % normal distribution, equal variances
    [~,p_t] = ttest(g1,g2);
    p_list(1,1) = p_t;
else
    % not normal distribution, not equal variances
    p_rs = ranksum(g1,g2);
    p_list(1,1) = p_rs;
end

