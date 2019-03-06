function ExperimentStop(fromPause,Params)
if ~exist('fromPause', 'var'), fromPause = 0; end

% final sync to blackrock
if Params.SerialSync, fprintf(Params.SerialPtr, '%s\n', 'START'); end
if Params.ArduinoSync, PulseArduino(Params.ArduinoPtr,Params.ArduinoPin,30); end

% Close Screen & Audio & sync files
Screen('CloseAll');
if Params.AudCue.Flag,
    PsychPortAudio('Close', Params.PAPTR);
end
fclose('all');

% quit
if fromPause, keyboard; end

end % ExperimentStop
