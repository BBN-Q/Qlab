function T1Sequence(makePlot)

if ~exist('makePlot', 'var')
    makePlot = true;
end

basename = 'T1';

fixedPt = 40000;
cycleLength = 44000;

% load config parameters from file
load(getpref('qlab','pulseParamsBundleFile'));
% if using SSB, uncomment the following line
% Ts('12') = eye(2);
IQkey = 'BBNAPS12';
pg = PatternGen('dPiAmp', piAmps('q1'), 'dPiOn2Amp', pi2Amps('q1'), 'dSigma', sigmas('q1'), 'dPulseType', pulseTypes('q1'), 'dDelta', deltas('q1'), 'correctionT', Ts(IQkey), 'dBuffer', buffers('q1'), 'dPulseLength', pulseLengths('q1'), 'cycleLength', cycleLength, 'passThru', passThrus(IQkey));

numsteps = 120 ; %250
nbrRepeats = 1;
stepsize = 240; %24
delaypts = 0:stepsize:(numsteps-1)*stepsize;
patseq = {{...
    pg.pulse('Xp'), ...
    pg.pulse('QId', 'width', delaypts) ...
    }};

calseq = {{pg.pulse('QId')}, {pg.pulse('QId')}, {pg.pulse('Xp')}, {pg.pulse('Xp')}};

compileSequenceBBNAPS12(basename, pg, patseq, calseq, numsteps, nbrRepeats, fixedPt, cycleLength, makePlot, 1);

end
