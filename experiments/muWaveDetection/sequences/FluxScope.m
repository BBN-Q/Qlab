% clear all;
% clear classes;
% clear import;
addpath('../../common/src','-END');
addpath('../../common/src/util/','-END');

path = 'U:\AWG\FluxScope\';
%path = '';
basename = 'FluxScope';
delay = -10;
measDelay = -53;
fluxDelay = 0;
bufferDelay = 58;
bufferReset = 100;
bufferPadding = 10;
fixedPt = 8000;
cycleLength = 12000;
offset = 8192;
piAmp = 6200;
pi2Amp = 2800;
sigma = 6;
pulseLength = 4*sigma;
fluxwidth = 100; %ns
fluxrise = 2; % ns
fluxamp = -550;
T = [0.822 0; 0 1.0];
%T = eye(2);
% note dBuffer = 0!
pg = PatternGen('dPiAmp', piAmp, 'dPiOn2Amp', pi2Amp, 'dSigma', sigma, 'dBuffer', 0, 'dPulseLength', pulseLength, 'correctionT', T, 'cycleLength', cycleLength);
zpg = PatternGen('dBuffer', 0, 'dPulseLength', pulseLength, 'cycleLength', cycleLength);

numsteps = 100;
stepsize = 1;
delaypts = 0:stepsize:(numsteps-1)*stepsize;
patseq = {...
    pg.pulse('Xp'), ...
    };

zseq = {...
    zpg.pulse('Zf', 'amp', fluxamp, 'width', fluxwidth, 'sigma', fluxrise, 'pType', 'tanh'),...
    zpg.pulse('ZId', 'width', delaypts)
    };

ch1 = zeros(numsteps + 4, cycleLength);
ch2 = ch1;
ch4 = ch1;
ch3m1 = ch1;

for n = 1:numsteps;
	[patx paty] = pg.getPatternSeq(patseq, n, delay, fixedPt);
    [patz, ~] = zpg.getPatternSeq(zseq, n, fluxDelay, fixedPt);
	ch1(n, :) = patx + offset;
	ch2(n, :) = paty + offset;
    ch4(n, :) = patz + offset;
    ch3m1(n, :) = pg.bufferPulse(patx, paty, 0, bufferPadding, bufferReset, bufferDelay);
end

calseq = {{pg.pulse('QId')}, {pg.pulse('QId')}, {pg.pulse('Xp')}, {pg.pulse('Xp')}};
zcalseq = {zpg.pulse('ZId')};
for n = 1:length(calseq);
	[patx paty] = pg.getPatternSeq(calseq{n}, n, delay, fixedPt);
    [patz, ~] = zpg.getPatternSeq(zcalseq, n, fluxDelay, fixedPt);
	ch1(numsteps+n, :) = patx + offset;
	ch2(numsteps+n, :) = paty + offset;
    ch4(numsteps+n, :) = patz + offset;
    ch3m1(numsteps+n, :) = pg.bufferPulse(patx, paty, 0, bufferPadding, bufferReset, bufferDelay);
end

numsteps = numsteps + length(calseq);

% trigger at beginning of measurement pulse
% measure from (6000:9000)
measLength = 3000;
measSeq = {pg.pulse('M', 'width', measLength)};
ch1m1 = zeros(numsteps, cycleLength);
ch1m2 = zeros(numsteps, cycleLength);
for n = 1:numsteps;
	ch1m1(n,:) = pg.makePattern([], fixedPt-500, ones(100,1), cycleLength);
	ch1m2(n,:) = int32(pg.getPatternSeq(measSeq, n, measDelay, fixedPt+measLength));
end

myn = 20;
figure
plot(ch1(myn,:));
hold on
plot(ch2(myn,:), 'r')
plot(ch4(myn,:), 'c')
plot(5000*ch3m1(myn,:), 'k')
plot(5000*ch1m2(myn,:), 'g')
%plot(1000*ch3m1(myn,:))
plot(5000*ch1m1(myn,:),'.')
grid on
hold off

% fill remaining channels with empty stuff
ch3 = zeros(numsteps, cycleLength);
%ch4 = zeros(numsteps, cycleLength);
ch2m1 = ch3;
ch2m2 = ch4;
ch3 = ch3 + offset;
%ch4 = ch4 + offset;

% make TekAWG file
TekPattern.exportTekSequence(path, basename, ch1, ch1m1, ch1m2, ch2, ch2m1, ch2m2, ch3, ch3m1, ch2m2, ch4, ch2m1, ch2m2);
%clear ch1 ch2 ch3 ch4 ch1m1 ch1m2 ch2m1 ch2m2 ch3m1
