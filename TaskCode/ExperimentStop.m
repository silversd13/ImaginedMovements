function ExperimentStop(fromPause,Params)
if ~exist('fromPause', 'var'), fromPause = 0; end

% final sync to blackrock
fprintf(Params.SerialPtr, '%s\n', 'START');
if Params.ArduinoSync, PulseArduino(length(Data.Events)); end

% Close Screen & Audio & sync files
Screen('CloseAll');
if Params.AudCue.Flag,
    PsychPortAudio('Close', Params.PAPTR);
end
fclose('all');

% quit
if fromPause, keyboard; end

end % ExperimentStop
