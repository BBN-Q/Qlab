% clear classes;
% clear import;
addpath('../../common/src','-END');
addpath('../../common/src/util/','-END');

clear patseq pg 

path = 'U:\AWG\PiCal\';
basename = 'PiCal';
delay = -10;
measDelay = -53;
bufferDelay = 58;
bufferReset = 100;
bufferPadding = 20;
fixedPt = 6000;
cycleLength = 10000;
offset = 8192;
pulseOffset = offset ;
numsteps = 42;
piAmp = 7875;
pi2Amp = 3225;
sigma = 4;
pulseType = 'drag';
delta = -1.5; % DRAG parameter
pulseLength = 4*sigma;

% load correction matrix from file
cfg_path = '../cfg/';
%cfg_path = 'cfg/';
load([cfg_path 'mixercal.mat'], 'T');
if ~exist('T', 'var') % check that it loaded
    T = eye(2);
end
%T = eye(2);
T = [0.970  0; 0 1.0];

pg = PatternGen('dPiAmp', piAmp, 'dPiOn2Amp', pi2Amp, 'dSigma', sigma, 'dPulseType', pulseType, 'dDelta', delta, 'correctionT', T, 'dBuffer', 5, 'dPulseLength', pulseLength, 'cycleLength', cycleLength);

% +X rotations
% QId
% X90p Xp
% X90p Xp Xp
% X90p Xp Xp Xp
% X90p Xp Xp Xp Xp
patseq{1}={pg.pulse('QId')};
patseq{2}={pg.pulse('X90p'),pg.pulse('Xp')};
patseq{3}={pg.pulse('X90p'),pg.pulse('Xp'),pg.pulse('Xp')};
patseq{4}={pg.pulse('X90p'),pg.pulse('Xp'),pg.pulse('Xp'),pg.pulse('Xp')};
patseq{5}={pg.pulse('X90p'),pg.pulse('Xp'),pg.pulse('Xp'),pg.pulse('Xp'),pg.pulse('Xp')};

% -X rotations
% QId
% X90m Xm
% X90m Xm Xm
% X90m Xm Xm Xm
% X90m Xm Xm Xm Xm
patseq{6}={pg.pulse('QId')};
patseq{7}={pg.pulse('X90m'),pg.pulse('Xm')};
patseq{8}={pg.pulse('X90m'),pg.pulse('Xm'),pg.pulse('Xm')};
patseq{9}={pg.pulse('X90m'),pg.pulse('Xm'),pg.pulse('Xm'),pg.pulse('Xm')};
patseq{10}={pg.pulse('X90m'),pg.pulse('Xm'),pg.pulse('Xm'),pg.pulse('Xm'),pg.pulse('Xm')};

% +Y rotations
% QId
% Y90p Yp
% Y90p Yp Yp
% Y90p Yp Yp Yp
% Y90p Yp Yp Yp Yp
patseq{11}={pg.pulse('QId')};
patseq{12}={pg.pulse('Y90p'),pg.pulse('Yp')};
patseq{13}={pg.pulse('Y90p'),pg.pulse('Yp'),pg.pulse('Yp')};
patseq{14}={pg.pulse('Y90p'),pg.pulse('Yp'),pg.pulse('Yp'),pg.pulse('Yp')};
patseq{15}={pg.pulse('Y90p'),pg.pulse('Yp'),pg.pulse('Yp'),pg.pulse('Yp'),pg.pulse('Yp')};

% -Y rotations
% QId
% Y90m Ym
% Y90m Ym Ym
% Y90m Ym Ym Ym
% Y90m Ym Ym Ym Ym
patseq{16}={pg.pulse('QId')};
patseq{17}={pg.pulse('Y90m'),pg.pulse('Ym')};
patseq{18}={pg.pulse('Y90m'),pg.pulse('Ym'),pg.pulse('Ym')};
patseq{19}={pg.pulse('Y90m'),pg.pulse('Ym'),pg.pulse('Ym'),pg.pulse('Ym')};
patseq{20}={pg.pulse('Y90m'),pg.pulse('Ym'),pg.pulse('Ym'),pg.pulse('Ym'),pg.pulse('Ym')};

% just a pi pulse for scaling
patseq{21}={pg.pulse('Xp')};

% double every pulse
nbrPatterns = 2*length(patseq);
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
%clear ch1 ch2 ch3 ch4 ch1m1 ch1m2 ch2m1 ch2m2 ch3m1 pg
