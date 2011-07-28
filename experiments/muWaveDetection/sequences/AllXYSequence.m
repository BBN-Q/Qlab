% clear classes;
% clear import;
addpath('../../common/src','-END');
addpath('../../common/src/util/','-END');

clear patseq pg 

path = 'U:\AWG\AllXY\';
basename = 'AllXY';
delay = -10;
measDelay = -53;
bufferDelay = 58;
bufferReset = 100;
bufferPadding = 10;
fixedPt = 6000;
cycleLength = 10000;
offset = 8192;
numsteps = 50;
piAmp = 7875;
pi2Amp = 3200;
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
T = [0.970 0; 0 1.0];

pg = PatternGen('dPiAmp', piAmp, 'dPiOn2Amp', pi2Amp, 'dSigma', sigma, 'dPulseType', pulseType, 'dDelta', delta, 'correctionT', T, 'dBuffer', 5, 'dPulseLength', pulseLength, 'cycleLength', cycleLength);

% ground state:
% QId
% Xp Xm
% Yp Ym
% Xp Xp
% Yp Yp
% Xp Yp
% Yp Xp
% Yp Xm
% Xp Ym

patseq{1}={pg.pulse('QId')};

patseq{2}={pg.pulse('Xp'),pg.pulse('Xm')};
patseq{3}={pg.pulse('Yp'),pg.pulse('Ym')};
patseq{4}={pg.pulse('Xp'),pg.pulse('Xp')};
patseq{5}={pg.pulse('Yp'),pg.pulse('Yp')};

patseq{6}={pg.pulse('Xp'),pg.pulse('Yp')};
patseq{7}={pg.pulse('Yp'),pg.pulse('Xp')};

patseq{8}={pg.pulse('Yp'),pg.pulse('Xm')};
patseq{9}={pg.pulse('Xp'),pg.pulse('Ym')};

% superposition state:
% -1 * eps error
% X90p
% Y90p
% X90m
% Y90m

% 0 * eps error (phase sensitive)
% X90p Y90p
% Y90p X90p
% X90m Y90m
% Y90m X90m

% +1 * eps error
% Xp Y90p
% Yp X90p
% Xp Y90m
% Yp X90m
% X90p Yp
% Y90p Xp

% +3 * eps error
% Xp X90p
% Yp Y90p
% Xm X90m
% Ym Y90m

patseq{10}={pg.pulse('X90p')};
patseq{11}={pg.pulse('Y90p')};
patseq{12}={pg.pulse('X90m')};
patseq{13}={pg.pulse('Y90m')};

patseq{14}={pg.pulse('X90p'), pg.pulse('Y90p')};
patseq{15}={pg.pulse('Y90p'), pg.pulse('X90p')};
patseq{16}={pg.pulse('X90m'), pg.pulse('Y90m')};
patseq{17}={pg.pulse('Y90m'), pg.pulse('X90m')};


patseq{18}={pg.pulse('Xp'),pg.pulse('Y90p')};
patseq{19}={pg.pulse('Yp'),pg.pulse('X90p')};
patseq{20}={pg.pulse('Xp'),pg.pulse('Y90m')};
patseq{21}={pg.pulse('Yp'),pg.pulse('X90m')};
patseq{22}={pg.pulse('X90p'),pg.pulse('Yp')};
patseq{23}={pg.pulse('Y90p'),pg.pulse('Xp')};


patseq{24}={pg.pulse('Xp'),pg.pulse('X90p')};
patseq{25}={pg.pulse('Yp'),pg.pulse('Y90p')};
patseq{26}={pg.pulse('Xm'),pg.pulse('X90m')};
patseq{27}={pg.pulse('Ym'),pg.pulse('Y90m')};

% excited state;
% Xp
% Xm
% Yp
% Ym
% X90p X90p
% X90m X90m
% Y90p Y90p
% Y90m Y90m

patseq{28} = {pg.pulse('QId'),pg.pulse('Xp')};
patseq{29} = {pg.pulse('QId'),pg.pulse('Xm')};
patseq{30} = {pg.pulse('QId'),pg.pulse('Yp')};
patseq{31} = {pg.pulse('QId'),pg.pulse('Ym')};

patseq{32} = {pg.pulse('X90p'),pg.pulse('X90p')};
patseq{33} = {pg.pulse('X90m'),pg.pulse('X90m')};
patseq{34} = {pg.pulse('Y90p'),pg.pulse('Y90p')};
patseq{35} = {pg.pulse('Y90m'),pg.pulse('Y90m')};

%for iindex = 1:nbrPulses
%    for jindex = 1:nbrPulses
%        patseq{(iindex-1)*nbrPulses+jindex} = {AllPulses{iindex}, AllPulses{jindex}};
%    end
%end

% double every pulse
nbrPatterns = 2*length(patseq);

ch1 = zeros(numsteps, cycleLength);
ch2 = ch1;
ch3m1 = ch1;

for kindex = 1:nbrPatterns;
	[patx paty] = pg.getPatternSeq(patseq{floor((kindex-1)/2)+1}, 1, delay, fixedPt);
	ch1(kindex, :) = patx + offset;
	ch2(kindex, :) = paty + offset;
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
ch2m2 = ch4;
ch3 = ch3 + offset;
ch4 = ch4 + offset;

% make TekAWG file
TekPattern.exportTekSequence(path, basename, ch1, ch1m1, ch1m2, ch2, ch2m1, ch2m2, ch3, ch3m1, ch2m2, ch4, ch2m1, ch2m2);
clear ch1 ch2 ch3 ch4 ch1m1 ch1m2 ch2m1 ch2m2 ch3m1
