function PulsedSpec(varargin)

%varargin assumes qubit and then makePlot
qubit = 'q2';
makePlot = true;

if length(varargin) == 1
    qubit = varargin{1};
elseif length(varargin) == 2
    qubit = varargin{1};
    makePlot = varargin{2};
elseif length(varargin) > 2
    error('Too many input arguments.')
end

basename = 'PulsedSpec';

fixedPt = 10000;
cycleLength = 18000;
numsteps = 1;
nbrRepeats = 1;
specLength = 9600;
specAmp = 4000;

% load config parameters from file
params = jsonlab.loadjson(getpref('qlab', 'pulseParamsBundleFile'));
qParams = params.(qubit);
qubitMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));
IQkey = qubitMap.(qubit).IQkey;

pg = PatternGen('dPiAmp', qParams.piAmp, 'dPiOn2Amp', qParams.pi2Amp, 'dSigma', qParams.sigma, 'dPulseType', qParams.pulseType, 'dDelta', qParams.delta, 'correctionT', params.(IQkey).T, 'dBuffer', qParams.buffer, 'dPulseLength', qParams.pulseLength, 'cycleLength', cycleLength, 'linkList', params.(IQkey).linkListMode);

patseq = {{pg.pulse('Xtheta', 'amp', specAmp, 'width', specLength, 'pType', 'square')}};

calseq = {};

compiler = ['compileSequence' IQkey];
compileArgs = {basename, pg, patseq, calseq, numsteps, nbrRepeats, fixedPt, cycleLength, makePlot, 1};
if exist(compiler, 'file') == 2 % check that the pulse compiler is on the path
    feval(compiler, compileArgs{:});
else
    error('Unable to find compiler for IQkey: %s',IQkey) 
end

end
