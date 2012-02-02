function [filename, nbrPatterns] = rabiAmpChannelSequence(obj, qubit, makePlot)

if ~exist('makePlot', 'var')
    makePlot = false;
end

pathAWG = 'U:\AWG\Rabi\';
pathAPS = 'U:\APS\Rabi\';
basename = 'Rabi';

IQchannels = obj.channelMap(qubit);
IQkey = [IQchannels.instr num2str(IQchannels.i) num2str(IQchannels.q)];

fixedPt = 6000;
cycleLength = 10000;
numsteps = 40; %should be even
stepsize = 400;

% load config parameters from file
params = jsonlab.loadjson(getpref('qlab', 'pulseParamsBundleFile'));
qParams = params.(qubit); % choose target qubit here

pg = PatternGen(...
    'dPiAmp', obj.pulseParams.piAmp, ...
    'dPiOn2Amp', obj.pulseParams.pi2Amp, ...
    'dSigma', qParams.sigma, ...
    'dPulseType', obj.pulseParams.pulseType, ...
    'dDelta', obj.pulseParams.delta, ...
    'correctionT', obj.pulseParams.T, ...
    'dBuffer', qParams.buffer, ...
    'dPulseLength', qParams.pulseLength, ...
    'cycleLength', cycleLength, ...
    'linkList', params.(IQkey).passThru ...
    );

%Don't use zero because if there is a mixer offset it will be completely
%different because the source is never pulsed
amps = [-(numsteps/2)*stepsize:stepsize:-stepsize stepsize:stepsize:(numsteps/2)*stepsize];

for n = 1:numsteps;
    patseq{n} = {pg.pulse('Xtheta', 'amp', amps(n))};
end

for n = 1:numsteps;
    patseq{n+numsteps} = {pg.pulse('Ytheta', 'amp', amps(n))};
end

nbrRepeats = 1;
nbrPatterns = nbrRepeats*length(patseq);
numsteps = 1;

calseq = {};

compiler = ['compileSequence' IQkey];
compileArgs = {basename, pg, patseq, calseq, numsteps, nbrRepeats, fixedPt, cycleLength, makePlot};
if ~obj.testMode && exist(compiler, 'file') == 2 % check that the pulse compiler is on the path
    feval(compiler, compileArgs{:});
end

filename{1} = [pathAWG basename IQkey '.awg'];
if ismember(IQkey, {'BBNAPS12', 'BBNAPS34'})
    filename{2} = [pathAPS basename IQkey '.mat'];
end

end
