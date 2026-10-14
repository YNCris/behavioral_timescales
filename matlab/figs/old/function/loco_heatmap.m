function [XX,YY,conv_bk_xy] = loco_heatmap(sel_frame_xy)
sel_frame_xy = round(sel_frame_xy);
min_x = min(min(sel_frame_xy(:,1:2:end)));
max_x = max(max(sel_frame_xy(:,1:2:end)));
min_y = min(min(sel_frame_xy(:,2:2:end)));
max_y = max(max(sel_frame_xy(:,2:2:end)));
[XX,YY] = meshgrid(min_x:max_x,min_y:max_y);
bk_xy = zeros(size(XX));
k_size = 3;
conv_k = conv2(ones(k_size,k_size),ones(k_size,k_size));
bias_frame_xy = sel_frame_xy;
bias_frame_xy(:,1:2:end) = bias_frame_xy(:,1:2:end)-min_x+1;
bias_frame_xy(:,2:2:end) = bias_frame_xy(:,2:2:end)-min_y+1;
for m = 1:size(bias_frame_xy,1)
    for n = 1:(size(bias_frame_xy,2)/2)
        pos_x = bias_frame_xy(m,2*(n-1)+1);
        pos_y = bias_frame_xy(m,2*n);
        bk_xy(pos_y,pos_x) = bk_xy(pos_y,pos_x)+1;
    end
end
conv_bk_xy = mat2gray(sqrt(conv2(bk_xy,conv_k,'same')));