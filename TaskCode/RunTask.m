function Neuro = RunTask(Params,Neuro)
% Explains the task to the subject, and serves as a reminder for pausing
% and quitting the experiment (w/o killing matlab or something)

% output to screen
fprintf('\n\nImagined Movements:\n')
fprintf('  %i Blocks (%i Total Trials)\n',...
    Params.NumBlocks,...
    Params.NumBlocks*Params.NumTrialsPerBlock)
fprintf('  Saving data to %s\n\n',Params.Datadir)

Neuro = RunLoop(Params,Neuro,Params.Datadir);


end % RunTask
