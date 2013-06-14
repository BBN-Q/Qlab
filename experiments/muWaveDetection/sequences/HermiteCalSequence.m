function HermiteCalSequence(makePlot)

if ~exist('makePlot', 'var')
    makePlot = true;
end
script = java.io.File(mfilename('fullpath'));
path = char(script.getParentFile().getParentFile().getParentFile().getParent());
addpath([path '/common/src'],'-END');
addpath([path '/common/src/util/'],'-END');

temppath = [char(script.getParent()) '\'];
path = 'U:\AWG\Hermite\';
basename = 'Hermite';

fixedPt = 6000;
cycleLength = 10000;
numsteps = 81;
stepsize = 200;

% load config parameters from file
parent_path = char(script.getParentFile.getParent());
cfg_path = [parent_path '/cfg/'];
load([cfg_path 'pulseParams.mat'], 'T', 'delay', 'measDelay', 'bufferDelay', 'bufferReset', 'bufferPadding', 'offset', 'piAmp', 'pi2Amp', 'sigma', 'pulseType', 'delta', 'buffer', 'pulseLength');
pg = PatternGen('dPiAmp', piAmp, 'dPiOn2Amp', pi2Amp, 'dSigma', sigma, 'dPulseType', pulseType, 'dDelta', delta, 'dPulseLength', pulseLength, 'correctionT', T, 'cycleLength', cycleLength);

%amps = -((numsteps-1)/2)*stepsize:stepsize:((numsteps-1)/2)*stepsize;
%amps = 0:stepsize:(numsteps-1)*stepsize;
amps = 2300*ones(numsteps,1);
patseq = {pg.pulse('Xtheta', 'amp', amps, 'pType', 'hermite', 'sigma', 45, 'width', 180, 'rotAngle', pi)};

calseq = {{pg.pulse('QId')}, {pg.pulse('QId')}, {pg.pulse('Xp')}, {pg.pulse('Xp')}};
% calseq2 = {{pg2.pulse('QId')}, {pg2.pulse('QId')}, {pg2.pulse('QId')}, {pg2.pulse('QId')}};

ch1 = zeros(numsteps+length(calseq), cycleLength);
ch2 = ch1;
ch4m1 = ch1;
ch3m1 = ch1;

for n = 1:numsteps;
	[patx paty] = pg.getPatternSeq(patseq, n, delay, fixedPt);
	ch1(n, :) = patx + offset;
	ch2(n, :) = paty + offset;
    ch3m1(n, :) = pg.bufferPulse(patx, paty, 0, bufferPadding, bufferReset, bufferDelay);
end

for n = 1:length(calseq);
	[patx paty] = pg.getPatternSeq(calseq{n}, n, delay, fixedPt);
	ch1(numsteps+n, :) = patx + offset;
	ch2(numsteps+n, :) = paty + offset;
    ch3m1(numsteps+n, :) = pg.bufferPulse(patx, paty, 0, bufferPadding, bufferReset, bufferDelay);
    
%     [patx paty] = pg2.getPatternSeq(calseq2{n}, n, delayQ2, fixedPt);
% 	ch3(numsteps+n, :) = patx + offsetQ2;
% 	ch4(numsteps+n, :) = paty + offsetQ2;
%     ch4m1(numsteps+n, :) = pg2.bufferPulse(patx, paty, 0, bufferPadding2, bufferReset2, bufferDelay2);
end

numsteps = numsteps + length(calseq);

% trigger at fixedPt-500
% measure from (fixedPt:fixedPt+measLength)
measLength = 3000;
measSeq = {pg.pulse('M', 'width', measLength)};
ch1m1 = zeros(numsteps, cycleLength);
ch1m2 = zeros(numsteps, cycleLength);
for n = 1:numsteps;
	ch1m1(n,:) = pg.makePattern([], fixedPt-500, ones(100,1), cycleLength);
	ch1m2(n,:) = int32(pg.getPatternSeq(measSeq, n, measDelay, fixedPt+measLength));
end

if makePlot
    myn = 25;
    figure
    plot(ch1(myn,:))
    hold on
    plot(ch2(myn,:), 'r')
    plot(5000*ch1m2(myn,:), 'g')
    plot(1000*ch3m1(myn,:), 'r')
    plot(5000*ch1m1(myn,:),'.')
    grid on
    hold off
end

% fill remaining channels with empty stuff
ch3 = zeros(numsteps, cycleLength) + offset;
ch4 = zeros(numsteps, cycleLength) + offset;
ch2m1 = zeros(numsteps, cycleLength);
ch2m2 = zeros(numsteps, cycleLength);

% make TekAWG file
TekPattern.exportTekSequence(temppath, basename, ch1, ch1m1, ch1m2, ch2, ch2m1, ch2m2, ch3, ch3m1, ch2m2, ch4, ch2m1, ch2m2);
disp('Moving AWG file to destination');
movefile([temppath basename '.awg'], [path basename '.awg']);
end
