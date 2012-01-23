function RamseyCalSequence(makePlot)

if ~exist('makePlot', 'var')
    makePlot = true;
end

basename = 'Ramsey';
fixedPt = 16000;
cycleLength = 20000;

% load config parameters from file
load(getpref('qlab','pulseParamsBundleFile'));
% if using SSB, uncomment the following line
% Ts('12') = eye(2);
IQkey = 'BBNAPS12';
pg = PatternGen('dPiAmp', piAmps('q1'), 'dPiOn2Amp', pi2Amps('q1'), 'dSigma', sigmas('q1'), 'dPulseType', pulseTypes('q1'), 'dDelta', deltas('q1'), 'correctionT', Ts('12'), 'dBuffer', buffers('q1'), 'dPulseLength', pulseLengths('q1'), 'cycleLength', cycleLength, 'passThru', passThrus(IQkey));

numsteps = 150;
stepsize = 48; %24 (300)
delaypts = 0:stepsize:(numsteps-1)*stepsize;
patseq = {{...
    pg.pulse('X90p'), ...
    pg.pulse('QId', 'width', delaypts), ...
    pg.pulse('X90p')
    }};
calseq = {{pg.pulse('QId')}, {pg.pulse('QId')}, {pg.pulse('Xp')}, {pg.pulse('Xp')}};

compileSequenceBBNAPS12(basename, pg, patseq, calseq, numsteps, 1, fixedPt, cycleLength, makePlot);
end