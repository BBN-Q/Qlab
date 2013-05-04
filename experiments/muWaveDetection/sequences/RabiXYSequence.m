% clear all;
% clear classes;
% clear import;
addpath('../../common/src','-END');
addpath('../../common/src/util/','-END');

path = 'U:\AWG\Rabi\';
%path = '';
basename = 'RabiXY';
delay = -10;
measDelay = -53;
bufferDelay = 58;
bufferReset = 100;
bufferPadding = 10;
fixedPt = 6000;
cycleLength = 10000;
offset = 8192;
numsteps = 81;
stepsize = 200;
sigma = 4;
pulseLength = 4*sigma;
pg = PatternGen('dPiAmp', piAmp, 'dPiOn2Amp', piAmp/2, 'dSigma', sigma, 'dPulseLength', pulseLength, 'cycleLength', cycleLength);

amps = -((numsteps-1)/2)*stepsize:stepsize:((numsteps-1)/2)*stepsize;
patseqX = {pg.pulse('Xtheta', 'amp', amps)};
patseqY = {pg.pulse('Ytheta', 'amp', amps)};

ch1 = zeros(2*numsteps, cycleLength);
ch2 = ch1;
ch3m1 = ch1;

for n = 1:numsteps;
	[patx paty] = pg.getPatternSeq(patseqX, n, delay, fixedPt);
	ch1(n, :) = patx + offset;
	ch2(n, :) = paty + offset;
    ch3m1(n, :) = pg.bufferPulse(patx, paty, 0, bufferPadding, bufferReset, bufferDelay);
end

for n = 1:numsteps;
    [patx paty] = pg.getPatternSeq(patseqX, n, delay, fixedPt);
	ch1(n+numsteps, :) = patx + offset;
	ch2(n+numsteps, :) = paty + offset;
    ch3m1(n+numsteps, :) = pg.bufferPulse(patx, paty, 0, bufferPadding, bufferReset, bufferDelay);
end

numsteps = 2*numsteps;

% trigger at fixedPt-500
% measure from (fixedPt:fixedPt+measLength)
measLength = 3000;
measSeq = {pg.pulse('M', 'width', measLength)};
ch1m1 = zeros(numsteps, cycleLength);
ch1m2 = zeros(numsteps, cycleLength);
for n = 1:numsteps;
	ch1m1(n,:) = pg.makePattern([], fixedPt-500, ones(100,1), cycleLength);
	ch1m2(n,:) = pg.getPatternSeq(measSeq, n, measDelay, fixedPt+measLength);
end

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

% fill remaining channels with empty stuff
ch3 = zeros(numsteps, cycleLength) + offset;
ch4 = zeros(numsteps, cycleLength) + offset;
ch2m1 = zeros(numsteps, cycleLength);
ch2m2 = zeros(numsteps, cycleLength);

% make TekAWG file
TekPattern.exportTekSequence(path, basename, ch1, ch1m1, ch1m2, ch2, ch2m1, ch2m2, ch3, ch3m1, ch2m2, ch4, ch2m1, ch2m2);
clear ch1 ch2 ch3 ch4 ch1m1 ch1m2 ch2m1 ch2m2 ch3m1 pg