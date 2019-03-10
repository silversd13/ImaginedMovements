function PlotERPsCompBlocks(datadirs,savedir,mvmt_str)
% function PlotERPsCompBlocks()
% loads all trials in datadir and plots each feature as a heatmap in a
% separate figure. saves a .png
%
% datadir - directory of data (also saves fig there)

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
Nch = 128;
limch = ch_layout(R,1);
YYs = {
    [-4,4]
    [-2,2]
    [-2,2]
    [-2,2]
    [-2,2]
    [-2,2]
    [-2,2]
    };
feature_strs = {'delta-phase','delta-pwr','theta-pwr','alpha-pwr',...
    'beta-pwr','low-gamma-pwr','high-gamma-pwr'};
feature_list = 1:length(feature_strs); % all features

% go through each feature and plot erps
for feature=feature_list,
    YY = YYs{feature};
    fig = figure('units','normalized','position',[.1,.1,.8,.8],'name',feature_strs{feature});
    ax = tight_subplot(R,C,[.01,.01],[.05,.01],[.03,.01]);
    set(ax,'NextPlot','add');
    
    for i=1:2,
        datadir = datadirs{i};
        
        % grab data trial data
        fprintf('Loading Data.\n')
        datafiles = dir(fullfile(datadir,'Data*.mat'));
        Y = [];
        for j=1:length(datafiles),
            % load data, grab cursor pos and time
            load(fullfile(datadir,datafiles(j).name)) %#ok<LOAD>
            Ytrial = cat(3,TrialData.NeuralFeatures{:});
            Y = cat(4,Y,Ytrial);
        end
        
        disp(datadir)
        disp(savedir)
        disp(mvmt_str)
        
        fprintf('Making ERP plots.\n')
        for ch=1:Nch,
            [r,c] = find(ch_layout == ch);
            idx = C*(r-1) + c;
            
            % get erps [ samples x trial ]
            erps = squeeze(Y(feature,ch,:,:));
            t_erp = (((1:90)-41)*.1)';
            
            % split into baseline and mvmt periods
            erps0 = erps(1:20,:); % inter trial interval
            %         erps1 = erps(21:40,:); % hold interval
            %         erps2 = erps(41:end,:); % mvmt
            mu = mean(erps0);
            sigma = std(erps0);
            zerps = (erps - repmat(mu,90,1)) ./ repmat(sigma,90,1);
            
            % plot
            if feature==1,
                erp = circ_mean(erps,[],2);
                zerp = circ_mean(erps,[],2);
            else,
                erp = mean(erps,2);
                zerp = mean(zerps,2);
            end
            plot(ax(idx),t_erp,zerp,'linewidth',1)
            
            % clean
            set(ax(idx),'XTick',[],'YTick',[]);
        end
    end % compare dirs
    
    % clean up
    XX = [minmax(t_erp')];
    if ~exist('YY','var'),
        YY = cell2mat(get(ax,'YLim'));
        YY = [min(YY(:,1)),max(YY(:,2))];
    end
    set(ax,'XLim',XX,'YLim',YY);
    
    % add channel nums
    for ch=1:Nch,
        [r,c] = find(ch_layout == ch);
        idx = C*(r-1) + c;
        text(ax(idx),XX(1),YY(1),sprintf('ch%03i',ch),...
            'VerticalAlignment','Bottom')
        vline(ax(idx),-2,'k');
        vline(ax(idx),0,'r');
    end
    
    % add lims
    [r,c] = find(ch_layout == limch);
    idx = C*(r-1) + c;
    set(ax(idx),...
        'XTick',XX,'XTickLabels',XX,...
        'YTick',YY,'YTickLabels',YY);
    
    % save plot
    drawnow
    saveas(fig,fullfile(savedir,sprintf('ERPs_%s_%s',mvmt_str,feature_strs{feature})),'png')
    close(fig)
end


fprintf('Done.\n\n')

end % PlotHeatMap
