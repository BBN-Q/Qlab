function [rawData, delayedPhases, freqs] = cavity_power_scan(na, powerScan, fixedAtten)
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

fitCoeffs = polyfit(freqs(1:100), phases(1,1:100),1);
for ct = 1:size(phases,1)
    delayedPhases(ct,:) = phases(ct,:) - polyval(fitCoeffs, freqs);
end

%magic number cutoff to try and catch where unwrap goes back in between the
%bare and dressed states
delayedPhases(delayedPhases > 0.05) = delayedPhases(delayedPhases > 0.05)-2*pi;

figure()
imagesc(freqs/1e9, powerScan-fixedAtten, delayedPhases);
xlabel('Frequency (GHz)');
ylabel('Drive Power (dBm)');


