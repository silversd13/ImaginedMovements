function PlotHeatMapPerTrial(datadir,savedir,mvmt_str)
% function PlotERPs()
% loads all trials in datadir and plots each feature as a heatmap in a
% separate figure. saves a .png
% 
% datadir - directory of data (also saves fig there)
% vis - visibility of plot (if off save w/o plot in matlab) {'on','off'}
    
% grab data trial data
fprintf('Loading Data.\n')
if ~exist('datadir','var'), datadir = uigetdir(); end
datafiles = dir(fullfile(datadir,'Data*.mat'));
Y = [];
for feature=1:length(datafiles),
    % load data, grab cursor pos and time
    load(fullfile(datadir,datafiles(feature).name)) %#ok<LOAD>
    Ytrial = cat(3,TrialData.NeuralFeatures{:});
    Y = cat(4,Y,Ytrial);
end

% 
if ~exist('mvmt_str','var'), mvmt_str = input('select movement str: ', 's'); end

% saving directory
fprintf('Choose Save Directory.\n')
if ~exist('savedir','var'), savedir = uigetdir(); end

disp(datadir)
disp(savedir)
disp(mvmt_str)

fprintf('Making ERP plots.\n')
ch_layout = [
    96	84	76	95	70	82	77	87	74	93	66	89	86	94	91	79
    92	65	85	83	68	75	78	81	72	69	88	71	80	73	90	67
    62	37	56	48	43	44	60	33	49	64	58	59	63	61	51	34
    45	53	55	52	35	57	38	50	54	39	47	42	36	40	46	41
    19	2	10	21	30	23	17	28	18	1	8	15	32	27	9	3
    24	13	6	4	7	16	22	5	20	14	11	12	29	26	31	25
    124	126	128	119	110	113	111	122	117	125	112	98	104	116	103	106
    102	109	99	101	121	127	105	120	107	123	118	114	108	115	100	97];
[R,C] = size(ch_layout);
Nch = size(Y,2);
limch = ch_layout(R,1);

YYs = {
    [-4,4]
    [-2,2]
    [-2,2]
    [-2,2]
    [-2,2]
    [-2,2]
    [-2.5,0]
    };

% go through each feature and plot erps
feature_strs = {'delta-phase','delta-pwr','theta-pwr','alpha-pwr',...
    'beta-pwr','low-gamma-pwr','high-gamma-pwr'};
feature_list = length(feature_strs); % all features
for feature=feature_list,
    YY = YYs{feature};
    fig = figure('units','normalized','position',[.1,.1,.8,.8],'name',feature_strs{feature});
    ax = tight_subplot(3,5,[.025,.025],[.1,.05],[.03,.01]);
    
    for trial=1:15,
        heatmap = zeros(size(ch_layout));
        for ch=1:Nch,
            [r,c] = find(ch_layout == ch);

            % get erps [ samples x trial ]
            erps = squeeze(Y(feature,ch,:,trial));
            mu = mean(erps(1:20));
            sigma = std(erps(1:20));
            erps = (erps - mu) / sigma;

            % plot
            if feature==1,
                erp = circ_mean(erps,[],2);
            else,
                erp = mean(erps,2);
            end
            heatmap(r,c) = mean(erp(41:end));

        end

        imagesc(ax(trial),heatmap);
        title(ax(trial),sprintf('trial%02i',trial))
    end
    
    % add lims
    YY = cell2mat(cat(1,get(ax,'CLim')));
    YY = [min(YY(:)),max(YY(:))];
    set(ax,'CLim',YY,'XTick',[],'YTick',[]);
    c = colorbar(ax(end),'southoutside','position',[.1,.035,.8,.05]);
        
    % save plot
    drawnow
    saveas(fig,fullfile(savedir,sprintf('HeatMapTrials_zscored_%s_%s',mvmt_str,feature_strs{feature})),'png')
    close(fig);
end

fprintf('Done.\n\n')

end % PlotHeatMap
