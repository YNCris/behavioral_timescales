function self_sim_s1 = pose2sim(self_pose_s1)
self_sim_s1 = self_pose_s1;
for k = 1:size(self_pose_s1,1)
    temppose = self_pose_s1{k,1};
    posepos = zeros(16,3);
    posepos(:,1) = temppose(1:3:end);
    posepos(:,2) = temppose(2:3:end);
    posepos(:,3) = temppose(3:3:end);
    self_sim_s1{k,1} = mean(posepos,2);
end
self_sim_s1 = cell2mat(self_sim_s1');