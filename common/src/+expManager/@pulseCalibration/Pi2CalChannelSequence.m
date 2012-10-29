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
basename = 'Pi2Cal';

qubitMap = obj.channelMap.(qubit);
IQkey = qubitMap.IQkey;

fixedPt = 6000;
cycleLength = 15000;
numPi2s = 9; % number of odd numbered pi/2 sequences for each rotation direction

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
    'linkList', params.(IQkey).linkListMode, ...
    'dmodFrequency', obj.pulseParams.SSBFreq ...
    );

pulseLib = containers.Map();
pulses = {'QId', 'X90p', 'X90m', 'Y90p', 'Y90m'};
for p = pulses
    pname = cell2mat(p);
    pulseLib(pname) = pg.pulse(pname);
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
calseq = [];

% prepare parameter structures for the pulse compiler
seqParams = struct(...
    'basename', basename, ...
    'suffix', '', ...
    'numSteps', numsteps, ...
    'nbrRepeats', nbrRepeats, ...
    'fixedPt', fixedPt, ...
    'cycleLength', cycleLength, ...
    'measLength', 2000);
patternDict = containers.Map();
if ~isempty(calseq), calseq = {calseq}; end
patternDict(IQkey) = struct('pg', pg, 'patseq', {patseq}, 'calseq', calseq, 'channelMap', qubitMap);
measChannels = {'M1'};
%awgs = {'TekAWG', 'BBNAPS'};
awgs = cellfun(@(x) x.InstrName, obj.awgParams, 'UniformOutput',false);

compileSequences(seqParams, patternDict, measChannels, awgs, makePlot, 20);

for awgct = 1:length(awgs)
    switch awgs{awgct}(1:6)
        case 'TekAWG'
            filename{awgct} = [pathAWG basename '-' awgs{awgct}, '.awg'];
        case 'BBNAPS'
            filename{awgct} = [pathAWG basename '-', awgs{awgct}, '.h5'];
        otherwise
            error('Unknown AWG type.');
    end
end


end

