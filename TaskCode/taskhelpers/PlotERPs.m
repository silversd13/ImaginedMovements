function PlotERPs(datadir,vis)
% function PlotERPs(datadir,vis)
% loads all trials in datadir and plots each feature as a heatmap in a
% separate figure. saves a .png
% 
% datadir - directory of data (also saves fig there)
% vis - visibility of plot (if off save w/o plot in matlab) {'on','off'}
tic;
fprintf('\n\nMaking ERP plots...')
    
% grab data trial data
datafiles = dir(fullfile(datadir,'Data*.mat'));
Y = [];
for i=1:length(datafiles),
    % load data, grab cursor pos and time
    load(fullfile(datadir,datafiles(i).name)) %#ok<LOAD>
    Ytrial = cat(3,TrialData.NeuralFeatures{:});
    Y = cat(4,Y,Ytrial);
end
toc
% avg over trials
Y = squeeze(mean(Y,4));

% channel layout
ch_layout = [
    65	93	74	73	94	68	75	69	87	66	92	72	82	71	78	91
    80	67	81	84	95	88	70	76	96	89	90	77	86	83	79	85
    58	52	36	62	35	60	53	47	39	37	43	54	41	63	44	40
    57	61	42	64	38	45	50	59	51	56	46	49	55	34	48	33
    23	9	26	25	18	31	3	16	5	28	27	6	15	2	20	14
    8	29	12	13	4	19	24	7	21	30	32	17	11	22	1	10
    119 102 97  100 109 113 107 104 126 98  122 112 108 103 116 125
    118 121 127 124 123 128 111 99  101 115 120 114 106 105 117 110];
[R,C] = size(ch_layout);
Nch = size(Y,2);
limch = ch_layout(R,1);

% go through each feature and plot erps
% feature_list = 1:size(Y,1); % all features
feature_list = size(Y,1); % high gamma
for i=feature_list,
    fig = figure('units','normalized','position',[.1,.1,.8,.8],'visible',vis);
    ax = tight_subplot(R,C,[.01,.01],[.05,.01],[.03,.01]);
    
    for ch=1:Nch,
        [r,c] = find(ch_layout == ch);
        idx = C*(r-1) + c;
    
        % plot
        erp = squeeze(Y(i,ch,:));
        plot(ax(idx),erp,'linewidth',1)
        grid on
        
        if ch~=limch,
            set(ax(idx),'XTick',[],'YTick',[]);
        end
    end
    
    % clean up
    XX = [1,size(Y,3)];
    YY = cell2mat(get(ax,'YLim'));
    YY = [min(YY(:,1)),max(YY(:,2))];
    set(ax,'XLim',XX,'YLim',YY);
    
    % add channel nums
    for ch=1:Nch,
        [r,c] = find(ch_layout == ch);
        idx = C*(r-1) + c;
        text(ax(idx),XX(1),YY(1),sprintf('ch%03i',ch),...
            'VerticalAlignment','Bottom')
    end
    toc
    % save plot
    saveas(fig,fullfile(datadir,sprintf('ERPs_Feature%i',i)),'png')
    toc
end

fprintf('Done.\n\n')

end % PlotHeatMap
