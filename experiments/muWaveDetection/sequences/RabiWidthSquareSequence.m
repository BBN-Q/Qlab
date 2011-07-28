% clear all;
% clear classes;
% clear import;
addpath('../../../common/src','-END');
addpath('../../../common/src/util/','-END');

path = 'U:\AWG\Rabi\';
%path = '';
basename = 'RabiWidthSquare';
delay = -10;
measDelay = -53;
bufferDelay = 58;
bufferReset = 100;
bufferPadding = 20;
fixedPt = 6000;
cycleLength = 10000;
offset = 8192;

piAmp = 8000;
pg = PatternGen('dPiAmp', piAmp, 'dPiOn2Amp', piAmp/2, 'cycleLength', cycleLength);

numsteps = 100;
minWidth = 0;
stepsize = 10;
pulseLength = minWidth:stepsize:(numsteps-1)*stepsize+minWidth;

%patseq1 = {pg.pulse('Yp', 'width', pulseLength, 'pType', 'square')};
patseq = {pg.pulse('Xp', 'width', pulseLength, 'pType', 'square')};

ch1 = zeros(numsteps, cycleLength);
ch2 = ch1;
ch4m1 = ch1;
ch3m1 = ch1;

for n = 1:numsteps;
	[patx paty] = pg.getPatternSeq(patseq, n, delay, fixedPt);
	ch1(n, :) = patx + offset;
	ch2(n, :) = paty + offset;
    ch3m1(n, :) = pg.bufferPulse(patx, paty, 0, bufferPadding, bufferReset, bufferDelay);
    %ch4m1(n, :) = pg.bufferPulse(patx2, paty2, 0, bufferPadding, bufferReset, bufferDelay);
end

% trigger at beginning of measurement pulse
% measure from (6000:8000)
measLength = 3000;
measSeq = {pg.pulse('M', 'width', measLength)};
ch1m1 = zeros(numsteps, cycleLength);
ch1m2 = zeros(numsteps, cycleLength);
for n = 1:numsteps;
	ch1m1(n,:) = pg.makePattern([], fixedPt-500, ones(100,1), cycleLength);
	ch1m2(n,:) = int32(pg.getPatternSeq(measSeq, n, measDelay, fixedPt+measLength));
end

myn = 10;
figure
plot(ch1(myn,:))
hold on
plot(ch2(myn,:), 'r')
plot(5000*ch3m1(myn,:), 'k')
plot(5000*ch1m2(myn,:), 'g')
%plot(5000*ch4m1(myn,:),'c')
plot(5000*ch1m1(myn,:),'.')
grid on
hold off

% fill remaining channels with empty stuff
ch3 = zeros(numsteps, cycleLength);
ch4 = zeros(numsteps, cycleLength);
ch2m1 = ch3;
ch2m2 = ch3;
ch3 = ch3 + offset;
ch4 = ch4 + offset;

% make TekAWG file
TekPattern.exportTekSequence(path, basename, ch1, ch1m1, ch1m2, ch2, ch2m1, ch2m2, ch3, ch3m1, ch2m2, ch4, ch2m1, ch2m2);
clear ch1 ch2 ch3 ch4 ch1m1 ch1m2 ch2m1 ch2m2 ch3m1
