function[] = assessStability(scr, eyetracker, id)
% function to repeat the calibration and assess fixation stability

%% common
screen_pixels = [scr.xres scr.yres];
dotSizePix = 30;
HideCursor;

% legacy
subjectID = id;

childfriendly = 0;

%% prepare childfriendly calib if required
count_i = 0;
if childfriendly
    for i=1:4
        img_path = [pwd '\files\dino' num2str(i) '.png'];
        if exist(img_path, 'file')>1
            [img,~,alpha] = imread(img_path);
            img(:, :, 4) = alpha;
            count_i = count_i+1;
            dinotex(count_i) = Screen('MakeTexture', scr.main, img);
            img = flip(img,2);
            count_i = count_i+1;
            dinotex(count_i) = Screen('MakeTexture', scr.main, img);
        else
            childriendly=0;
            break;
        end
    end
end

%% here do actual drawing of calibration stimulus
dotColor = [[1 0 0];[1 1 1]]*255; % Red and white

leftColor = [1 0 0]*255; % Red
rightColor = [0 0 1]*255; % Bluesss

% Calibration points
lb = 0.1;  % left bound
xc = 0.5;  % horizontal center
rb = 0.9;  % right bound
ub = 0.1;  % upper bound
yc = 0.5;  % vertical center
bb = 0.9;  % bottom bound

points_to_calibrate = [[lb,ub];[rb,ub];[xc,yc];[lb,bb];[rb,bb];[xc,bb];[xc,ub];[lb,yc];[rb,yc]];
points_to_calibrate = points_to_calibrate(randperm(size(points_to_calibrate,1)),:);

% house keeping
gazeDir = [pwd '/gazedata_validation/'];
if exist(gazeDir, 'dir') < 1
    mkdir(gazeDir);
end

% inizialize data file
eyeFid = fopen([gazeDir id '_validation'], 'w');
fprintf(eyeFid, 'subjectID\tdevice_time_stamp\tsystem_time_stamp\tL_valid\tL_x\tL_y\tR_valid\tR_x\tR_y\tx_target\ty_target\n');
 

% wait for user
DrawFormattedText(scr.main, 'Validation. Press a key to continue', 'center', scr.yres * 0.1, scr.white);
Screen('Flip', scr.main);
SitNWait;

XY_target = [NaN, NaN];

% start recording
eyetracker.get_gaze_data();
WaitSecs(0.2);

for i=1:length(points_to_calibrate)
    
    if childfriendly
        Screen('DrawTexture', scr.main, dinotex(round(rand(1) * 5 + 1)), [], CenterRectOnPoint([0,0, dotSizePix, dotSizePix]*2.5, points_to_calibrate(i,1)*screen_pixels(1), points_to_calibrate(i,2)*screen_pixels(2)));
    else
        Screen('FillOval', scr.main, dotColor(1,:), CenterRectOnPoint([0,0, dotSizePix, dotSizePix]*2, points_to_calibrate(i,1)*screen_pixels(1), points_to_calibrate(i,2)*screen_pixels(2)));
        Screen('FillOval', scr.main, dotColor(2,:), CenterRectOnPoint([0,0, dotSizePix, dotSizePix]*0.3, points_to_calibrate(i,1)*screen_pixels(1), points_to_calibrate(i,2)*screen_pixels(2)));
    end
    
    % store gazedata
    collected_gaze_data = eyetracker.get_gaze_data();
    % eyetracker.stop_gaze_data();
    stimulus_string = sprintf('%.2f\t%.2f',XY_target(1),XY_target(2));
    savegazedata_tobii(collected_gaze_data, eyeFid, subjectID, stimulus_string, scr, 1, [0 0 0 0 0 0]);
    
    Screen('Flip', scr.main);
    XY_target = [scr.xres*points_to_calibrate(i,1), scr.yres*points_to_calibrate(i,2)];
    
    % Wait a moment to allow the user to focus on the point
    pause(1);

    
end

eyetracker.stop_gaze_data();
fclose(eyeFid);

Screen('TextSize', scr.main, 20);
Screen('TextFont', scr.main, 'Arial');
DrawFormattedText(scr.main, 'Press a key to continue.', 'center', 'center', scr.white);
Screen('Flip', scr.main);

end


function SitNWait(keyName)
% Matteo Lisi, 2012
% wait for a particular key to be pressed
% if keyName is not provided, any key will do
if nargin == 1
    specificKey = KbName(keyName);
    anyFlag = 0;
else
    anyFlag = 1;
end
sitFlag = 1;
while sitFlag
    [keyIsDown, ~, keyCode] = KbCheck(-1);
    if keyIsDown
        response = find(keyCode);
        response = response(1);
        if anyFlag || response == specificKey
            sitFlag = 0;
        end
    end
end
% now wait for the key to come up again
while KbCheck; end
%if response == KbName('delete')
%    error('Program execution terminated, by your command');
%end
end
