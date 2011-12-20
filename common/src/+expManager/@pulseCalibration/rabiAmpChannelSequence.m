function [filename, nbrPatterns] = rabiAmpChannelSequence(obj, qubit, makePlot)

if ~exist('makePlot', 'var')
    makePlot = false;
end
script = java.io.File(mfilename('fullpath'));
path = char(script.getParentFile().getParentFile().getParent());
addpath(path,'-END');
addpath([path '/util/'],'-END');

temppath = [char(script.getParent()) '\'];
path = 'U:\AWG\Rabi\';
basename = 'RabiChannel';

IQchannels = obj.channelMap(qubit);
IQkey = [num2str(IQchannels{1}) num2str(IQchannels{2})];

fixedPt = 6000;
cycleLength = 10000;
numsteps = 41;
stepsize = 200;

nbrPatterns = numsteps;

% load config parameters dictionaries
load(obj.pulseParamPath, 'measDelay', 'delays',  'bufferDelays',  'bufferResets',  'bufferPaddings',  'offsets',  'sigmas',  'deltas', 'buffers',  'pulseLengths');

pg = PatternGen(...
    'dPiAmp', obj.pulseParams.piAmp, ...
    'dPiOn2Amp', obj.pulseParams.pi2Amp, ...
    'dSigma', sigmas(qubit), ...
    'dPulseType', obj.pulseParams.pulseType, ...
    'dDelta', obj.pulseParams.delta, ...
    'correctionT', obj.pulseParams.T, ...
    'dBuffer', buffers(qubit), ...
    'dPulseLength', pulseLengths(qubit), ...
    'cycleLength', cycleLength ...
    );

delay = delays(IQkey);
offset = offsets(IQkey);
bufferPadding = bufferPaddings(IQkey);
bufferReset = bufferResets(IQkey);
bufferDelay = bufferDelays(IQkey);

amps = 0:stepsize:(numsteps-1)*stepsize;
patseq = {pg.pulse('Xtheta', 'amp', amps)};

% pre-allocate space
ch1 = zeros(numsteps, cycleLength);
ch2 = ch1; ch3 = ch1; ch4 = ch1;
ch1m1 = ch1; ch1m2 = ch1; ch2m1 = ch1; ch2m2 = ch1;
ch3m1 = ch1; ch3m2 = ch1; ch4m1 = ch1; ch4m2 = ch1;
chI = ch1; chQ = ch1; chBuffer = ch1;

for n = 1:numsteps;
	[patx paty] = pg.getPatternSeq(patseq, n, delay, fixedPt);
	chI(n, :) = patx + offset;
	chQ(n, :) = paty + offset;
    chBuffer(n, :) = pg.bufferPulse(patx, paty, 0, bufferPadding, bufferReset, bufferDelay);
end

% trigger at fixedPt-500
% measure from (fixedPt:fixedPt+measLength)
measLength = 3000;
measSeq = {pg.pulse('M', 'width', measLength)};
for n = 1:numsteps;
	ch1m1(n,:) = pg.makePattern([], fixedPt-500, ones(100,1), cycleLength);
	ch1m2(n,:) = int32(pg.getPatternSeq(measSeq, n, measDelay, fixedPt+measLength));
end

% add channel offsets
ch1 = ch1 + offsets('12');
ch2 = ch2 + offsets('12');
ch3 = ch3 + offsets('34');
ch4 = ch4 + offsets('34');

% map control onto the physical channel
eval(['ch' num2str(IQchannels{1}) ' = chI;']);
eval(['ch' num2str(IQchannels{2}) ' = chQ;']);
eval(['ch' IQchannels{3} ' = chBuffer;']);

if makePlot
    myn = 30;
    figure
    plot(ch1(myn,:))
    hold on
    plot(ch2(myn,:), 'r')
    plot(ch3(myn,:), ':')
    plot(ch4(myn,:), 'r:')
    plot(5000*ch3m1(myn,:), 'g')
    plot(5000*ch4m1(myn,:), 'k')
    grid on
    hold off
end

% make TekAWG file
filename{1} = [pathAWG basename '.awg'];
if ~obj.testMode
    options = struct('m21_high', 2.0, 'm41_high', 2.0);
    TekPattern.exportTekSequence(temppath, basename, ch1, ch1m1, ch1m2, ch2, ch2m1, ch2m2, ch3, ch3m1, ch3m2, ch4, ch4m1, ch4m2, options);
    disp('Moving AWG file to destination');
    movefile([temppath basename '.awg'], [pathAWG basename '.awg']);
end
end
