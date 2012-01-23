function PulsedSpec(makePlot)

if ~exist('makePlot', 'var')
    makePlot = true;
end

basename = 'PulsedSpec';

fixedPt = 10000;
cycleLength = 16000;
numsteps = 1;
nbrRepeats = 1;
specLength = 9600;
specAmp = 4000;

% load config parameters from file
load(getpref('qlab','pulseParamsBundleFile'));
% if using SSB, uncomment the following line
% Ts('12') = eye(2);
IQkey = 'BBNAPS12';
pg = PatternGen('dPiAmp', piAmps('q1'), 'dPiOn2Amp', pi2Amps('q1'), 'dSigma', sigmas('q1'), 'dPulseType', pulseTypes('q1'), 'dDelta', deltas('q1'), 'correctionT', Ts(IQkey), 'dBuffer', buffers('q1'), 'dPulseLength', pulseLengths('q1'), 'cycleLength', cycleLength, 'passThru', passThrus(IQkey));

patseq = {{pg.pulse('Xtheta', 'amp', specAmp, 'width', specLength, 'pType', 'square')}};

calseq = {};

compileSequenceBBNAPS12(basename, pg, patseq, calseq, numsteps, nbrRepeats, fixedPt, cycleLength, makePlot, 1);

end
