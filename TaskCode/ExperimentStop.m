function ExperimentStop(fromPause,Params)
if ~exist('fromPause', 'var'), fromPause = 0; end

% Close Screen & Audio
Screen('CloseAll');
PsychPortAudio('Close', Params.PAPTR);

% quit
if fromPause, keyboard; end

end % ExperimentStop
