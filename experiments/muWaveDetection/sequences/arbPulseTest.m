function arbPulseTest(makePlot)

if ~exist('makePlot', 'var')
    makePlot = true;
end
script = java.io.File(mfilename('fullpath'));
path = char(script.getParentFile().getParentFile().getParentFile().getParent());
addpath([path '/common/src'],'-END');
addpath([path '/common/src/util/'],'-END');

temppath = [char(script.getParent()) '\'];
%path = 'U:\AWG\Pi2Cal\';
%basename = 'Pi2Cal';

fixedPt = 6000;
cycleLength = 10000;
numPi2s = 9; % number of odd numbered pi/2 sequences for each rotation direction

% load config parameters from file
parent_path = char(script.getParentFile.getParent());
cfg_path = [parent_path '/cfg/'];
load([cfg_path 'pulseParams.mat'], 'T', 'delay', 'measDelay', 'bufferDelay', 'bufferReset', 'bufferPadding', 'offset', 'piAmp', 'pi2Amp', 'sigma', 'pulseType', 'delta', 'buffer', 'pulseLength');
T = eye(2);
pg = PatternGen('dPiAmp', piAmp, 'dPiOn2Amp', pi2Amp, 'dSigma', sigma, 'dPulseType', pulseType, 'dDelta', delta, 'correctionT', T, 'dBuffer', buffer, 'dPulseLength', pulseLength, 'cycleLength', cycleLength);

patseq = {...
    pg.pulse('Xp'),...
    pg.pulse('Y90p', 'pType', 'square'),...
    pg.pulse('Xm', 'pType', 'drag'),...
    pg.pulse('Yp', 'pType', 'gaussOn', 'duration', pulseLength),...
    pg.pulse('Yp', 'pType', 'square', 'duration', pulseLength),...
    pg.pulse('Yp', 'pType', 'gaussOff', 'duration', pulseLength),...
    pg.pulse('Xtheta', 'amp', 1, 'pType', 'arbitrary', 'arbfname', 'wackyXY.dat'),...
    pg.pulse('Ytheta', 'amp', 0.5, 'pType', 'arbitrary', 'arbfname', 'wackyXY.dat')
    };

numsteps = 2;

ch1 = zeros(numsteps, cycleLength);
ch2 = ch1;
ch3m1 = ch1;

for n = 1:numsteps;
	[patx paty] = pg.getPatternSeq(patseq, n, delay, fixedPt);
	ch1(n, :) = patx + offset;
	ch2(n, :) = paty + offset;
    ch3m1(n, :) = pg.bufferPulse(patx, paty, 0, bufferPadding, bufferReset, bufferDelay);
end

if makePlot
    myn = 1;
    figure
    plot(ch1(myn,:))
    hold on
    plot(ch2(myn,:), 'r')
    plot(5000*ch3m1(myn,:), 'k')
    grid on
    hold off
end

end

