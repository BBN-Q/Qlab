function EchoSequence(makePlot)

if ~exist('makePlot', 'var')
    makePlot = true;
end

basename = 'Echo';

fixedPt = 25000;
cycleLength = 30000;

% load config parameters from file
params = jsonlab.loadjson(getpref('qlab', 'pulseParamsBundleFile'));
qParams = params.q1; % choose target qubit here
IQkey = 'BBN12';
% if using SSB, uncomment the following line
% params.(IQkey).T = eye(2);
pg = PatternGen('dPiAmp', qParams.piAmp, 'dPiOn2Amp', qParams.pi2Amp, 'dSigma', qParams.sigma, 'dPulseType', qParams.pulseType, 'dDelta', qParams.delta, 'correctionT', params.(IQkey).T, 'dBuffer', qParams.buffer, 'dPulseLength', qParams.pulseLength, 'cycleLength', cycleLength, 'passThru', params.(IQkey).passThru);

numsteps = 70; %150
stepsize = 120;
delaypts = 0:stepsize:(numsteps-1)*stepsize;
%anglepts = 0:pi/8:(numsteps-1)*pi/8;
anglepts = 0;
patseq = {{...
    pg.pulse('X90p'), ...
    pg.pulse('QId', 'width', delaypts), ...
    pg.pulse('Yp') ...
    pg.pulse('QId', 'width', delaypts), ...
    pg.pulse('U90p', 'angle', anglepts), ...
    }};

calseq = {{pg.pulse('QId')},{pg.pulse('QId')},{pg.pulse('Xp')},{pg.pulse('Xp')}};

compileSequenceBBNAPS12(basename, pg, patseq, calseq, numsteps, 1, fixedPt, cycleLength, makePlot);

end
