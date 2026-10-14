function all_lw_free_fix_p_list = quantify_weights2line(...
    all_free_fix_p_weights,line_width_list)
[B,I] = sort(all_free_fix_p_weights);
all_lw_free_fix_p_list = zeros(size(all_free_fix_p_weights));
seg_len = round(length(all_lw_free_fix_p_list)/length(line_width_list));
for k = 1:length(line_width_list)
    all_lw_free_fix_p_list(((k-1)*seg_len+1):(k*seg_len)) = ...
        line_width_list(k);
end
all_lw_free_fix_p_list = all_lw_free_fix_p_list(1:length(all_free_fix_p_weights));
all_lw_free_fix_p_list(I) = all_lw_free_fix_p_list;