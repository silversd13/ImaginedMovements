function [Data, Neuro] = RunTrial(Data,Params,Neuro)
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
VisMvmtStartRect([1,3]) = Params.VisMvmt.Rect([1,3]) + Params.VisMvmt.StartPos(1) + Params.Center(1); % add x-pos
VisMvmtStartRect([2,4]) = Params.VisMvmt.Rect([2,4]) + Params.VisMvmt.StartPos(2) + Params.Center(2); % add y-pos
VisMvmtEndRect([1,3]) = Params.VisMvmt.Rect([1,3]) + Params.VisMvmt.EndPos(1) + Params.Center(1); % add x-pos
VisMvmtEndRect([2,4]) = Params.VisMvmt.Rect([2,4]) + Params.VisMvmt.EndPos(2) + Params.Center(2); % add y-pos

%% Inter Trial Interval
if Params.InterTrialInterval>0,
    tstart  = GetSecs;
    Data.Events(end+1).Time = tstart;
    Data.Events(end).Str  = 'Inter Trial Interval';

    % Blank Screen
    Screen('Flip', Params.WPTR);

    done = 0;
    TotalTime = 0;
    while ~done,
        % Update Time & Position
        tim = GetSecs;

        % for pausing and quitting expt
        if CheckPause,
            [Neuro,Data] = ExperimentPause(Params,Neuro,Data);
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
                elseif Params.GenNeuralFeaturesFlag,
                    Neuro.NeuralFeatures = VelToNeuralFeatures(Params);
                    Data.NeuralFeatures{end+1} = Neuro.NeuralFeatures;
                    Data.NeuralTime(1,end+1) = tim;
                end
            end

        end

        % end if takes too long
        if TotalTime > Params.HoldInterval,
            done = 1;
        end

    end % Inter trial interval
end % if there is an interval

%% Hold Interval
tstart  = GetSecs;
Data.Events(end+1).Time = tstart;
Data.Events(end).Str  = 'Hold Interval';

% Stop Movement Cue (visual only)
Screen('FillOval', Params.WPTR, Params.VisCue.StopColor, VisCueRect)
Screen('Flip', Params.WPTR);

done = 0;
TotalTime = 0;
while ~done,
    % Update Time & Position
    tim = GetSecs;
    
    % for pausing and quitting expt
    if CheckPause,
        [Neuro,Data] = ExperimentPause(Params,Neuro,Data);
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
            elseif Params.GenNeuralFeaturesFlag,
                Neuro.NeuralFeatures = VelToNeuralFeatures(Params);
                Data.NeuralFeatures{end+1} = Neuro.NeuralFeatures;
                Data.NeuralTime(1,end+1) = tim;
            end
        end
        
        if Params.VisMvmt.Flag,
            % Drawing
            Screen('FillOval', Params.WPTR, ... % Stop Light
                Params.VisCue.StopColor, ...
                VisCueRect)
            Screen('FillOval', Params.WPTR, ... % Start Pos
                Params.VisMvmt.Color, ...
                VisMvmtStartRect)
            Screen('FrameOval', Params.WPTR, ... % End Pos
                Params.VisMvmt.Color, ...
                VisMvmtEndRect)

            Screen('Flip', Params.WPTR);
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

% Movement Cue (visual and auditory)
% audio buffer
PsychPortAudio('FillBuffer', Params.PAPTR, Params.AudCue.Beep);
% screen buffer
Screen('FillOval', Params.WPTR, Params.VisCue.StartColor, VisCueRect)
% cues
PsychPortAudio('Start', Params.PAPTR, 1, 0, 1);
Screen('Flip', Params.WPTR);

done = 0;
TotalTime = 0;
ct = 1;
while ~done,
    % Update Time & Position
    tim = GetSecs;
    
    % for pausing and quitting expt
    if CheckPause,
        [Neuro,Data] = ExperimentPause(Params,Neuro,Data);
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
            elseif Params.GenNeuralFeaturesFlag,
                Neuro.NeuralFeatures = VelToNeuralFeatures(Params);
                Data.NeuralFeatures{end+1} = Neuro.NeuralFeatures;
                Data.NeuralTime(1,end+1) = tim;
            end
        end
        
        if Params.VisMvmt.Flag,
            % Drawing
            pos = Params.VisMvmt.Traj(ct,:);
            if ct<size(Params.VisMvmt.Traj,1)
                ct = ct + 1;
                Screen('FrameOval', Params.WPTR, ... % Start Pos
                    Params.VisMvmt.Color, ...
                    VisMvmtStartRect)
                Screen('FrameOval', Params.WPTR, ... % End Pos
                    Params.VisMvmt.Color, ...
                    VisMvmtEndRect)
                Rect([1,3]) = Params.VisMvmt.Rect([1,3]) + pos(1) + Params.Center(1); % add x-pos
                Rect([2,4]) = Params.VisMvmt.Rect([2,4]) + pos(2) + Params.Center(2); % add y-pos
                Screen('FillOval', Params.WPTR, ... % End Pos
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



