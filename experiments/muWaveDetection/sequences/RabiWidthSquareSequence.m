function RabiWidthSquareSequence(makePlot)

if ~exist('makePlot', 'var')
    makePlot = true;
end

basename = 'RabiWidth';
fixedPt = 6000;
cycleLength = 10000;
nbrRepeats = 1;

% load config parameters from file
params = jsonlab.loadjson(getpref('qlab', 'pulseParamsBundleFile'));
qParams = params.q1; % choose target qubit here
IQkey = 'BBN12';
% if using SSB, uncomment the following line
% params.(IQkey).T = eye(2);
pg = PatternGen('dPiAmp', qParams.piAmp, 'dPiOn2Amp', qParams.pi2Amp, 'dSigma', qParams.sigma, 'dPulseType', qParams.pulseType, 'dDelta', qParams.delta, 'correctionT', params.(IQkey).T, 'dBuffer', qParams.buffer, 'dPulseLength', qParams.pulseLength, 'cycleLength', cycleLength, 'passThru', params.(IQkey).passThru);

numsteps = 100;
minWidth = 12;
stepsize = 12; % 12
pulseLength = minWidth:stepsize:(numsteps-1)*stepsize+minWidth;

patseq = {{pg.pulse('Xtheta', 'amp', 6000, 'width', pulseLength, 'pType', 'square')}};

calseq = {};

compileSequenceBBNAPS12(basename, pg, patseq, calseq, numsteps, nbrRepeats, fixedPt, cycleLength, makePlot);

end