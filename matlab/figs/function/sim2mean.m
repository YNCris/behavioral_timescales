function self_sim_s1_mean = sim2mean(self_sim_s1)
self_sim_s1_mean = zeros(size(self_sim_s1{1}));
for k = 1:size(self_sim_s1,1)
    self_sim_s1_mean = self_sim_s1_mean+...
        self_sim_s1{k};
end
self_sim_s1_mean = self_sim_s1_mean./...
    size(self_sim_s1,1);