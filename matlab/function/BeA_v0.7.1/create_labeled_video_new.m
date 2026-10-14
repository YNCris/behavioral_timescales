%{
    用标定文件索引
%}
clear all
close all
%% set path
filepath = ['X:\hanyaning\multi_mice_test\Social_analysis\data\' ...
    'MTPM_body_language\raw_data\behavior_all'];
%% laod calibration files
videoFolder = fullfile(filepath);
dirOutput = dir(fullfile(videoFolder,'*caliParas.mat'));
videoNames = {dirOutput.name}';


DLC_file = {...
    'DLC_resnet50_freeDec1shuffle1_1030000.csv';...
    'DLC_resnet50_tpmDec1shuffle1_1030000.csv';...
    'DLC_resnet50_trapDec1shuffle1_1030000.csv'};

cam_num = 4;
%% process
parfor k = 1:size(videoNames,1)
    %% load name
    tempname = videoNames{k,1};
    rootname = tempname(1:(end-14));
    %% process by videos
    for m = 1:cam_num
        videoname = [rootname,'-camera-',num2str(m),'.avi'];
        %% DLC
        for n = 1:length(DLC_file)
            %% load video
            vidobj = VideoReader([filepath,'\',videoname]);
            tempdlc = DLC_file{n};
            dataname = [videoname(1,1:(end-4)),tempdlc];
            %% process loop
            %% load CSV
            tempdata = importdata([filepath,'\',dataname]);
            %% 
            csvdata = tempdata.data;
            csvdata(:,1:3:end) = [];
            lldata = tempdata.data(:,1:3:end);
            lldata(:,1) = [];
            mean_lldata = mean(lldata,2);
            cmap = imresize(colormap('jet'),[(size(csvdata,2)/2),3]); 
            %% 
            writeobj = VideoWriter(...
                [filepath,'\',dataname(1,1:(end-4)),'_label']);
            writeobj.FrameRate = vidobj.FrameRate;
            open(writeobj)
            %% 
            for p = 1:size(csvdata,1)
                %%
                frame = read(vidobj,p);
                %% 
                temppos = csvdata(p,:);
                showpos = [temppos(1:2:(end-1))',temppos(2:2:end)'];
                %%
                markframe = insertMarker(frame,showpos,...
                    'o','Size',4,'Color',uint8(255*cmap));
                markframe = insertMarker(markframe,showpos,'*','Size',2,'Color',uint8(255*cmap));
%                 imshow(markframe)
%                 title(mean_lldata(m))
%                 
%                 
%                 pause(0.0000001)
                %% 
                 writeVideo(writeobj,markframe);
            end
            close(writeobj)
            disp(k)
        end
    end
    
end
