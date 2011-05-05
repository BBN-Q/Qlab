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
piAmp = 7100;
pi2Amp = 3550;
sigma = 4;
pulseType = 'gaussian';
delta = -0.1; % DRAG parameter
pulseLength = 4*sigma;

% load correction matrix from file
cfg_path = 'cfg/';
load([cfg_path 'mixercal.mat'], 'T');
if ~exist('T', 'var') % check that it loaded
    T = eye(2);
end
T = [0.90 0; 0 1.0];

pg = PatternGen('dPiAmp', piAmp, 'dPiOn2Amp', pi2Amp, 'dSigma', sigma, 'dPulseType', pulseType, 'correctionT', T, 'dBuffer', 5, 'dPulseLength', pulseLength, 'cycleLength', cycleLength);

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
	ch1(kindex, :) = patx + offset;
	ch2(kindex, :) = paty + offset;
    ch3m1(kindex, :) = pg.bufferPulse(patx, paty, 0, bufferPadding, bufferReset, bufferDelay);
end

calseq = {{pg.pulse('QId')},{pg.pulse('QId')},{pg.pulse('Xp')},{pg.pulse('Xp')}};
calsteps = length(calseq);

for n = 1:calsteps;
    [patx paty] = pg.getPatternSeq(calseq{n}, 1, delay, fixedPt);
	ch1(n+nbrPatterns, :) = patx + offset;
	ch2(n+nbrPatterns, :) = paty + offset;
    ch3m1(n+nbrPatterns, :) = pg.bufferPulse(patx, paty, 0, bufferPadding, bufferReset, bufferDelay);
end

nbrPatterns = nbrPatterns + calsteps;

% trigger at beginning of measurement pulse
% measure from (6000:8000)
measLength = 2000;
measSeq = {pg.pulse('M', 'width', measLength)};
ch1m1 = zeros(nbrPatterns, cycleLength);
ch1m2 = zeros(nbrPatterns, cycleLength);
for n = 1:nbrPatterns;
	ch1m1(n,:) = pg.makePattern([], fixedPt-500, ones(100,1), cycleLength);
	ch1m2(n,:) = int32(pg.getPatternSeq(measSeq, n, measDelay, fixedPt+measLength));
end

myn = 20;
figure
plot(ch1(myn,:))
hold on
plot(ch2(myn,:), 'r')
plot(5000*ch3m1(myn,:), 'k')
plot(5000*ch1m1(myn,:),'.')
plot(5000*ch1m2(myn,:), 'g')
grid on
hold off

figure
subplot(2,1,1)
imagesc(ch1);
subplot(2,1,2)
imagesc(ch2);

% fill remaining channels with empty stuff
ch3 = zeros(nbrPatterns, cycleLength);
ch4 = zeros(nbrPatterns, cycleLength);
ch2m1 = ch3;
ch2m2 = ch3;
ch3 = ch3 + offset;
ch4 = ch4 + offset;

% make TekAWG file
TekPattern.exportTekSequence(path, basename, ch1, ch1m1, ch1m2, ch2, ch2m1, ch2m2, ch3, ch3m1, ch2m2, ch4, ch2m1, ch2m2);
clear ch1 ch2 ch3 ch4 ch1m1 ch1m2 ch2m1 ch2m2 ch3m1 patseq calseq pg
clear pulseLibrary
