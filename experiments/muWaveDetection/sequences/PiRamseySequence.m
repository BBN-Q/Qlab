function PiRamseySequence(makePlot)

if ~exist('makePlot', 'var')
    makePlot = true;
end
script = java.io.File(mfilename('fullpath'));
path = char(script.getParentFile().getParentFile().getParentFile().getParent());
addpath([path '/common/src'],'-END');
addpath([path '/common/src/util/'],'-END');

temppath = [char(script.getParent()) '\'];
path = 'U:\AWG\Ramsey\';
basename = 'PiRamsey';

fixedPt = 16000; %12500
cycleLength = 20000; %17000
SSBFreqQ2 = -150e6;
samplingRate = 1.2e9;

% load config parameters from file
load(getpref('qlab','pulseParamsBundleFile'), 'Ts', 'delays', 'measDelay', 'bufferDelays', 'bufferResets', 'bufferPaddings', 'offsets', 'piAmps', 'pi2Amps', 'sigmas', 'pulseTypes', 'deltas', 'buffers', 'pulseLengths');

pg1 = PatternGen('dPiAmp', piAmps('q1'), 'dPiOn2Amp', pi2Amps('q1'), 'dSigma', sigmas('q1'), 'dPulseType', pulseTypes('q1'), 'dDelta', deltas('q1'), 'correctionT', Ts('12'), 'dBuffer', buffers('q1'), 'dPulseLength', pulseLengths('q1'), 'cycleLength', cycleLength);
pg2 = PatternGen('dPiAmp', piAmps('q2'), 'dPiOn2Amp', pi2Amps('q2'), 'dSigma', sigmas('q2'), 'dPulseType', pulseTypes('q2'), 'dDelta', deltas('q2'), 'correctionT', Ts('34'), 'dBuffer', buffers('q2'), 'dPulseLength', pulseLengths('q2'), 'cycleLength', cycleLength, 'samplingRate', samplingRate, 'dmodFrequency', SSBFreqQ2);

numsteps = 150;
stepsize = 48;
delaypts = 0:stepsize:(numsteps-1)*stepsize;
patseq = {pg1.pulse('QId','width',pulseLengths('q2')),...
    pg1.pulse('X90p'), ...
    pg1.pulse('QId', 'width', delaypts), ...
    pg1.pulse('X90p')
    };
patseq2 = {pg2.pulse('Xp'),...
    pg2.pulse('QId', 'width', pulseLengths('q1')),...
    pg2.pulse('QId', 'width', delaypts),...
    pg2.pulse('QId', 'width', pulseLengths('q1'))
    };
calseq = {{pg1.pulse('QId')}, {pg1.pulse('QId')}, {pg1.pulse('Xp')}, {pg1.pulse('Xp')}};
calseq2 = {{pg2.pulse('Xp')}, {pg2.pulse('Xp')}, {pg2.pulse('Xp')}, {pg2.pulse('Xp')}};

% pre-allocate space
ch1 = zeros(numsteps+length(calseq), cycleLength);
ch2 = ch1; ch3 = ch1; ch4 = ch1;
ch1m1 = ch1; ch1m2 = ch1; ch2m1 = ch1; ch2m2 = ch1;
ch3m1 = ch1; ch3m2 = ch1; ch4m1 = ch1; ch4m2 = ch1;

for n = 1:numsteps;
	[patx paty] = pg1.getPatternSeq(patseq, n, delays('12'), fixedPt);
	ch1(n, :) = patx + offsets('12');
	ch2(n, :) = paty + offsets('12');
    ch3m1(n, :) = pg1.bufferPulse(patx, paty, 0, bufferPaddings('12'), bufferResets('12'), bufferDelays('12'));
    
    [patx paty] = pg2.getPatternSeq(patseq2, n, delays('34'), fixedPt);
	ch3(n, :) = patx + offsets('34');
	ch4(n, :) = paty + offsets('34');
    ch4m1(n, :) = pg2.bufferPulse(patx, paty, 0, bufferPaddings('34'), bufferResets('34'), bufferDelays('34'));
end

for n = 1:length(calseq);
	[patx paty] = pg1.getPatternSeq(calseq{n}, n, delays('12'), fixedPt);
	ch1(numsteps+n, :) = patx + offsets('12');
	ch2(numsteps+n, :) = paty + offsets('12');
    ch3m1(numsteps+n, :) = pg1.bufferPulse(patx, paty, 0, bufferPaddings('12'), bufferResets('12'), bufferDelays('12'));
    
    [patx paty] = pg2.getPatternSeq(calseq2{n}, n, delays('34'), fixedPt);
	ch3(numsteps+n, :) = patx + offsets('34');
	ch4(numsteps+n, :) = paty + offsets('34');
    ch4m1(numsteps+n, :) = pg2.bufferPulse(patx, paty, 0, bufferPaddings('34'), bufferResets('34'), bufferDelays('34'));

end

numsteps = numsteps + length(calseq);

% trigger at beginning of measurement pulse
% measure from (6000:9000)
measLength = 3000;
measSeq = {pg1.pulse('M', 'width', measLength)};
for n = 1:numsteps;
	ch1m1(n,:) = pg1.makePattern([], fixedPt-500, ones(100,1), cycleLength);
	ch1m2(n,:) = int32(pg1.getPatternSeq(measSeq, n, measDelay, fixedPt+measLength));
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

% add offsets to unused channels
%ch1 = ch1 + offset;
%ch2 = ch2 + offset;
%ch3 = ch3 + offset2;
%ch4 = ch4 + offset2;

% make TekAWG file
options = struct('m21_high', 2.0, 'm41_high', 2.0);
TekPattern.exportTekSequence(temppath, basename, ch1, ch1m1, ch1m2, ch2, ch2m1, ch2m2, ch3, ch3m1, ch3m2, ch4, ch4m1, ch4m2, options);
disp('Moving AWG file to destination');
movefile([temppath basename '.awg'], [path basename '.awg']);
end
