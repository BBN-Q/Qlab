function SingleShotSequence(obj, qubit)

basename = 'SingleShot';
fixedPt = 2000;
cycleLength = fixedPt + obj.settings.measLength + 100;
nbrRepeats = 1;

% if using SSB, set the frequency here
pg = PatternGen(qubit);

patseq = {{pg.pulse('QId')}, {pg.pulse('Xp')}};
calseq  = [];

% prepare parameter structures for the pulse compiler
seqParams = struct(...
    'basename', basename, ...
    'suffix', '', ...
    'numSteps', 1, ...
    'nbrRepeats', nbrRepeats, ...
    'fixedPt', fixedPt, ...
    'cycleLength', cycleLength, ...
    'measLength', obj.settings.measLength);
patternDict = containers.Map();
if ~isempty(calseq), calseq = {calseq}; end

qubitMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));
IQkey = qubitMap.(qubit).IQkey;

patternDict(IQkey) = struct('pg', pg, 'patseq', {patseq}, 'calseq', calseq, 'channelMap', qubitMap.(qubit));
measChannels = {obj.settings.measurement};
awgs = {'TekAWG', 'BBNAPS1', 'BBNAPS2'};

compileSequences(seqParams, patternDict, measChannels, awgs, false);


end