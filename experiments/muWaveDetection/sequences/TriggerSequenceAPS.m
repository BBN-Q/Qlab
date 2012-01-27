function TriggerSequenceAPS(makePlot)

if ~exist('makePlot', 'var')
    makePlot = true;
end
script = java.io.File(mfilename('fullpath'));
path = char(script.getParentFile().getParentFile().getParentFile().getParent());
addpath([path '/common/src'],'-END');
addpath([path '/common/src/util/'],'-END');

temppath = [char(script.getParent()) '\'];
pathAPS = 'U:\APS\Trigger\';
basename = 'Trigger';

fixedPt = 6000;
cycleLength = 10000;
numsteps = 1;

% load config parameters from file
parent_path = char(script.getParentFile.getParent());
cfg_path = [parent_path '/cfg/'];
load([cfg_path 'pulseParams.mat'], 'T', 'delay', 'measDelay', 'bufferDelay', 'bufferReset', 'bufferPadding', 'offset', 'piAmp', 'pi2Amp', 'sigma', 'pulseType', 'delta', 'buffer', 'pulseLength');
load([cfg_path 'pulseParams.mat'], 'offset2');
load([cfg_path 'pulseParams.mat'], 'T3', 'delay3', 'bufferDelay3', 'bufferReset3', 'bufferPadding3', 'offset3', 'piAmp3', 'pi2Amp3', 'sigma3', 'pulseType3', 'delta3', 'buffer3', 'pulseLength3');

pg = PatternGen('dPiAmp', piAmp3, 'dPiOn2Amp', pi2Amp3, 'dSigma', sigma3, 'dPulseLength', pulseLength3, 'correctionT', T3, 'dBuffer', buffer3, 'cycleLength', cycleLength);

patseq = {{'QId'}};

[ch5seq, ch6seq, ~, ~] = pg.build(patseq, numsteps, delay3, fixedPt);

if makePlot
    myn = 1;
    ch5 = pg.linkListToPattern(ch5seq, myn);
    ch6 = pg.linkListToPattern(ch6seq, myn);
    figure
    plot(ch5)
    hold on
    plot(ch6, 'r')
    grid on
    hold off
end

% make APS file
%exportAPSConfig(temppath, basename, ch5seq, ch6seq);
exportAPSConfig(temppath, basename, ch5seq, ch5seq, ch5seq, ch5seq);
disp('Moving APS file to destination');
movefile([temppath basename '.mat'], [pathAPS basename '.mat']);
end
