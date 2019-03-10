%% analyze blackrock datafiles
clear, clc, close all
addpath(genpath('/home/dsilver/Projects/BR_Ecog_Visualization/NPMK'));

%% load data
[filename,pathname] = uigetfile('*.*');
data = openNSx(fullfile(pathname,filename),'read','report','precision','double');

% get lfp and analog input
lfp = data.Data(1:128,:)';
anin = data.Data(129:end,:)';
Fs = data.MetaTags.SamplingFreq; % Hz
clear data

%% get trial structure from anin signal
time = (1:length(anin))/Fs - 1/Fs;

% get upward pulse times
th = 1e4;
anin = anin>th;
pulseidx = find(diff(anin)>.5)+1;
pulsetime = time(pulseidx);

%% look for groups of pulses
% consolidate (e.g., [5,5,5,5,5,4,4,4,4,4,4,4,4,1] --> [5,4,4,1])
i = 1;
ct = 1;
while i<length(pulseidx),
    % within group of pulses
    num_pulses = sum(pulsetime>=pulsetime(i) & pulsetime<=pulsetime(i)+1.5);
    pulse_groups(ct) = num_pulses; 
    group_idx(ct) = pulseidx(i); 
    group_times(ct) = pulsetime(i); 
    ct = ct + 1;
    i = i + num_pulses;
end

%% trial times
idx1 = find(pulse_groups==1);
idx2 = find(pulse_groups==2);
idx3 = find(pulse_groups==3);
events = [];
for i=1:length(idx1),
    events(i).iti_idx = group_idx(idx1(i));
    events(i).hold_idx = group_idx(idx2(i));
    events(i).mvmt_idx = group_idx(idx3(i));
    events(i).iti_time = group_times(idx1(i));
    events(i).hold_time = group_times(idx2(i));
    events(i).mvmt_time = group_times(idx3(i));
end

%% use order of trials/blocks to get idx of trial types
mvmt_strs = {'shake','r_arm','vocalize','nod'};
mvmt_idx = repmat([1,1,1,2,2,2,3,3,3,4,4,4],1,length(events)/12);

%% channel layout for plotting
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

%% make erp plots of high gamma for each movement
% filter for hg
hg = hg_pwr(lfp,Fs);

%% 
pwr = zscore(log10(hg));

%%
fig = figure('units','normalized','position',[.1,.1,.8,.8],'name','hg-erps-br');
ax = tight_subplot(R,C,[.01,.01],[.06,.01],[.03,.01]);
set(ax,'NextPlot','add');
for i=1:4,
    for ch=1:Nch,
        [r,c] = find(ch_layout == ch);
        idx = C*(r-1) + c;
        
        E = [events.iti_time];
        E = E(mvmt_idx==i);
        erps = createdatamatc(pwr(:,ch),E,Fs,[0,9]);
        
        plot(ax(idx),linspace(-4,5,9000),mean(erps,2))
    end
end
% make all axes the same
XX = [-4,5];
YY = [-2,2];
set(ax,'XTick',[],'YTick',[],'XLim',XX,'YLim',YY)

% add channel nums
for ch=1:Nch,
    [r,c] = find(ch_layout == ch);
    idx = C*(r-1) + c;
    text(ax(idx),XX(1),YY(1),sprintf('ch%03i',ch),...
        'VerticalAlignment','Bottom')
    vline(ax(idx),-2,'k');
    vline(ax(idx),0,'r');
end

% add lims and legend
[r,c] = find(ch_layout == limch);
idx = C*(r-1) + c;
set(ax(idx),'XTick',XX,'XTickLabel',XX,'YTick',YY,'YTickLabel',YY)

[r,c] = find(ch_layout == 120);
idx = C*(r-1) + c;
L = legend(ax(idx),mvmt_strs,'position',[.3,.01,.4,.035],'orientation','horizontal');

%% go through each channel, use chronux to calc spectrogram & plot
params.tapers = [3,5];
params.pad = 0;
params.Fs = Fs;
params.fpass = [0,150];
params.err = 0;
params.trialave = 1;

mu = median(lfp,2);
zlfpref = zscore(lfp-mu);

for i=1:4,
    fig = figure('units','normalized','position',[.1,.1,.8,.8],...
        'name',sprintf('spectrogram-br-%s',mvmt_strs{i}));
    ax = tight_subplot(R,C,[.01,.01],[.06,.01],[.03,.01]);
    set(ax,'NextPlot','add');
    for ch=1:Nch,
        [r,c] = find(ch_layout == ch);
        idx = C*(r-1) + c;
        
        E = [events.iti_time];
        E = E(mvmt_idx==i);
        erps = createdatamatc(zscore(zlfpref(:,ch)),E,Fs,[0,9]);
        
        [S,t,f]=mtspecgramc(erps,[.3,.1],params);
        imagesc(ax(idx),t-4,f,log10(S'))
        set(ax(idx),'Ydir','normal')
    end
end




