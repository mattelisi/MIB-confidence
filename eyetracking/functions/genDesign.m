function design = genDesign(sess, sub_n, vpcode)
% Set experiment details - MIB\confidence task
% Matteo Lisi


design.ID_n = sub_n;
design.ID = vpcode;

%% practice?
if sess==1
    design.practice.n_trials = 5;
else
    design.practice.n_trials = 0;
end

%% (some) stimuli settings - see prepStim.m for visual parameters

% How long should the dot dim/disappear for (duration in seconds)
design.off_dur = 1;

% This is the speed of the ball
% expressed in degrees of angle per frame
design.speed_of_rotation = 1/3;

% transition duration (in ms)
design.frame_dim_sec = 0.4;

%% load info about previous session accuracy 
desired_accuracy = 1/3 + 2/3/2;
design.step_contrast_change = 0.05;
if sess>1
    prev_sess = num2str(sess -1);
    if length(prev_sess)==1
        prev_sess = strcat('0',prev_sess);
    end
    infofile = sprintf('./data/%s/%s/%s_info.mat',vpcode(1:4),prev_sess, [vpcode(1:4),prev_sess]);
    if isfile(infofile)
        load(infofile);
        if session_info.acc > desired_accuracy
            design.prop_contrast_decrement = session_info.prop_contrast_decrement - design.step_contrast_change;
        elseif session_info.acc < desired_accuracy
            design.prop_contrast_decrement = session_info.prop_contrast_decrement + design.step_contrast_change;
        else
            design.prop_contrast_decrement = session_info.prop_contrast_decrement;
        end
        
        % boundaries
        if design.prop_contrast_decrement<0.1
            design.prop_contrast_decrement = 0.1;
        elseif design.prop_contrast_decrement>1
            design.prop_contrast_decrement = 1;
        end
    else
        design.prop_contrast_decrement = 0.8;
    end
else
    design.prop_contrast_decrement = 0.8;
end

%% other 
design.iti = 0.6; % inter trial interval
design.practice.n_trials = 1;

%% varying parameters
%design.off_onset = [2,3,4,5,6,7,8];
design.off_onset = [2,5,8];

%% trial list
t = 0;
design.repetitions = 6;
for t_on = design.off_onset 
for r = 1:design.repetitions
    t = t+1;
    trial(t).off_onset = t_on;
end
end
design.n_trials = t;

%% exp structure
design.nTrialsInBlock = 6;
design.nBlocks = ceil(design.n_trials/design.nTrialsInBlock);

% generate blocks
trial = trial(randperm(design.n_trials));
beginB=1; endB=min([design.nTrialsInBlock,design.n_trials]);
for i = 1:design.nBlocks
    design.b(i).trial = trial(beginB:endB);
    beginB  = beginB + design.nTrialsInBlock;
    endB    = endB   + design.nTrialsInBlock;
end