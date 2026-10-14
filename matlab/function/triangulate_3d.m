function [X, reprojErr] = triangulate_3d(points,cam_mat,camnum)

A = zeros(camnum * 2, 4);

for i = 1:camnum    
    idx = 2 * i;
    A(idx-1:idx,:) = points(:, i) * cam_mat(3,:,i) - cam_mat(1:2,:,i);
end

[~,~,V] = svd(A);
X = V(:, end);
X = X/X(end);
X = X(1:3);

% calculate reprojection error
reprojErr = nan(1,camnum);
for i = 1:camnum  
  reprojPoint = cam_mat(:,:,i)*[X; 1];
  reprojPoint = reprojPoint/reprojPoint(end);
  reprojErr(i) = norm(points(:, i) - reprojPoint(1:2));
end