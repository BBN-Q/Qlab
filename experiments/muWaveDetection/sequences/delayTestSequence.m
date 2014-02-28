% clear all;
% clear classes;
% clear import;
addpath('../../common/src','-END');
addpath('../../common/src/util/','-END');

path = 'U:\AWG\DelayTest\';
%path = '';
basename = 'DelayTest';
delay = 0;
measDelay = -30;
fixedPt = 2000;
cycleLength = 5000;
offset = 8192;
pg = PatternGen;
numsteps = 1;
stepsize = 200;
pulseLength = 1000;
patseq = {pg.pulse('Xtheta', 'amp', 8000, 'width', pulseLength, 'pType', 'square')};

ch3 = zeros(numsteps, cycleLength);
ch4 = ch3;

for n = 1:numsteps;
	[patx paty] = pg.getPatternSeq(patseq, n, delay, fixedPt, cycleLength);
	ch3(n, :) = patx + offset;
	ch4(n, :) = paty + offset;
end

% trigger at 1000
% measure from (2000:4000)
measLength = 2000;
measSeq = {pg.pulse('M', 'width', measLength)};
ch1m1 = zeros(numsteps, cycleLength);
ch1m2 = zeros(numsteps, cycleLength);
for n = 1:numsteps;
	ch1m1(n,:) = pg.makePattern(ones(100,1), 1500, [], cycleLength);
	ch1m2(n,:) = pg.getPatternSeq(measSeq, n, measDelay, fixedPt+measLength, cycleLength);
end

myn = 1;
startx = 1800; stopx = 3100;
figure
plot(ch3(myn,:))
hold on
plot(ch4(myn,:), 'r')
plot(500*ch1m2(myn,:), 'g')
grid on
hold off

% fill remaining channels with empty stuff
ch1 = zeros(numsteps, cycleLength);
ch2 = zeros(numsteps, cycleLength);
ch2m1 = ch1;
ch2m2 = ch1;

% make TekAWG file
TekPattern.exportTekSequence(path, basename, ch1, ch1m1, ch1m2, ch2, ch2m1, ch2m2, ch3, ch2m1, ch2m2, ch4, ch2m1, ch2m2);
clear ch1 ch2 ch3 ch4 ch1m1 ch1m2 ch2m1 ch2m2
