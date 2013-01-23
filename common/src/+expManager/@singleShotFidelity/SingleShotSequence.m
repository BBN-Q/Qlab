function SingleShotSequence(qubit)

basename = 'SingleShot';
fixedPt = 2000;
cycleLength = 7100;
nbrRepeats = 1;

% if using SSB, set the frequency here
SSBFreq = -100e6;
pg = PatternGen(qubit, 'SSBFreq', SSBFreq, 'cycleLength', cycleLength);

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
    'measLength', 5000);
patternDict = containers.Map();
if ~isempty(calseq), calseq = {calseq}; end

qubitMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));
IQkey = qubitMap.(qubit).IQkey;

patternDict(IQkey) = struct('pg', pg, 'patseq', {patseq}, 'calseq', calseq, 'channelMap', qubitMap.(qubit));
measChannels = {'M1'};
awgs = {'TekAWG'};

compileSequences(seqParams, patternDict, measChannels, awgs, false);


end