function Pi2CalSequence(makePlot)

if ~exist('makePlot', 'var')
    makePlot = true;
end
script = java.io.File(mfilename('fullpath'));
path = char(script.getParentFile().getParentFile().getParentFile().getParent());
addpath([path '/common/src'],'-END');
addpath([path '/common/src/util/'],'-END');

path = 'U:\AWG\Pi2Cal\';
basename = 'Pi2Cal';

fixedPt = 6000;
cycleLength = 10000;
numsteps = 50;

% load config parameters from file
cfg_path = '../cfg/';
%cfg_path = 'cfg/';
load([cfg_path 'pulseParams.mat'], 'T', 'delay', 'measDelay', 'bufferDelay', 'bufferReset', 'bufferPadding', 'offset', 'piAmp', 'pi2Amp', 'sigma', 'pulseType', 'delta', 'buffer', 'pulseLength');
% override correction matrix
T = eye(2);
%T = [1.05 0; 0 1.0];

pulseOffset = offset;

pg = PatternGen('dPiAmp', piAmp, 'dPiOn2Amp', pi2Amp, 'dSigma', sigma, 'dPulseType', pulseType, 'dDelta', delta, 'correctionT', T, 'dBuffer', buffer, 'dPulseLength', pulseLength, 'cycleLength', cycleLength);
pulseLib = containers.Map();
pulses = {'QId', 'X90p', 'X90m', 'Y90p', 'Y90m'};
for p = pulses
    pname = cell2mat(p);
    pulseLib(pname) = pg.pulse(pname);
end

sindex = 1;
numPi2s = 10; % number of odd numbered pi/2 sequences for each rotation direction

% +X rotations
% QId
% (1, 3, 5, 7, 9, 11, 13, 15, 17, 19) x X90p
patseq{sindex} = {pulseLib('QId')};
for j = 1:numPi2s
    for k = 1:(1+2*(j-1))
        patseq{sindex + j}{k} = pulseLib('X90p');
    end
end
sindex = sindex + numPi2s;

% -X rotations
% QId
% (1, 3, 5, 7, 9, 11, ...) x X90m
patseq{sindex} = {pulseLib('QId')};
for j = 1:numPi2s
    for k = 1:(1+2*(j-1))
        patseq{sindex + j}{k} = pulseLib('X90m');
    end
end
sindex = sindex + numPi2s;

% +Y rotations
% QId
% (1, 3, 5, 7, 9, 11) x Y90p
patseq{sindex} = {pulseLib('QId')};
for j = 1:numPi2s
    for k = 1:(1+2*(j-1))
        patseq{sindex + j}{k} = pulseLib('Y90p');
    end
end
sindex = sindex + numPi2s;

% -Y rotations
% QId
% (1, 3, 5, 7, 9, 11) x Y90m
patseq{sindex} = {pulseLib('QId')};
for j = 1:numPi2s
    for k = 1:(1+2*(j-1))
        patseq{sindex + j}{k} = pulseLib('Y90m');
    end
end
sindex = sindex + numPi2s;

% just a pi pulse for scaling
patseq{sindex}={pg.pulse('Xp')};

% double every pulse
nbrPatterns = 2*length(patseq);
fprintf('Number of sequences: %i\n', nbrPatterns);
ch1 = zeros(nbrPatterns, cycleLength);
ch2 = ch1;
ch3m1 = ch1;

for kindex = 1:nbrPatterns;
	[patx paty] = pg.getPatternSeq(patseq{floor((kindex-1)/2)+1}, 1, delay, fixedPt);
	ch1(kindex, :) = patx + pulseOffset;
	ch2(kindex, :) = paty + pulseOffset;
    ch3m1(kindex, :) = pg.bufferPulse(patx, paty, 0, bufferPadding, bufferReset, bufferDelay);
end

% trigger at beginning of measurement pulse
% measure from (6000:9000)
measLength = 3000;
measSeq = {pg.pulse('M', 'width', measLength)};
ch1m1 = zeros(nbrPatterns, cycleLength);
ch1m2 = zeros(nbrPatterns, cycleLength);
for n = 1:nbrPatterns;
	ch1m1(n,:) = pg.makePattern([], fixedPt-500, ones(100,1), cycleLength);
	ch1m2(n,:) = int32(pg.getPatternSeq(measSeq, n, measDelay, fixedPt+measLength));
end

if makePlot
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
end

% fill remaining channels with empty stuff
ch3 = zeros(nbrPatterns, cycleLength);
ch4 = zeros(nbrPatterns, cycleLength);
ch2m1 = ch3;
ch2m2 = ch4;
ch3 = ch3 + offset;
ch4 = ch4 + offset;

% make TekAWG file
TekPattern.exportTekSequence(path, basename, ch1, ch1m1, ch1m2, ch2, ch2m1, ch2m2, ch3, ch3m1, ch2m2, ch4, ch2m1, ch2m2);
