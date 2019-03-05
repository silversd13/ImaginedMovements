function [Neuro,Data,Params] = ExperimentPause(Params,Neuro,Data)
% Display text then wait for subject to resume experiment

if ~exist('Data','var'),
    Data.Events = [];
end

% Pause Screen
tex = 'Paused... Press ''p'' to continue, ''escape'' to quit, or ''d'' to debug';
DrawFormattedText(Params.WPTR, tex,'center','center',255);
Screen('Flip', Params.WPTR);

% add event to data structure
Data.Events(end+1).Time = GetSecs;
Data.Events(end).Str  = 'Pause';

KbCheck;
WaitSecs(.1);
while 1, % pause until subject presses p again or quits
    [~, ~, keyCode, ~] = KbCheck;
    if keyCode(KbName('p'))==1,
        keyCode(KbName('p'))=0; % set to 0 to avoid multiple pauses in a row
        break;
    end
    if keyCode(KbName('escape'))==1 || keyCode(KbName('q'))==1,
        ExperimentStop(1,Params); % quit experiment
    end
    if keyCode(KbName('d'))==1,
        keyboard; % quit experiment
    end
    
    % grab and process neural data
    tim = GetSecs;
    if ((tim-Neuro.LastUpdateTime)>1/Params.UpdateRate),
        Neuro.LastUpdateTime = tim;
        if Params.BLACKROCK,
            [Neuro,~] = NeuroPipeline(Neuro,Data);
        elseif Params.GenNeuralFeaturesFlag,
            Neuro.NeuralFeatures = VelToNeuralFeatures(Params);
        end
    end
end

% add event to data structure
Data.Events(end+1).Time = GetSecs;
Data.Events(end).Str  = 'EndPause';

Screen('Flip', Params.WPTR);
WaitSecs(.1);

end % ExperimentPause