% initialize eye tracker

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

% assess fixation stability
assessStability(scr, eyetracker, SJ.id);

% inizialize data file
%'subjectID', 'device_time_stamp','system_time_stamp', 'description','L_valid','L_x','L_y','R_valid','R_x','R_y'
eyeFid = fopen([gazeDir filename '_gaze'], 'w');
fprintf(eyeFid, 'subjectID\tdevice_time_stamp\tsystem_time_stamp\tL_valid\tL_x\tL_y\tR_valid\tR_x\tR_y\timg_gender\timg_actor\timg_emotion\tx_res\ty_res\timg_left\timg_top\timg_right\timg_bottom\n');
subjectID = sprintf('%s%i',SJ.id,SJ.number);