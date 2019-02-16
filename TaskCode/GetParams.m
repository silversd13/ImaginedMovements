function Params = GetParams(Params)
% Experimental Parameters
% These parameters are meant to be changed as necessary (day-to-day,
% subject-to-subject, experiment-to-experiment)
% The parameters are all saved in 'Params.mat' for each experiment

%% Verbosity
Params.Verbose = true;

%% Experiment
Params.Task = 'ImaginedMovements';

%% Current Date and Time
% get today's date
now = datetime;
Params.YYYYMMDD = sprintf('%i',yyyymmdd(now));
Params.HHMMSS = sprintf('%02i%02i%02i',now.Hour,now.Minute,round(now.Second));

%% Data Saving

% if Subject is 'Test' or 'test' then can write over previous test
if strcmpi(Params.Subject,'Test'),
    Params.YYYYMMDD = 'YYYYMMDD';
    Params.HHMMSS = 'HHMMSS';
end

if IsWin,
    projectdir = 'C:\Users\ganguly-lab2\Documents\MATLAB\ImaginedMovements';
elseif IsOSX,
    projectdir = '/Users/daniel/Projects/ImaginedMovements/';
else,
    projectdir = '/home/dsilver/Projects/ImaginedMovements/';
end
addpath(genpath(fullfile(projectdir,'TaskCode')));

% create folders for saving
datadir = fullfile(projectdir,'Data',Params.Subject,Params.YYYYMMDD,Params.HHMMSS);
Params.Datadir = datadir;
% if folders already exist, warn user before continuing (unless,
% subject='Test')
if exist(Params.Datadir,'dir'),
    if ~strcmpi(Params.Subject,'Test'),
        str = input([...
            '\n\nData directory already exists.',...
            '\nAre you sure you want to continue? Y/N ',...
            '\nThis directory will be overwritten if you continue. '],'s');
    else, str = 'Y';
    end
%     if strcmpi(str,'Y'), % delete all files in directory
%         recycle('on')
%         delete(fullfile(datadir,'*'))
%         delete(fullfile(datadir,'Imagined','*'))
%         delete(fullfile(datadir,'BCI_CLDA','*'))
%         delete(fullfile(datadir,'BCI_Fixed','*'))
%     end
end
mkdir(datadir);

%% Timing
Params.ScreenRefreshRate = 10; % Hz
Params.UpdateRate = 10; % Hz
Params.BaselineTime = 1; % secs

%% Trial and Block Types
Params.NumBlocks            = 10;
Params.NumTrialsPerBlock    = 3;

%% Hold Times
Params.InterTrialInterval   = .5;
Params.InterBlockInterval   = 0;
Params.HoldInterval         = 2;
Params.MovementInterval     = 3;
Params.MovementTime         = .75*Params.MovementInterval;

%% Movements
Params.Movements = {...
    'Wrist Flexion'
    'Wrist Extension'
    'Elbow Flexion'
    'Elbow Extension'
    };
Params.MvmtSelectionFlag = 2; % 1-in order, 2-pseudorandom, 3-random, 
switch Params.MvmtSelectionFlag,
    case {1,2}, Params.MvmtSelection = @(n,B) mod(B-1,n)+1;
    case 3, Params.MvmtSelection = @(n,B) randi(n);
end

%% Visual Go Cue
Params.VisCue.Size = 30;
Params.VisCue.StopColor = [255,0,0];
Params.VisCue.StartColor = [0,255,0];
Params.VisCue.Position  = [0,100];
Params.VisCue.Rect = ...
    [-Params.VisCue.Size -Params.VisCue.Size ...
    +Params.VisCue.Size +Params.VisCue.Size];

%% Auditory Go Cue
Params.AudCue.Fs = 44100; % hz
Params.AudCue.Time = .5; % secs
Params.AudCue.Beep = MakeBeep(500, Params.AudCue.Time, Params.AudCue.Fs);

%% Visual Movement Timing
Params.VisMvmt.Flag = true;
Params.VisMvmt.Width = 10; % 1/2
Params.VisMvmt.Color = [66,217,244];
Params.VisMvmt.EndPos = 100;
Params.VisMvmt.StartPos = -300;
Params.VisMvmt.Offset = 200;
Params.VisMvmt.FrameRect = ...
    [-Params.VisMvmt.Width+Params.VisMvmt.Offset +Params.VisMvmt.StartPos ...
    +Params.VisMvmt.Width+Params.VisMvmt.Offset +Params.VisMvmt.EndPos];
Params.VisMvmt.Traj = GenerateCursorTraj(...
    [Params.VisMvmt.Offset,Params.VisMvmt.StartPos],...
    [Params.VisMvmt.Offset,Params.VisMvmt.EndPos],...
    Params.MovementTime,Params);

%% BlackRock Params
Params.GenNeuralFeaturesFlag = true;
Params.ZscoreRawFlag = true;
Params.SaveProcessed = false;

Params.Fs = 1000;
Params.NumChannels = 128;
Params.BufferTime = 2; % secs longer for better phase estimation of low frqs
Params.BufferSamps = Params.BufferTime * Params.Fs;
Params.BadChannels = [];
RefModeStr = {'none','common_mean','common_median'};
Params.ReferenceMode = 0; % 0-no ref, 1-common mean, 2-common median
Params.ReferenceModeStr = RefModeStr{Params.ReferenceMode+1};

% filter bank - each element is a filter bank
% fpass - bandpass cutoff freqs
% feature - # of feature (can have multiple filters for a single feature
% eg., high gamma is composed of multiple freqs)
Params.FilterBank = [];
Params.FilterBank(end+1).fpass = [.5,4];    % delta
Params.FilterBank(end).feature = 1;
Params.FilterBank(end+1).fpass = [4,8];     % theta
Params.FilterBank(end).feature = 2;
Params.FilterBank(end+1).fpass = [8,13];    % alpha
Params.FilterBank(end).feature = 3;
Params.FilterBank(end+1).fpass = [13,19];   % beta1
Params.FilterBank(end).feature = 4;
Params.FilterBank(end+1).fpass = [19,30];   % beta2
Params.FilterBank(end).feature = 4;
Params.FilterBank(end+1).fpass = [30,36];   % low gamma1 
Params.FilterBank(end).feature = 5;
Params.FilterBank(end+1).fpass = [36,42];   % low gamma2 
Params.FilterBank(end).feature = 5;
Params.FilterBank(end+1).fpass = [42,50];   % low gamma3
Params.FilterBank(end).feature = 5;
Params.FilterBank(end+1).fpass = [70,77];   % high gamma1
Params.FilterBank(end).feature = 6;
Params.FilterBank(end+1).fpass = [77,85];   % high gamma2
Params.FilterBank(end).feature = 6;
Params.FilterBank(end+1).fpass = [85,93];   % high gamma3
Params.FilterBank(end).feature = 6;
Params.FilterBank(end+1).fpass = [93,102];  % high gamma4
Params.FilterBank(end).feature = 6;
Params.FilterBank(end+1).fpass = [102,113]; % high gamma5
Params.FilterBank(end).feature = 6;
Params.FilterBank(end+1).fpass = [113,124]; % high gamma6
Params.FilterBank(end).feature = 6;
Params.FilterBank(end+1).fpass = [124,136]; % high gamma7
Params.FilterBank(end).feature = 6;
Params.FilterBank(end+1).fpass = [136,150]; % high gamma8
Params.FilterBank(end).feature = 6;
% compute filter coefficients
for i=1:length(Params.FilterBank),
    [b,a] = butter(3,Params.FilterBank(i).fpass/(Params.Fs/2));
    Params.FilterBank(i).b = b;
    Params.FilterBank(i).a = a;
end

Params.NumFeatures = length(unique([Params.FilterBank.feature])) + 1;

%% Save Parameters
save(fullfile(Params.Datadir,'Params.mat'),'Params');

end % GetParams

