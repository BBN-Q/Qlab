% clear all;
% clear classes;
% clear import;
addpath('../../common/src','-END');
addpath('../../common/src/util/','-END');

path = 'U:\AWG\Rabi\';
%path = '';
basename = 'Rabi';
delay = -10;
measDelay = -53;
bufferDelay = 58;
bufferReset = 100;
bufferPadding = 20;
fixedPt = 6000;
cycleLength = 10000;
offset = 8192;
numsteps = 81;
stepsize = 200;
sigma = 15;
pulseLength = 6*sigma;
pg = PatternGen('dPiAmp', piAmp, 'dPiOn2Amp', piAmp/2, 'dSigma', sigma, 'dPulseLength', pulseLength, 'cycleLength', cycleLength);

amps = -((numsteps-1)/2)*stepsize:stepsize:((numsteps-1)/2)*stepsize;
patseq = {pg.pulse('Xtheta', 'amp', amps)};

ch3 = zeros(numsteps, cycleLength);
ch4 = ch3;
ch3m1 = ch3;

for n = 1:numsteps;
	[patx paty] = pg.getPatternSeq(patseq, n, delay, fixedPt);
	ch3(n, :) = patx + offset;
	ch4(n, :) = paty + offset;
    ch3m1(n, :) = pg.bufferPulse(patx, paty, 0, bufferPadding, bufferReset, bufferDelay);
end

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
plot(ch3(myn,:))
hold on
plot(ch4(myn,:), 'r')
plot(5000*ch1m2(myn,:), 'g')
%plot(1000*ch3m1(myn,:))
plot(5000*ch1m1(myn,:),'.')
grid on
hold off

% fill remaining channels with empty stuff
ch1 = zeros(numsteps, cycleLength) + offset;
ch2 = zeros(numsteps, cycleLength) + offset;
ch2m1 = zeros(numsteps, cycleLength);
ch2m2 = zeros(numsteps, cycleLength);

% make TekAWG file
TekPattern.exportTekSequence(path, basename, ch1, ch1m1, ch1m2, ch2, ch2m1, ch2m2, ch3, ch3m1, ch2m2, ch4, ch2m1, ch2m2);
%clear ch1 ch2 ch3 ch4 ch1m1 ch1m2 ch2m1 ch2m2
