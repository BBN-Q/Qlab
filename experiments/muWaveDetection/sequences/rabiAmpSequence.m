function rabiAmpSequence(makePlot)

if ~exist('makePlot', 'var')
    makePlot = true;
end

basename = 'Rabi';
fixedPt = 6000;
cycleLength = 10000;
numsteps = 81;
nbrRepeats = 1;
stepsize = 200;

% load config parameters from file
params = jsonlab.loadjson(getpref('qlab', 'pulseParamsBundleFile'));
qParams = params.q1; % choose target qubit here
IQkey = 'BBN12';
% if using SSB, uncomment the following line
% params.(IQkey).T = eye(2);
pg = PatternGen('dPiAmp', qParams.piAmp, 'dPiOn2Amp', qParams.pi2Amp, 'dSigma', qParams.sigma, 'dPulseType', qParams.pulseType, 'dDelta', qParams.delta, 'correctionT', params.(IQkey).T, 'dBuffer', qParams.buffer, 'dPulseLength', qParams.pulseLength, 'cycleLength', cycleLength, 'passThru', params.(IQkey).passThru);

amps = -((numsteps-1)/2)*stepsize:stepsize:((numsteps-1)/2)*stepsize;
%amps = 0:stepsize:(numsteps-1)*stepsize;
patseq = {{pg.pulse('Xtheta', 'amp', amps)}};
calseq = {};

compileSequenceBBNAPS12(basename, pg, patseq, calseq, numsteps, nbrRepeats, fixedPt, cycleLength, makePlot);

end
