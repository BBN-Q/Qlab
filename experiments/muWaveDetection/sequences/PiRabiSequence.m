function PiRabiSequence(makePlot)

if ~exist('makePlot', 'var')
    makePlot = true;
end
script = java.io.File(mfilename('fullpath'));
path = char(script.getParentFile().getParentFile().getParentFile().getParent());
addpath([path '/common/src'],'-END');
addpath([path '/common/src/util/'],'-END');

temppath = [char(script.getParent()) '\'];
pathAWG = 'U:\AWG\PiRabi\';
pathAPS = 'U:\APS\PiRabi\';
basename = 'PiRabi';

fixedPt = 6000;
cycleLength = 10000;

numsteps = 80; 
stepsize = 12; % 4

% load config parameters from file
load(getpref('qlab','pulseParamsBundleFile'), 'Ts', 'delays', 'measDelay', 'bufferDelays', 'bufferResets', 'bufferPaddings', 'offsets', 'piAmps', 'pi2Amps', 'sigmas', 'pulseTypes', 'deltas', 'buffers', 'pulseLengths');
buffers('q1q2') = 0;

pg1 = PatternGen('dPiAmp', piAmps('q1'), 'dPiOn2Amp', pi2Amps('q1'), 'dSigma', sigmas('q1'), 'dPulseType', pulseTypes('q1'), 'dDelta', deltas('q1'), 'correctionT', Ts('12'), 'dBuffer', buffers('q1'), 'dPulseLength', pulseLengths('q1'), 'cycleLength', cycleLength);
pg2 = PatternGen('dPiAmp', piAmps('q2'), 'dPiOn2Amp', pi2Amps('q2'), 'dSigma', sigmas('q2'), 'dPulseType', pulseTypes('q2'), 'dDelta', deltas('q2'), 'correctionT', Ts('34'), 'dBuffer', buffers('q2'), 'dPulseLength', pulseLengths('q2'), 'cycleLength', cycleLength);
pg21 = PatternGen('dPiAmp', piAmps('q1q2'), 'dPiOn2Amp', pi2Amps('q1q2'), 'dSigma', sigmas('q1q2'), 'dPulseType', pulseTypes('q1q2'), 'dDelta', deltas('q1q2'), 'correctionT', Ts('56'), 'dBuffer', buffers('q1q2'), 'dPulseLength', pulseLengths('q1q2'), 'cycleLength', cycleLength, 'passThru', true);

minWidth = 480; 
pulseLength = minWidth:stepsize:(numsteps-1)*stepsize+minWidth;

patseq1  = {pg2.pulse('Xp'), pg2.pulse('QId', 'width', pulseLength), pg2.pulse('Xp')};
patseq2  = {pg2.pulse('QId')};
patseq21 = {...
    pg21.pulse('Xp', 'pType', 'dragGaussOn', 'width', 3*sigmas('q1q2')), ...
    pg21.pulse('Xp', 'width', pulseLength-6*sigmas('q1q2'), 'pType', 'square'), ...
    pg21.pulse('Xp', 'pType', 'dragGaussOff', 'width', 3*sigmas('q1q2')), ...
    pg21.pulse('QId', 'width', pulseLengths('q2')+buffers('q2'))...
    };

ch1 = zeros(2*numsteps, cycleLength);
ch2 = ch1;
ch3 = ch1;
ch4 = ch1;
ch1m1 = ch1; ch1m2 = ch1;
ch2m1 = ch1; ch2m2 = ch1;
ch3m1 = ch1; ch3m2 = ch1;
ch4m1 = ch1; ch4m2 = ch1;
delayDiff = delays('34') - delays('56');

[ch5seq, ch6seq, ~, ~] = pg21.build(patseq21, numsteps, delays('56'), fixedPt);

for n = 1:numsteps;
	%[patx paty] = pg1.getPatternSeq(patseq1, n, delays('q1'), fixedPt);
	%ch1(n, :) = patx + offsets('12');
	%ch2(n, :) = paty + offsets('12');
    %ch3m1(n, :) = pg1.bufferPulse(patx, paty, 0, bufferPaddings('12'), bufferResets('12'), bufferDelays('12'));
    
    [patx paty] = pg2.getPatternSeq(patseq1, n, delays('34'), fixedPt);
	ch3(n, :) = patx + offsets('34');
	ch4(n, :) = paty + offsets('34');
    ch4m1(n, :) = pg2.bufferPulse(patx, paty, 0, bufferPaddings('34'), bufferResets('34'), bufferDelays('34'));
    
    % construct buffer for APS pulses
    patx = pg21.linkListToPattern(ch5seq, n)';
    paty = pg21.linkListToPattern(ch6seq, n)';
    % remove difference of delays
    patx = circshift(patx, delayDiff);
    paty = circshift(paty, delayDiff);
%     ch2m1(n, :) = pg21.bufferPulse(patx, paty, 0, bufferPaddings('56'), bufferResets('56'), bufferDelays('56'));
    ch3m1(n, :) = pg21.bufferPulse(patx, paty, 0, bufferPaddings('12'), bufferResets('12'), bufferDelays('12'));
    
    % second sequence without the pi's
    [patx paty] = pg2.getPatternSeq(patseq2, n, delays('34'), fixedPt);
	ch3(n+numsteps, :) = patx + offsets('34');
	ch4(n+numsteps, :) = paty + offsets('34');
    ch4m1(n+numsteps, :) = pg2.bufferPulse(patx, paty, 0, bufferPaddings('34'), bufferResets('34'), bufferDelays('34'));

%     ch2m1(n+numsteps, :) = ch2m1(n, :);
    ch3m1(n+numsteps, :) = ch3m1(n, :);
end

% trigger at fixedPt-500
% measure from (fixedPt:fixedPt+measLength)
measLength = 3000;
measSeq = {pg1.pulse('M', 'width', measLength)};
for n = 1:2*numsteps;
	ch1m1(n,:) = pg1.makePattern([], fixedPt-500, ones(100,1), cycleLength);
	ch1m2(n,:) = int32(pg1.getPatternSeq(measSeq, n, measDelay, fixedPt+measLength));
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
    ch5 = pg21.linkListToPattern(ch5seq, myn)';
    ch6 = pg21.linkListToPattern(ch6seq, myn)';
    plot(ch5, 'm')
    plot(ch6, 'c')
    plot(5000*ch1m2(myn,:), 'g')
    plot(1000*ch2m1(myn,:), 'r')
    %plot(5000*ch1m1(myn,:),'.')
    grid on
    hold off
end

% add offsets to unused channels
ch1 = ch1 + offsets('12');
ch2 = ch2 + offsets('12');
%ch3 = ch3 + offsets('34');
%ch4 = ch4 + offsets('34');
ch2m2 = ch4m2;

% make APS file
exportAPSConfig(temppath, basename, ch5seq, ch6seq, ch5seq, ch6seq);
disp('Moving APS file to destination');
movefile([temppath basename '.mat'], [pathAPS basename '.mat']);
% make TekAWG file
options = struct('m21_high', 2.0, 'm41_high', 2.0);
TekPattern.exportTekSequence(temppath, basename, ch1, ch1m1, ch1m2, ch2, ch2m1, ch2m2, ch3, ch3m1, ch3m2, ch4, ch4m1, ch4m2, options);
disp('Moving AWG file to destination');
movefile([temppath basename '.awg'], [pathAWG basename '.awg']);
end
