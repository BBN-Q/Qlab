function rabiAmpSequence(varargin)

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

basename = 'Rabi';
fixedPt = 1000;
cycleLength = 18000;
numsteps = 81; % 81 or 100
nbrRepeats = 1;
stepsize = 200; % 200 or 80

% load config parameters from files
params = jsonlab.loadjson(getpref('qlab', 'pulseParamsBundleFile'));
qParams = params.(qubit);
qubitMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));
IQkey = qubitMap.(qubit).IQkey;

% if using SSB, set the frequency here
SSBFreq = 0e6;
pg = PatternGen('dPiAmp', qParams.piAmp, 'dPiOn2Amp', qParams.pi2Amp, 'dSigma', qParams.sigma, 'dPulseType', qParams.pulseType, 'dDelta', qParams.delta, 'correctionT', params.(IQkey).T,'bufferDelay',params.(IQkey).bufferDelay,'bufferReset',params.(IQkey).bufferReset,'bufferPadding',params.(IQkey).bufferPadding, 'dBuffer', qParams.buffer, 'dPulseLength', qParams.pulseLength, 'cycleLength', cycleLength, 'linkList', params.(IQkey).linkListMode);

%pg = PatternGen('dPiAmp', qParams.piAmp, 'dPiOn2Amp', qParams.pi2Amp, 'dSigma', qParams.sigma, 'dPulseType', qParams.pulseType, 'dDelta', qParams.delta, 'correctionT', params.(IQkey).T, 'dBuffer', qParams.buffer, 'dPulseLength', qParams.pulseLength, 'cycleLength', cycleLength, 'linkList', params.(IQkey).linkListMode, 'dmodFrequency',SSBFreq);

amps = -((numsteps-1)/2)*stepsize:stepsize:((numsteps-1)/2)*stepsize;
%amps = 0:stepsize:(numsteps-1)*stepsize;
patseq = {{pg.pulse('Xtheta', 'amp', amps)}};
calseq = {};

compiler = ['compileSequence' IQkey];
compileArgs = {basename, pg, patseq, calseq, numsteps, nbrRepeats, fixedPt, cycleLength, makePlot};
if exist(compiler, 'file') == 2 % check that the pulse compiler is on the path
    feval(compiler, compileArgs{:});
else
    error('Unable to find compiler for IQkey: %s',IQkey) 
end

end
