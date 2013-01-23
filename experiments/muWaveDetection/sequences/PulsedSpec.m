function PulsedSpec(qubit, pulseLength, makePlot)


basename = 'PulsedSpec';

fixedPt = 10000;
cycleLength = 13100;
nbrRepeats = 1;

% if using SSB, set the frequency here
SSBFreq = -150e6;
pg = PatternGen(qubit, 'SSBFreq', SSBFreq, 'cycleLength', cycleLength);

patseq = {{pg.pulse('Xtheta', 'amp', 8000, 'width', pulseLength, 'pType', 'square')}};
calseq = [];

% prepare parameter structures for the pulse compiler
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

qubitMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));
IQkey = qubitMap.(qubit).IQkey;

patternDict(IQkey) = struct('pg', pg, 'patseq', {patseq}, 'calseq', calseq, 'channelMap', qubitMap.(qubit));
measChannels = {'M1'};
awgs = {'TekAWG', 'BBNAPS1', 'BBNAPS2'};

compileSequences(seqParams, patternDict, measChannels, awgs, makePlot);


end
