% clear classes;
% clear import;
% addpath('../../common/src','-END');
% addpath('../../common/src/util/','-END');

clear patseq pg 

path = 'U:\AWG\RB\';
basename = 'RB';
delay = -10;
measDelay = -53;
bufferDelay = 58;
bufferReset = 100;
bufferPadding = 20;
fixedPt = 7000;
cycleLength = 10000;
offset = 8192;
numsteps = 50;
piAmp = 6000;
pi2Amp = 3000;
sigma = 6;
pulseLength = 6*sigma;

% load correction matrix from file
cfg_path = '../cfg/';
load([cfg_path 'mixercal.mat'], 'T');
if ~exist('T', 'var') % check that it loaded
    T = eye(2);
end

pg = PatternGen('dPiAmp', piAmp, 'dPiOn2Amp', pi2Amp, 'dSigma', sigma, 'dPulseType', 'drag', 'correctionT', T, 'dBuffer', 5, 'dPulseLength', pulseLength, 'cycleLength', cycleLength);

% load in random Clifford sequences from text file
fid = fopen('RBsequences.txt');
if ~fid
    error('Could not open Clifford sequence list')
end

tline = fgetl(fid);
lnum = 1;
while ischar(tline)
    seqStrings{lnum} = textscan(tline, '%s');
    lnum = lnum + 1;
    tline = fgetl(fid);
end
fclose(fid);
clear fid

% convert sequence strings into pulses
pulseLibrary = containers.Map();
for ii = 1:length(seqStrings)
    for jj = 1:length(seqStrings{ii}{1})
        pulseName = seqStrings{ii}{1}{jj};
        if ~isKey(pulseLibrary, pulseName)
            pulseLibrary(pulseName) = pg.pulse(pulseName);
        end
        currentSeq{jj} = pulseLibrary(pulseName);
    end
    patseq{ii} = currentSeq(1:jj);
end

nbrPatterns = length(patseq);

for kindex = 1:nbrPatterns;
	[patx paty] = pg.getPatternSeq(patseq{kindex}, 1, delay, fixedPt);
	ch3(kindex, :) = patx + offset;
	ch4(kindex, :) = paty + offset;
    ch3m1(kindex, :) = pg.bufferPulse(patx, paty, 0, bufferPadding, bufferReset, bufferDelay);
end

% trigger at beginning of measurement pulse
% measure from (6000:8000)
measLength = 2000;
measSeq = {pg.pulse('M', 'width', measLength)};
ch1m1 = zeros(numsteps, cycleLength);
ch1m2 = zeros(numsteps, cycleLength);
for n = 1:numsteps;
	ch1m1(n,:) = pg.makePattern([], fixedPt-500, ones(100,1), cycleLength);
	ch1m2(n,:) = pg.getPatternSeq(measSeq, n, measDelay, fixedPt+measLength);
end

myn = 20;
figure
plot(ch3(myn,:))
hold on
plot(ch4(myn,:), 'r')
plot(5000*ch3m1(myn,:), 'k')
plot(5000*ch1m1(myn,:),'.')
plot(5000*ch1m2(myn,:), 'g')
grid on
hold off

figure
subplot(2,1,1)
imagesc(ch3);
subplot(2,1,2)
imagesc(ch4);

% fill remaining channels with empty stuff
ch1 = zeros(numsteps, cycleLength);
ch2 = zeros(numsteps, cycleLength);
ch2m1 = ch1;
ch2m2 = ch1;
ch1 = ch1 + offset;
ch2 = ch2 + offset;

% make TekAWG file
TekPattern.exportTekSequence(path, basename, ch1, ch1m1, ch1m2, ch2, ch2m1, ch2m2, ch3, ch3m1, ch2m2, ch4, ch2m1, ch2m2);
clear ch1 ch2 ch3 ch4 ch1m1 ch1m2 ch2m1 ch2m2
clear pulseLibrary
