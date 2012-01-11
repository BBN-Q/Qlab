function RandomizedBenchmarking(makePlot)

if ~exist('makePlot', 'var')
    makePlot = true;
end
script = java.io.File(mfilename('fullpath'));
path = char(script.getParentFile().getParentFile().getParentFile().getParent());
addpath([path '/common/src'],'-END');
addpath([path '/common/src/util/'],'-END');

temppath = [char(script.getParent()) '\'];

pathAWG = 'U:\AWG\RB\';
basename = 'RB';

fixedPt = 7000;
cycleLength = 10000;
numsteps = 356;

% load config parameters from file
parent_path = char(script.getParentFile.getParent());
cfg_path = [parent_path '/cfg/'];
load([cfg_path 'pulseParamBundles.mat'], 'Ts', 'delays', 'measDelay', 'bufferDelays', 'bufferResets', 'bufferPaddings', 'offsets', 'piAmps', 'pi2Amps', 'sigmas', 'pulseTypes', 'deltas', 'buffers', 'pulseLengths');

pg1 = PatternGen('dPiAmp', piAmps('q1'), 'dPiOn2Amp', pi2Amps('q1'), 'dSigma', sigmas('q1'), 'dPulseType', pulseTypes('q1'), 'dDelta', deltas('q1'), 'correctionT', Ts('12'), 'dBuffer', buffers('q1'), 'dPulseLength', pulseLengths('q1'), 'cycleLength', cycleLength);
pg2 = PatternGen('dPiAmp', piAmps('q2'), 'dPiOn2Amp', pi2Amps('q2'), 'dSigma', sigmas('q2'), 'dPulseType', pulseTypes('q2'), 'dDelta', deltas('q2'), 'correctionT', Ts('34'), 'dBuffer', buffers('q2'), 'dPulseLength', pulseLengths('q2'), 'cycleLength', cycleLength);
pg = pg1;

% load in random Clifford sequences from text file
fid = fopen('RBsequences.txt');
if ~fid
    error('Could not open Clifford sequence list')
end

tline = fgetl(fid);
lnum = 1;
while ischar(tline)
    seqStrings{lnum} = textscan(tline, '%s');
    lnum = lnum + 1;
    tline = fgetl(fid);
end
fclose(fid);

% convert sequence strings into pulses
pulseLibrary = containers.Map();
for ii = 1:length(seqStrings)
    for jj = 1:length(seqStrings{ii}{1})
        pulseName = seqStrings{ii}{1}{jj};
        if ~isKey(pulseLibrary, pulseName)
            pulseLibrary(pulseName) = pg.pulse(pulseName);
        end
        currentSeq{jj} = pulseLibrary(pulseName);
    end
    patseq{ii} = currentSeq(1:jj);
end

calseq = {{pg.pulse('QId')},{pg.pulse('QId')},{pg.pulse('Xp')},{pg.pulse('Xp')}};
calsteps = length(calseq);
nbrPatterns = length(patseq);

% pre-allocate space
ch1 = zeros(nbrPatterns+length(calseq), cycleLength);
ch2 = ch1; ch3 = ch1; ch4 = ch1;
ch1m1 = ch1; ch1m2 = ch1; ch2m1 = ch1; ch2m2 = ch1;
ch3m1 = ch1; ch3m2 = ch1; ch4m1 = ch1; ch4m2 = ch1;

for kindex = 1:nbrPatterns;
	[patx paty] = pg.getPatternSeq(patseq{kindex}, 1, delays('12'), fixedPt);
	ch1(kindex, :) = patx + offsets('12');
	ch2(kindex, :) = paty + offsets('12');
    ch3m1(kindex, :) = pg.bufferPulse(patx, paty, 0, bufferPaddings('12'), bufferResets('12'), bufferDelays('12'));
end

for n = 1:calsteps;
    [patx paty] = pg.getPatternSeq(calseq{n}, 1, delays('12'), fixedPt);
	ch1(n+nbrPatterns, :) = patx + offsets('12');
	ch2(n+nbrPatterns, :) = paty + offsets('12');
    ch3m1(n+nbrPatterns, :) = pg.bufferPulse(patx, paty, 0, bufferPaddings('12'), bufferResets('12'), bufferDelays('12'));
end

nbrPatterns = nbrPatterns + calsteps;
fprintf('Number of sequences: %i\n', nbrPatterns);

% trigger at beginning of measurement pulse
% measure from (6000:9000)
measLength = 3000;
measSeq = {pg.pulse('M', 'width', measLength)};
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

    figure
    subplot(2,1,1)
    imagesc(ch1);
    subplot(2,1,2)
    imagesc(ch2);
end

% add offsets to unused channels
%ch1 = ch1 + offset;
%ch2 = ch2 + offset;
ch3 = ch3 + offsets('34');
ch4 = ch4 + offsets('34');

% make TekAWG file
options = struct('m21_high', 2.0, 'm41_high', 2.0);
TekPattern.exportTekSequence(temppath, basename, ch1, ch1m1, ch1m2, ch2, ch2m1, ch2m2, ch3, ch3m1, ch3m2, ch4, ch4m1, ch4m2, options);
disp('Moving AWG file to destination');
movefile([temppath basename '.awg'], [path basename '.awg']);
end
