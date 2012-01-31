function PiRabiCR32Sequence(makePlot)

if ~exist('makePlot', 'var')
    makePlot = true;
end

pathAWG = 'U:\AWG\PiRabi\';
pathAPS = 'U:\APS\PiRabi\';
basename = 'PiRabi';

fixedPt = 6000;
cycleLength = 10000;

numsteps = 80; 
stepsize = 4; % 4

% load config parameters from file
params = jsonlab.loadjson(getpref('qlab', 'pulseParamsBundleFile'));
measDelay = -64;

q3Params = params.q3; % choose target qubit here
IQkeyQ3 = 'BBNAPS12';
pgQ3 = PatternGen('dPiAmp', q3Params.piAmp, 'dPiOn2Amp', q3Params.pi2Amp, 'dSigma', q3Params.sigma, 'dPulseType', q3Params.pulseType, 'dDelta', q3Params.delta, 'correctionT', params.(IQkeyQ3).T, 'dBuffer', q3Params.buffer, 'dPulseLength', q3Params.pulseLength, 'cycleLength', cycleLength, 'passThru', params.(IQkeyQ3).passThru);


CR32Params = params.CR32;
IQkeyCR = 'TekAWG34';
pgCR32 = PatternGen('dPiAmp', CR32Params.piAmp, 'dPiOn2Amp', CR32Params.pi2Amp, 'dSigma', CR32Params.sigma, 'dPulseType', CR32Params.pulseType, 'dDelta', CR32Params.delta, 'correctionT', params.(IQkeyCR).T, 'dBuffer', CR32Params.buffer, 'dPulseLength', CR32Params.pulseLength, 'cycleLength', cycleLength, 'passThru', params.(IQkeyCR).passThru);

minWidth = 1680; 
pulseLength = minWidth:stepsize:(numsteps-1)*stepsize+minWidth;

patseqQ3 = {pgQ3.pulse('Xp'), pgQ3.pulse('QId', 'width', pulseLength), pgQ3.pulse('Xp')};
patseqCR = {...
    pgCR32.pulse('Xp', 'pType', 'dragGaussOn', 'width', 3*CR32Params.sigma), ...
    pgCR32.pulse('Xp', 'width', pulseLength-6*CR32Params.sigma, 'pType', 'square'), ...
    pgCR32.pulse('Xp', 'pType', 'dragGaussOff', 'width', 3*CR32Params.sigma), ...
    pgCR32.pulse('QId', 'width', q3Params.pulseLength+q3Params.buffer)...
    };

ch1 = zeros(2*numsteps, cycleLength);
ch2 = ch1;
ch3 = ch1;
ch4 = ch1;
ch1m1 = ch1; ch1m2 = ch1;
ch2m1 = ch1; ch2m2 = ch1;
ch3m1 = ch1; ch3m2 = ch1;
ch4m1 = ch1; ch4m2 = ch1;
delayDiff = params.(IQkeyCR).delay - params.(IQkeyQ3).delay;

[ch5seq, ch6seq, ~, ~] = pgQ3.build(patseqQ3, numsteps, params.(IQkeyQ3).delay, fixedPt);

for n = 1:numsteps;
    
    [patx paty] = pgCR32.getPatternSeq(patseqCR, n, params.(IQkeyCR).delay, fixedPt);
	ch3(n, :) = patx + params.(IQkeyCR).offset;
	ch4(n, :) = paty + params.(IQkeyCR).offset;
    ch4m1(n, :) = pgCR32.bufferPulse(patx, paty, 0, params.(IQkeyCR).bufferPadding, params.(IQkeyCR).bufferReset, params.(IQkeyCR).bufferDelay);
    
    % construct buffer for APS pulses
    patx = pgQ3.linkListToPattern(ch5seq, n)';
    paty = pgQ3.linkListToPattern(ch6seq, n)';
    % remove difference of delays
    patx = circshift(patx, delayDiff);
    paty = circshift(paty, delayDiff);
    ch3m1(n, :) = pgQ3.bufferPulse(patx, paty, 0, params.(IQkeyQ3).bufferPadding, params.(IQkeyQ3).bufferReset, params.(IQkeyQ3).bufferDelay);
    
    % second sequence without the pi's
    [patx paty] = pgCR32.getPatternSeq(patseqCR, n, params.(IQkeyCR).delay, fixedPt);
	ch3(n+numsteps, :) = patx + params.(IQkeyCR).offset;
	ch4(n+numsteps, :) = paty + params.(IQkeyCR).offset;
    ch4m1(n+numsteps, :) = pgCR32.bufferPulse(patx, paty, 0, params.(IQkeyCR).bufferPadding, params.(IQkeyCR).bufferReset, params.(IQkeyCR).bufferDelay);

end

% trigger at fixedPt-500
% measure from (fixedPt:fixedPt+measLength)
measLength = 3000;
measSeq = {pgCR32.pulse('M', 'width', measLength)};
for n = 1:2*numsteps;
	ch1m1(n,:) = pgCR32.makePattern([], fixedPt-500, ones(100,1), cycleLength);
	ch1m2(n,:) = int32(pgCR32.getPatternSeq(measSeq, n, measDelay, fixedPt+measLength));
    ch4m2(n,:) = pgCR32.makePattern([], 5, ones(100,1), cycleLength);
end

if makePlot
    myn = 25;
    figure
    plot(ch1(myn,:))
    hold on
    plot(ch2(myn,:), 'r')
    plot(ch3(myn,:), 'b--')
    plot(ch4(myn,:), 'r--')
    ch5 = pgQ3.linkListToPattern(ch5seq, myn)';
    ch6 = pgQ3.linkListToPattern(ch6seq, myn)';
    plot(ch5, 'm')
    plot(ch6, 'c')
    plot(5000*ch1m2(myn,:), 'g')
    plot(1000*ch2m1(myn,:), 'r')
    %plot(5000*ch1m1(myn,:),'.')
    grid on
    hold off
end

% add offsets to unused channels
ch1 = ch1 + params.TekAWG12.offset;
ch2 = ch2 + params.TekAWG12.offset;
ch2m2 = ch4m2;

% make APS file
exportAPSConfig(tempdir, basename, ch5seq, ch6seq, ch5seq, ch6seq);
disp('Moving APS file to destination');
movefile([tempdir basename '.mat'], [pathAPS basename '.mat']);
% make TekAWG file
options = struct('m21_high', 2.0, 'm41_high', 2.0);
TekPattern.exportTekSequence(tempdir, basename, ch1, ch1m1, ch1m2, ch2, ch2m1, ch2m2, ch3, ch3m1, ch3m2, ch4, ch4m1, ch4m2, options);
disp('Moving AWG file to destination');
movefile([tempdir basename '.awg'], [pathAWG basename '.awg']);
end
