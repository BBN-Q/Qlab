% hack for measurinf slow light sample with PNA labbrick
% set up intsruments
%labbrick
ms = deviceDrivers.Labbrick64();
ms.connect('1702')
ms.output = 0;
% network analyzer
na = deviceDrivers.AgilentE8363C();
na.connect('128.33.89.127')
%yoko
yoko=deviceDrivers.YokoGS200();
yoko.connect('USB0::0xB21::0x39::91M731000::INSTR');
yoko.output = 1;

% set LB power
%ms.power = -4;
% loop for LB scans for fixed power and fixed NA window
%freqwc = linspace(7.50,7.68,91);
bias = linspace(.61,.64,30);
%freqwc = 7.5134
%freqwc = 7.5920;
%ms.frequency = freqwc;
pts = na.sweep_points;
s21=zeros(length(bias),pts);
for ct=1:length(bias)
    ct 
    yoko.value = bias(ct);
    na.reaverage
    [freqwp, s21(ct,:)] = na.getTrace();
end
 
 ms.disconnect
 delete(ms)
 na.disconnect
 delete(na)
 clear na ms
 
