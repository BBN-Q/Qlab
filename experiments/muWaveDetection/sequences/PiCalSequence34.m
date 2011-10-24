function PiCalSequence34(makePlot)

if ~exist('makePlot', 'var')
    makePlot = true;
end
script = java.io.File(mfilename('fullpath'));
path = char(script.getParentFile().getParentFile().getParentFile().getParent());
addpath([path '/common/src'],'-END');
addpath([path '/common/src/util/'],'-END');

temppath = [char(script.getParent()) '\'];
pathAWG = 'U:\AWG\PiCal\';
basename = 'PiCal34';

fixedPt = 6000;
cycleLength = 10000;
numsteps = 42;

% load config parameters from file
parent_path = char(script.getParentFile.getParent());
cfg_path = [parent_path '/cfg/'];
load([cfg_path 'pulseParams.mat'], 'T', 'delay', 'measDelay', 'bufferDelay', 'bufferReset', 'bufferPadding', 'offset', 'piAmp', 'pi2Amp', 'sigma', 'pulseType', 'delta', 'buffer', 'pulseLength');
load([cfg_path 'pulseParams.mat'], 'T2', 'delay2', 'bufferDelay2', 'bufferReset2', 'bufferPadding2', 'offset2', 'piAmp2', 'pi2Amp2', 'sigma2', 'pulseType2', 'delta2', 'buffer2', 'pulseLength2');
load([cfg_path 'pulseParams.mat'], 'T3', 'delay3', 'bufferDelay3', 'bufferReset3', 'bufferPadding3', 'offset3', 'piAmp3', 'pi2Amp3', 'sigma3', 'pulseType3', 'delta3', 'buffer3', 'pulseLength3');

pg21 = PatternGen('dPiAmp', piAmp, 'dPiOn2Amp', pi2Amp, 'dSigma', sigma, 'dPulseType', pulseType, 'dDelta', delta, 'correctionT', T, 'dBuffer', buffer, 'dPulseLength', pulseLength, 'cycleLength', cycleLength);
pg1 = PatternGen('dPiAmp', piAmp2, 'dPiOn2Amp', pi2Amp2, 'dSigma', sigma2, 'dPulseType', pulseType2, 'dDelta', delta2, 'correctionT', T2, 'dBuffer', buffer2, 'dPulseLength', pulseLength2, 'cycleLength', cycleLength);
pg2 = PatternGen('dPiAmp', piAmp3, 'dPiOn2Amp', pi2Amp3, 'dSigma', sigma3, 'dPulseType', pulseType3, 'dDelta', delta3, 'correctionT', T3, 'dBuffer', buffer3, 'dPulseLength', pulseLength3, 'cycleLength', cycleLength);
delayQ1 = delay2;
offsetQ1 = offset2;
delayQ2 = delay3;
offsetQ2 = offset3;
delayCR21 = delay;
offsetCR21 = offset;
pg = pg1;

% +X rotations
% QId
% X90p
% X90p Xp
% X90p Xp Xp
% X90p Xp Xp Xp
% X90p Xp Xp Xp Xp
patseq{1}={pg.pulse('QId')};
patseq{2}={pg.pulse('X90p')};
patseq{3}={pg.pulse('X90p'),pg.pulse('Xp')};
patseq{4}={pg.pulse('X90p'),pg.pulse('Xp'),pg.pulse('Xp')};
patseq{5}={pg.pulse('X90p'),pg.pulse('Xp'),pg.pulse('Xp'),pg.pulse('Xp')};

% -X rotations
% QId
% X90m
% X90m Xm
% X90m Xm Xm
% X90m Xm Xm Xm
% X90m Xm Xm Xm Xm
patseq{6}={pg.pulse('QId')};
patseq{7}={pg.pulse('X90m')};
patseq{8}={pg.pulse('X90m'),pg.pulse('Xm')};
patseq{9}={pg.pulse('X90m'),pg.pulse('Xm'),pg.pulse('Xm')};
patseq{10}={pg.pulse('X90m'),pg.pulse('Xm'),pg.pulse('Xm'),pg.pulse('Xm')};

% +Y rotations
% QId
% Y90p
% Y90p Yp
% Y90p Yp Yp
% Y90p Yp Yp Yp
% Y90p Yp Yp Yp Yp
patseq{11}={pg.pulse('QId')};
patseq{12}={pg.pulse('Y90p')};
patseq{13}={pg.pulse('Y90p'),pg.pulse('Yp')};
patseq{14}={pg.pulse('Y90p'),pg.pulse('Yp'),pg.pulse('Yp')};
patseq{15}={pg.pulse('Y90p'),pg.pulse('Yp'),pg.pulse('Yp'),pg.pulse('Yp')};

% -Y rotations
% QId
% Y90m
% Y90m Ym
% Y90m Ym Ym
% Y90m Ym Ym Ym
% Y90m Ym Ym Ym Ym
patseq{16}={pg.pulse('QId')};
patseq{17}={pg.pulse('Y90m')};
patseq{18}={pg.pulse('Y90m'),pg.pulse('Ym')};
patseq{19}={pg.pulse('Y90m'),pg.pulse('Ym'),pg.pulse('Ym')};
patseq{20}={pg.pulse('Y90m'),pg.pulse('Ym'),pg.pulse('Ym'),pg.pulse('Ym')};

% just a pi pulse for scaling
patseq{21}={pg.pulse('Xp')};

% double every pulse
nbrPatterns = 2*length(patseq);
fprintf('Number of sequences: %i\n', nbrPatterns);

% pre-allocate space
ch1 = zeros(nbrPatterns, cycleLength);
ch2 = ch1; ch3 = ch1; ch4 = ch1;
ch1m1 = ch1; ch1m2 = ch1; ch2m1 = ch1; ch2m2 = ch1;
ch3m1 = ch1; ch3m2 = ch1; ch4m1 = ch1; ch4m2 = ch1;

for kindex = 1:nbrPatterns;
	[patx paty] = pg.getPatternSeq(patseq{floor((kindex-1)/2)+1}, 1, delayQ1, fixedPt);
	ch3(kindex, :) = patx + offsetQ1;
	ch4(kindex, :) = paty + offsetQ1;
    ch4m1(kindex, :) = pg.bufferPulse(patx, paty, 0, bufferPadding2, bufferReset2, bufferDelay2);
end

% trigger at beginning of measurement pulse
% measure from (6000:9500)
measLength = 3500;
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
    plot(ch3(myn,:))
    hold on
    plot(ch4(myn,:), 'r')
    plot(5000*ch4m1(myn,:), 'k')
    plot(5000*ch1m1(myn,:),'.')
    plot(5000*ch1m2(myn,:), 'g')
    grid on
    hold off
end

% add offsets to unused channels
ch1 = ch1 + offset;
ch2 = ch2 + offset;
%ch3 = ch3 + offset2;
%ch4 = ch4 + offset2;

% make TekAWG file
options = struct('m21_high', 2.0, 'm41_high', 2.0);
TekPattern.exportTekSequence(temppath, basename, ch1, ch1m1, ch1m2, ch2, ch2m1, ch2m2, ch3, ch3m1, ch3m2, ch4, ch4m1, ch4m2, options);
disp('Moving AWG file to destination');
movefile([temppath basename '.awg'], [pathAWG basename '.awg']);
end
