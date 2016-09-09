% hack for measurinf slow light sample with PNA labbrick
% set up intsruments
%labbrick
ms = deviceDrivers.Labbrick64();
ms.connect('1702')
ms.output = 1;
% network analyzer
na = deviceDrivers.AgilentE8363C();
na.connect('128.33.89.127')

% set LB power
ms.power = -4;
% loop for LB scans for fixed power and fixed NA window
freqwc = linspace(6.95,7.05,101);
%freqwc = 7.5134
pts = na.sweep_points;
s21=zeros(length(freqwc),pts);
for ct=1:length(freqwc)
    ms.frequency = freqwc(ct);
    na.reaverage
    [freqwp, s21(ct,:)] = na.getTrace();
end
 
 ms.disconnect
 delete(ms)
 na.disconnect
 delete(na)
 clear na ms
 
