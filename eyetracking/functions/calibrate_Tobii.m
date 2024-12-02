function[eyetracker] = calibrate_Tobii(scr, eyetracker)
%
% Calibrate Tobii eyetracker using 
% Tobii Pro SDK (Matlab/Octave) V 1.7
%
% modified from the (buggy) routine on Tobii Pro SDK documentation
% made into a standard 9-points calibration
% Matteo Lisi, 2019
%
% - added childfriendly calibration mode, with dinosaurs target
%   (they must be in the 'files' folder, and called 'dino1.png',...,'dino4.png')
%

%% common
screen_pixels = [scr.xres scr.yres];
dotSizePix = 30;
HideCursor;

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
    
%% first check that participats is laced in the correct position 

% Start collecting data
% The subsequent calls return the current values in the stream buffer.
% If a flat structure is prefered just use an extra input 'flat'.
% i.e. gaze_data = eyetracker.get_gaze_data('flat');
eyetracker.get_gaze_data();

Screen('TextSize', scr.main, 20);

while ~KbCheck

    DrawFormattedText(scr.main, 'When correctly positioned press any key to start the calibration.', 'center', scr.yres * 0.1, scr.white);

    distance = [];

    gaze_data = eyetracker.get_gaze_data();

    if ~isempty(gaze_data)
        last_gaze = gaze_data(end);

        validityColor = [1 0 0]*255;

        % Check if user has both eyes inside a reasonable tacking area.
        if last_gaze.LeftEye.GazeOrigin.Validity.('value') && last_gaze.RightEye.GazeOrigin.Validity.('value')
            left_validity = all(last_gaze.LeftEye.GazeOrigin.InTrackBoxCoordinateSystem(1:2) < 0.85) ...
                                 && all(last_gaze.LeftEye.GazeOrigin.InTrackBoxCoordinateSystem(1:2) > 0.15);
            right_validity = all(last_gaze.RightEye.GazeOrigin.InTrackBoxCoordinateSystem(1:2) < 0.85) ...
                                 && all(last_gaze.RightEye.GazeOrigin.InTrackBoxCoordinateSystem(1:2) > 0.15);
            if left_validity && right_validity
                validityColor = [0 1 0]*255;
            end
        end

        origin = [scr.xres/4 scr.yres/4];
        size = [scr.xres/2 scr.yres/2];

        penWidthPixels = 3;
        baseRect = [0 0 size(1) size(2)];
        frame = CenterRectOnPointd(baseRect, scr.xres/2, scr.centerY);

        Screen('FrameRect', scr.main, validityColor, frame, penWidthPixels);

        % Left Eye
        if last_gaze.LeftEye.GazeOrigin.Validity.('value')
            distance = [distance; round(last_gaze.LeftEye.GazeOrigin.InUserCoordinateSystem(3)/10,1)];
            left_eye_pos_x = double(1-last_gaze.LeftEye.GazeOrigin.InTrackBoxCoordinateSystem(1))*size(1) + origin(1);
            left_eye_pos_y = double(last_gaze.LeftEye.GazeOrigin.InTrackBoxCoordinateSystem(2))*size(2) + origin(2);
            %Screen('DrawDots', scr.main, [left_eye_pos_x left_eye_pos_y], dotSizePix, validityColor, [], 1);
            Screen('FillOval', scr.main, validityColor, CenterRectOnPoint([0,0, dotSizePix, dotSizePix], left_eye_pos_x, left_eye_pos_y));
        end

        % Right Eye
        if last_gaze.RightEye.GazeOrigin.Validity.('value')
            distance = [distance;round(last_gaze.RightEye.GazeOrigin.InUserCoordinateSystem(3)/10,1)];
            right_eye_pos_x = double(1-last_gaze.RightEye.GazeOrigin.InTrackBoxCoordinateSystem(1))*size(1) + origin(1);
            right_eye_pos_y = double(last_gaze.RightEye.GazeOrigin.InTrackBoxCoordinateSystem(2))*size(2) + origin(2);
            %Screen('DrawDots', scr.main, [right_eye_pos_x right_eye_pos_y], dotSizePix, validityColor, [], 1);
            Screen('FillOval', scr.main, validityColor, CenterRectOnPoint([0,0, dotSizePix, dotSizePix], right_eye_pos_x, right_eye_pos_y));
        end
        pause(0.05);
    end

    DrawFormattedText(scr.main, sprintf('Current distance to the eye tracker: %.2f cm.',mean(distance)), 'center', scr.yres * 0.85, scr.white);


    % Flip to the screen. This command basically draws all of our previous
    % commands onto the screen.
    % For help see: Screen Flip?
    Screen('Flip', scr.main);

end

eyetracker.stop_gaze_data();


%% here do actual calibration
spaceKey = KbName('Space');
RKey = KbName('R');

dotColor = [[1 0 0];[1 1 1]]*255; % Red and white

leftColor = [1 0 0]*255; % Red
rightColor = [0 0 1]*255; % Bluesss

% Calibration points
shrink_factor = 0.0125;
lb = 0.1 + shrink_factor;  % left bound
xc = 0.5;  % horizontal center
rb = 0.9 - shrink_factor;  % right bound
ub = 0.1 + shrink_factor;  % upper bound
yc = 0.5;  % vertical center
bb = 0.9 - shrink_factor;  % bottom bound

points_to_calibrate = [[lb,ub];[rb,ub];[xc,yc];[lb,bb];[rb,bb];[xc,bb];[xc,ub];[lb,yc];[rb,yc]];
% points_to_calibrate = points_to_calibrate(randperm(size(points_to_calibrate,1)),:);
points_to_calibrate = points_to_calibrate(randperm(9),:);

% Create calibration object
calib = ScreenBasedCalibration(eyetracker);

Screen('FillOval', scr.main, dotColor(1,:), CenterRectOnPoint([0,0, dotSizePix, dotSizePix]*2, 0.5*screen_pixels(1), 0.5*screen_pixels(2)));
Screen('FillOval', scr.main, dotColor(2,:), CenterRectOnPoint([0,0, dotSizePix, dotSizePix]*0.3, 0.5*screen_pixels(1), 0.5*screen_pixels(2)));
DrawFormattedText(scr.main, 'Focus your gaze on the small white dot within the red disk, and follow as it jumps to different locations. \n Press any key to begin.', 'center', scr.yres * 0.65, scr.white);
Screen('Flip', scr.main);
SitNWait;

calibrating = true;

while calibrating
    % Enter calibration mode
    calib.enter_calibration_mode();

    for i=1:length(points_to_calibrate)

        % Screen('DrawDots', scr.main, round(points_to_calibrate(i,:).*screen_pixels)', dotSizePix, dotColor(1,:), [], 2);
        % Screen('DrawDots', scr.main, round(points_to_calibrate(i,:).*screen_pixels)', dotSizePix*0.5, dotColor(2,:), [], 2);
        %Screen('DrawDots', scr.main, round(points_to_calibrate(i,:).*screen_pixels)', dotSizePix, dotColor(1,:),[],1);
        %Screen('DrawDots', scr.main, round(points_to_calibrate(i,:).*screen_pixels)', dotSizePix*0.5, dotColor(2,:),[],1);
        if childfriendly
            Screen('DrawTexture', scr.main, dinotex(round(rand(1) * 5 + 1)), [], CenterRectOnPoint([0,0, dotSizePix, dotSizePix]*2.5, points_to_calibrate(i,1)*screen_pixels(1), points_to_calibrate(i,2)*screen_pixels(2)));
        else
            Screen('FillOval', scr.main, dotColor(1,:), CenterRectOnPoint([0,0, dotSizePix, dotSizePix]*2, points_to_calibrate(i,1)*screen_pixels(1), points_to_calibrate(i,2)*screen_pixels(2)));
            Screen('FillOval', scr.main, dotColor(2,:), CenterRectOnPoint([0,0, dotSizePix, dotSizePix]*0.3, points_to_calibrate(i,1)*screen_pixels(1), points_to_calibrate(i,2)*screen_pixels(2)));
        end
        Screen('Flip', scr.main);

        % Wait a moment to allow the user to focus on the point
        pause(1);

        if calib.collect_data(points_to_calibrate(i,:)) ~= CalibrationStatus.Success
            % Try again if it didn't go well the first time.
            % Not all eye tracker models will fail at this point, but instead fail on ComputeAndApply.
            calib.collect_data(points_to_calibrate(i,:));
        end

    end

    Screen('TextSize', scr.main, 20);
    Screen('TextFont', scr.main, 'Arial');
    DrawFormattedText(scr.main, 'Calculating calibration result....', 'center', 'center', scr.white);

    Screen('Flip', scr.main);

    % Blocking call that returns the calibration result
    calibration_result = calib.compute_and_apply();

    calib.leave_calibration_mode();

    if calibration_result.Status ~= CalibrationStatus.Success
        break
    end

    % Calibration Result

    points = calibration_result.CalibrationPoints;

    for i=1:length(points)
        %Screen('DrawDots', scr.main, (points(i).PositionOnDisplayArea.*screen_pixels)', dotSizePix*0.5, dotColor(2,:), [], 2);
        %Screen('DrawDots', scr.main, (points(i).PositionOnDisplayArea.*screen_pixels)', dotSizePix*0.5, dotColor(2,:));
        Screen('FillOval', scr.main, dotColor(2,:), CenterRectOnPoint([0,0, dotSizePix, dotSizePix]*0.5, points(i).PositionOnDisplayArea(1)*screen_pixels(1), points(i).PositionOnDisplayArea(2)*screen_pixels(2)));
        
        for j=1:length(points(i).RightEye)
            if points(i).LeftEye(j).Validity == CalibrationEyeValidity.ValidAndUsed
                %Screen('DrawDots', scr.main, (points(i).LeftEye(j).PositionOnDisplayArea.*screen_pixels)', dotSizePix*0.3, leftColor, [], 2);
                %Screen('DrawDots', scr.main, (points(i).LeftEye(j).PositionOnDisplayArea.*screen_pixels)', dotSizePix*0.3, leftColor);
                Screen('FillOval', scr.main, leftColor, CenterRectOnPoint([0,0, dotSizePix, dotSizePix]*0.2, points(i).LeftEye(j).PositionOnDisplayArea(1)*screen_pixels(1), points(i).LeftEye(j).PositionOnDisplayArea(2)*screen_pixels(2)));
                Screen('DrawLines', scr.main, ([points(i).LeftEye(j).PositionOnDisplayArea; points(i).PositionOnDisplayArea].*repmat(screen_pixels,2,1))', 2, leftColor, [0 0], 2);
            end
            if points(i).RightEye(j).Validity == CalibrationEyeValidity.ValidAndUsed
                %Screen('DrawDots', scr.main, (points(i).RightEye(j).PositionOnDisplayArea.*screen_pixels)', dotSizePix*0.3, rightColor, [], 2);
                %Screen('DrawDots', scr.main, (points(i).RightEye(j).PositionOnDisplayArea.*screen_pixels)', dotSizePix*0.3, rightColor);
                Screen('FillOval', scr.main, rightColor, CenterRectOnPoint([0,0, dotSizePix, dotSizePix]*0.2, points(i).RightEye(j).PositionOnDisplayArea(1)*screen_pixels(1), points(i).RightEye(j).PositionOnDisplayArea(2)*screen_pixels(2)));
                Screen('DrawLines', scr.main, ([points(i).RightEye(j).PositionOnDisplayArea; points(i).PositionOnDisplayArea].*repmat(screen_pixels,2,1))', 2, rightColor, [0 0], 2);
            end
        end

    end

    DrawFormattedText(scr.main, 'Press the ''R'' key to recalibrate or ''Space'' to continue....', 'center', scr.yres * 0.95, scr.white)

    Screen('Flip', scr.main);

    while 1.
        [ keyIsDown, ~, keyCode ] = KbCheck;
        keyCode = find(keyCode, 1);

        if keyIsDown
            if keyCode == spaceKey
                calibrating = false;
                break;
            elseif keyCode == RKey
                break;
            end
            KbReleaseWait;
        end
    end
end
ShowCursor('Arrow');
