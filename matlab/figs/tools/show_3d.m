
drawline = [ 1 2; 1 3;2 3; 4 5;4 6;5 7;...
        6 8;7 14;8 14;5 13;6 13;7 13;8 13;...
    5 9;7 11;6 10; 8 12;14 15; 15 16];

figure(1)

savepath = 'E:\MTPM_body_language\进展文档\素材';

writeobj = VideoWriter([savepath,'\test20241106.avi']);

open(writeobj)

for k = 2000:1:18000
    X4 = ys_pca_predict(k,1:3:end)';
    Y4 = ys_pca_predict(k,2:3:end)';
    Z4 = ys_pca_predict(k,3:3:end)';
    plot_skl_dl(X4,Y4,Z4,'c','c',drawline)
    hold on

    X3 = XTrain(k,1:3:end)';
    Y3 = XTrain(k,2:3:end)';
    Z3 = XTrain(k,3:3:end)';
    plot_skl_dl(X3,Y3,Z3,'g','g',drawline)
    hold on


    X1 = YTrain(k,1:3:end)';
    Y1 = YTrain(k,2:3:end)';
    Z1 = YTrain(k,3:3:end)';
    plot_skl_dl(X1,Y1,Z1,'b','b',drawline)
    hold on

    X2 = ys_predict(k,1:3:end)';
    Y2 = ys_predict(k,2:3:end)';
    Z2 = ys_predict(k,3:3:end)';
    plot_skl_dl(X2,Y2,Z2,'r','r',drawline)
    hold off

    axis([-500,500,-500,500,-50,200])

    view(2)

    title(k)

    F = getframe(gca);
    % pause(0.0000001)

    framedata = F.cdata;

    writeVideo(writeobj,framedata)


end

close(writeobj)

%% show single figure
figure
for m = 1:18
    subplot(3,6,m)
    k = 2000+m*10

    X4 = ys_pca_predict(k,1:3:end)';
    Y4 = ys_pca_predict(k,2:3:end)';
    Z4 = ys_pca_predict(k,3:3:end)';
    plot_skl_dl(X4,Y4,Z4,'c','c',drawline)
    hold on

    X3 = XTrain(k,1:3:end)';
    Y3 = XTrain(k,2:3:end)';
    Z3 = XTrain(k,3:3:end)';
    plot_skl_dl(X3,Y3,Z3,'g','g',drawline)
    hold on


    X1 = YTrain(k,1:3:end)';
    Y1 = YTrain(k,2:3:end)';
    Z1 = YTrain(k,3:3:end)';
    plot_skl_dl(X1,Y1,Z1,'b','b',drawline)
    hold on

    X2 = ys_predict(k,1:3:end)';
    Y2 = ys_predict(k,2:3:end)';
    Z2 = ys_predict(k,3:3:end)';
    plot_skl_dl(X2,Y2,Z2,'r','r',drawline)
    hold off

    axis([-300,300,-300,300,-50,200])

    view(2)

    title(k)

end

%%
for k = 2000:4:18000
    X4 = valid_ys_pca_predict(k,1:3:end)';
    Y4 = valid_ys_pca_predict(k,2:3:end)';
    Z4 = valid_ys_pca_predict(k,3:3:end)';
    plot_skl_dl(X4,Y4,Z4,'c','c',drawline)
    hold on

    X3 = valid_XTrain(k,1:3:end)';
    Y3 = valid_XTrain(k,2:3:end)';
    Z3 = valid_XTrain(k,3:3:end)';
    plot_skl_dl(X3,Y3,Z3,'g','g',drawline)
    hold on


    X1 = valid_YTrain(k,1:3:end)';
    Y1 = valid_YTrain(k,2:3:end)';
    Z1 = valid_YTrain(k,3:3:end)';
    plot_skl_dl(X1,Y1,Z1,'b','b',drawline)
    hold on

    X2 = valid_ys_predict(k,1:3:end)';
    Y2 = valid_ys_predict(k,2:3:end)';
    Z2 = valid_ys_predict(k,3:3:end)';
    plot_skl_dl(X2,Y2,Z2,'r','r',drawline)
    hold off

    axis([-500,500,-500,500,-50,200])

    view(2)

    title(k)
    pause(0.0000001)
end