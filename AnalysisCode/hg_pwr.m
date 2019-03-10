function y = hg_pwr(x,Fs)

FilterBank = [];
FilterBank(end+1).fpass = [70,77];   % high gamma1
FilterBank(end+1).fpass = [77,85];   % high gamma2
FilterBank(end+1).fpass = [85,93];   % high gamma3
FilterBank(end+1).fpass = [93,102];  % high gamma4
FilterBank(end+1).fpass = [102,113]; % high gamma5
FilterBank(end+1).fpass = [113,124]; % high gamma6
FilterBank(end+1).fpass = [124,136]; % high gamma7
FilterBank(end+1).fpass = [136,150]; % high gamma8

% compute filter coefficients
for i=1:length(FilterBank),
    [b,a] = butter(3,FilterBank(i).fpass/(Fs/2));
    FilterBank(i).b = b;
    FilterBank(i).a = a;
end

y = zeros(size(x,1),size(x,2));
for i=1:length(FilterBank),
    % filter
    tmp = filtfilt(...
        FilterBank(i).b,....
        FilterBank(i).a,...
        x);
    % hilbert envelope
    y = y + abs(hilbert(tmp));
end
y = y / length(FilterBank);

end