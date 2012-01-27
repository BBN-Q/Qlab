function JayPiCalSequence(makePlot)

if ~exist('makePlot', 'var')
    makePlot = true;
end
script = java.io.File(mfilename('fullpath'));
path = char(script.getParentFile().getParentFile().getParentFile().getParent());
addpath([path '/common/src'],'-END');
addpath([path '/common/src/util/'],'-END');

temppath = [char(script.getParent()) '\'];
path = 'U:\AWG\PiCal\';
jayPulsePath = ['U:\Blake\outputX.dat'];
basename = 'JayPiCal';

fixedPt = 6000;
cycleLength = 10000;
numsteps = 42;

% load config parameters from file
parent_path = char(script.getParentFile.getParent());
cfg_path = [parent_path '/cfg/'];
load([cfg_path 'pulseParams.mat'], 'T', 'delay', 'measDelay', 'bufferDelay', 'bufferReset', 'bufferPadding', 'offset', 'piAmp', 'pi2Amp', 'sigma', 'pulseType', 'delta', 'buffer', 'pulseLength');

pulseLength = 144;
arbDelta = 1.0;
pulseType = 'arbitrary';
pg = PatternGen('dArbfname', jayPulsePath, 'dPiAmp', piAmp, 'dPiOn2Amp', pi2Amp, 'dSigma', sigma, 'dPulseType', pulseType, 'dDelta', delta, 'correctionT', T, 'dBuffer', buffer, 'dPulseLength', pulseLength, 'cycleLength', cycleLength);

% QId
% +X rotations
X90p = pg.pulse('X90p', 'pType', 'drag', 'width', 4*sigma );
Xp = pg.pulse('Xp', 'delta', arbDelta);
patseq{1}={pg.pulse('QId')};
patseq{2}={X90p};
patseq{3}={X90p, Xp};
patseq{4}={X90p, Xp, Xp};
patseq{5}={X90p, Xp, Xp, Xp};
patseq{6}={X90p, Xp, Xp, Xp, Xp};

% QId
% -X rotations
X90m = pg.pulse('X90m', 'pType', 'drag', 'width', 4*sigma );
Xm = pg.pulse('Xm', 'delta', arbDelta);
patseq{7}= {pg.pulse('QId')};
patseq{8}= {X90m};
patseq{9}= {X90m, Xm};
patseq{10}={X90m, Xm, Xm};
patseq{11}={X90m, Xm, Xm, Xm};
patseq{12}={X90m, Xm, Xm, Xm, Xm};

% QId
% +Y rotations
Y90p = pg.pulse('Y90p', 'pType', 'drag', 'width', 4*sigma );
Yp = pg.pulse('Yp', 'delta', arbDelta);
patseq{13}={pg.pulse('QId')};
patseq{14}={Y90p};
patseq{15}={Y90p, Yp};
patseq{16}={Y90p, Yp, Yp};
patseq{17}={Y90p, Yp, Yp, Yp};
patseq{18}={Y90p, Yp, Yp, Yp, Yp};

% QId
% -Y rotations
Y90m = pg.pulse('Y90m', 'pType', 'drag', 'width', 4*sigma );
Ym = pg.pulse('Ym', 'delta', arbDelta);
patseq{19}={pg.pulse('QId')};
patseq{20}={Y90m};
patseq{21}={Y90m, Ym};
patseq{22}={Y90m, Ym, Ym};
patseq{23}={Y90m, Ym, Ym, Ym};
patseq{24}={Y90m, Ym, Ym, Ym, Ym};

% just a pi pulse for scaling
patseq{25}={pg.pulse('Xtheta', 'amp', pi2Amp*2, 'pType', 'drag', 'width', 4*sigma)};

% double every pulse
nbrPatterns = 2*length(patseq);
fprintf('Number of sequences: %i\n', nbrPatterns);
ch1 = zeros(nbrPatterns, cycleLength);
ch2 = ch1;
ch3m1 = ch1;

for kindex = 1:nbrPatterns;
	[patx paty] = pg.getPatternSeq(patseq{floor((kindex-1)/2)+1}, 1, delay, fixedPt);
	ch1(kindex, :) = patx + offset;
	ch2(kindex, :) = paty + offset;
    ch3m1(kindex, :) = pg.bufferPulse(patx, paty, 0, bufferPadding, bufferReset, bufferDelay);
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
TekPattern.exportTekSequence(temppath, basename, ch1, ch1m1, ch1m2, ch2, ch2m1, ch2m2, ch3, ch3m1, ch2m2, ch4, ch2m1, ch2m2);
disp('Moving AWG file to destination');
movefile([temppath basename '.awg'], [path basename '.awg']);
end
