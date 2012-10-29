function [pulseData] = initializeWaveform(wfParams,samplingRate,waveformDuration)

[pulseData] = generatePulseData(wfParams.time,...
    wfParams.amp,samplingRate);

pulseLength = round(waveformDuration*samplingRate);

if length(pulseData) < pulseLength
    pulseData = [pulseData pulseData(end)*ones(1,pulseLength-length(pulseData))];
elseif length(pulseData) > pulseLength
    error('pulseData is longer than specified pulse length')
end

end