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
    projectdir = '~/Projects/ImaginedMovements/';
    butter(1,[.1,.5]);
end
addpath(genpath(fullfile(projectdir,'TaskCode')));

% create folders for saving
Params.ProjectDir = projectdir;
datadir = fullfile(projectdir,'Data',Params.Subject,Params.YYYYMMDD,Params.HHMMSS);
Params.Datadir = datadir;
mkdir(datadir);

%% Sync to Blackrock
Params.SerialSync = false;
Params.SyncDev = '/dev/ttyS1';
Params.BaudRate = 115200;

Params.ArduinoSync = true;

%% Timing
Params.ScreenRefreshRate = 5; % Hz
Params.UpdateRate = 5; % Hz
Params.BaselineTime = 120; % secs

%% Trial and Block Types
Params.NumBlocks            = 4;
Params.NumTrialsPerBlock    = 5;

%% Hold Times
Params.InterTrialInterval   = 3;
Params.HoldInterval         = 2;
Params.MovementInterval     = 3;
Params.MovementTime         = 4/5*Params.MovementInterval;

%% Movements
Params.Movements = {...
    'Squeeze your right hand'
    };
% Params.Movements = {...
%     'Move Your Left Arm'
%     'Move Your Right Arm'
%     'Grasp Your Right Hand'
%     'Say "OK"'
%     'Shake Your Head (No)'
%     'Nod Your Head (Yes)'
%     };
Params.MovementMovDir = fullfile(projectdir,'TaskCode','movements');
Params.MovementMovFiles = {...
    'nan.mov'
    'nan.mov'
    'nan.mov'
    'nan.mov'
    'nan.mov'
    'nan.mov'
    };
Params.MovementMovRect = [-200 -200 200 200];

Params.MvmtSelectionFlag = 1; % 1-in order, 2-pseudorandom, 3-random, 
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
Params.AudCue.Flag = false;
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
Params.BadChannels = [];
Params.ZBufSize = 120; % secs
Params.GenNeuralFeaturesFlag = false;
Params.ZscoreRawFlag = true;
Params.UpdateChStatsFlag = false;
Params.ZscoreFeaturesFlag = true;
Params.UpdateFeatureStatsFlag = false;
Params.SaveRaw = true;
Params.SaveProcessed = false;

Params.Fs = 1000;
Params.NumChannels = 128;
Params.NumFeatureBins = 1;
Params.BufferTime = 2; % secs longer for better phase estimation of low frqs
Params.BufferSamps = Params.BufferTime * Params.Fs;
RefModeStr = {'none','common_mean','common_median'};
Params.ReferenceMode = 2; % 0-no ref, 1-common mean, 2-common median
Params.ReferenceModeStr = RefModeStr{Params.ReferenceMode+1};

% filter bank - each element is a filter bank
% fpass - bandpass cutoff freqs
% feature - # of feature (can have multiple filters for a single feature
% eg., high gamma is composed of multiple freqs)
Params.FilterBank = [];
Params.FilterBank(end+1).fpass = [.5,4];    % delta
Params.FilterBank(end).buffer_flag = true;
Params.FilterBank(end).hilbert_flag = true;
Params.FilterBank(end).phase_flag = true;
Params.FilterBank(end).feature = 2;

Params.FilterBank(end+1).fpass = [4,8];     % theta
Params.FilterBank(end).buffer_flag = true;
Params.FilterBank(end).hilbert_flag = true;
Params.FilterBank(end).phase_flag = false;
Params.FilterBank(end).feature = 3;

Params.FilterBank(end+1).fpass = [8,13];    % alpha
Params.FilterBank(end).buffer_flag = true;
Params.FilterBank(end).hilbert_flag = true;
Params.FilterBank(end).phase_flag = false;
Params.FilterBank(end).feature = 4;

Params.FilterBank(end+1).fpass = [13,19];   % beta1
Params.FilterBank(end).buffer_flag = false;
Params.FilterBank(end).hilbert_flag = false;
Params.FilterBank(end).phase_flag = false;
Params.FilterBank(end).feature = 5;

Params.FilterBank(end+1).fpass = [19,30];   % beta2
Params.FilterBank(end).buffer_flag = false;
Params.FilterBank(end).hilbert_flag = false;
Params.FilterBank(end).phase_flag = false;
Params.FilterBank(end).feature = 5;

Params.FilterBank(end+1).fpass = [30,36];   % low gamma1 
Params.FilterBank(end).buffer_flag = false;
Params.FilterBank(end).hilbert_flag = false;
Params.FilterBank(end).phase_flag = false;
Params.FilterBank(end).feature = 6;

Params.FilterBank(end+1).fpass = [36,42];   % low gamma2 
Params.FilterBank(end).buffer_flag = false;
Params.FilterBank(end).hilbert_flag = false;
Params.FilterBank(end).phase_flag = false;
Params.FilterBank(end).feature = 6;

Params.FilterBank(end+1).fpass = [42,50];   % low gamma3
Params.FilterBank(end).buffer_flag = false;
Params.FilterBank(end).hilbert_flag = false;
Params.FilterBank(end).phase_flag = false;
Params.FilterBank(end).feature = 6;

Params.FilterBank(end+1).fpass = [70,77];   % high gamma1
Params.FilterBank(end).buffer_flag = false;
Params.FilterBank(end).hilbert_flag = false;
Params.FilterBank(end).phase_flag = false;
Params.FilterBank(end).feature = 7;

Params.FilterBank(end+1).fpass = [77,85];   % high gamma2
Params.FilterBank(end).buffer_flag = false;
Params.FilterBank(end).hilbert_flag = false;
Params.FilterBank(end).phase_flag = false;
Params.FilterBank(end).feature = 7;

Params.FilterBank(end+1).fpass = [85,93];   % high gamma3
Params.FilterBank(end).buffer_flag = false;
Params.FilterBank(end).hilbert_flag = false;
Params.FilterBank(end).phase_flag = false;
Params.FilterBank(end).feature = 7;

Params.FilterBank(end+1).fpass = [93,102];  % high gamma4
Params.FilterBank(end).buffer_flag = false;
Params.FilterBank(end).hilbert_flag = false;
Params.FilterBank(end).phase_flag = false;
Params.FilterBank(end).feature = 7;

Params.FilterBank(end+1).fpass = [102,113]; % high gamma5
Params.FilterBank(end).buffer_flag = false;
Params.FilterBank(end).hilbert_flag = false;
Params.FilterBank(end).phase_flag = false;
Params.FilterBank(end).feature = 7;

Params.FilterBank(end+1).fpass = [113,124]; % high gamma6
Params.FilterBank(end).buffer_flag = false;
Params.FilterBank(end).hilbert_flag = false;
Params.FilterBank(end).phase_flag = false;
Params.FilterBank(end).feature = 7;

Params.FilterBank(end+1).fpass = [124,136]; % high gamma7
Params.FilterBank(end).buffer_flag = false;
Params.FilterBank(end).hilbert_flag = false;
Params.FilterBank(end).phase_flag = false;
Params.FilterBank(end).feature = 7;

Params.FilterBank(end+1).fpass = [136,150]; % high gamma8
Params.FilterBank(end).buffer_flag = false;
Params.FilterBank(end).hilbert_flag = false;
Params.FilterBank(end).phase_flag = false;
Params.FilterBank(end).feature = 7;

% compute filter coefficients
for i=1:length(Params.FilterBank),
    [b,a] = butter(3,Params.FilterBank(i).fpass/(Params.Fs/2));
    Params.FilterBank(i).b = b;
    Params.FilterBank(i).a = a;
end

% unique pwr feature + all phase features
Params.NumBuffer = sum([Params.FilterBank.buffer_flag]);
Params.NumHilbert = sum([Params.FilterBank.hilbert_flag]);
Params.NumPhase = sum([Params.FilterBank.phase_flag]);
Params.NumPower = length(unique([Params.FilterBank.feature]));
Params.NumFeatures = Params.NumPower + Params.NumPhase;

end % GetParams

