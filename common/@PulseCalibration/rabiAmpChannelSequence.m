function [filename, segmentPoints] = rabiAmpChannelSequence(obj, qubit, makePlot)

if ~exist('makePlot', 'var')
    makePlot = false;
end

basename = 'Rabi';

fixedPt = 2000;
cycleLength = fixedPt + obj.settings.measLength + 100;
numsteps = 40; %should be even
stepsize = 400;

pg = PatternGen(qubit,...
    'pi2Amp', obj.pulseParams.pi2Amp,...
    'piAmp', obj.pulseParams.piAmp);

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
segmentPoints = [amps amps];
numsteps = 1;

calseq = [];

% prepare parameter structures for the pulse compiler
seqParams = struct(...
    'basename', basename, ...
    'suffix', '', ...
    'numSteps', numsteps, ...
    'nbrRepeats', nbrRepeats, ...
    'fixedPt', fixedPt, ...
    'cycleLength', cycleLength, ...
    'measLength', obj.settings.measLength);
patternDict = containers.Map();
if ~isempty(calseq), calseq = {calseq}; end

qubitMap = obj.channelMap.(qubit);
IQkey = qubitMap.IQkey;

patternDict(IQkey) = struct('pg', pg, 'patseq', {patseq}, 'calseq', calseq, 'channelMap', qubitMap);
measChannels = {obj.settings.measurement};
awgs = fieldnames(obj.AWGs)';

compileSequences(seqParams, patternDict, measChannels, awgs, makePlot);

filename = obj.getAWGFileNames(basename);

end
