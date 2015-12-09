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
%ms.power = -5;
% loop for LB scans for fixed power and fixed NA window
%freqwc = linspace(7.475,7.575,100);
%freqwc = 7.5134;
%freqwc = 7.5818;

wcpow = linspace(-30,10,81);
pts = na.sweep_points;
%freqwc = linspace(6.385,6.4,5);
freqwc = 7.0005;
%s21=zeros(length(freqwc),length(wcpow),pts);
s21=zeros(length(wcpow),pts);
figure
%for ct2=1:length(freqwc)
ms.frequency = freqwc;
for ct=1:length(wcpow)
    ms.power = wcpow(ct) ;
    ms.power
    ms.frequency
    na.reaverage
    [freqwp, s21(ct,:)] = na.getTrace();
end

%subplot(1,5,ct2)
figure
imagesc(freqwp/1e9,freqwc/1e9,20*log10(abs(squeeze(s21(ct2,:,:)))))
%ft=num2str(freqwc(ct2));
%title(ft)
%end 
ms.power = -20
ms.output = 0;
 
 
 ms.disconnect
 delete(ms)
 na.disconnect
 delete(na)
 clear na ms
 
