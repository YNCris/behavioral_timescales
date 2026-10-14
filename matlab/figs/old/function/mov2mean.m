function self_mov_s1_mean = mov2mean(self_mov_s1)
self_mov_s1_mat = cell2mat(self_mov_s1');
self_mov_s1_mean = -1*ones(size(self_mov_s1_mat,1),1);
for k = 1:size(self_mov_s1_mat,1)
    templist = self_mov_s1_mat(k,:);
    templist(templist==-1) = [];
    if ~isempty(templist)
        if length(templist)>1
            self_mov_s1_mean(k,1) = mean(templist);
        else
            self_mov_s1_mean(k,1) = templist;
        end
    end
end