function [Data, Neuro, Params] = RunTrial(Data,Params,Neuro)
% Runs a trial, saves useful data along the way
% Each trial contains the following pieces
% 1) Inter-trial interval
% 2) Get the cursor to the start target (center)
% 3) Hold position during an instructed delay period
% 4) Get the cursor to the reach target (different on each trial)
% 5) Feedback

%% Set up trial
Movement = Data.Movement;

% Output to Command Line
fprintf('\nTrial: %i\n',Data.Trial)
fprintf('Target: %s\n',Movement)

% keep track of update times
tim = GetSecs;
LastPredictTime = tim;
Neuro.LastUpdateTime = tim;
dt_vec = [];
dT_vec = [];

% Visual Go Cue
VisCueRect([1,3]) = Params.VisCue.Rect([1,3]) + Params.VisCue.Position(1) + Params.Center(1); % add x-pos
VisCueRect([2,4]) = Params.VisCue.Rect([2,4]) + Params.VisCue.Position(2) + Params.Center(2); % add y-pos

% Visual Mvmt Cue
VisMvmtFrameRect([1,3]) = Params.VisMvmt.FrameRect([1,3]) + Params.Center(1); % add x-pos
VisMvmtFrameRect([2,4]) = Params.VisMvmt.FrameRect([2,4]) + Params.Center(2); % add y-pos

%% Inter Trial Interval
if Params.InterTrialInterval>0,
    tstart  = GetSecs;
    Data.Events(end+1).Time = tstart;
    Data.Events(end).Str  = 'Inter Trial Interval';
    if Params.SerialSync, fprintf(Params.SerialPtr, '%s\n', 'ITI'); end
    if Params.ArduinoSync, PulseArduino(Params.ArduinoPtr,Params.ArduinoPin,length(Data.Events)); end
    
    % Blank Screen
    Screen('Flip', Params.WPTR);

    done = 0;
    TotalTime = 0;
    while ~done,
        % Update Time & Position
        tim = GetSecs;

        % for pausing and quitting expt
        if CheckPause,
            [Neuro,Data,Params] = ExperimentPause(Params,Neuro,Data);
            LastPredictTime = Neuro.LastUpdateTime;
        end

        % Update Screen Every Xsec
        if (tim-LastPredictTime) > 1/Params.ScreenRefreshRate,
            % time
            dt = tim - LastPredictTime;
            TotalTime = TotalTime + dt;
            dt_vec(end+1) = dt; %#ok<*AGROW>
            LastPredictTime = tim;
            Data.Time(1,end+1) = tim;

            % grab and process neural data
            if ((tim-Neuro.LastUpdateTime)>1/Params.UpdateRate),
                dT = tim-Neuro.LastUpdateTime;
                dT_vec(end+1) = dT;
                Neuro.LastUpdateTime = tim;
                if Params.BLACKROCK,
                    [Neuro,Data] = NeuroPipeline(Neuro,Data);
                    Data.NeuralTime(1,end+1) = tim;
                end
                if Params.GenNeuralFeaturesFlag,
                    Neuro.NeuralFeatures = VelToNeuralFeatures(Params);
                    if Params.BLACKROCK, % override
                        Data.NeuralFeatures{end} = Neuro.NeuralFeatures;
                        Data.NeuralTime(1,end) = tim;
                    else,
                        Data.NeuralFeatures{end+1} = Neuro.NeuralFeatures;
                        Data.NeuralTime(1,end+1) = tim;
                    end
                end
            end

        end

        % end if takes too long
        if TotalTime > Params.InterTrialInterval,
            done = 1;
        end

    end % Inter trial interval
end % if there is an interval

%% Hold Interval
tstart  = GetSecs;
Data.Events(end+1).Time = tstart;
Data.Events(end).Str  = 'Hold Interval';
if Params.SerialSync, fprintf(Params.SerialPtr, '%s\n', 'HI'); end
if Params.ArduinoSync, PulseArduino(Params.ArduinoPtr,Params.ArduinoPin,length(Data.Events)); end

% Stop Movement Cue (visual only)
Screen('FillOval', Params.WPTR, Params.VisCue.StopColor, VisCueRect)
if Params.VisMvmt.Flag,
    Screen('FillRect', Params.WPTR, ... % End Pos
        Params.VisMvmt.Color, ...
        VisMvmtFrameRect)
end
Screen('Flip', Params.WPTR);

done = 0;
TotalTime = 0;
while ~done,
    % Update Time & Position
    tim = GetSecs;
    
    % for pausing and quitting expt
    if CheckPause,
        [Neuro,Data,Params] = ExperimentPause(Params,Neuro,Data);
        LastPredictTime = Neuro.LastUpdateTime;
    end
    
    % Update Screen Every Xsec
    if (tim-LastPredictTime) > 1/Params.ScreenRefreshRate,
        % time
        dt = tim - LastPredictTime;
        TotalTime = TotalTime + dt;
        dt_vec(end+1) = dt; %#ok<*AGROW>
        LastPredictTime = tim;
        Data.Time(1,end+1) = tim;
        
        % grab and process neural data
        if ((tim-Neuro.LastUpdateTime)>1/Params.UpdateRate),
            dT = tim-Neuro.LastUpdateTime;
            dT_vec(end+1) = dT;
            Neuro.LastUpdateTime = tim;
            if Params.BLACKROCK,
                [Neuro,Data] = NeuroPipeline(Neuro,Data);
                Data.NeuralTime(1,end+1) = tim;
            end
            if Params.GenNeuralFeaturesFlag,
                Neuro.NeuralFeatures = VelToNeuralFeatures(Params);
                if Params.BLACKROCK, % override
                    Data.NeuralFeatures{end} = Neuro.NeuralFeatures;
                    Data.NeuralTime(1,end) = tim;
                else,
                    Data.NeuralFeatures{end+1} = Neuro.NeuralFeatures;
                    Data.NeuralTime(1,end+1) = tim;
                end
            end
        end
        
    end
    
    % end if takes too long
    if TotalTime > Params.HoldInterval,
        done = 1;
    end
    
end % Hold Interval

%% Go to reach target
tstart  = GetSecs;
Data.Events(end+1).Time = tstart;
Data.Events(end).Str  = 'Movement Start';
if Params.SerialSync, fprintf(Params.SerialPtr, '%s\n', 'MS'); end
if Params.ArduinoSync, PulseArduino(Params.ArduinoPtr,Params.ArduinoPin,length(Data.Events)); end

% Movement Cue (visual and auditory)
% audio buffer
if Params.AudCue.Flag,
    PsychPortAudio('FillBuffer', Params.PAPTR, Params.AudCue.Beep);
    PsychPortAudio('Start', Params.PAPTR, 1, 0, 1);
end
% screen buffer
Screen('FillOval', Params.WPTR, Params.VisCue.StartColor, VisCueRect)
Screen('Flip', Params.WPTR);

done = 0;
TotalTime = 0;
ct = 1;
while ~done,
    % Update Time & Position
    tim = GetSecs;
    
    % for pausing and quitting expt
    if CheckPause,
        [Neuro,Data,Params] = ExperimentPause(Params,Neuro,Data);
        LastPredictTime = Neuro.LastUpdateTime;
    end
    
    % Update Screen
    if (tim-LastPredictTime) > 1/Params.ScreenRefreshRate,
        % time
        dt = tim - LastPredictTime;
        TotalTime = TotalTime + dt;
        dt_vec(end+1) = dt;
        LastPredictTime = tim;
        Data.Time(1,end+1) = tim;
        
        % grab and process neural data
        if ((tim-Neuro.LastUpdateTime)>1/Params.UpdateRate),
            dT = tim-Neuro.LastUpdateTime;
            dT_vec(end+1) = dT;
            Neuro.LastUpdateTime = tim;
            if Params.BLACKROCK,
                [Neuro,Data] = NeuroPipeline(Neuro,Data);
                Data.NeuralTime(1,end+1) = tim;
            end
            if Params.GenNeuralFeaturesFlag,
                Neuro.NeuralFeatures = VelToNeuralFeatures(Params);
                if Params.BLACKROCK, % override
                    Data.NeuralFeatures{end} = Neuro.NeuralFeatures;
                    Data.NeuralTime(1,end) = tim;
                else,
                    Data.NeuralFeatures{end+1} = Neuro.NeuralFeatures;
                    Data.NeuralTime(1,end+1) = tim;
                end
            end
        end
        
        if Params.VisMvmt.Flag,
            % Drawing
            pos = Params.VisMvmt.Traj(ct,:);
            if ct<size(Params.VisMvmt.Traj,1)
                ct = ct + 1;
                Screen('FrameRect', Params.WPTR, ... % Full Time
                    Params.VisMvmt.Color, ...
                    VisMvmtFrameRect)
                Rect = VisMvmtFrameRect;
                Rect(2) = pos(2) + Params.Center(2); % adjust height
                Screen('FillRect', Params.WPTR, ... % Current Time
                    Params.VisMvmt.Color, ...
                    Rect)
            end
            Screen('FillOval', Params.WPTR, ... % Start Light
                Params.VisCue.StartColor, ...
                VisCueRect)
            
            Screen('Flip', Params.WPTR);
        end
    end
    
    % end if takes too long
    if TotalTime > Params.MovementInterval,
        done = 1;
    end
    
end % Movement Loop


%% Completed Trial - Give Feedback

% output update times
if Params.Verbose,
    fprintf('Screen Update Frequency: Goal=%iHz, Actual=%.2fHz (+/-%.2fHz)\n',...
        Params.ScreenRefreshRate,mean(1./dt_vec),std(1./dt_vec))
    fprintf('System Update Frequency: Goal=%iHz, Actual=%.2fHz (+/-%.2fHz)\n',...
        Params.UpdateRate,mean(1./dT_vec),std(1./dT_vec))
end

end % RunTrial



