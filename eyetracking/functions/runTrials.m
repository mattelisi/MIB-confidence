function [design, acc_session] = runTrials(design, datFile, resDir, scr, visual)
% run experimental blocks

%% get ready
% preload important functions
Screen(scr.main, 'Flip');
GetSecs;
WaitSecs(.2);
FlushEvents('keyDown');
HideCursor;

% create data fid
datFid = fopen(sprintf('./%s/%s',resDir,datFile), 'w');

% unify keynames for different operating systems
KbName('UnifyKeyNames');
HideCursor(scr.main);

% text 
Screen('TextFont', scr.main, 'Arial');

%% initialize eye tracker

Tobii = EyeTrackingOperations();
found_eyetrackers = Tobii.find_all_eyetrackers();

% eyetracker_address = 'tet-tcp://172.28.195.1';
eyetracker_address = found_eyetrackers(1).Address;

eyetracker = Tobii.get_eyetracker(eyetracker_address);

if isa(eyetracker,'EyeTracker')
    disp(['Address:',eyetracker.Address]);
    disp(['Name:',eyetracker.Name]);
    disp(['Serial Number:',eyetracker.SerialNumber]);
    disp(['Model:',eyetracker.Model]);
    disp(['Firmware Version:',eyetracker.FirmwareVersion]);
    disp(['Runtime Version:',eyetracker.RuntimeVersion]);
else
    disp('Eye tracker not found!');
end

% calibrate
eyetracker = calibrate_Tobii4C(scr, eyetracker);

%%%% THIS NEEDs CHECKING -> <-

% assess fixation stability
assessStability(scr, eyetracker, SJ.id);

% inizialize data file
%'subjectID', 'device_time_stamp','system_time_stamp', 'description','L_valid','L_x','L_y','R_valid','R_x','R_y'
eyeFid = fopen([gazeDir filename '_gaze'], 'w');
fprintf(eyeFid, 'subjectID\tdevice_time_stamp\tsystem_time_stamp\tL_valid\tL_x\tL_y\tR_valid\tR_x\tR_y\timg_gender\timg_actor\timg_emotion\tx_res\ty_res\timg_left\timg_top\timg_right\timg_bottom\n');
subjectID = sprintf('%s%i',SJ.id,SJ.number);


%% practice?
%if isfield(design,'practice')

Screen('TextSize', scr.main, visual.textSize);
DrawFormattedText(scr.main, 'Press a key to start.', 'center', round(1/2 * scr.yres) ,  visual.fgColor);
Screen('Flip', scr.main);
SitNWait;

txtmsg = ['Do you want to run a quick practice (y/n)?'];
Screen('FillRect', scr.main, visual.bgColor);
DrawFormattedText(scr.main, txtmsg, 'center', 'center', visual.fgColor);
Screen('Flip', scr.main);

while 1
    [keyisdown, ~, keycode] = KbCheck(-1);
    if keyisdown && (keycode(KbName('y')) || keycode(KbName('n')))
        if keycode(KbName('y'))
            do_practice = 1;
        elseif keycode(KbName('n'))
            do_practice = 0;
        end
        break;
    end
end

while do_practice
    
    npt = design.practice.n_trials;
    visual.col_dots = [0, 0, 0];
    for i = 1:npt
        
          % random determination of side, condition, etc.
          td = design.b(1).trial(1);
          td.off_onset = rand(1)*8 + 1;
          runSingleTrial(td, scr, visual, design);
        
    end
    visual.col_dots = [0, 0, 255];
    
    txtmsg = ['Practice trials completed.\n\n Continue to main experiment (y) or repeat practice (r)?'];
    Screen('FillRect', scr.main, visual.bgColor);
    DrawFormattedText(scr.main, txtmsg, 'center', 'center', visual.fgColor);
    Screen('Flip', scr.main);
    
    while 1
        [keyisdown, ~, keycode] = KbCheck(-1);
        if keyisdown && (keycode(KbName('y')) || keycode(KbName('r')))
            if keycode(KbName('y'))
                do_practice = 0;
            end
            break;
        end
    end
    
end
%end

%% experimental blocks
acc_session = [];
for b = 1:design.nBlocks
    
    ntt = length(design.b(b).trial);

    %% block instructions
    GeneralInstructions = ['Block ',num2str(b),' of ',num2str(design.nBlocks),'. \n\n',...
        'Press any key to begin.'];
    Screen('FillRect', scr.main, visual.bgColor);
    DrawFormattedText(scr.main, GeneralInstructions, 'center', 'center', visual.fgColor);
    Screen('Flip', scr.main);
    
    SitNWait;
    
    % trial loop
    t = 0;
    while t < ntt
        
        t = t + 1;
        td = design.b(b).trial(t);
        
        % run single trial
        [data, acc, fix_ok] = runSingleTrial(td, scr, visual, design, eyetracker);
        acc_session = [acc_session, acc];
        
        % add here code to increase ntt up to a certain number (and add the current td to design.b(b).trial(t)) if fixation was broken

        % print data to string
        dataStr1 = sprintf('%s\t%i\t%i\t%s',datFile, b, t, data); 
        
         % write data to datFile
        fprintf(datFid,dataStr1);
        WaitSecs(design.iti);       % inter-trial interval
        
    end
end

%% save data and say goodbye
fclose(datFid); % close datFile
Screen('FillRect', scr.main,visual.bgColor);
Screen(scr.main,'DrawText','Thanks! This session has finished.',100,100,visual.fgColor);
Screen(scr.main,'DrawText',['You correctly identified the target that blinked ',num2str(sum(acc_session)),' times, out of ',num2str(length(acc_session)),' trials.'],100,200,visual.fgColor);
Screen(scr.main,'DrawText','Press any key to exit.',100,300,visual.fgColor);
Screen(scr.main,'Flip');
WaitSecs(1);
SitNWait;
ShowCursor('Arrow',scr.main);

