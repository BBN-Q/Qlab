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

params = jsonlab.loadjson(getpref('qlab', 'pulseParamsBundleFile'));
qParams = params.q2; % choose target qubit here
IQkey = 'TekAWG34';
% if using SSB, uncomment the following line
% params.(IQkey).T = eye(2);
pg = PatternGen('dPiAmp', qParams.piAmp, 'dPiOn2Amp', qParams.pi2Amp, 'dSigma', qParams.sigma, 'dPulseType', qParams.pulseType, 'dDelta', qParams.delta, 'correctionT', params.(IQkey).T, 'dBuffer', qParams.buffer, 'dPulseLength', qParams.pulseLength, 'cycleLength', cycleLength, 'linkList', params.(IQkey).passThru);

patseq = {{pg.pulse('Xtheta', 'amp', specAmp, 'width', specLength, 'pType', 'square')}};

calseq = {};

compiler = ['compileSequence' IQkey];
compileArgs = {basename, pg, patseq, calseq, numsteps, nbrRepeats, fixedPt, cycleLength, makePlot};
if exist(compiler, 'file') == 2 % check that the pulse compiler is on the path
    feval(compiler, compileArgs{:});
else
    error('Unable to find compiler for IQkey: %s',IQkey) 
end

end
