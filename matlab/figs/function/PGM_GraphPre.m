function [sL,tL,weightL,GN,GA] = PGM_GraphPre(TransM)
%{
    图可视化前数据预处理，生成图类
%}
sL = zeros(1,size(TransM,1)*size(TransM,2));
tL = sL;
weightL = sL;
count = 1;
for m = 1:size(TransM,1)
    for n = 1:size(TransM,2)
        sL(:,count) = n;
        tL(:,count) = m;
        weightL(:,count) = TransM(m,n);
        count = count + 1;
    end
end
GN = graph(sL,tL,weightL);%无向图
GA = digraph(sL,tL,weightL);%有向图