function PiRabiSequence(makePlot)

if ~exist('makePlot', 'var')
    makePlot = true;
end

pathAWG = 'U:\AWG\PiRabi\';
pathAPS = 'U:\APS\PiRabi\';
basename = 'PiRabi';

fixedPt = 6000;
cycleLength = 16000;

numsteps = 160; 
stepsize = 1;

% load config parameters from file
params = jsonlab.loadjson(getpref('qlab', 'pulseParamsBundleFile'));
qubitMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));

params.measDelay = -64;
q1Params = params.q1;
IQkey1 = qubitMap.q1.IQkey;
q2Params = params.q2;
IQkey2 = qubitMap.q2.IQkey;

% if using SSB, set the frequency here
SSBFreq = -150e6;
pg1 = PatternGen('dPiAmp', q1Params.piAmp, 'dPiOn2Amp', q1Params.pi2Amp, 'dSigma', q1Params.sigma, 'dPulseType', q1Params.pulseType, 'dDelta', q1Params.delta, 'correctionT', params.(IQkey1).T, 'dBuffer', q1Params.buffer, 'dPulseLength', q1Params.pulseLength, 'cycleLength', cycleLength, 'linkList', params.(IQkey1).linkListMode, 'dmodFrequency',SSBFreq);

SSBFreq = 0e6;
q2Params.buffer = 0;
pg2 = PatternGen('dPiAmp', q2Params.piAmp, 'dPiOn2Amp', q2Params.pi2Amp, 'dSigma', q2Params.sigma, 'dPulseType', q2Params.pulseType, 'dDelta', q2Params.delta, 'correctionT', params.(IQkey2).T, 'dBuffer', q2Params.buffer, 'dPulseLength', q2Params.pulseLength, 'cycleLength', cycleLength, 'linkList', params.(IQkey2).linkListMode, 'dmodFrequency',SSBFreq);

minWidth = 24; 
pulseLength = minWidth:stepsize:(numsteps-1)*stepsize+minWidth;

patseq1  = {pg1.pulse('Xp'), pg1.pulse('QId', 'width', pulseLength), pg1.pulse('Xp')};
patseq2 = {...
    pg2.pulse('Xp', 'pType', 'dragGaussOn', 'width', 3*q2Params.sigma), ...
    pg2.pulse('Xp', 'width', pulseLength-6*q2Params.sigma, 'pType', 'square'), ...
    pg2.pulse('Xp', 'pType', 'dragGaussOff', 'width', 3*q2Params.sigma), ...
    pg2.pulse('QId', 'width', q1Params.pulseLength + q1Params.buffer)...
    };

patseq1_2 = {pg1.pulse('QId')};

ch1 = zeros(2*numsteps, cycleLength);
ch2 = ch1;
ch3 = ch1;
ch4 = ch1;
ch1m1 = ch1; ch1m2 = ch1;
ch2m1 = ch1; ch2m2 = ch1;
ch3m1 = ch1; ch3m2 = ch1;
ch4m1 = ch1; ch4m2 = ch1;
%delayDiff = delays('34') - delays('56');

for n = 1:numsteps;
	[patx paty] = pg1.getPatternSeq(patseq1, n, params.(IQkey1).delay, fixedPt);
	ch1(n, :) = patx + params.(IQkey1).offset;
	ch2(n, :) = paty + params.(IQkey1).offset;
    ch3m1(n, :) = pg1.bufferPulse(patx, paty, 0, params.(IQkey1).bufferPadding, params.(IQkey1).bufferReset, params.(IQkey1).bufferDelay);
    
    [patx paty] = pg2.getPatternSeq(patseq2, n, params.(IQkey2).delay, fixedPt);
	ch3(n, :) = patx + params.(IQkey2).offset;
	ch4(n, :) = paty + params.(IQkey2).offset;
    ch4m1(n, :) = pg2.bufferPulse(patx, paty, 0, params.(IQkey2).bufferPadding, params.(IQkey2).bufferReset, params.(IQkey2).bufferDelay);
    
%     % construct buffer for APS pulses
%     patx = pg21.linkListToPattern(ch5seq, n)';
%     paty = pg21.linkListToPattern(ch6seq, n)';
%     % remove difference of delays
%     patx = circshift(patx, delayDiff);
%     paty = circshift(paty, delayDiff);
% %     ch2m1(n, :) = pg21.bufferPulse(patx, paty, 0, bufferPaddings('56'), bufferResets('56'), bufferDelays('56'));
%     ch3m1(n, :) = pg21.bufferPulse(patx, paty, 0, bufferPaddings('12'), bufferResets('12'), bufferDelays('12'));
    
    % second sequence without the pi's
%     ch1(n+numsteps, :) = ch1(n, :);
%     ch2(n+numsteps, :) = ch2(n, :);
%     
%     [patx paty] = pg2.getPatternSeq(patseq2_2, n, params.(IQkey2).delay, fixedPt);
% 	ch3(n+numsteps, :) = patx + params.(IQkey2).offset;
% 	ch4(n+numsteps, :) = paty + params.(IQkey2).offset;
%     ch4m1(n+numsteps, :) = pg2.bufferPulse(patx, paty, 0, params.(IQkey2).bufferPadding, params.(IQkey2).bufferReset, params.(IQkey2).bufferDelay);

    ch3(n+numsteps, :) = ch3(n, :);
    ch4(n+numsteps, :) = ch4(n, :);
    
    [patx paty] = pg1.getPatternSeq(patseq1_2, n, params.(IQkey1).delay, fixedPt);
	ch1(n+numsteps, :) = patx + params.(IQkey1).offset;
	ch2(n+numsteps, :) = paty + params.(IQkey1).offset;
    ch3m1(n+numsteps, :) = pg1.bufferPulse(patx, paty, 0, params.(IQkey1).bufferPadding, params.(IQkey1).bufferReset, params.(IQkey1).bufferDelay);


%     ch2m1(n+numsteps, :) = ch2m1(n, :);
    ch3m1(n+numsteps, :) = ch3m1(n, :);
end

% trigger at fixedPt-500
% measure from (fixedPt:fixedPt+measLength)
measLength = 9600;
measSeq = {pg1.pulse('M', 'width', measLength)};
for n = 1:2*numsteps;
	ch1m1(n,:) = pg1.makePattern([], fixedPt-500, ones(100,1), cycleLength);
	ch1m2(n,:) = int32(pg1.getPatternSeq(measSeq, n, params.measDelay, fixedPt+measLength));
    ch4m2(n,:) = pg1.makePattern([], 5, ones(100,1), cycleLength);
end

if makePlot
    myn = 25;
    figure
    plot(ch1(myn,:))
    hold on
    plot(ch2(myn,:), 'r')
    plot(ch3(myn,:), 'b--')
    plot(ch4(myn,:), 'r--')
    %ch5 = pg21.linkListToPattern(ch5seq, myn)';
    %ch6 = pg21.linkListToPattern(ch6seq, myn)';
    %plot(ch5, 'm')
    %plot(ch6, 'c')
    plot(5000*ch1m2(myn,:), 'g')
    plot(1000*ch2m1(myn,:), 'r')
    plot(5000*ch3m1(myn,:),'.')
    plot(5000*ch4m1(myn,:),'y.')
    grid on
    hold off
end

% add offsets to unused channels
%ch1 = ch1 + offsets('12');
%ch2 = ch2 + offsets('12');
%ch3 = ch3 + offsets('34');
%ch4 = ch4 + offsets('34');
ch2m2 = ch4m2;

% make APS file
%exportAPSConfig(tempdir, basename, ch5seq, ch6seq, ch5seq, ch6seq);
%disp('Moving APS file to destination');
%movefile([tempdir basename '.mat'], [pathAPS basename '.mat']);
% make TekAWG file
options = struct('m21_high', 2.0, 'm41_high', 2.0);
TekPattern.exportTekSequence(tempdir, basename, ch1, ch1m1, ch1m2, ch2, ch2m1, ch2m2, ch3, ch3m1, ch3m2, ch4, ch4m1, ch4m2, options);
disp('Moving AWG file to destination');
movefile([tempdir basename '.awg'], [pathAWG basename '.awg']);
end
