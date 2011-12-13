function [filename, nbrPatterns] = Pi2CalChannelSequence(obj, qubit, direction, makePlot)

if ~exist('direction', 'var')
    direction = 'X';
elseif ~strcmp(direction, 'X') && ~strcmp(direction, 'Y')
    warning('Unknown direction, assuming X');
    direction = 'X';
end
if ~exist('makePlot', 'var')
    makePlot = false;
end

script = java.io.File(mfilename('fullpath'));
path = char(script.getParentFile().getParentFile().getParent());
addpath(path,'-END');
addpath([path '/util/'],'-END');

temppath = [char(script.getParent()) '\'];
pathAWG = 'U:\AWG\Pi2Cal\';
basename = 'Pi2CalChannel';

IQchannels = obj.channelMap(qubit);
IQkey = [num2str(IQchannels{1}) num2str(IQchannels{2})];

fixedPt = 6000;
cycleLength = 10000;
numPi2s = 9; % number of odd numbered pi/2 sequences for each rotation direction

% load config parameters dictionaries
load(obj.pulseParamPath, 'measDelay', 'delays',  'bufferDelays',  'bufferResets',  'bufferPaddings',  'offsets',  'sigmas',  'deltas', 'buffers',  'pulseLengths');

pg1 = PatternGen(...
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

pulseLib = containers.Map();
pulses = {'QId', 'X90p', 'X90m', 'Y90p', 'Y90m'};
for p = pulses
    pname = cell2mat(p);
    pulseLib(pname) = pg1.pulse(pname);
end

patseq{1} = {pulseLib('QId')};

sindex = 1;

% +X rotations
% (1, 3, 5, 7, 9, 11, 13, 15, 17) x X90p
for j = 1:numPi2s
    for k = 1:(1+2*(j-1))
        patseq{sindex + j}{k} = pulseLib([direction '90p']);
    end
end
sindex = sindex + numPi2s;

% -X rotations
% (1, 3, 5, 7, 9, 11, ...) x X90m
for j = 1:numPi2s
    for k = 1:(1+2*(j-1))
        patseq{sindex + j}{k} = pulseLib([direction '90m']);
    end
end

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
	[patx paty] = pg1.getPatternSeq(patseq{floor((kindex-1)/2)+1}, 1, delay, fixedPt);
	chI(kindex, :) = patx + offset;
	chQ(kindex, :) = paty + offset;
    chBuffer(kindex, :) = pg1.bufferPulse(patx, paty, 0, bufferPadding, bufferReset, bufferDelay);
end

% trigger at beginning of measurement pulse
% measure from (6000:9000)
measLength = 3000;
measSeq = {pg1.pulse('M', 'width', measLength)};
for n = 1:nbrPatterns;
	ch1m1(n,:) = pg1.makePattern([], fixedPt-500, ones(100,1), cycleLength);
	ch1m2(n,:) = int32(pg1.getPatternSeq(measSeq, n, measDelay, fixedPt+measLength));
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

