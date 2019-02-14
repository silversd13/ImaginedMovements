function KF = FitKF(Params,datadir,fitFlag,KF,TrialBatch,dimRedFunc)
% function KF = FitKF(Params,datadir,fitFlag,KF,TrialBatch)
% Uses all trials in given data directory to initialize matrices for kalman
% filter. Returns KF structure containing matrices: A,W,P,C,Q
% 
% datadir - directory containing trials to fit data on
% fitFlag - 0-fit on actual state,
%           1-fit on intended kinematics (refit algorithm)
%           2-fit on intended kinematics (smoothbatch algorithm)
% KF - kalman filter structure containing matrices: A,W,P,C,Q
% TrialBatch - cell array of filenames w/ trials to use in smooth batch
% dimRedFunc - function handle for dimensionality red. redX = dimRedFunc(X)

% ouput to screen
fprintf('\n\nFitting Kalman Filter:\n')
switch fitFlag,
    case 0,
        fprintf('  Initial Fit\n')
        fprintf('  Data in %s\n', datadir)
    case 1,
        fprintf('  ReFit\n')
        fprintf('  Data in %s\n', datadir)
    case 2,
        fprintf('  Smooth Batch\n')
        fprintf('  Data in %s\n', datadir)
        fprintf('  Trials: {%s-%s}\n', TrialBatch{1},TrialBatch{end})
end

% Initialization of KF
if ~exist('KF','var'),
    KF = Params.KF;
end

% grab data trial data
datafiles = dir(fullfile(datadir,'Data*.mat'));
if fitFlag==2, % if smooth batch, only use files TrialBatch
    names = {datafiles.name};
    idx = zeros(1,length(names))==1;
    for i=1:length(TrialBatch),
        idx = idx | strcmp(names,TrialBatch{i});
    end
    datafiles = datafiles(idx);
end

Tfull = [];
Xfull = [];
Y = [];
T = [];
for i=1:length(datafiles),
    % load data, grab cursor pos and time
    load(fullfile(datadir,datafiles(i).name)) %#ok<LOAD>
    Tfull = cat(2,Tfull,TrialData.Time);
    if fitFlag==0, % fit on true kinematics
        Xfull = cat(2,Xfull,TrialData.CursorState);
    else, % refit on intended kinematics
        Xfull = cat(2,Xfull,TrialData.IntendedCursorState);
    end
    T = cat(2,T,TrialData.NeuralTime);
    Y = cat(2,Y,TrialData.NeuralFeatures{:});
end

% interpolate to get cursor pos and vel at neural times
if size(Xfull,2)>size(Y,2)
    X = interp1(Tfull',Xfull',T')';
else,
    X = Xfull;
end

% if DimRed is on, reduce dimensionality of neural features
if exist('dimRedFunc','var'),
    Y = dimRedFunc(Y);
end

% full cursor state at neural times
D = size(X,2);

% if initialization mode returns shuffled weights
if fitFlag==0 && KF.InitializationMode==2, % return shuffled weights
    idx = randperm(size(Y,2));
    Y = Y(:,idx);
end

% fit kalman matrices
C = (Y*X') / (X*X');
Q = (1/D) * ((Y-C*X) * (Y-C*X)');

% update kalman matrices
switch fitFlag,
    case {0,1},
        % fit sufficient stats
        KF.R = X*X';
        KF.S = Y*X';
        KF.T = Y*Y';
        KF.ESS = D;
        KF.C = C;
        KF.Q = Q;
        KF.Tinv = inv(KF.T);
        KF.Qinv = inv(Q);
    case 2, % smooth batch
        alpha = Params.CLDA.Alpha;
        KF.C = alpha*KF.C + (1-alpha)*C;
        KF.Q = alpha*KF.Q + (1-alpha)*Q;
        KF.Qinv = inv(KF.Q);
end

end % FitKF
