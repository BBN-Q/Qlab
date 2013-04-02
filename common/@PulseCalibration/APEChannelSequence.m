function [filename, segmentPoints] = APEChannelSequence(obj, qubit, deltas, makePlot)

if ~exist('makePlot', 'var')
    makePlot = false;
end

basename = 'APE';

fixedPt = 6000;
cycleLength = 9000;
nbrRepeats = 1;

pg = PatternGen(qubit,...
    'pi2Amp', obj.pulseParams.pi2Amp,...
    'piAmp', obj.pulseParams.piAmp);

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

segmentPoints = 1:nbrRepeats*(length(patseq) + length(calseq));

seqParams = struct(...
    'basename', basename, ...
    'suffix', '', ...
    'numSteps', 1, ...
    'nbrRepeats', nbrRepeats, ...
    'fixedPt', fixedPt, ...
    'cycleLength', cycleLength, ...
    'measLength', 2000);
if ~isempty(calseq), calseq = {calseq}; end
qubitMap = obj.channelMap.(qubit);

IQkey = qubitMap.IQkey;
patternDict = containers.Map();
patternDict(IQkey) = struct('pg', pg, 'patseq', {patseq}, 'calseq', calseq, 'channelMap', qubitMap);
measChannels = {obj.settings.measurement};
awgs = fieldnames(obj.AWGs)';

compileSequences(seqParams, patternDict, measChannels, awgs, makePlot);

filename = obj.getAWGFileNames(basename);

end