function [Neuro,Params] = RunLoop(Params,Neuro,DataDir)
% Defines the structure of collected data on each trial
% Loops through blocks and trials within blocks

%% Start Experiment
DataFields = struct(...
    'Block',NaN,...
    'Trial',NaN,...
    'TrialStartTime',NaN,...
    'TrialEndTime',NaN,...
    'Time',[],...
    'Movement','',...
    'NeuralTime',[],...
    'NeuralTimeBR',[],...
    'NeuralSamps',[],...
    'NeuralFeatures',{{}},...
    'ProcessedData',{{}},...
    'Events',[]...
    );

%%  Loop Through Blocks of Trials
Movements = Params.Movements;
Trial = 0;
for Block=1:Params.NumBlocks, % Block Loop
    
    % select movement for block
    if Params.MvmtSelectionFlag==2 && mod(Block-1,length(Params.Movements))==0,
        Movements = Params.Movements(randperm(length(Params.Movements)));
    end
    MvmtIdx = 1;Params.MvmtSelection(length(Params.Movements),Block);
    Movement = Movements{MvmtIdx};
    
    % Display Instructions
    Instructions = [...
        '\n\nImagined Movements: '...
        sprintf('%s\n\n',Movement)];
    InstructionScreen(Params,Instructions);
    
    % Display movie of movement
    mov_file = fullfile(Params.MovementMovDir,Params.MovementMovFiles{MvmtIdx});
    [mov_ptr,~,~,w,h] = Screen('OpenMovie', Params.WPTR, mov_file);
    Screen('PlayMovie', mov_ptr, 1);
    while 1,
        tex = Screen('GetMovieImage', Params.WPTR, mov_ptr);
        if tex<=0, break; end
        Screen('DrawTexture', Params.WPTR, tex, [], Params.MovementMovRect, 180);
        Screen('Flip', Params.WPTR);
        Screen('Close', tex);
    end
    Screen('PlayMovie', mov_ptr, 0);
    Screen('CloseMovie', mov_ptr);
    
    % Display Instructions
    Instructions = [...
        sprintf('\n\n%s\n\n',Movement)...
        'Time your movement to the bar.'...
        '\nAt any time, you can press ''p'' to briefly pause the task.'...
        '\n\nPress the ''Space Bar'' to begin!' ];
    InstructionScreen(Params,Instructions);
    mkdir(fullfile(Params.Datadir,Movement));

    for TrialPerBlock=1:Params.NumTrialsPerBlock, % Trial Loop
        % update trial
        Trial = Trial + 1;
        
        % set up trial
        TrialData = DataFields;
        TrialData.Block = Block;
        TrialData.Trial = Trial;
        TrialData.Movement = Movement;

        % Run Trial
        TrialData.TrialStartTime  = GetSecs;
        [TrialData,Neuro,Params] = RunTrial(TrialData,Params,Neuro);
        TrialData.TrialEndTime    = GetSecs;
                
        % Save Data from Single Trial
        save(...
            fullfile(DataDir,Movement,...
            sprintf('Data_Block%02i_TrialBlock%02i_Trial%04i.mat',...
            Block,TrialPerBlock,Trial)),...
            'TrialData',...
            '-v7.3','-nocompression');
        
    end % Trial Loop
    
    % Give Feedback for Block
    WaitSecs(Params.InterBlockInterval);
    
    % Make some figures based on all trials
    PlotERPs(fullfile(Params.Datadir,Movement),'off')
    
end % Block Loop

end % RunLoop



