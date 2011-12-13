function PiCalChannelSequence(obj, qubit, direction, makePlot)

if ~exist('direction', 'var')
    direction = 'X';
elseif ~strcmp(direction, 'X') && ~strcmp(direction, 'Y')
    warning('Unknown direction, assuming X');
    direction = 'X';
end
if ~exist('makePlot', 'var')
    makePlot = true;
end
script = java.io.File(mfilename('fullpath'));
path = char(script.getParentFile().getParentFile().getParent());
addpath(path,'-END');
addpath([path '/util/'],'-END');

temppath = [char(script.getParent()) '\'];
pathAWG = 'U:\AWG\PiCal\';
basename = 'PiCalChannel';

IQchannels = obj.channelMap(qubit);
IQkey = [num2str(IQchannels{1}) num2str(IQchannels{2})];

fixedPt = 6000;
cycleLength = 10000;
numsteps = 42;

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

% +X/Y rotations
X90p = pg.pulse([direction '90p']);
Xp   = pg.pulse([direction 'p']);
patseq{1}={X90p};
patseq{2}={X90p, Xp};
patseq{3}={X90p, Xp, Xp};
patseq{4}={X90p, Xp, Xp, Xp};
patseq{5}={X90p, Xp, Xp, Xp, Xp};
patseq{6}={X90p, Xp, Xp, Xp, Xp, Xp};
patseq{7}={X90p, Xp, Xp, Xp, Xp, Xp, Xp};
patseq{8}={X90p, Xp, Xp, Xp, Xp, Xp, Xp, Xp};
patseq{9}={X90p, Xp, Xp, Xp, Xp, Xp, Xp, Xp, Xp};

% -X/Y rotations
X90m = pg.pulse([direction '90m']);
Xm   = pg.pulse([direction 'm']);
patseq{10}={X90m};
patseq{11}={X90m, Xm};
patseq{12}={X90m, Xm, Xm};
patseq{13}={X90m, Xm, Xm, Xm};
patseq{14}={X90m, Xm, Xm, Xm, Xm};
patseq{15}={X90m, Xm, Xm, Xm, Xm, Xm};
patseq{16}={X90m, Xm, Xm, Xm, Xm, Xm, Xm};
patseq{17}={X90m, Xm, Xm, Xm, Xm, Xm, Xm, Xm};
patseq{18}={X90m, Xm, Xm, Xm, Xm, Xm, Xm, Xm, Xm};

% double every pulse
nbrPatterns = 2*length(patseq);
fprintf('Number of sequences: %i\n', nbrPatterns);

% pre-allocate space
ch1 = zeros(nbrPatterns, cycleLength);
ch2 = ch1; ch3 = ch1; ch4 = ch1;
ch1m1 = ch1; ch1m2 = ch1; ch2m1 = ch1; ch2m2 = ch1;
ch3m1 = ch1; ch3m2 = ch1; ch4m1 = ch1; ch4m2 = ch1;
chI = ch1; chQ = ch1; chBuffer = ch1;

for kindex = 1:nbrPatterns;
	[patx paty] = pg.getPatternSeq(patseq{floor((kindex-1)/2)+1}, 1, delay, fixedPt);
	chI(kindex, :) = patx + offset;
	chQ(kindex, :) = paty + offset;
    chBuffer(kindex, :) = pg.bufferPulse(patx, paty, 0, bufferPadding, bufferReset, bufferDelay);
end

% trigger at beginning of measurement pulse
% measure from (6000:9500)
measLength = 3000;
measSeq = {pg.pulse('M', 'width', measLength)};
for n = 1:nbrPatterns;
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
    myn = 18;
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
% options = struct('m21_high', 2.0, 'm41_high', 2.0);
% TekPattern.exportTekSequence(temppath, basename, ch1, ch1m1, ch1m2, ch2, ch2m1, ch2m2, ch3, ch3m1, ch3m2, ch4, ch4m1, ch4m2, options);
% disp('Moving AWG file to destination');
% movefile([temppath basename '.awg'], [pathAWG basename '.awg']);
end
