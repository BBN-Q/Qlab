function RamseyCalSequence(varargin)

%varargin assumes qubit and then makePlot
qubit = 'q1';
makePlot = true;

if length(varargin) == 1
    qubit = varargin{1};
elseif length(varargin) == 2
    qubit = varargin{1};
    makePlot = varargin{2};
elseif length(varargin) > 2
    error('Too many input arguments.')
end

basename = 'Ramsey';
fixedPt = 19000;
cycleLength = 27000;
nbrRepeats = 1;

% load config parameters from file
params = jsonlab.loadjson(getpref('qlab', 'pulseParamsBundleFile'));
qParams = params.(qubit);
qubitMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));
IQkey = qubitMap.(qubit).IQkey;
% if using SSB, set the frequency here
SSBFreq = 0e6;
pg = PatternGen('dPiAmp', qParams.piAmp, 'dPiOn2Amp', qParams.pi2Amp, 'dSigma', qParams.sigma, 'dPulseType', qParams.pulseType, 'dDelta', qParams.delta, 'correctionT', params.(IQkey).T,'bufferDelay',params.(IQkey).bufferDelay,'bufferReset',params.(IQkey).bufferReset,'bufferPadding',params.(IQkey).bufferPadding, 'dBuffer', qParams.buffer, 'dPulseLength', qParams.pulseLength, 'cycleLength', cycleLength, 'linkList', params.(IQkey).linkListMode, 'dmodFrequency',SSBFreq);

numsteps = 150;
stepsize = 120; %24 (300)
delaypts = 0:stepsize:(numsteps-1)*stepsize;
anglepts = 0:pi/4:(numsteps-1)*pi/4;
anglepts = 0;
patseq = {{...
    pg.pulse('X90p'), ...
    pg.pulse('QId', 'width', delaypts), ...
    pg.pulse('U90p', 'angle', anglepts)
   }};
calseq = {{pg.pulse('QId')}, {pg.pulse('QId')}, {pg.pulse('Xp')}, {pg.pulse('Xp')}};

compiler = ['compileSequence' IQkey];
compileArgs = {basename, pg, patseq, calseq, numsteps, nbrRepeats, fixedPt, cycleLength, makePlot, 39};
if exist(compiler, 'file') == 2 % check that the pulse compiler is on the path
    feval(compiler, compileArgs{:});
else
    error('Unable to find compiler for IQkey: %s',IQkey) 
end

end