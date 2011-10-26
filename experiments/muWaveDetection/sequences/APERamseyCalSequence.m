% clear all;
% clear classes;
% clear import;
addpath('../../common/src','-END');
addpath('../../common/src/util/','-END');

path = 'U:\AWG\Ramsey\';
%path = '';
basename = 'APERamseyCal';
delay = -10;
measDelay = -53;
bufferDelay = 58;
bufferReset = 100;
bufferPadding = 20;
fixedPt = 6000;
cycleLength = 10000;
offset = 8192;
piAmp = 7200;
pi2Amp = 3600;
sigma = 6;
pulseLength = 4*sigma;
T = [1.145  0; 0 1.0];
anglepts = pi/4;
numPsQId = 10; % number pseudoidentities
numsteps = 10; %number of drag parameters
deltamax=2;
deltamin=-2;
delta=linspace(deltamin,deltamax,numsteps);
pulseType='gaussian';

pg = PatternGen('dPiAmp', piAmp, 'dPiOn2Amp', pi2Amp, 'dSigma', sigma, 'dPulseType', pulseType, 'dDelta', delta, 'correctionT', T, 'dPulseLength', pulseLength, 'cycleLength', cycleLength);
% pulseLib = containers.Map();
% pulses = {'QId', 'X90p', 'X90m', 'Y90p', 'Y90m'};
% for p = pulses
%     pname = cell2mat(p);
%     pulseLib(pname) = pg.pulse(pname);
% end
sindex = 1;
% N applications of psuedoidentity
% QId, X90p,  (sequence of +/-Xp), U90p
% (1-numPsQId) of +/-Xp
for i=1:numsteps
patseq{sindex} = {pg.pulse('QId')};
sindex=sindex+1;
patseq{sindex} = {pg.pulse('X90p', 'delta', delta(i))};
for j = 1:numPsQId
    for k = 1:j
        patseq{sindex + j}{k} = {pg.pulse('X90p','delta',delta(i)),pg.pulse('X90m','delta',delta(i))};
    end
end
sindex = sindex + numPsQId+1;
end
sindex = sindex-1;

nbrPatterns = length(patseq);
fprintf('Number of sequences: %i\n', nbrPatterns);
ch1 = zeros(nbrPatterns, cycleLength);
ch2 = ch1;
ch3m1 = ch1;

for n = 1:numsteps;
	[patx paty] = pg.getPatternSeq(patseq, n, delay, fixedPt);
	ch1(n, :) = patx + offset;
	ch2(n, :) = paty + offset;
    ch3m1(n, :) = pg.bufferPulse(patx, paty, 0, bufferPadding, bufferReset, bufferDelay);
end

calseq = {{pg.pulse('QId')}, {pg.pulse('QId')}, {pg.pulse('Xp')}, {pg.pulse('Xp')}};
for n = 1:length(calseq);
	[patx paty] = pg.getPatternSeq(calseq{n}, n, delay, fixedPt);
	ch1(numsteps+n, :) = patx + offset;
	ch2(numsteps+n, :) = paty + offset;
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
ch3 = zeros(numsteps, cycleLength);
ch4 = zeros(numsteps, cycleLength);
ch2m1 = ch3;
ch2m2 = ch3;
ch3 = ch3 + offset;
ch4 = ch4 + offset;

% make TekAWG file
TekPattern.exportTekSequence(path, basename, ch1, ch1m1, ch1m2, ch2, ch2m1, ch2m2, ch3, ch3m1, ch2m2, ch4, ch2m1, ch2m2);
clear ch1 ch2 ch3 ch4 ch1m1 ch1m2 ch2m1 ch2m2 ch3m1
