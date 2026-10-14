%{
    3D reconstruction of two mice
%}
clear all
close all
addpath(genpath(pwd))
%% set path
datapath = ['H:\MTPM_body_language\' ...
    'raw_data\behavior_op_20250915'];
%% load data
dataFolder = fullfile(datapath);
dataOutput = dir(fullfile(dataFolder,...
    '*caliParas.mat'));
caliNames = {dataOutput.name}';
splname = split(caliNames,'-cali');
rootnames = splname(:,1);

ncams = 4;

llh_thres_2d = 0.3;%likelihood threshold for 3D reconstruction
llh_thres_3d = 0.3;%likelihood threshold for 3D reconstruction
%% process, 3D reconstruction
for k = 1:size(rootnames,1)
    %% load calibration data
    caliname = [rootnames{k,1},'-caliParas.mat'];
    tempcali = load([datapath,'\',caliname]);
    cam_mat_all = tempcali.caliParams.cam_mat_all;
    %% load 2d data
    raw_csv_cell = cell(ncams,1);
    for m = 1:ncams
        csvname = [rootnames{k,1},'-camera-',num2str(m),'.csv'];
        tempdata = importdata([datapath,'\',csvname]);
        raw_csv_cell{m,1} = tempdata.data;
    end
    time_len = size(raw_csv_cell{1},1);
    body_parts_num = (size(raw_csv_cell{1},2)-1)/3;
    %% preprocessing
    csv_cell = cell(size(raw_csv_cell,1),1);
    for m = 1:size(csv_cell,1)
        tempdata = raw_csv_cell{m,1};
        nan_data = zeros(size(tempdata));
        for dims = 0:(body_parts_num-1)
            ttdata = tempdata(:,(dims*3+2):(dims*3+4));
            thres_idx = ttdata(:,3)<llh_thres_2d;
            nan_ttdata = ttdata;
            nan_ttdata(thres_idx,1:2) = nan;
            nan_data(:,(dims*3+2):(dims*3+4)) = nan_ttdata;
        end
        fill_data = fillmissing(nan_data,'linear');
        csv_cell{m,1} = fill_data;
    end
    %% 3D reconstruction
    skl_3d = zeros(time_len,body_parts_num*3);
    err_3d = zeros(time_len,body_parts_num);
    for timepoint = 1:time_len
        %%
        onetime3d = zeros(1,body_parts_num*3);
        onetimeerr = zeros(1,body_parts_num);
        for dims = 0:(body_parts_num-1)
            temppoints = zeros(2,size(csv_cell,1));
            likelihoods = zeros(1,size(csv_cell,1));
            for csvnum = 1:size(csv_cell,1)
                tempdata = ...
                    csv_cell{csvnum}(...
                    timepoint,(dims*3+2):(dims*3+3));
                temppoints(:,csvnum) = tempdata';
                likelihoods(:,csvnum) = ...
                    csv_cell{csvnum}(...
                    timepoint,dims*3+4);
            end
            %% reconstruct
            points = temppoints;
            cam_mat = cam_mat_all;
            camnum = ncams;

            %% add likelihood thresholding
            sel_llh_idx = likelihoods>llh_thres_3d;
            if sum(sel_llh_idx)<2
                [X, reprojErr] = ...
                    triangulate_3d(points,cam_mat,camnum);
                
            else
                [X, reprojErr] = ...
                    triangulate_3d(...
                    points(:,sel_llh_idx),...
                    cam_mat(:,:,sel_llh_idx),...
                    sum(sel_llh_idx));
            end
            %% append
            onetime3d(1,(dims*3+1):(dims*3+3)) = X';
            onetimeerr(1,dims+1) = mean(reprojErr);
        end
        skl_3d(timepoint,:) = onetime3d;
        err_3d(timepoint,:) = onetimeerr;
        if rem(timepoint,10000) == 0
            disp(timepoint)
        end
    end
    coords3d = skl_3d;
    err3d = err_3d;
    save([datapath,'\',rootnames{k,1},'-raw3d.mat'],...
        'coords3d','err3d')
    disp(k)
    disp('save!')
    %% temp show
    % tempdata1 = coords3d(:,1:48);
    % X1 = tempdata1(:,1:3:end)';
    % Y1 = tempdata1(:,2:3:end)';
    % Z1 = tempdata1(:,3:3:end)';
    % tempdata2 = coords3d(:,49:end);
    % X2 = tempdata2(:,1:3:end)';
    % Y2 = tempdata2(:,2:3:end)';
    % Z2 = tempdata2(:,3:3:end)';
    % plotstr1 = 'r';
    % linestr1 = 'r';
    % plotstr2 = 'b';
    % linestr2 = 'b';
    % for m = 1:16:size(X1,2)
    %     subplot(121)
    %     plot_skl(X1(:,m),Y1(:,m),Z1(:,m),plotstr1,linestr1)
    %     hold on
    %     plot_skl(X2(:,m),Y2(:,m),Z2(:,m),plotstr2,linestr2)
    %     hold off
    %     axis([-500,500,-500,500,0,1000])
    % %     axis([min(X1(:)),max(X1(:)),min(Y1(:)),max(Y1(:)),min(Z1(:)),max(Z1(:))])
    %     view(2)
    %     subplot(122)
    %     plot_skl(X1(:,m),Y1(:,m),Z1(:,m),plotstr1,linestr1)
    %     hold on
    %     plot_skl(X2(:,m),Y2(:,m),Z2(:,m),plotstr2,linestr2)
    %     hold off
    %     axis([-500,500,-500,500,0,1000])
    %     grid on
    % %     axis([min(X1(:)),max(X1(:)),min(Y1(:)),max(Y1(:)),min(Z1(:)),max(Z1(:))])
    %     view(-44,10)
    % %     pause
    %     pause(0.00000001)
    % end
end
%% rotation
for k = 1:size(rootnames,1)
    %% load calibration data
    caliname = [rootnames{k,1},'-caliParas.mat'];
    tempcali = load([datapath,'\',caliname]);
    cam_mat_all = tempcali.caliParams.cam_mat_all;

    rotation = tempcali.caliParams.rotation{1};
    translation = tempcali.caliParams.translation{1};
    %% load raw 3d data
    raw3dname = [rootnames{k,1},'-raw3d.mat'];
    tempraw3d = load([datapath,'\',raw3dname]);
    %% trans and rot
    data_3d = tempraw3d.coords3d;
    data_3d = data_3d';
    size_3d = size(data_3d);
    r_data_3d = zeros(size_3d);

    for i = 1:size_3d(2)
        for j = 1:3:size_3d(1)
            r_data_3d(j:j+2,i) = rotation * (data_3d(j:j+2,i)-translation');
        end
    end

    r_data_3d = r_data_3d';
    %% reverse
    size_3d = size(r_data_3d);
    max_3336 = 0;
    for i = 1:round(size_3d(2)/3)
        r_data_3d(:,i*3) = -r_data_3d(:,i*3)+max_3336;
    end

    %% change x and y
    size_3d = size(r_data_3d);
    a = zeros(size_3d);
    for i = 1:3:size_3d(2)
        a(:,i+1) = r_data_3d(:,i);
        a(:,i) = r_data_3d(:,i+1);
        a(:,i+2) = r_data_3d(:,i+2);
    end

    r_data_3d = a;
%     %% temp show
%     tempdata1 = r_data_3d(:,1:48);
%     X1 = tempdata1(:,1:3:end)';
%     Y1 = tempdata1(:,2:3:end)';
%     Z1 = tempdata1(:,3:3:end)';
%     tempdata2 = r_data_3d(:,49:end);
%     X2 = tempdata2(:,1:3:end)';
%     Y2 = tempdata2(:,2:3:end)';
%     Z2 = tempdata2(:,3:3:end)';
%     plotstr1 = 'r';
%     linestr1 = 'r';
%     plotstr2 = 'b';
%     linestr2 = 'b';
%     for m = 1:16:size(X1,2)
%         subplot(121)
%         plot_skl(X1(:,m),Y1(:,m),Z1(:,m),plotstr1,linestr1)
%         hold on
%         plot_skl(X2(:,m),Y2(:,m),Z2(:,m),plotstr2,linestr2)
%         hold off
%         axis([-500,500,-500,500,-100,1000])
%   
%         view(2)
%         subplot(122)
%         plot_skl(X1(:,m),Y1(:,m),Z1(:,m),plotstr1,linestr1)
%         hold on
%         plot_skl(X2(:,m),Y2(:,m),Z2(:,m),plotstr2,linestr2)
%         hold off
%         axis([-500,500,-500,500,-100,1000])
%         grid on
%  
%         view(-44,10)
%         pause(0.00000001)
%     end
    %% rot to ground
    down_sample_num = 1;

    sel_foot_idx = [79,80,81,82,83,84];
    sel_data3d = r_data_3d(:,sel_foot_idx);
    x_all = sel_data3d(1:down_sample_num:end,1:3:end);
    y_all = sel_data3d(1:down_sample_num:end,2:3:end);
    z_all = sel_data3d(1:down_sample_num:end,3:3:end);

    x_mean = mean(x_all,2);
    y_mean = mean(y_all,2);
    z_mean = mean(z_all,2);

    med_win = 60;
    smo_win = 60;

    x_smo = common_list_filter(x_mean,med_win,smo_win);
    y_smo = common_list_filter(y_mean,med_win,smo_win);
    z_smo = common_list_filter(z_mean,med_win,smo_win);

    planeData = [x_smo,y_smo,z_smo];
    
    xyz0 = mean(planeData,1);
    centeredPlane = bsxfun(@minus,planeData,xyz0);
    [U,S,V] = svd(centeredPlane);

    a = V(1,3);
    b = V(2,3);
    c = V(3,3);
    d = -dot([a b c],xyz0);
    %     % 图形绘制
%     figure
%     plot3(x_smo,y_smo,z_smo,'o')
%     hold on
%     xfit = min(x_smo):1:max(x_smo);
%     yfit = min(y_smo):1:max(y_smo);
%     [XFIT,YFIT]= meshgrid (xfit,yfit);
%     ZFIT = -(d + a * XFIT + b * YFIT)/c;
%     mesh(XFIT,YFIT,ZFIT);
%     hold off
    %% calculate R and T
    N = [a,b,c];
    new_N = [0,0,1];
    
    A = N';
    B = new_N';
    C = cross(A,B);
    theta = acos((A'*B)/(norm(A)*norm(B)));

    Rv = C/norm(C)*theta;

    R = rotationVectorToMatrix(Rv)';

%     new_xyz = R*N';

%     figure
%     enh_len = 100;
%     plot3([0,N(1)*enh_len], ...
%         [0,N(2)*enh_len],[0,N(3)*enh_len],'y-')
%     hold on
%     plot3([0,new_N(1)*enh_len], ...
%         [0,new_N(2)*enh_len],[0,new_N(3)*enh_len],'r-')
%     hold on
%     plot3([0,new_xyz(1)],[0,new_xyz(2)], ...
%         [0,new_xyz(3)],'g-')
%     hold on
%     xfit = min(x_smo):1:max(x_smo);
%     yfit = min(y_smo):1:max(y_smo);
%     [XFIT,YFIT]= meshgrid (xfit,yfit);
%     ZFIT = -(d + a * XFIT + b * YFIT)/c;
%     mesh(XFIT,YFIT,ZFIT);
%     hold off
%     xlabel('x')
%     ylabel('y')
%     zlabel('z')
    %% rot R
    rot_r_data_3d = r_data_3d;
    for m = 1:(size(rot_r_data_3d,2)/3)
        seldata = r_data_3d(:,((m-1)*3+1):(m*3));
        rot_data = R*seldata';
        rot_r_data_3d(:,((m-1)*3+1):(m*3)) = rot_data';
    end
    %% reverse Z
    rot_foot_z = rot_r_data_3d(:,[30,33]);
    rot_body_z = rot_r_data_3d(:,39);
    
    mean_rot_foot_z = mean(rot_foot_z(:));
    mean_rot_body_z = mean(rot_body_z(:));

    if mean_rot_foot_z>mean_rot_body_z
        % reverse
        rot_r_data_3d(:,3:3:end) = -1*rot_r_data_3d(:,3:3:end);
        disp('reverse!')
    end
%    %% temp show
%     tempdata1 = rot_r_data_3d(:,1:48);
%     X1 = tempdata1(:,1:3:end)';
%     Y1 = tempdata1(:,2:3:end)';
%     Z1 = tempdata1(:,3:3:end)';
%     tempdata2 = rot_r_data_3d(:,49:end);
%     X2 = tempdata2(:,1:3:end)';
%     Y2 = tempdata2(:,2:3:end)';
%     Z2 = tempdata2(:,3:3:end)';
%     plotstr1 = 'r';
%     linestr1 = 'r';
%     plotstr2 = 'b';
%     linestr2 = 'b';
%     for m = 1:16:size(X1,2)
%         subplot(121)
%         plot_skl(X1(:,m),Y1(:,m),Z1(:,m),plotstr1,linestr1)
%         hold on
%         plot_skl(X2(:,m),Y2(:,m),Z2(:,m),plotstr2,linestr2)
%         hold off
%         axis([-500,500,-500,500,-200,1000])
%     %     axis([min(X1(:)),max(X1(:)),min(Y1(:)),max(Y1(:)),min(Z1(:)),max(Z1(:))])
%         view(2)
%         subplot(122)
%         plot_skl(X1(:,m),Y1(:,m),Z1(:,m),plotstr1,linestr1)
%         hold on
%         plot_skl(X2(:,m),Y2(:,m),Z2(:,m),plotstr2,linestr2)
%         hold off
%         axis([-500,500,-500,500,-200,1000])
%         grid on
%     %     axis([min(X1(:)),max(X1(:)),min(Y1(:)),max(Y1(:)),min(Z1(:)),max(Z1(:))])
%         view(-44,10)
%     %     pause
%         pause(0.00000001)
%     end
    %% trans T
    sel_rot_data3d = rot_r_data_3d(:,sel_foot_idx);
    
    z_all_rot = sel_rot_data3d(1:down_sample_num:end,3:3:end);

    z_mean_rot = mean(z_all_rot,2);

    T_z = mean(z_mean_rot);

    rt_data3d = rot_r_data_3d;
    
    rt_data3d(:,3:3:end) = rot_r_data_3d(:,3:3:end)-T_z;
     %% temp show
    tempdata1 = rt_data3d(:,1:48);
    X1 = tempdata1(:,1:3:end)';
    Y1 = tempdata1(:,2:3:end)';
    Z1 = tempdata1(:,3:3:end)';
    tempdata2 = rt_data3d(:,49:end);
    X2 = tempdata2(:,1:3:end)';
    Y2 = tempdata2(:,2:3:end)';
    Z2 = tempdata2(:,3:3:end)';
    plotstr1 = 'r';
    linestr1 = 'r';
    plotstr2 = 'b';
    linestr2 = 'b';
    figure
    for m = 500
        subplot(121)
        plot_skl(X1(:,m),Y1(:,m),Z1(:,m),plotstr1,linestr1)
        hold on
        plot_skl(X2(:,m),Y2(:,m),Z2(:,m),plotstr2,linestr2)
        hold off
        axis([-500,500,-500,500,-100,200])
    %     axis([min(X1(:)),max(X1(:)),min(Y1(:)),max(Y1(:)),min(Z1(:)),max(Z1(:))])
        view(2)
        subplot(122)
        plot_skl(X1(:,m),Y1(:,m),Z1(:,m),plotstr1,linestr1)
        hold on
        plot_skl(X2(:,m),Y2(:,m),Z2(:,m),plotstr2,linestr2)
        hold off
        axis([-500,500,-500,500,-100,200])
        grid on
    %     axis([min(X1(:)),max(X1(:)),min(Y1(:)),max(Y1(:)),min(Z1(:)),max(Z1(:))])
        view(-44,10)
    %     pause
        pause(0.00000001)
    end
    %% save
    coords3d = rt_data3d;
    save([datapath,'\',rootnames{k,1},'-rot3d.mat'],...
        'coords3d')
    disp(k)
    disp('save!')
end





























