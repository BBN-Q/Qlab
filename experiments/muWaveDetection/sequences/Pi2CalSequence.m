% clear classes;
% clear import;
addpath('../../common/src','-END');
addpath('../../common/src/util/','-END');

clear patseq pg 

path = 'U:\AWG\Pi2Cal\';
basename = 'Pi2Cal';
delay = -10;
measDelay = -53;
bufferDelay = 58;
bufferReset = 100;
bufferPadding = 10;
fixedPt = 6000;
cycleLength = 10000;
offset = 8192;
numsteps = 50;
piAmp = 6800;
pi2Amp = 3450;
sigma = 4;
pulseType = 'gaussian';
delta = -0.1; % DRAG parameter
pulseLength = 4*sigma;

% load correction matrix from file
%cfg_path = '../cfg/';
cfg_path = 'cfg/';
load([cfg_path 'mixercal.mat'], 'T');
if ~exist('T', 'var') % check that it loaded
    T = eye(2);
end
%T = eye(2);
T = [0.90 0; 0 1.0];

pg = PatternGen('dPiAmp', piAmp, 'dPiOn2Amp', pi2Amp, 'dSigma', sigma, 'dPulseType', pulseType, 'dDelta', delta, 'correctionT', T, 'dBuffer', 5, 'dPulseLength', pulseLength, 'cycleLength', cycleLength);

% +X rotations
% QId
% X90p
% X90p X90p
% X90p X90p X90p
% X90p X90p X90p
% X90p X90p X90p X90p
patseq{1}={pg.pulse('QId')};
patseq{2}={pg.pulse('X90p')};
patseq{3}={pg.pulse('X90p'),pg.pulse('X90p')};
patseq{4}={pg.pulse('X90p'),pg.pulse('X90p'),pg.pulse('X90p')};
patseq{5}={pg.pulse('X90p'),pg.pulse('X90p'),pg.pulse('X90p'),pg.pulse('X90p')};
patseq{6}={pg.pulse('X90p'),pg.pulse('X90p'),pg.pulse('X90p'),pg.pulse('X90p'),pg.pulse('X90p')};

% -X rotations
% QId
% X90m
% X90m X90m
% X90m X90m X90m
% X90m X90m X90m
% X90m X90m X90m X90m
patseq{7}={pg.pulse('QId')};
patseq{8}={pg.pulse('X90m')};
patseq{9}={pg.pulse('X90m'),pg.pulse('X90m')};
patseq{10}={pg.pulse('X90m'),pg.pulse('X90m'),pg.pulse('X90m')};
patseq{11}={pg.pulse('X90m'),pg.pulse('X90m'),pg.pulse('X90m'),pg.pulse('X90m')};
patseq{12}={pg.pulse('X90m'),pg.pulse('X90m'),pg.pulse('X90m'),pg.pulse('X90m'),pg.pulse('X90m')};

% +Y rotations
% QId
% Y90p
% Y90p Y90p
% Y90p Y90p Y90p
% Y90p Y90p Y90p Y90p
% Y90p Y90p Y90p Y90p Y90p
patseq{13}={pg.pulse('QId')};
patseq{14}={pg.pulse('Y90p')};
patseq{15}={pg.pulse('Y90p'),pg.pulse('Y90p')};
patseq{16}={pg.pulse('Y90p'),pg.pulse('Y90p'),pg.pulse('Y90p')};
patseq{17}={pg.pulse('Y90p'),pg.pulse('Y90p'),pg.pulse('Y90p'),pg.pulse('Y90p')};
patseq{18}={pg.pulse('Y90p'),pg.pulse('Y90p'),pg.pulse('Y90p'),pg.pulse('Y90p'),pg.pulse('Y90p')};

% -Y rotations
% QId
% Y90m
% Y90m Y90m
% Y90m Y90m Y90m
% Y90m Y90m Y90m Y90m
% Y90m Y90m Y90m Y90m Y90m
patseq{19}={pg.pulse('QId')};
patseq{20}={pg.pulse('Y90m')};
patseq{21}={pg.pulse('Y90m'),pg.pulse('Y90m')};
patseq{22}={pg.pulse('Y90m'),pg.pulse('Y90m'),pg.pulse('Y90m')};
patseq{23}={pg.pulse('Y90m'),pg.pulse('Y90m'),pg.pulse('Y90m'),pg.pulse('Y90m')};
patseq{24}={pg.pulse('Y90m'),pg.pulse('Y90m'),pg.pulse('Y90m'),pg.pulse('Y90m'),pg.pulse('Y90m')};

% double every pulse
nbrPatterns = 2*length(patseq);

for kindex = 1:nbrPatterns;
	[patx paty] = pg.getPatternSeq(patseq{floor((kindex-1)/2)+1}, 1, delay, fixedPt);
	ch1(kindex, :) = patx + offset;
	ch2(kindex, :) = paty + offset;
    ch3m1(kindex, :) = pg.bufferPulse(patx, paty, 0, bufferPadding, bufferReset, bufferDelay);
end

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

% fill remaining channels with empty stuff
ch3 = zeros(nbrPatterns, cycleLength);
ch4 = zeros(nbrPatterns, cycleLength);
ch2m1 = ch3;
ch2m2 = ch4;
ch3 = ch3 + offset;
ch4 = ch4 + offset;

% make TekAWG file
TekPattern.exportTekSequence(path, basename, ch1, ch1m1, ch1m2, ch2, ch2m1, ch2m2, ch3, ch3m1, ch2m2, ch4, ch2m1, ch2m2);
clear ch1 ch2 ch3 ch4 ch1m1 ch1m2 ch2m1 ch2m2 ch3m1 pg
