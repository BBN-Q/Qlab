% clear all;
% clear classes;
% clear import;
addpath('../../common/src','-END');
addpath('../../common/src/util/','-END');

path = 'U:\AWG\Echo\';
%path = '';
basename = 'Echo';
delay = -10;
measDelay = -53;
bufferDelay = 58;
bufferReset = 100;
bufferPadding = 10;
fixedPt = 6000;
cycleLength = 10000;
offset = 8192;
piAmp = 7100;
pi2Amp = 3550;
sigma = 4;
pulseLength = 4*sigma;
T = [0.90 0; 0 1.0]; % correction matrix
pg = PatternGen('dPiAmp', piAmp, 'dPiOn2Amp', pi2Amp, 'dSigma', sigma, 'correctionT', T, 'dPulseLength', pulseLength, 'cycleLength', cycleLength);

numsteps = 100;
stepsize = 20;
delaypts = 0:stepsize:(numsteps-1)*stepsize;
anglepts = 0:pi/4:(numsteps-1)*pi/4;
patseq = {...
    pg.pulse('X90p'), ...
    pg.pulse('QId', 'width', delaypts), ...
    pg.pulse('Yp') ...
    pg.pulse('QId', 'width', delaypts), ...
    pg.pulse('U90p', 'angle', anglepts), ...
    };

calseq = {{pg.pulse('QId')},{pg.pulse('QId')},{pg.pulse('Xp')},{pg.pulse('Xp')}};
calsteps = length(calseq);

ch1 = zeros(numsteps+calsteps, cycleLength);
ch2 = ch1;
ch3m1 = ch1;

for n = 1:numsteps;
	[patx paty] = pg.getPatternSeq(patseq, n, delay, fixedPt);
	ch1(n, :) = patx + offset;
	ch2(n, :) = paty + offset;
    ch3m1(n, :) = pg.bufferPulse(patx, paty, 0, bufferPadding, bufferReset, bufferDelay);
end

for n = 1:calsteps;
    [patx paty] = pg.getPatternSeq(calseq{n}, 1, delay, fixedPt);
	ch1(n+numsteps, :) = patx + offset;
	ch2(n+numsteps, :) = paty + offset;
    ch3m1(n+numsteps, :) = pg.bufferPulse(patx, paty, 0, bufferPadding, bufferReset, bufferDelay);
end

% trigger at beginning of measurement pulse
% measure from (6000:8000)
measLength = 2000;
measSeq = {pg.pulse('M', 'width', measLength)};
ch1m1 = zeros(numsteps+calsteps, cycleLength);
ch1m2 = zeros(numsteps+calsteps, cycleLength);
for n = 1:numsteps+calsteps;
	ch1m1(n,:) = pg.makePattern([], fixedPt-500, ones(100,1), cycleLength);
	ch1m2(n,:) = int32(pg.getPatternSeq(measSeq, n, measDelay, fixedPt+measLength));
end

myn = 20;
figure
plot(ch1(myn,:))
hold on
plot(ch2(myn,:), 'r')
plot(5000*ch3m1(myn,:), 'k')
plot(5000*ch1m2(myn,:), 'g')
%plot(1000*ch3m1(myn,:))
plot(5000*ch1m1(myn,:),'.')
grid on
hold off

% fill remaining channels with empty stuff
ch3 = zeros(numsteps+calsteps, cycleLength);
ch4 = zeros(numsteps+calsteps, cycleLength);
ch2m1 = ch3;
ch2m2 = ch4;
ch3 = ch3 + offset;
ch4 = ch4 + offset;

% make TekAWG file
TekPattern.exportTekSequence(path, basename, ch1, ch1m1, ch1m2, ch2, ch2m1, ch2m2, ch3, ch3m1, ch2m2, ch4, ch2m1, ch2m2);
clear ch1 ch2 ch3 ch4 ch1m1 ch1m2 ch2m1 ch2m2 ch3m1 pg patseq
