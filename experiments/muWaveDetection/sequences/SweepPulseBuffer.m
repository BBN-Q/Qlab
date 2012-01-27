function SweepPulseBuffer(makePlot)

%Sweep the pulse buffer across a 180 degree pulse to determine the relative
%delays.  Basically we're looking for a trapezoid as the buffer pulse sweeps across the main pulse 

if ~exist('makePlot', 'var')
    makePlot = true;
end
script = java.io.File(mfilename('fullpath'));
path = char(script.getParentFile().getParentFile().getParentFile().getParent());
addpath([path '/common/src'],'-END');
addpath([path '/common/src/util/'],'-END');

temppath = [char(script.getParent()) '\'];
path = 'U:\AWG\SweepBufferPulse\';
basename = 'SweepBufferPulse';

fixedPt = 6000;
cycleLength = 10000;
numpoints = 50;
step = 6;

% load config parameters from file
parent_path = char(script.getParentFile.getParent());
cfg_path = [parent_path '/cfg/'];
load([cfg_path 'pulseParamBundles.mat'], 'Ts', 'delays', 'measDelay', 'bufferDelays', 'bufferResets', 'bufferPaddings', 'offsets', 'piAmps', 'pi2Amps', 'sigmas', 'pulseTypes', 'deltas', 'buffers', 'pulseLengths');


pg = PatternGen('dPiAmp', piAmps('q1'), 'dPiOn2Amp', pi2Amps('q1'), 'dSigma', sigmas('q1'), 'dPulseType', pulseTypes('q1'), 'dDelta', deltas('q1'), 'correctionT', Ts('12'), 'dBuffer', buffers('q1'), 'dPulseLength', pulseLengths('q1'), 'cycleLength', cycleLength);

patseq = {pg.pulse('Xtheta','amp',1000,'width',64,'pType','square'), pg.pulse('QId','width',88)};
bufferSweep = 0:step:(numpoints-1)*step;
patseqBuffer = {pg.pulse('M','width',88), pg.pulse('QId','width',bufferSweep)};

ch1 = zeros(numpoints, cycleLength);
ch2 = ch1;
ch3m1 = ch1;

for kindex = 1:numpoints;
	[patx paty] = pg.getPatternSeq(patseq, 1, delays('12'), fixedPt);
	ch1(kindex, :) = patx + offsets('12');
	ch2(kindex, :) = paty + offsets('12');
    [patx ~] = pg.getPatternSeq(patseqBuffer, kindex, delays('12'), fixedPt);
	ch3m1(kindex, :) = int32(patx);
end

% trigger at beginning of measurement pulse
% measure from (6000:9500)
measLength = 3500;
measSeq = {pg.pulse('M', 'width', measLength)};
ch1m1 = zeros(numpoints, cycleLength);
ch1m2 = zeros(numpoints, cycleLength);
for n = 1:numpoints;
	ch1m1(n,:) = pg.makePattern([], fixedPt-500, ones(100,1), cycleLength);
	ch1m2(n,:) = int32(pg.getPatternSeq(measSeq, n, measDelay, fixedPt+measLength));
end

if makePlot
    myn = 40;
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
ch3 = zeros(numpoints, cycleLength);
ch4 = zeros(numpoints, cycleLength);
ch2m1 = ch3;
ch2m2 = ch4;
ch3 = ch3 + offsets('34');
ch4 = ch4 + offsets('34');

% make TekAWG file
TekPattern.exportTekSequence(temppath, basename, ch1, ch1m1, ch1m2, ch2, ch2m1, ch2m2, ch3, ch3m1, ch2m2, ch4, ch2m1, ch2m2);
disp('Moving AWG file to destination');
movefile([temppath basename '.awg'], [path basename '.awg']);
end
