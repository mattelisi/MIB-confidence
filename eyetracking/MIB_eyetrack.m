%
% MIB task
%

clear all;
addpath('functions/');
home;

%% general parameters
const.gammaLinear = 0;      % use monitor linearization


%% participant informations
% collect data and, if duplicate, check before overwriting
newFile = 0;


while ~newFile
    [vpcode] = getVpCode;

    % create data file
    datFile = sprintf('%s.mat',vpcode);
    
    % dir names
    subDir=vpcode(1:4);
    sessionDir=vpcode(5:6);
    resdir=sprintf('data/%s/%s',subDir,sessionDir);
    
    if exist(resdir,'file')==7
        o = input('\n\n         This directory exists already. Should I continue/overwrite it [y / n]? ','s');
        if strcmp(o,'y')
            % delete files to be overwritten?
            if exist([resdir,'/',datFile])>0;                    delete([resdir,'/',datFile]); end
            if exist([resdir,'/',sprintf('%s',vpcode)])>0;       delete([resdir,'/',sprintf('%s',vpcode)]); end
            newFile = 1;
        end
    else
        mkdir(resdir);
        newFile = 1;
    end
end

%% run
sub_n = str2double(vpcode(1:2));
ses_n = str2double(vpcode(5:6));

% random number generator stream (r2010a default, different command for r2014a)
% this is needed only for matlab (where the random number generator start always at the same state)
% in octave the generator is initialized from /dev/urandom (if available) otherwise from CPU time,
% wall clock time, and the current fraction of a second.
rng('shuffle');

design = genDesign(ses_n, sub_n, vpcode);

% prepare screens
scr = prepScreen;

% prepare stimuli
visual = prepStim(scr, design);

tic;
try
    % runtrials
    [design, acc_session] = runTrials(design, vpcode, resdir, scr, visual);
catch ME
    sca;
    rethrow(ME);
end

% save updated design information
save(sprintf('./%s/%s.mat',resdir,vpcode),'design','visual','scr');

% save info for adjusting the difficulty ofthe task
session_info.prop_contrast_decrement = design.prop_contrast_decrement;
session_info.session_n = ses_n;
session_info.id =vpcode;
session_info.acc =mean(acc_session, 'omitnan');
session_info.N = sum(~isnan(acc_session));
save(sprintf('./%s/%s_info.mat',resdir,vpcode),'session_info');


fprintf(1,'\n\nThis part of the experiment took %.0f min.\n',(toc)/60);

% close
sca;
