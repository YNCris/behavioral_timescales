function intersection = line_inter(P1,P2,P3,P4)

% 定义两条直线的两个点
% P1 = [-2, 2]; 
% P2 = [5, 3.5]; 
% 
% P3 = [0, 1]; 
% P4 = [0, 0];


% 计算方向向量
d1 = P2 - P1;
d2 = P4 - P3;

% 计算交点参数 t, s
A = [d1', -d2'];
B = P3' - P1';
% 
% if det(A) == 0
%     disp('两条直线平行或重合，无交点');
% else
%     ts = A \ B;
%     intersection = P1 + ts(1) * d1;
%     disp(['交点: (', num2str(intersection(1)), ', ', num2str(intersection(2)), ')']);
% 
%     % 绘制直线
%     figure;
%     hold on;
%     plot([P1(1), P2(1)], [P1(2), P2(2)], 'b-', 'LineWidth', 2);
%     plot([P3(1), P4(1)], [P3(2), P4(2)], 'r-', 'LineWidth', 2);
%     plot(intersection(1), intersection(2), 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 8);
%     legend('Line 1', 'Line 2', 'Intersection', 'Location', 'best');
%     xlabel('x');
%     ylabel('y');
%     title('Intersection of Two Lines (Vector Method)');
%     grid on;
%     hold off;
% end
if det(A) == 0
    disp('两条直线平行或重合，无交点');
else
    ts = A \ B;
    intersection = P1 + ts(1) * d1;
end