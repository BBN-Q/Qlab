function RabiWidthSquareSequence(makePlot)

if ~exist('makePlot', 'var')
    makePlot = true;
end

basename = 'RabiWidth';
fixedPt = 6000;
cycleLength = 10000;
nbrRepeats = 1;

% load config parameters from file
load(getpref('qlab','pulseParamsBundleFile'), 'Ts', 'delays', 'measDelay', 'bufferDelays', 'bufferResets', 'bufferPaddings', 'offsets', 'piAmps', 'pi2Amps', 'sigmas', 'pulseTypes', 'deltas', 'buffers', 'pulseLengths');
% if using SSB, uncomment the following line
Ts('12') = eye(2);
pg = PatternGen('dPiAmp', piAmps('q1'), 'dPiOn2Amp', pi2Amps('q1'), 'dSigma', sigmas('q1'), 'dPulseType', pulseTypes('q1'), 'dDelta', deltas('q1'), 'correctionT', Ts('12'), 'dBuffer', buffers('q1'), 'dPulseLength', pulseLengths('q1'), 'cycleLength', cycleLength);

numsteps = 100;
minWidth = 12;
stepsize = 12; % 12
pulseLength = minWidth:stepsize:(numsteps-1)*stepsize+minWidth;

patseq = {{pg.pulse('Xtheta', 'amp', 6000, 'width', pulseLength, 'pType', 'square')}};

calseq = {};

compileSequenceSSB12(basename, pg, patseq, calseq, numsteps, nbrRepeats, fixedPt, cycleLength, makePlot);

end