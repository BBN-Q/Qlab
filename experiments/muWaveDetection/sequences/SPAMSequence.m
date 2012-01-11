function SPAMSequence(makePlot)

%Y90-(X180-Y180-X180-Y180)^n to determine phase difference between quadrature channels

if ~exist('makePlot', 'var')
    makePlot = true;
end
script = java.io.File(mfilename('fullpath'));
path = char(script.getParentFile().getParentFile().getParentFile().getParent());
addpath([path '/common/src'],'-END');
addpath([path '/common/src/util/'],'-END');

temppath = [char(script.getParent()) '\'];
path = 'U:\AWG\SPAM\';
basename = 'SPAM';

fixedPt = 6000;
cycleLength = 10000;
numsteps = 42;

% load config parameters from file
parent_path = char(script.getParentFile.getParent());
cfg_path = [parent_path '/cfg/'];
load([cfg_path 'pulseParamBundles.mat'], 'Ts', 'delays', 'measDelay', 'bufferDelays', 'bufferResets', 'bufferPaddings', 'offsets', 'piAmps', 'pi2Amps', 'sigmas', 'pulseTypes', 'deltas', 'buffers', 'pulseLengths');

delay = delays('12');
offset = offsets('12');
bufferPadding = bufferPaddings('12');
bufferReset = bufferResets('12');
bufferDelay = bufferDelays('12');

pg = PatternGen('dPiAmp', piAmps('q1'), 'dPiOn2Amp', pi2Amps('q1'), 'dSigma', sigmas('q1'), 'dPulseType', pulseTypes('q1'), 'dDelta', deltas('q1'), 'correctionT', Ts('12'), 'dBuffer', buffers('q1'), 'dPulseLength', pulseLengths('q1'), 'cycleLength', cycleLength);

angleShift = 0.0*pi/180;
SPAMBlock = {pg.pulse('Xp'),pg.pulse('Up','angle',pi/2+angleShift),pg.pulse('Xp'),pg.pulse('Up','angle',pi/2+angleShift)};

patseq = {};

for SPAMct = 0:10
    patseq{end+1} = {pg.pulse('Y90p')};
    for ct = 0:SPAMct
        patseq{end} = [patseq{end}, SPAMBlock];
    end
    patseq{end} = [patseq{end}, {pg.pulse('X90m')}];
end

patseq{end+1} = {pg.pulse('QId')};
patseq{end+1} = {pg.pulse('QId')};
patseq{end+1} = {pg.pulse('Xp')};
patseq{end+1} = {pg.pulse('Xp')};
    
nbrPatterns = 1*length(patseq);
fprintf('Number of sequences: %i\n', nbrPatterns);
ch1 = zeros(nbrPatterns, cycleLength);
ch2 = ch1;
ch3m1 = ch1;

for kindex = 1:nbrPatterns;
	[patx paty] = pg.getPatternSeq(patseq{kindex}, 1, delay, fixedPt);
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
    myn = 4;
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
