function scr = prepScreen()
%
% prepare and open display window
%

HideCursor;

scr.colDept = 32;
scr.width   = 29.5;% monitor width (cm)

% If there are multiple displays guess that one without the menu bar is the
% best choice.  Dislay 0 has the menu bar.
scr.allScreens = Screen('Screens');
scr.expScreen  = max(scr.allScreens);

% get rid of PsychtoolBox Welcome screen
Screen('Preference', 'SkipSyncTests', 0)

% get rid of warning to test program on dell HPDI laptop
Screen('Preference','SuppressAllWarnings', 1);

% Open a window.  Note the new argument to OpenWindow with value 2, specifying the number of buffers to the onscreen window.
%[scr.main, scr.rect] = PsychImaging('OpenWindow', scr.expScreen, [0 0 0], [], 32, 2);
[scr.main, scr.rect] = PsychImaging('OpenWindow', scr.expScreen, [0 0 0], [0 0 1080 1080], 32, 2);

% get information about  screen
[scr.xres, scr.yres]    = Screen('WindowSize', scr.main);  % heigth and width of screen [pix]

% conversion factors
scr.cmPerPix = scr.width / scr.xres;
scr.pixPerCm = scr.xres / scr.width;


% eye tracking controls
scr.viewingDistance = 60; % cm
th_deg = 2;
scr.fixationThreshold = 2*scr.viewingDistance * tan((th_deg*pi)/360);

% determine th main window's center
[scr.centerX, scr.centerY] = WindowCenter(scr.main);

% refresh duration
scr.fd = Screen('GetFlipInterval',scr.main);    % frame duration [s]

% Enable alpha blending with proper blend-function
Screen('BlendFunction', scr.main, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

% Give the display a moment to recover from the change of display mode when
% opening a window. It takes some monitors and LCD scan converters a few seconds to resync.
WaitSecs(2);
