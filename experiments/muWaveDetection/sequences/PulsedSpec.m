function PulsedSpec(qubit, pulseAmp, pulseLength, makePlot)


basename = 'PulsedSpec';

fixedPt = pulseLength+1000;
nbrRepeats = 1;

% if using SSB, set the frequency here
pg = PatternGen(qubit);

patseq = {{pg.pulse('Xtheta', 'amp', pulseAmp, 'width', pulseLength, 'pType', 'tanh', 'sigma', 128), pg.pulse('QId','width',64)}};
calseq = [];

% prepare parameter structures for the pulse compiler
seqParams = struct(...
    'basename', basename, ...
    'suffix', '', ...
    'numSteps', 1, ...
    'nbrRepeats', nbrRepeats, ...
    'fixedPt', fixedPt);
patternDict = containers.Map();
if ~isempty(calseq), calseq = {calseq}; end

qubitMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));
IQkey = qubitMap.(qubit).IQkey;

patternDict(IQkey) = struct('pg', pg, 'patseq', {patseq}, 'calseq', calseq, 'channelMap', qubitMap.(qubit));

measChannels = getpref('qlab','MeasCompileList');
awgs = getpref('qlab','AWGCompileList');

compileSequences(seqParams, patternDict, measChannels, awgs, makePlot);


end
