function [filename, segmentPoints] = SPAMChannelSequence(obj, qubit, makePlot)

if ~exist('makePlot', 'var')
    makePlot = false;
end

basename = 'SPAM';
fixedPt = 6000;
nbrRepeats = 1;

pg = PatternGen(qubit,...
    'pi2Amp', obj.pulseParams.pi2Amp,...
    'piAmp', obj.pulseParams.piAmp,...
    'delta', obj.pulseParams.delta);

numPsQId = 10; % number pseudoidentities
angleShifts = (pi/180)*(-3:0.75:3);

patseq = {};

for angleShift = angleShifts
    patseq{end+1} = {pg.pulse('QId')};
    SPAMBlock = {pg.pulse('Xp'),pg.pulse('Up','angle',pi/2+angleShift),pg.pulse('Xp'),pg.pulse('Up','angle',pi/2+angleShift)};
     for SPAMct = 0:numPsQId
        patseq{end+1} = {pg.pulse('Y90p')};
        for ct = 0:SPAMct
            patseq{end} = [patseq{end}, SPAMBlock];
        end
        patseq{end} = [patseq{end}, {pg.pulse('X90m')}];
     end
end
calseq = {{pg.pulse('Xp')}};

segmentPoints = 1:nbrRepeats*(length(patseq) + length(calseq));

seqParams = struct(...
    'basename', basename, ...
    'suffix', '', ...
    'numSteps', 1, ...
    'nbrRepeats', nbrRepeats, ...
    'fixedPt', fixedPt);
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