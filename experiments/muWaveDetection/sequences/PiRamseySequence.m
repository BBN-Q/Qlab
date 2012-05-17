function PiRamseySequence(makePlot)

if ~exist('makePlot', 'var')
    makePlot = true;
end

pathAWG = 'U:\AWG\Ramsey\';
basename = 'PiRamsey';

fixedPt = 20000;
cycleLength = 30000;

% load config parameters from file
params = jsonlab.loadjson(getpref('qlab', 'pulseParamsBundleFile'));
qubitMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));
params.measDelay = -64;

q1Params = params.q1;
IQkey1 = qubitMap.q1.IQkey;
q2Params = params.q1;
IQkey2 = qubitMap.q2.IQkey;

% if using SSB, set the frequency here
SSBFreq = 0e6;
pg1 = PatternGen('dPiAmp', q1Params.piAmp, 'dPiOn2Amp', q1Params.pi2Amp, 'dSigma', q1Params.sigma, 'dPulseType', q1Params.pulseType, 'dDelta', q1Params.delta, 'correctionT', params.(IQkey1).T, 'dBuffer', q1Params.buffer, 'dPulseLength', q1Params.pulseLength, 'cycleLength', cycleLength, 'linkList', params.(IQkey1).linkListMode, 'dmodFrequency',SSBFreq);

pg2 = PatternGen('dPiAmp', q2Params.piAmp, 'dPiOn2Amp', q2Params.pi2Amp, 'dSigma', q2Params.sigma, 'dPulseType', q2Params.pulseType, 'dDelta', q2Params.delta, 'correctionT', params.(IQkey2).T, 'dBuffer', q2Params.buffer, 'dPulseLength', q2Params.pulseLength, 'cycleLength', cycleLength, 'linkList', params.(IQkey2).linkListMode, 'dmodFrequency',SSBFreq);

numsteps = 100;
stepsize = 120;
delaypts = 0:stepsize:(numsteps-1)*stepsize;
anglepts = 0:pi/8:(numsteps-1)*pi/8;
% anglepts = 0;

% patseq1 = {pg1.pulse('QId','width',q2Params.pulseLength),...
%     pg1.pulse('X90p'), ...
%     pg1.pulse('QId', 'width', delaypts), ...
%     pg1.pulse('X90p')
%     };
% patseq2 = {pg2.pulse('Xp'),...
%     pg2.pulse('QId', 'width', q1Params.pulseLength),...
%     pg2.pulse('QId', 'width', delaypts),...
%     pg2.pulse('QId', 'width', q1Params.pulseLength)
%     };

patseq1 = {pg1.pulse('Xp'),...
    pg1.pulse('QId', 'width', q2Params.pulseLength),...
    pg1.pulse('QId', 'width', delaypts),...
    pg1.pulse('QId', 'width', q2Params.pulseLength)
    };

patseq2 = {pg2.pulse('QId','width',q1Params.pulseLength),...
    pg2.pulse('X90p'), ...
    pg2.pulse('QId', 'width', delaypts), ...
    pg2.pulse('U90p', 'angle', anglepts)
    };

calseq = {{pg1.pulse('Xp')}, {pg1.pulse('Xp')}, {pg1.pulse('Xp')}, {pg1.pulse('Xp')}};
calseq2 = {{pg2.pulse('QId')}, {pg2.pulse('QId')}, {pg2.pulse('Xp')}, {pg2.pulse('Xp')}};

% pre-allocate space
ch1 = zeros(numsteps+length(calseq), cycleLength);
ch2 = ch1; ch3 = ch1; ch4 = ch1;
ch1m1 = ch1; ch1m2 = ch1; ch2m1 = ch1; ch2m2 = ch1;
ch3m1 = ch1; ch3m2 = ch1; ch4m1 = ch1; ch4m2 = ch1;

for n = 1:numsteps;
    
    [patx paty] = pg1.getPatternSeq(patseq1, n, params.(IQkey1).delay, fixedPt);
	ch3(n, :) = patx + params.(IQkey1).offset;
	ch4(n, :) = paty + params.(IQkey1).offset;
    ch4m1(n, :) = pg1.bufferPulse(patx, paty, 0, params.(IQkey1).bufferPadding, params.(IQkey1).bufferReset, params.(IQkey1).bufferDelay);
    
    [patx paty] = pg2.getPatternSeq(patseq2, n, params.(IQkey2).delay, fixedPt);
    ch1(n, :) = patx + params.(IQkey2).offset;
    ch2(n, :) = paty + params.(IQkey2).offset;
    ch3m1(n, :) = pg2.bufferPulse(patx, paty, 0, params.(IQkey2).bufferPadding, params.(IQkey2).bufferReset, params.(IQkey2).bufferDelay);

end

for n = 1:length(calseq);
    [patx paty] = pg1.getPatternSeq(calseq{n}, 1, params.(IQkey1).delay, fixedPt);
	ch3(n+numsteps, :) = patx + params.(IQkey1).offset;
	ch4(n+numsteps, :) = paty + params.(IQkey1).offset;
    ch4m1(n+numsteps, :) = pg1.bufferPulse(patx, paty, 0, params.(IQkey1).bufferPadding, params.(IQkey1).bufferReset, params.(IQkey1).bufferDelay);
    
    [patx paty] = pg2.getPatternSeq(calseq2{n}, 1, params.(IQkey2).delay, fixedPt);
    ch1(n+numsteps, :) = patx + params.(IQkey2).offset;
    ch2(n+numsteps, :) = paty + params.(IQkey2).offset;
    ch3m1(n+numsteps, :) = pg2.bufferPulse(patx, paty, 0, params.(IQkey2).bufferPadding, params.(IQkey2).bufferReset, params.(IQkey2).bufferDelay);

end

numsteps = numsteps + length(calseq);

% trigger at beginning of measurement pulse
% measure from (6000:9000)
measLength = 9600;
measSeq = {pg1.pulse('M', 'width', measLength)};
for n = 1:numsteps;
	ch1m1(n,:) = pg1.makePattern([], fixedPt-500, ones(100,1), cycleLength);
	ch1m2(n,:) = int32(pg1.getPatternSeq(measSeq, n, params.measDelay, fixedPt+measLength));
    ch4m2(n,:) = pg1.makePattern([], 5, ones(100,1), cycleLength);
end

if makePlot
    myn = 20;
    figure
    plot(ch1(myn,:));
    hold on
    plot(ch2(myn,:), 'r')
    plot(ch3(myn,:),'b--');
    plot(ch4(myn,:),'r--');
    plot(5000*ch3m1(myn,:), 'k')
    plot(5000*ch1m2(myn,:), 'g')
    %plot(1000*ch3m1(myn,:))
    plot(5000*ch1m1(myn,:),'.')
    grid on
    hold off
end

% make TekAWG file
options = struct('m21_high', 2.0, 'm41_high', 2.0);
TekPattern.exportTekSequence(tempdir, basename, ch1, ch1m1, ch1m2, ch2, ch2m1, ch2m2, ch3, ch3m1, ch3m2, ch4, ch4m1, ch4m2, options);
disp('Moving AWG file to destination');
movefile([tempdir basename '.awg'], [pathAWG basename '.awg']);

end