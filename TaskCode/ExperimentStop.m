function ExperimentStop(fromPause,Params)
if ~exist('fromPause', 'var'), fromPause = 0; end

% Close Screen & Audio
Screen('CloseAll');
if Params.AudCue.Flag,
    PsychPortAudio('Close', Params.PAPTR);
end

% quit
if fromPause, keyboard; end

end % ExperimentStop
