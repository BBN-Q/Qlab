function rabiAmpSequence56(makePlot)

if ~exist('makePlot', 'var')
    makePlot = true;
end
script = java.io.File(mfilename('fullpath'));
path = char(script.getParentFile().getParentFile().getParentFile().getParent());
addpath([path '/common/src'],'-END');
addpath([path '/common/src/util/'],'-END');

temppath = [char(script.getParent()) '\'];
path = 'U:\AWG\Rabi\';
pathAPS = 'U:\APS\Rabi\';
basename = 'Rabi56';

fixedPt = 6000;
cycleLength = 10000;
numsteps = 81;
stepsize = 200;

% load config parameters from file
parent_path = char(script.getParentFile.getParent());
cfg_path = [parent_path '/cfg/'];
load([cfg_path 'pulseParams.mat'], 'T', 'delay', 'measDelay', 'bufferDelay', 'bufferReset', 'bufferPadding', 'offset', 'piAmp', 'pi2Amp', 'sigma', 'pulseType', 'delta', 'buffer', 'pulseLength');
load([cfg_path 'pulseParams.mat'], 'offset2');
load([cfg_path 'pulseParams.mat'], 'T3', 'delay3', 'bufferDelay3', 'bufferReset3', 'bufferPadding3', 'offset3', 'piAmp3', 'pi2Amp3', 'sigma3', 'pulseType3', 'delta3', 'buffer3', 'pulseLength3');

pg = PatternGen('dPiAmp', piAmp3, 'dPiOn2Amp', pi2Amp3, 'dSigma', sigma3, 'dPulseLength', pulseLength3, 'correctionT', T3, 'dBuffer', buffer3, 'cycleLength', cycleLength);

amps = -((numsteps-1)/2)*stepsize:stepsize:((numsteps-1)/2)*stepsize;
patseq = {{'Xtheta', 'amp', amps}};
%patseq2 = {pg.pulse('Xtheta', 'amp', amps)};
patseq2 = {pg.pulse('QId')};

% pre-allocate space
ch1 = zeros(numsteps, cycleLength);
ch2 = ch1; ch3 = ch1; ch4 = ch1;
ch1m1 = ch1; ch1m2 = ch1; ch2m1 = ch1; ch2m2 = ch1;
ch3m1 = ch1; ch3m2 = ch1; ch4m1 = ch1; ch4m2 = ch1;

[ch5seq, ch6seq, ~, ~] = pg.build(patseq, numsteps, delay3, fixedPt);

for n = 1:numsteps;
    [patx paty] = pg.getPatternSeq(patseq2, n, delay, fixedPt);
	ch1(n, :) = patx + offset;
	ch2(n, :) = paty + offset;
    
	% ch5/6 buffer on ch2m1
    patx = pg.linkListToPattern(ch5seq, n)';
    paty = pg.linkListToPattern(ch6seq, n)';
    ch2m1(n, :) = pg.bufferPulse(patx, paty, 0, bufferPadding3, bufferReset3, bufferDelay3);
end

% trigger slave AWG (the APS) at beginning
% trigger digitizer at beginning of measurement pulse
measLength = 3000;
measSeq = {pg.pulse('M', 'width', measLength)};
for n = 1:numsteps;
	ch1m1(n,:) = pg.makePattern([], fixedPt-500, ones(100,1), cycleLength);
	ch1m2(n,:) = int32(pg.getPatternSeq(measSeq, n, measDelay, fixedPt+measLength));
    ch4m2(n,:) = pg.makePattern([], 5, ones(100,1), cycleLength);
end

if makePlot
    myn = 10;
    ch5 = pg.linkListToPattern(ch5seq, myn);
    ch6 = pg.linkListToPattern(ch6seq, myn);
    figure
    plot(ch5)
    hold on
    plot(ch6, 'r')
    plot(5000*ch1m2(myn,:), 'g')
    plot(1000*ch2m1(myn,:), 'r')
    %plot(5000*ch1m1(myn,:),'.')
    grid on
    hold off
end

% add offsets to unused channels
%ch1 = ch1 + offset;
%ch2 = ch2 + offset;
ch3 = ch3 + offset2;
ch4 = ch4 + offset2;

% make APS file
%exportAPSConfig(temppath, basename, ch5seq, ch6seq);
exportAPSConfig(temppath, basename, ch5seq, ch5seq, ch5seq, ch5seq);
disp('Moving APS file to destination');
movefile([temppath basename '.mat'], [pathAPS basename '.mat']);
% make TekAWG file
options = struct('m21_high', 2.0, 'm41_high', 2.0);
%TekPattern.exportTekSequence(temppath, basename, ch1, ch1m1, ch1m2, ch2, ch2m1, ch2m2, ch3, ch3m1, ch3m2, ch4, ch4m1, ch4m2, options);
TekPattern.exportTekSequence(temppath, basename, ch1, ch1m1, ch1m2, ch2, ch2m1, ch4m2, ch3, ch3m1, ch3m2, ch4, ch4m1, ch4m2, options);
disp('Moving AWG file to destination');
movefile([temppath basename '.awg'], [path basename '.awg']);
end
