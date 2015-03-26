function [rawData, delayedPhases, freqs, kappa] = cavity_power_scan(na, powerScan, fixedAtten)
%cavity_power_scan Scan the power of the network analyser to find the bare
%to dressed shift 
%
% [rawData, delayedPhases, freqs] = cavity_power_scan(na, powerScan, fixedAtten)

rawData = zeros(length(powerScan), na.sweep_points);

for ct = 1:length(powerScan)
    na.power = powerScan(ct);
    na.reaverage();
    [freqs, curScan] = na.getTrace();
    rawData(ct,:) = curScan;
end

%Fit the first 100 pts to remove the linear phase
phases = unwrap(angle(rawData), [], 2);

delayedPhases = zeros(size(phases));

fitCoeffs = polyfit(freqs(1:100)/1e9, phases(1,1:100),1);
for ct = 1:size(phases,1)
    delayedPhases(ct,:) = phases(ct,:) - polyval(fitCoeffs, freqs/1e9);
end

%magic number cutoff to try and catch where unwrap goes back in between the
%bare and dressed states
c = 0.2;
delayedPhases(delayedPhases > c) = delayedPhases(delayedPhases > c)-2*pi;

figure()
imagesc(freqs/1e9, powerScan-fixedAtten, delayedPhases);
xlabel('Frequency (GHz)');
ylabel('Drive Power (dBm)');

%Fit the lower power to extract the cavity \Kappa
modelF = @(beta, f) 2*beta(1)*atan2(f - beta(2), beta(3)/2) + beta(4);
%Fit it MHz
[~, peakIndex] = min(diff(unwrap(delayedPhases(1,:))));
betas = nlinfit(freqs/1e6, unwrap(delayedPhases(1,:)), modelF, [-1, freqs(peakIndex)/1e6, 1, -3]);
kappa = betas(3);
text(freqs(floor(end/4))/1e9, powerScan(1)-fixedAtten+5, ['$\kappa/2\pi = ', num2str(kappa, '%1.2f'), '\, \mathrm{MHz}$'], 'Color', 'white', 'interpreter', 'latex', 'FontSize', 14)

end


