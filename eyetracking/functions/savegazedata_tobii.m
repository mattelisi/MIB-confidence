function[] = savegazedata_tobii(GazeData, fid, subjectID, stimulus_string, scr, fix_ok, timestamp_seq)
%
% function that store gaze data from Tobii eyetracker
% using the news Tobii proSDK
% Matteo Lisi, 2019
%
% output format should the following:

%fprintf(eyeFid, 'device_time_stamp\tsystem_time_stamp\tL_valid\tL_x\tL_y\tR_valid\tR_x\tR_y\tpupil_L_valid\tpupil_L_diameter\tpupil_R_valid\tpupil_R_diameter\tevents\tfix_ok\t ...');

gazeCell = {};
event = 0;
%                  1               2               3                4                5               6
% timestamp_seq = [time_MIB_onset, time_dim_onset, time_dim_offset, time_MIB_offset, timestamp_resp, timestamp_conf]

for i=1:length(GazeData)
    
    thisPoint = GazeData(i);
    
    %Check if data was collected for each eye
    if length(thisPoint.LeftEye.GazePoint.OnDisplayArea)==2
        % latestGazeData.LeftEye.GazePoint.OnDisplayArea
        Lx = round(thisPoint.LeftEye.GazePoint.OnDisplayArea(1)*scr.xres);
        Ly = round(thisPoint.LeftEye.GazePoint.OnDisplayArea(2)*scr.yres);
    else
        Lx = NaN;
        Ly = NaN;
    end
    
    if length(thisPoint.RightEye.GazePoint.OnDisplayArea)==2
        Rx = round(thisPoint.RightEye.GazePoint.OnDisplayArea(1)*scr.xres);
        Ry = round(thisPoint.RightEye.GazePoint.OnDisplayArea(2)*scr.yres);
    else
        Rx = NaN;
        Ry = NaN;
    end

    % Find the last timestamp that has been passed by `SystemTimeStamp`
    event = find(thisPoint.SystemTimeStamp >= timestamp_seq, 1, 'last');
    
    %Make a full row for each sample
    gazeCell(end+1,:) = {subjectID,...
        thisPoint.DeviceTimeStamp,...
        thisPoint.SystemTimeStamp,...
        thisPoint.LeftEye.GazePoint.Validity.('value'),...
        Lx,...
        Ly,...
        thisPoint.RightEye.GazePoint.Validity.('value'),...
        Rx,...
        Ry,...
        thisPoint.LeftEye.Pupil.Validity.value,...
        thisPoint.LeftEye.Pupil.Diameter,...
        thisPoint.RightEye.Pupil.Validity.value,...
        thisPoint.RightEye.Pupil.Diameter,...
        event};  
end

% now write to text file
[rows,~]=size(gazeCell);
for i=1:rows
    % removed the end of line \n because is already in stimulus string
    fprintf(fid,'%s\t%i\t%i\t%i\t%i\t%i\t%i\t%i\t%i\t%d\t%.2f\t%d\t%.2f\t%i\t%i\t%s',gazeCell{i,:}, fix_ok, stimulus_string);
end
