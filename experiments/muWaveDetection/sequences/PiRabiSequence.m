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

numsteps = 120; % 125
minWidth = 12; % 12
stepsize = 8; % 4

% load config parameters from file
parent_path = char(script.getParentFile.getParent());
cfg_path = [parent_path '/cfg/'];
load([cfg_path 'pulseParams.mat'], 'T', 'delay', 'measDelay', 'bufferDelay', 'bufferReset', 'bufferPadding', 'offset', 'piAmp', 'pi2Amp', 'sigma', 'pulseType', 'delta', 'buffer', 'pulseLength');
load([cfg_path 'pulseParams.mat'], 'T2', 'delay2', 'bufferDelay2', 'bufferReset2', 'bufferPadding2', 'offset2', 'piAmp2', 'pi2Amp2', 'sigma2', 'pulseType2', 'delta2', 'buffer2', 'pulseLength2');
load([cfg_path 'pulseParams.mat'], 'T3', 'delay3', 'bufferDelay3', 'bufferReset3', 'bufferPadding3', 'offset3', 'piAmp3', 'pi2Amp3', 'sigma3', 'pulseType3', 'delta3', 'buffer3', 'pulseLength3');

pg1 = PatternGen('dPiAmp', piAmp, 'dPiOn2Amp', pi2Amp, 'dSigma', sigma, 'dPulseLength', pulseLength, 'correctionT', T, 'dBuffer', buffer, 'cycleLength', cycleLength);
pg2 = PatternGen('dPiAmp', piAmp2, 'dPiOn2Amp', pi2Amp2, 'dSigma', sigma2, 'dPulseType', pulseType2, 'dDelta', delta2, 'correctionT', T2, 'dBuffer', buffer2, 'dPulseLength', pulseLength2, 'cycleLength', cycleLength);
pg21 = PatternGen('dPiAmp', piAmp3, 'dPiOn2Amp', pi2Amp3, 'dSigma', sigma3, 'dPulseLength', pulseLength3, 'correctionT', T3, 'dBuffer', buffer3, 'cycleLength', cycleLength, 'passThru', true);

length = minWidth:stepsize:(numsteps-1)*stepsize+minWidth;
%patseq1   = {pg1.pulse('Xp'), pg1.pulse('QId', 'width', length), pg1.pulse('Xp')};
patseq1   = {pg2.pulse('Xp'), pg2.pulse('QId', 'width', length), pg2.pulse('Xp')};
%patseq2  = {pg2.pulse('QId', 'width', pulseLength), pg2.pulse('Xp', 'width', length, 'pType', 'square'), pg2.pulse('QId', 'width', pulseLength)};
%patseq21  = {pg21.pulse('QId', 'width', pulseLength), pg21.pulse('Xp', 'width', length, 'pType', 'square'), pg21.pulse('QId', 'width', pulseLength)};
patseq21  = {pg21.pulse('Xp', 'width', length, 'pType', 'square'), pg21.pulse('QId', 'width', pulseLength)};

ch1 = zeros(numsteps, cycleLength);
ch2 = ch1;
ch3 = ch1;
ch4 = ch1;
ch1m1 = ch1; ch1m2 = ch1;
ch2m1 = ch1; ch2m2 = ch1;
ch3m1 = ch1; ch3m2 = ch1;
ch4m1 = ch1; ch4m2 = ch1;

[ch5seq, ch6seq, ~, ~] = pg21.build(patseq21, numsteps, delay3, fixedPt);

for n = 1:numsteps;
	%[patx paty] = pg1.getPatternSeq(patseq1, n, delay, fixedPt);
	%ch1(n, :) = patx + offset;
	%ch2(n, :) = paty + offset;
    %ch3m1(n, :) = pg1.bufferPulse(patx, paty, 0, bufferPadding, bufferReset, bufferDelay);
    
    [patx paty] = pg2.getPatternSeq(patseq1, n, delay2, fixedPt);
	ch3(n, :) = patx + offset;
	ch4(n, :) = paty + offset;
    ch4m1(n, :) = pg1.bufferPulse(patx, paty, 0, bufferPadding2, bufferReset2, bufferDelay2);
    
    % construct buffer for APS pulses
    patx = pg21.linkListToPattern(ch5seq, n)';
    paty = pg21.linkListToPattern(ch6seq, n)';
    ch2m1(n, :) = pg21.bufferPulse(patx, paty, 0, bufferPadding3, bufferReset3, bufferDelay3);
end

% trigger at fixedPt-500
% measure from (fixedPt:fixedPt+measLength)
measLength = 3000;
measSeq = {pg1.pulse('M', 'width', measLength)};
for n = 1:numsteps;
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
    plot(1000*ch3m1(myn,:), 'r')
    plot(5000*ch1m1(myn,:),'.')
    grid on
    hold off
end

% add offsets to unused channels
ch1 = ch1 + offset;
ch2 = ch2 + offset;
%ch3 = ch3 + offset2;
%ch4 = ch4 + offset2;
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
