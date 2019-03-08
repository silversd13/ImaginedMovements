function ExperimentStart(Subject,BLACKROCK,DEBUG)
% function ExperimentStart(Subject)
% Subject - string for the subject id
% BLACKROCK - [0,1] if 1, collects, processes, and saves neural data
% DEBUG - [0,1] if 1, enters DEBUG mode in which screen is small and cursor
%   remains unhidden

%% Clear All and Close All
clearvars -except Subject BLACKROCK DEBUG
clearvars -global
clc
warning off

if ~exist('Subject','var'), Subject = 'Test'; DEBUG = 1; end
if ~exist('BLACKROCK','var'), BLACKROCK = 0; end
if ~exist('DEBUG','var'), DEBUG = 0; end

AssertOpenGL;
KbName('UnifyKeyNames');

if strcmpi(Subject,'Test'), Subject = 'Test'; end

%% Retrieve Parameters from Params File
Params.Subject = Subject;
Params.BLACKROCK = BLACKROCK;
Params.DEBUG = DEBUG;
Params = GetParams(Params);

%% Initialize Blackrock System
if BLACKROCK,
    if IsWin,
        addpath('C:\Program Files (x86)\Blackrock Microsystems\Cerebus Windows Suite')
    elseif IsLinux,
        addpath('/usr/local/CereLink');
    end
    cbmex('close'); % always close
    cbmex('open'); % open library
    cbmex('trialconfig', 1); % empty the buffer
end

%% Initialize Sync to Blackrock
if Params.SerialSync,
    Params.SerialPtr = serial(Params.SyncDev, 'BaudRate', Params.BaudRate);
    fopen(Params.SerialPtr);
    fprintf(Params.SerialPtr, '%s\n', 'START');
end
if Params.ArduinoSync,
    Params.ArduinoPtr = arduino;
    Params.ArduinoPin = 'D13';
    writeDigitalPin(Params.ArduinoPtr, Params.ArduinoPin, 0); % make sure the pin is at 0
    PulseArduino(Params.ArduinoPtr,Params.ArduinoPin,20);
end

%% Neural Signal Processing
% create neuro structure for keeping track of all neuro updates/state
% changes
Neuro.SaveRaw           = Params.SaveRaw;
Neuro.ZscoreRawFlag     = Params.ZscoreRawFlag;
Neuro.SaveProcessed     = Params.SaveProcessed;
Neuro.FilterBank        = Params.FilterBank;
Neuro.NumChannels       = Params.NumChannels;
Neuro.BufferSamps       = Params.BufferSamps;
Neuro.BadChannels       = Params.BadChannels;
Neuro.ReferenceMode     = Params.ReferenceMode;
Neuro.NumFeatures       = Params.NumFeatures;
Neuro.LastUpdateTime    = GetSecs;

% initialize filter bank state
for i=1:length(Params.FilterBank),
    Neuro.FilterBank(i).state = [];
end

% initialize stats for each channel for z-scoring
Neuro.ChStats.wSum1  = 0; % count
Neuro.ChStats.wSum2  = 0; % squared count
Neuro.ChStats.mean   = zeros(1,Params.NumChannels); % estimate of mean for each channel
Neuro.ChStats.S      = zeros(1,Params.NumChannels); % aggregate deviation from estimated mean for each channel
Neuro.ChStats.var    = zeros(1,Params.NumChannels); % estimate of variance for each channel

% initialize stats for each feature for z-scoring
Neuro.FeatureStats.wSum1  = 0; % count
Neuro.FeatureStats.wSum2  = 0; % squared count
Neuro.FeatureStats.mean   = zeros(1,Params.NumChannels); % estimate of mean for each channel
Neuro.FeatureStats.S      = zeros(1,Params.NumChannels); % aggregate deviation from estimated mean for each channel
Neuro.FeatureStats.var    = zeros(1,Params.NumChannels); % estimate of variance for each channel

% create low freq buffers
Neuro.FilterDataBuf = zeros(Neuro.BufferSamps,Neuro.NumChannels,3);

%% Check Important Params with User
LogicalStr = {'false', 'true'};

fprintf('\n\nImportant Experimental Parameters:')
fprintf('\n\n  Task Parameters:')
fprintf('\n    - task: %s', Params.Task)
fprintf('\n    - subject: %s', Params.Subject)
fprintf('\n    - blackrock mode: %s', LogicalStr{Params.BLACKROCK+1})
fprintf('\n    - debug mode: %s', LogicalStr{Params.DEBUG+1})

fprintf('\n\n  Neuro Processing Pipeline:')
if Params.GenNeuralFeaturesFlag,
    fprintf('\n    - generating neural features!')
else,
    fprintf('\n    - reference mode: %s', Params.ReferenceModeStr)
    fprintf('\n    - zscore raw: %s', LogicalStr{Params.ZscoreRawFlag+1})
    fprintf('\n    - save filtered data: %s', LogicalStr{Params.ZscoreRawFlag+1})
end

str = input('\n\nContinue? (''n'' to quit, otherwise continue)\n' ,'s');
if strcmpi(str,'n'),
    fprintf('\n\nExperiment Ended\n\n')
    return
end

%% Initialize Window
% Screen('Preference', 'SkipSyncTests', 0);
if DEBUG
    [Params.WPTR, Params.ScreenRectangle] = Screen('OpenWindow', 0, 0, [50 50 1000 1000]);
else
    [Params.WPTR, Params.ScreenRectangle] = Screen('OpenWindow', max(Screen('Screens')), 0);
end
Params.Center = [mean(Params.ScreenRectangle([1,3])),mean(Params.ScreenRectangle([2,4]))];
Params.IFI = Screen('GetFlipInterval', Params.WPTR);

% Font
Screen('TextFont',Params.WPTR, 'Arial');
Screen('TextSize',Params.WPTR, 28);

%% Initialize Sound
if Params.AudCue.Flag,
    InitializePsychSound(1);
    Params.PAPTR = PsychPortAudio('Open', [], 1, 1, 44100, 1);
    PsychPortAudio('Volume', Params.PAPTR, 0.25);
end

%% Center Rectangle For Playing Movies
Params.MovementMovRect([1,3]) = Params.MovementMovRect([1,3]) + Params.Center(1);
Params.MovementMovRect([2,4]) = Params.MovementMovRect([2,4]) + Params.Center(2);

%% Start
try
    % Baseline 
    if Params.BaselineTime>0,
        Neuro = RunBaseline(Params,Neuro);
    end
    
    % Imagined Cursor Movements Loop
    if Params.NumBlocks>0,
        [Neuro,Params] = RunTask(Params,Neuro);
    end
    
    % Pause and Finish!
    ExperimentStop(0,Params);
    
catch ME, % handle errors gracefully
    Screen('CloseAll')
    if Params.AudCue.Flag,
        PsychPortAudio('Close', Params.PAPTR);
    end
    for i=length(ME.stack):-1:1,
        if i==1,
            errorMessage = sprintf('Error in function %s() at line %d.\n\nError Message:\n%s\n\n', ...
                ME.stack(1).name, ME.stack(1).line, ME.message);
        else,
            errorMessage = sprintf('Error in function %s() at line %d.\n\n', ...
                ME.stack(i).name, ME.stack(i).line);
        end
        fprintf(1,'\n%s\n', errorMessage);
    end
    keyboard;
end

end % ExperimentStart
