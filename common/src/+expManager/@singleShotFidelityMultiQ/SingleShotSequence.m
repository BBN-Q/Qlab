function SingleShotSequence(qubit1, qubit2)

pathAWG = 'U:\AWG\SingleShot\';
basename = 'SingleShot';
fixedPt = 2000;
cycleLength = 12000;

% load config parameters from files
params = jsonlab.loadjson(getpref('qlab', 'pulseParamsBundleFile'));
q1Params = params.(qubit1);
q2Params = params.(qubit2);
qubitMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));
IQkey1 = qubitMap.(qubit1).IQkey;
IQkey2 = qubitMap.(qubit2).IQkey;

% if using SSB, set the frequency here
SSBFreq = 0e6;

pg1 = PatternGen('dPiAmp', q1Params.piAmp, 'dPiOn2Amp', q1Params.pi2Amp, 'dSigma', q1Params.sigma, 'dPulseType', q1Params.pulseType, 'dDelta', q1Params.delta, 'correctionT', params.(IQkey1).T, 'dBuffer', q1Params.buffer, 'dPulseLength', q1Params.pulseLength, 'cycleLength', cycleLength, 'linkList', params.(IQkey1).linkListMode, 'dmodFrequency',SSBFreq);
pg2 = PatternGen('dPiAmp', q2Params.piAmp, 'dPiOn2Amp', q2Params.pi2Amp, 'dSigma', q2Params.sigma, 'dPulseType', q2Params.pulseType, 'dDelta', q1Params.delta, 'correctionT', params.(IQkey2).T, 'dBuffer', q2Params.buffer, 'dPulseLength', q1Params.pulseLength, 'cycleLength', cycleLength, 'linkList', params.(IQkey2).linkListMode, 'dmodFrequency',SSBFreq);

patseq1 = {{pg1.pulse('QId')}, {pg1.pulse('QId')}, {pg1.pulse('Xp')}, {pg1.pulse('Xp')}};
patseq2 = {{pg2.pulse('QId')}, {pg2.pulse('Xp')}, {pg2.pulse('QId')}, {pg2.pulse('Xp')}};

% pre-allocate space
ch1 = zeros(4, cycleLength);
ch2 = ch1; ch3 = ch1; ch4 = ch1;
ch1m1 = ch1; ch1m2 = ch1; ch2m1 = ch1; ch2m2 = ch1;
ch3m1 = ch1; ch3m2 = ch1; ch4m1 = ch1; ch4m2 = ch1;

for n = 1:length(patseq1);
    [patx paty] = pg1.getPatternSeq(patseq1{n}, 1, params.(IQkey1).delay, fixedPt);
	ch3(n, :) = patx + params.(IQkey1).offset;
	ch4(n, :) = paty + params.(IQkey1).offset;
    ch4m1(n, :) = pg1.bufferPulse(patx, paty, 0, params.(IQkey1).bufferPadding, params.(IQkey1).bufferReset, params.(IQkey1).bufferDelay);
    
    [patx paty] = pg2.getPatternSeq(patseq2{n}, 1, params.(IQkey2).delay, fixedPt);
    ch1(n, :) = patx + params.(IQkey2).offset;
    ch2(n, :) = paty + params.(IQkey2).offset;
    ch3m1(n, :) = pg2.bufferPulse(patx, paty, 0, params.(IQkey2).bufferPadding, params.(IQkey2).bufferReset, params.(IQkey2).bufferDelay);

end

% trigger at beginning of measurement pulse
measLength = 8000;
params.measDelay = -64;
measSeq = {pg1.pulse('M', 'width', measLength)};
for n = 1:4;
	ch1m1(n,:) = pg1.makePattern([], fixedPt-500, ones(100,1), cycleLength);
	ch1m2(n,:) = int32(pg1.getPatternSeq(measSeq, n, params.measDelay, fixedPt+measLength));
    ch4m2(n,:) = pg1.makePattern([], 5, ones(100,1), cycleLength);
end

% make TekAWG file
options = struct('m21_high', 2.0, 'm41_high', 2.0);
TekPattern.exportTekSequence(tempdir, basename, ch1, ch1m1, ch1m2, ch2, ch2m1, ch2m2, ch3, ch3m1, ch3m2, ch4, ch4m1, ch4m2, options);
disp('Moving AWG file to destination');
movefile([tempdir basename '.awg'], [pathAWG basename '.awg']);

end