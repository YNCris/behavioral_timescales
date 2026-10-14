%{
    绘制原始骨架测试
%}
clear all
genPath = genpath('./');
addpath(genPath)

%% get filename
filepath = ['X:\hanyaning\mulldling_data_analysis\' ...
    'liuhaoyi_analysis\to_lhy_fig_20230822\oft_3d'];
fileName = 'control1h-seg101.mat';

%% get videoname
videopath = 'X:\hanyaning\mulldling_data_analysis\liuhaoyi_analysis\process_20230315_data\fst';
videoName = 'control7d-seg1.avi';

%% Import dataset
clear global
global BeA
data_3d_name = [filepath,'\',fileName];
import_3d(data_3d_name);

%% Import dataset
video_name = [videopath,'\',videoName];
import_video(video_name);

%% 绘制原始骨架
X = BeA.RawData.X';
Y = BeA.RawData.Y';
Z = BeA.RawData.Z';

for k = 1:16
    X(k,:) = smooth(X(k,:),30);
    Y(k,:) = smooth(Y(k,:),30);
    Z(k,:) = smooth(Z(k,:),30);
end
plotstr = 'r';
linestr = 'b';
for k = 1:1:size(X,2)
    subplot(121)
    plot_skl(X(:,k),Y(:,k),Z(:,k),plotstr,linestr)
    grid on
    axis([min(X(:)),max(X(:)),min(Y(:)),max(Y(:)),min(Z(:)),max(Z(:))])
    view(2)
    tempdist = sqrt((X(13,k)-X(14,k)).^2+(Y(13,k)-Y(14,k)).^2+(Z(13,k)-Z(14,k)).^2);
%     title([num2str(k),'-',num2str(tempdist)])
    xlabel('x')
    ylabel('y')
    zlabel('z')
    subplot(122)
    plot_skl(X(:,k),Y(:,k),Z(:,k),plotstr,linestr)
    axis([min(X(:)),max(X(:)),min(Y(:)),max(Y(:)),min(Z(:)),max(Z(:))])
    view(3)
    tempdist = sqrt((X(13,k)-X(14,k)).^2+(Y(13,k)-Y(14,k)).^2+(Z(13,k)-Z(14,k)).^2);
%     title([num2str(k),'-',num2str(tempdist)])
    grid on
    xlabel('x')
    ylabel('y')
    zlabel('z')
    pause
    pause(0.00000001)
end
























