function [filename, nbrPatterns] = Pi2CalChannelSequence(obj, qubit, direction, makePlot)

if ~exist('direction', 'var')
    direction = 'X';
elseif ~strcmp(direction, 'X') && ~strcmp(direction, 'Y')
    warning('Unknown direction, assuming X');
    direction = 'X';
end
if ~exist('makePlot', 'var')
    makePlot = false;
end

pathAWG = 'U:\AWG\Pi2Cal\';
pathAPS = 'U:\APS\Pi2Cal\';
basename = 'Pi2Cal';

IQchannels = obj.channelMap(qubit);
IQkey = [IQchannels.instr num2str(IQchannels.i) num2str(IQchannels.q)];

fixedPt = 6000;
cycleLength = 10000;
numPi2s = 9; % number of odd numbered pi/2 sequences for each rotation direction

% load config parameters from file
params = jsonlab.loadjson(getpref('qlab', 'pulseParamsBundleFile'));
qParams = params.(qubit); % choose target qubit here

pg1 = PatternGen(...
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

pulseLib = containers.Map();
pulses = {'QId', 'X90p', 'X90m', 'Y90p', 'Y90m'};
for p = pulses
    pname = cell2mat(p);
    pulseLib(pname) = pg1.pulse(pname);
end

patseq{1} = {pulseLib('QId')};

sindex = 1;

% +X rotations
% (1, 3, 5, 7, 9, 11, 13, 15, 17) x X90p
for j = 1:numPi2s
    for k = 1:(1+2*(j-1))
        patseq{sindex + j}{k} = pulseLib([direction '90p']);
    end
end
sindex = sindex + numPi2s;

% -X rotations
% (1, 3, 5, 7, 9, 11, ...) x X90m
for j = 1:numPi2s
    for k = 1:(1+2*(j-1))
        patseq{sindex + j}{k} = pulseLib([direction '90m']);
    end
end

numsteps = 1;
nbrRepeats = 2;
nbrPatterns = nbrRepeats*length(patseq);
calseq = {};

compiler = ['compileSequence' IQkey];
compileArgs = {basename, pg1, patseq, calseq, numsteps, nbrRepeats, fixedPt, cycleLength, makePlot};
if ~obj.testMode && exist(compiler, 'file') == 2 % check that the pulse compiler is on the path
    feval(compiler, compileArgs{:});
end

filename{1} = [pathAWG basename IQkey '.awg'];
if ismember(IQkey, {'BBNAPS12', 'BBNAPS34'})
    filename{2} = [pathAPS basename IQkey '.mat'];
end

end

