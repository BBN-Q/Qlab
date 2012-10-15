function [filename, nbrPatterns] = APEChannelSequence(obj, qubit, deltas, makePlot)

if ~exist('makePlot', 'var')
    makePlot = false;
end

pathAWG = 'U:\AWG\APE\';
basename = 'APE';
fixedPt = 6000;
cycleLength = 8000;
nbrRepeats = 1;

% load config parameters from files
params = jsonlab.loadjson(getpref('qlab', 'pulseParamsBundleFile'));
qParams = params.(qubit);

qubitMap = obj.channelMap.(qubit);
IQkey = qubitMap.IQkey;

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

angle = pi/2;
numPsQId = 8; % number pseudoidentities

sindex = 1;
% QId
% N applications of psuedoidentity
% X90p, (sequence of +/-X90p), U90p
% (1-numPsQId) of +/-X90p
for ct=1:length(deltas)
    curDelta = deltas(ct);
    patseq{sindex} = {pg.pulse('QId')};
    sindex=sindex+1;
    for j = 0:numPsQId
        patseq{sindex + j} = {pg.pulse('X90p', 'delta', curDelta)};
        for k = 1:j
            patseq{sindex + j}(2*k:2*k+1) = {pg.pulse('X90p','delta',curDelta),pg.pulse('X90m','delta',curDelta)};
        end
        patseq{sindex+j}{end+1} = pg.pulse('U90p', 'angle', angle, 'delta', curDelta);
    end
    sindex = sindex + numPsQId+1;
end

% just a pi pulse for scaling
calseq={{pg.pulse('Xp')}};

nbrPatterns = nbrRepeats*(length(patseq) + length(calseq));

seqParams = struct(...
    'basename', basename, ...
    'suffix', '', ...
    'numSteps', 1, ...
    'nbrRepeats', nbrRepeats, ...
    'fixedPt', fixedPt, ...
    'cycleLength', cycleLength, ...
    'measLength', 2000);
patternDict = containers.Map();
if ~isempty(calseq), calseq = {calseq}; end
patternDict(IQkey) = struct('pg', pg, 'patseq', {patseq}, 'calseq', calseq, 'channelMap', qubitMap);
measChannels = {'M1'};
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