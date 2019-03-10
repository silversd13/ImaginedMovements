
%% Classify Movements
savedir = '/home/dsilver/Desktop/Bravo1ImaginedMvmtsFigs/114525/Matlab';

datadirs = {
    '/media/dsilver/FLASH/Bravo1/20190308/114525/Move Your Right Arm'
    '/media/dsilver/FLASH/Bravo1/20190308/114525/Nod Your Head (Down then Up)'
    '/media/dsilver/FLASH/Bravo1/20190308/114525/Say _OK_'
    '/media/dsilver/FLASH/Bravo1/20190308/114525/Shake Your Head (Right then Left)'};
mvmt_str = {
    'r_arm'
    'nod_head'
    'vocalize'
    'shake_head'};

feature_strs = {'delta-phase','delta-pwr','theta-pwr','alpha-pwr',...
    'beta-pwr','low-gamma-pwr','high-gamma-pwr','all-features'};

idx = randperm(240);
trainidx = idx(1:200);
testidx = idx(201:end);

fig = figure('units','normalized','position',[0,.1,.95,.8]);
row = 0;
feature_list = {1,2,3,4,5,6,7,1:7};
for fidx=1:7,
    feature = feature_list{fidx};
    if mod(feature,4)==1, row = row + 1; end
    feature_str = feature_strs{feature};
    %%
    X = [];
    Y = [];
    for j=1:4,
        datadir = datadirs{j};
        datafiles = dir(fullfile(datadir,'Data*.mat'));
        hg = [];
        for i=1:length(datafiles),
            % load data, grab cursor pos and time
            load(fullfile(datadir,datafiles(i).name))
            Ytrial = cat(3,TrialData.NeuralFeatures{:});
            hg = cat(4,hg,Ytrial);
        end
        
        % just high gamma, avg over time
        if fidx<8,
            hg = squeeze(hg(feature,:,:,:));
            hg = squeeze(mean(hg(:,41:end,:),2));
        else
            hg = squeeze(mean(hg(:,:,41:end,:),3));
            hg = reshape(hg,7*128,60);
        end
        X = cat(1,X,hg');
        Y = cat(1,Y,j*ones(60,1));
    end
    
    %%
    Mdl = fitcdiscr(X(trainidx,:),Y(trainidx),...
        'OptimizeHyperparameters','auto',...
        'HyperparameterOptimizationOptions',...
        struct('AcquisitionFunctionName','expected-improvement-plus'));
    Yhat = predict(Mdl,X(trainidx,:));
    CMat = confusionmat(Y(trainidx),Yhat);
    figure(fig);
    subplot(4,4,feature+4*(row-1))
    heatmap(mvmt_str,mvmt_str,CMat)
    title(sprintf('Training Performance: %s',feature_str))
    
    Yhat = predict(Mdl,X(testidx,:));
    CMat = confusionmat(Y(testidx),Yhat);
    figure(fig)
    subplot(4,4,feature+4*(row))
    heatmap(mvmt_str,mvmt_str,CMat)
    title(sprintf('Testing Performance: %s',feature_str))
end


%% Full feature model
X = [];
Y = [];
for j=1:4,
    datadir = datadirs{j};
    datafiles = dir(fullfile(datadir,'Data*.mat'));
    hg = [];
    for i=1:length(datafiles),
        % load data, grab cursor pos and time
        load(fullfile(datadir,datafiles(i).name))
        Ytrial = cat(3,TrialData.NeuralFeatures{:});
        hg = cat(4,hg,Ytrial);
    end
    
    % just high gamma, avg over time
    hg = squeeze(mean(hg(:,:,41:end,:),3));
    hg = reshape(hg,7*128,60);
    X = cat(1,X,hg');
    Y = cat(1,Y,j*ones(60,1));
end

Mdl = fitcdiscr(X(trainidx,:),Y(trainidx),...
    'OptimizeHyperparameters','auto',...
    'HyperparameterOptimizationOptions',...
    struct('AcquisitionFunctionName','expected-improvement-plus'));

feature_str = feature_strs{8};
Yhat = predict(Mdl,X(trainidx,:));
CMat = confusionmat(Y(trainidx),Yhat);
figure();
subplot(2,1,1)
heatmap(mvmt_str,mvmt_str,CMat)
title(sprintf('Training Performance: %s',feature_str))

Yhat = predict(Mdl,X(testidx,:));
CMat = confusionmat(Y(testidx),Yhat);
subplot(2,1,2)
heatmap(mvmt_str,mvmt_str,CMat)
title(sprintf('Testing Performance: %s',feature_str))

%% Full feature model after PCA
X = [];
Y = [];
for j=1:4,
    datadir = datadirs{j};
    datafiles = dir(fullfile(datadir,'Data*.mat'));
    hg = [];
    for i=1:length(datafiles),
        % load data, grab cursor pos and time
        load(fullfile(datadir,datafiles(i).name))
        Ytrial = cat(3,TrialData.NeuralFeatures{:});
        hg = cat(4,hg,Ytrial);
    end
    
    % just high gamma, avg over time
    hg = squeeze(mean(hg(:,:,41:end,:),3));
    hg = reshape(hg,7*128,60);
    X = cat(1,X,hg');
    Y = cat(1,Y,j*ones(60,1));
end

[C,~,~,~,per_var_exp,mu] = pca(X);
figure;
hold on
title('Percent Var Exp')
plot(cumsum(per_var_exp))
plot([0;size(X,1)],[80 90 95;80 90 95],'k--')
NumDims = 10;
% C = C(:,1:NumDims);
% F = @(X) ((X - mu)*C);
[estParams, ~] = myfastfa(X', NumDims);
F = @(X) (estParams.L\(X'-estParams.d))';
Xnew = F(X);

%%
Mdl = fitcdiscr(Xnew(trainidx,:),Y(trainidx),...
    'OptimizeHyperparameters','auto',...
    'HyperparameterOptimizationOptions',...
    struct('AcquisitionFunctionName','expected-improvement-plus'));

feature_str = feature_strs{8};
Yhat = predict(Mdl,Xnew(trainidx,:));
CMat = confusionmat(Y(trainidx),Yhat);
figure();
subplot(2,1,1)
heatmap(mvmt_str,mvmt_str,CMat)
title(sprintf('Training Performance: %s',feature_str))

Yhat = predict(Mdl,Xnew(testidx,:));
CMat = confusionmat(Y(testidx),Yhat);
subplot(2,1,2)
heatmap(mvmt_str,mvmt_str,CMat)
title(sprintf('Testing Performance: %s',feature_str))

