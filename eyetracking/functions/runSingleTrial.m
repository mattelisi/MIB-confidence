function [data1, acc, fix_ok] = runSingleTrial(td, scr, visual, design, eyetracker, t, b, Tobii, eyeFid)
% function that run individual trials

HideCursor;
SetMouse(scr.xres, scr.yres, scr.main);

% preallocate time stamps
time_MIB_onset = NaN;
time_dim_onset = NaN;
time_dim_offset = NaN;
time_MIB_offset = NaN;
timestamp_resp = NaN;
timestamp_conf = NaN;

% preallocate other stuff
choice = NaN;
tResp_1 = NaN;
conf_rating = NaN;
tResp_2 = NaN;

%% start eyetracker recording
% eyetracker.get_gaze_data();

dots_bg_xy = [(rand(1, round(visual.dots_bg_n)).*scr.xres); (rand(1, round(visual.dots_bg_n)).*scr.yres)] - [scr.centerX;scr.centerY];
Screen('DrawDots', scr.main, dots_bg_xy, visual.dotSizePixels, visual.col_dots, [scr.centerX;scr.centerY]', 2);

drawSingleCross([scr.centerX;scr.centerY], 1, scr.main, [160, 160, 160],round(visual.ppc/3), 3);
DrawFormattedText(scr.main, 'Press a key to start the trial.', 'center', round(2/3 * scr.yres) ,  [160, 160, 160]);
Screen('Flip', scr.main);
SitNWait;

Screen('Flip', scr.main);
WaitSecs(0.1);

%% stimuli
[S, fix_ok, time_dim_onset, time_dim_offset, time_MIB_onset, time_MIB_offset] = present_MIB(scr, visual, design, td, eyetracker, Tobii);

%% response
if fix_ok
    WaitSecs(0.3);
    Screen('DrawDots', scr.main, S.target_loc, visual.target_size, visual.target_color, S.fix_center', 1);
    tFlip = Screen('Flip', scr.main);
    
    
    %% check for mouse response
    SetMouse(scr.centerX, scr.centerY, scr.main);
    ShowCursor;
    while 1
        [mx, my, buttons] = GetMouse(scr.main);
        if sum(buttons) > 0
            if IsInRect(mx, my, CenterRectOnPoint([0 0 visual.target_size visual.target_size]*2, S.target_loc(1,1)+S.fix_center(1),S.target_loc(2,1)+S.fix_center(2)))
                choice = 1;
                tResp_1 = GetSecs - tFlip;
                timestamp_resp = Tobii.get_system_time_stamp;
                break;
            elseif IsInRect(mx, my, CenterRectOnPoint([0 0 visual.target_size visual.target_size]*2, S.target_loc(1,2)+S.fix_center(1),S.target_loc(2,2)+S.fix_center(2)))
                choice = 2;
                tResp_1 = GetSecs - tFlip;
                timestamp_resp = Tobii.get_system_time_stamp;
                break
            elseif IsInRect(mx, my, CenterRectOnPoint([0 0 visual.target_size visual.target_size]*2, S.target_loc(1,3)+S.fix_center(1),S.target_loc(2,3)+S.fix_center(2)))
                choice = 3;
                tResp_1 = GetSecs - tFlip;
                timestamp_resp = Tobii.get_system_time_stamp;
                break
            end
        end
    end
    HideCursor;
    
    if S.off_remo(choice)==1
        acc=1;
    else
        acc=0;
    end
    
    %% now measure confidence
    Screen('TextSize', scr.main, round(visual.ppc*0.8));
    Screen('DrawLine', scr.main, [80, 80, 80], visual.confH0, visual.confV, visual.confH1, visual.confV, round(visual.ppc*0.05))
    DrawFormattedText(scr.main, 'Unsure              (it could be any of the 3 targets, the  choice was random)', visual.confH0 - 7.5*round(visual.ppc*0.8), visual.confV+ round(visual.ppc*0.8), [200 200 200],21);
    DrawFormattedText(scr.main, 'Certain              (I am 100% sure to  have selected the   target that blinked)', visual.confH1 + round(visual.ppc*0.8), visual.confV+ round(visual.ppc*0.8), [200 200 200],21);
    
    tFlip = Screen('Flip', scr.main);
    WaitSecs(0.3);
    SetMouse(scr.centerX, scr.centerY, scr.main);
    % Screen('TextSize', scr.main, round(visual.ppc*0.3));
    while 1
        
        [mx, ~, buttons] = GetMouse(scr.main);
        
        % Draw a white dot where the mouse cursor is
        cur_x = mx;
        if cur_x < visual.confH0; cur_x = visual.confH0; end
        if cur_x > visual.confH1; cur_x = visual.confH1; end
        
        Screen('DrawLine', scr.main, [80, 80, 80], visual.confH0, visual.confV, visual.confH1, visual.confV, round(visual.ppc*0.05));
        DrawFormattedText(scr.main, 'Unsure              (it could be any of the 3 targets, the  choice was random)', visual.confH0 - 7.5*round(visual.ppc*0.8), visual.confV+ round(visual.ppc*0.8), [200 200 200],21);
        DrawFormattedText(scr.main, 'Certain              (I am 100% sure to  have selected the   target that blinked)', visual.confH1+ round(visual.ppc*0.8), visual.confV+ round(visual.ppc*0.8), [200 200 200],21);
        
        Screen('DrawDots', scr.main, [cur_x visual.confV], visual.target_size, [200 200 200], [], 1);
        
        Screen('DrawingFinished',scr.main);
        Screen(scr.main,'Flip');
        
        if sum(buttons) > 0
            conf_rating = ((cur_x - visual.confH0)/(visual.confH1 - visual.confH0))*(1-1/3) +1/3;
            tResp_2 = GetSecs - tFlip;
            timestamp_conf = Tobii.get_system_time_stamp;
            break;
        end
    end
    Screen(scr.main,'Flip');
    WaitSecs(0.1);

else
    % fix_ok != 1
    acc=NaN;
end

% reset text size
Screen('TextSize', scr.main, visual.textSize);

%% stop eyetracker recording & get eyetracking data
collected_gaze_data = eyetracker.get_gaze_data();
% eyetracker.stop_gaze_data();

%% compute the angles of targets
T = S.target_loc;
T(1,:) = T(1,:) - scr.centerX;
T(2,:) = scr.centerY - T(2,:);
target_angles = [atan(T(2,1)/T(1,1)),atan(T(2,2)/T(1,2)),atan(T(2,3)/T(1,3))];
angle_correct = target_angles(S.off_remo==1)/pi*180;
if fix_ok
    angle_chosen = target_angles(choice)/pi*180;
else
    angle_chosen = NaN;
end

%% store data
trial_mat = [td.off_onset, angle_correct, angle_chosen, choice, acc, tResp_1, conf_rating, tResp_2, T(1,:)/visual.ppc, T(2,:)/visual.ppc];
rea_format = strcat(repmat('%.4f\t', 1,size(trial_mat,2)-1), '%.4f\n');
data1 = sprintf(rea_format, trial_mat);

%% save eyetracking data
%stimulus_string = sprintf('%s\t%s\t%s',trial_gender{t},  trial_actor{t}, trial_emotion{t});
% time_dim_onset, time_dim_offset, time_MIB_onset, time_MIB_offset timestamp_resp timestamp_conf
trial_string = sprintf('%i\t%i\t%s', b,t,data1);
timestamp_seq = [time_MIB_onset, time_dim_onset, time_dim_offset, time_MIB_offset, timestamp_resp, timestamp_conf];
savegazedata_tobii(collected_gaze_data, eyeFid, design.ID, trial_string, scr, fix_ok, timestamp_seq);


