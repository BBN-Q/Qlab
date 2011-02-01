% clear all;
% clear classes;
% clear import;
addpath('../../common/src','-END');
addpath('../../common/src/util/','-END');

path = 'U:\AWG\PulsedSpec\';
%path = '';
basename = 'PulsedSpecin';
delay = -3600;
measDelay = -30;
fixedPt = 7000;
cycleLength = 10000;
offset = 8192;
pg = PatternGen;
numsteps = 1;
pulseLength = 50;
patseq = {pg.pulse('Xtheta', 'amp', 0, 'width', pulseLength, 'pType', 'square')};

ch3 = zeros(numsteps, cycleLength);
ch4 = ch3;
ch3m1 = ch3;

for n = 1:numsteps;
	[patx paty] = pg.getPatternSeq(patseq, n, delay, fixedPt, cycleLength);
	ch3(n, :) = patx + offset;
	ch4(n, :) = paty + offset;
    %ch3m1(n, :) = pg.bufferPulse(patx, 0, 50, 100, 50);
end

% trigger at 1000
% measure from (2000:4000)
measLength = 4000;
measSeq = {pg.pulse('M', 'width', measLength)};
ch1m1 = zeros(numsteps, cycleLength);
ch1m2 = zeros(numsteps, cycleLength);
for n = 1:numsteps;
    %trigger
	ch1m1(n,:) = pg.makePattern([], fixedPt-0.9*measLength, ones(100,1), cycleLength);
    %measurement
	ch1m2(n,:) = pg.getPatternSeq(measSeq, n, measDelay, fixedPt, cycleLength);
end

myn = 1;
startx = 1800; stopx = 3100;
figure
plot(ch3(myn,:))
hold on
plot(ch4(myn,:), 'r')
plot(5000*ch1m2(myn,:), 'g')
%plot(1000*ch3m1(myn,:),'k')
plot(5000*ch1m1(myn,:),'.')
grid on
hold off

% fill remaining channels with empty stuff
ch1 = zeros(numsteps, cycleLength) + offset;
ch2 = zeros(numsteps, cycleLength) + offset;
ch2m1 = zeros(numsteps, cycleLength);
ch2m2 = zeros(numsteps, cycleLength);

% make TekAWG file
%TekPattern.exportTekSequence(path, basename, ch1, ch1m1, ch1m2, ch2, ch2m1, ch2m2, ch3, ch3m1, ch2m2, ch4, ch2m1, ch2m2);
clear ch1 ch2 ch3 ch4 ch1m1 ch1m2 ch2m1 ch2m2
