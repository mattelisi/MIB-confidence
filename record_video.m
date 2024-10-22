% record video

clear all;
addpath('functions/');
home;

design = genDesign(99, 99, 'recvideo');

% prepare screens
scr = prepScreen;

% prepare stimuli
visual = prepStim(scr, design);

visual.numDots = 650; 
visual.dots_bg_n = 100;

movieName = sprintf('%s_2.mov','MIB');
% use GSstreamer
% Screen('Preference', 'DefaultVideocaptureEngine', 3);
moviePtr = Screen('CreateMovie', scr.main, movieName, scr.xres, scr.yres, 30, ':CodecSettings= EncodingQuality=1');
visual.imageRect =  scr.rect;

% play video
[stim_details] = record_MIB(scr, visual, design, moviePtr);

% finalise
Screen('FinalizeMovie', moviePtr);

%
sca;