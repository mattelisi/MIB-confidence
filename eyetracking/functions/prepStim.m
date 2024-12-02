function[visual] = prepStim(scr, design)
%
% Prepare display parameters
% set constant stimulus properties
%

%% general display settings
visual.ppc = scr.pixPerCm; 
visual.black = BlackIndex(scr.main);
visual.white = WhiteIndex(scr.main);
visual.bgColor = visual.black;
visual.darkGrey = ceil((visual.black + visual.white) / 3);
visual.fgColor = [160, 160, 160];

Screen('FillRect', scr.main,visual.bgColor);
Screen('Flip', scr.main);

%% stimulus - blue dots
visual.col_dots = [0, 0, 200];

% "Sphere" height, width (radius) in cm
visual.sphSize = 9.6;

% This is the number of dots in the sphere
visual.numDots = 500;

% blue dot size
visual.dotSizePixels = round(0.18 * visual.ppc);

% N dots outside sphere
visual.dots_bg_n = round(visual.numDots * 0.7);

%% salient yellow targets

% proportion of contrast decrement of the salient target (a number between 0 and 1)
% the smaller is the number, the more difficult the tast is, with the
% understanding that
% 0 = no change
% 1 = the dots disappear completely
visual.prop_contrast_decrement = design.prop_contrast_decrement;

visual.target_size = round( 0.3 * visual.ppc);
visual.target_color = [255, 255, 0];
visual.target_dim_color = [255, 255, 0, 1-visual.prop_contrast_decrement];
visual.target_diff_size = visual.target_size;
visual.target_ecc = visual.sphSize * 3/4;

% prepare location coord (this will be rotated randomly each trial)
visual.target_loc = [cosd(30).*[1,-1].*visual.target_ecc.*visual.ppc, 0; ...
                     sind(30).*[1,+1].*visual.target_ecc.*visual.ppc, 0-visual.target_ecc.*visual.ppc];

%% response display
conf_X = round(10* visual.ppc);
visual.confH0 = round(scr.centerX - conf_X/2);
visual.confH1 = round(scr.centerX + conf_X/2);
visual.confV = round(scr.centerY);
                 
%%
visual.textSize = round(visual.ppc*1);

%% set priority of window activities to maximum
priorityLevel=MaxPriority(scr.main);
Priority(priorityLevel);