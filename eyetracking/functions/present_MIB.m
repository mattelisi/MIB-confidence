function [stim_details, fix_ok, time_dim_onset, time_dim_offset, time_MIB_onset, time_MIB_offset] = present_MIB(scr, visual, design, td, eyetracker, Tobii)

HideCursor;
SetMouse(scr.xres, scr.yres, scr.main);

Screen('BlendFunction', scr.main, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

% Dots are uniformly distributed on the sphere surphace
beta = rand(1, visual.numDots) .* 360;
ypos = sin(beta .* (pi / 180)) * visual.sphSize.* visual.ppc;

% need to find the radius associated with each point
radii_y = cos(beta .* (pi / 180)) * visual.sphSize;

% Randomly assign the dots angles. This determines their X position on the
% screen. We are using ortographic projection, so the dots do not have a Z
% position.
angles = rand(1, visual.numDots) .* 360;

% add random dots in the BG
dots_bg_xy = [(rand(1, visual.dots_bg_n).*scr.xres); (rand(1, visual.dots_bg_n).*scr.yres)] - [scr.centerX;scr.centerY];

% keep only dots not in the circle
dots_bg_keep = sqrt(dots_bg_xy(1,:).^2 + dots_bg_xy(2,:).^2) > (visual.sphSize*visual.ppc);
dots_bg_xy = dots_bg_xy(:,dots_bg_keep);

% set location of fixation point
fix_center = [scr.centerX;scr.centerY];

% call the dots [1,2,3] according to the order of position in the matrix
% now draw a random angle
target_angle = rand(1) * 360;
Rmat = [cosd(target_angle),-sind(target_angle);sind(target_angle),cosd(target_angle)];
target_loc = Rmat*visual.target_loc;

rotation_speed = design.speed_of_rotation; % degrees
sign_1 = sign(randn(1));
sign_2 = sign(randn(1));

% make sphere rotate on both axis
Rmat_sphere = [cosd(rotation_speed/2),-sind(rotation_speed/2);sind(rotation_speed/2),cosd(rotation_speed/2)];

% count for flickering fixation:
count = 1;
center_on = 0;
fix_halfcycle = 0.5; % half duration of fixation cycle in sec
n_frame_void = 10;
void_count = 0;
void = 0;

% target offset
off_dur = design.off_dur;
off_onset = td.off_onset;

% dimming sequence
dim_count=0;
off_dur_fd = round(off_dur/scr.fd);
frame_dim = round(design.frame_dim_sec/scr.fd);
dim_sequence = [linspace(1, 1-visual.prop_contrast_decrement, frame_dim+1), ...
                repmat(1-visual.prop_contrast_decrement,1,off_dur_fd-frame_dim*2),...
                linspace(1-visual.prop_contrast_decrement, 1, frame_dim+1)];
dim_sequence = dim_sequence(2:end)*255;

% randomly pick choose one of the three targets
off_remo = custom_mnrnd([1/3, 1/3, 1/3]);
off_keep = off_remo==0;
off_remo = logical(off_remo);

% rot_count
r_i = 0;

t0 =GetSecs;

% parameters for fixation controls
fix_ok = 1;
n_consecutive = 12; %  100/(1/60*1000)
fix_counter = 0;


% other/timing
first_flip = 0;
time_dim_onset = NaN;
time_dim_offset = NaN;
time_MIB_onset = NaN;
time_MIB_offset = NaN;

while (GetSecs-t0) < 10 && fix_ok==1
    
    % Calculate the X screen position of the dots (note we have to convert
    % from degrees to radians here.
    xpos = cos(angles .* (pi / 180)) .* radii_y.* visual.ppc;
    
    % Draw the dots. Here we set them to white, determine the point at
    % which the dots are drawn relative to, in this case our screen center.
    % And set anti-aliasing to 1. This gives use smooth dots. If you use 0
    % instead you will get squares. And if you use 2 you will get nicer
    % anti-aliasing of the dots.
    r_i = sign_1*(rem(abs(r_i), 360/rotation_speed)+1);
    all_pos = [(Rmat_sphere^r_i)*[xpos; ypos], dots_bg_xy];
    Screen('DrawDots', scr.main, all_pos, visual.dotSizePixels, visual.col_dots, fix_center', 2);
    
    % draw fixation point
    %Screen('FillOval', window, col_dots, CenterRectOnPoint([0,0, round(pixPerCm/2), round(pixPerCm/2)], fix_center(1), fix_center(2)));
    %Screen('FillOval', window, black, CenterRectOnPoint([0,0, round(pixPerCm/1.1/2), round(pixPerCm/1.1/2)], fix_center(1), fix_center(2)));
    Screen('FillOval', scr.main, visual.black, CenterRectOnPoint([0,0, round(1.5*visual.ppc), round(1.5*visual.ppc)], fix_center(1), fix_center(2)));
    
    % draw fixation stimulus
    if void==0
        if center_on
            drawSingleCross(fix_center, 1, scr.main, [255, 100, 100],round(visual.ppc/3), 3);
        else
            drawSingleCross(fix_center, 3, scr.main, [255, 255, 0],round(visual.ppc/3), 3);
        end
    end
    
    %  draw targets
    if (GetSecs-t0)<off_onset || (GetSecs-t0)>(off_onset+off_dur)
        Screen('DrawDots', scr.main, target_loc, visual.target_size, visual.target_color, fix_center', 1);
    else
        Screen('DrawDots', scr.main, target_loc(:,off_keep), visual.target_size, visual.target_color, fix_center', 1);
        % if dimming
        dim_count=dim_count+1;
        Screen('DrawDots', scr.main, target_loc(:,off_remo), visual.target_diff_size, [visual.target_color, dim_sequence(dim_count)], fix_center', 1);
    end
    
    % Flip to the screen
    Screen('Flip', scr.main);
    
    % keep track of timestamps on tobii system
    if first_flip==0
        first_flip = 1;
        time_MIB_onset = Tobii.get_system_time_stamp;
    end
    if dim_count==1
        time_dim_onset = Tobii.get_system_time_stamp;
    elseif dim_count == frame_dim
        time_dim_offset = Tobii.get_system_time_stamp;
    end
    
    % Check fixation
    %[gazeX, gazeY, fix_ok] = getGazeCoordinates(eyetracker, scr, visual, fix_center, scr.fixationThreshold);
    [~, ~, fix_ok_i] = getGazeCoordinates(eyetracker, scr, visual, fix_center, scr.fixationThreshold);
    
    if ~fix_ok_i 
        fix_counter = fix_counter+1;
    else
        fix_counter = 0;
    end
    
    if fix_counter > n_consecutive
        fix_ok = 0;
    end

    %fprintf('gaze(x,y): %i, %i; fix target: %i, %i; fix criterion: %i\n', round(gazeX), round(gazeY), round(fix_center), fix_ok); %DEBUG
    %fix_ok = true; %DEBUG

    % Increment the angle of the dots by one degree per frame
    angles = angles + sign_2*rotation_speed;
    
    % fixation stimulus update
    if void==0
        count = count+1;
    end
    if count*scr.fd > fix_halfcycle
        void = 1;
        count =0;
        if center_on==1
            center_on=0;
        else
            center_on=1;
        end
    end
    if void==1
        void_count = void_count+1;
    end
    if void_count>n_frame_void
        void_count = 0;
        void=0;
    end

end

Screen('FillRect', scr.main,visual.bgColor);
Screen('Flip', scr.main);

time_MIB_offset = Tobii.get_system_time_stamp;

%% compile output
stim_details.target_angle = target_angle;
stim_details.target_loc = target_loc;
stim_details.off_remo = off_remo;
stim_details.fix_center=fix_center;

