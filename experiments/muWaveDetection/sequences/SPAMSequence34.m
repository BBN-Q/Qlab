function SPAMSequence34(makePlot)

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
basename = 'SPAM34';

fixedPt = 6000;
cycleLength = 10000;
numsteps = 42;

% load config parameters from file
parent_path = char(script.getParentFile.getParent());
cfg_path = [parent_path '/cfg/'];
load([cfg_path 'pulseParamBundles.mat'], 'Ts', 'delays', 'measDelay', 'bufferDelays', 'bufferResets', 'bufferPaddings', 'offsets', 'piAmps', 'pi2Amps', 'sigmas', 'pulseTypes', 'deltas', 'buffers', 'pulseLengths');

delay = delays('34');
offset = offsets('34');
bufferPadding = bufferPaddings('34');
bufferReset = bufferResets('34');
bufferDelay = bufferDelays('34');
pg = PatternGen('dPiAmp', piAmps('q2'), 'dPiOn2Amp', pi2Amps('q2'), 'dSigma', sigmas('q2'), 'dPulseType', pulseTypes('q2'), 'dDelta', deltas('q2'), 'correctionT', Ts('34'), 'dBuffer', buffers('q2'), 'dPulseLength', pulseLengths('q2'), 'cycleLength', cycleLength);

angleShift = -1*pi/180;
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
% pre-allocate space
ch1 = zeros(nbrPatterns, cycleLength);
ch2 = ch1; ch3 = ch1; ch4 = ch1;
ch1m1 = ch1; ch1m2 = ch1; ch2m1 = ch1; ch2m2 = ch1;
ch3m1 = ch1; ch3m2 = ch1; ch4m1 = ch1; ch4m2 = ch1;

for kindex = 1:nbrPatterns;
	[patx paty] = pg.getPatternSeq(patseq{kindex}, 1, delay, fixedPt);
	ch3(kindex, :) = patx + offset;
	ch4(kindex, :) = paty + offset;
    ch4m1(kindex, :) = pg.bufferPulse(patx, paty, 0, bufferPadding, bufferReset, bufferDelay);
end

% trigger at beginning of measurement pulse
% measure from (6000:9500)
measLength = 3500;
measSeq = {pg.pulse('M', 'width', measLength)};
for n = 1:nbrPatterns;
	ch1m1(n,:) = pg.makePattern([], fixedPt-500, ones(100,1), cycleLength);
	ch1m2(n,:) = int32(pg.getPatternSeq(measSeq, n, measDelay, fixedPt+measLength));
end

if makePlot
    myn = 4;
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
movefile([temppath basename '.awg'], [path basename '.awg']);
end
