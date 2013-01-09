function EchoSequence(qubit, pulseSpacings, pulsePhases, makePlot)
%EchoSequence Hahn spin echo experiment: pi/2-tau/2-pi-tau/2-pi/2
% EchoSequence(qubit, pulseSpacings, makePlot)
%   qubit - target qubit e.g. 'q1'
%   pulseSpacings - array of pulse spacings to scan over e.g. 60*(1:200)
%   pulsePhases - array or float of final pulse phases
%   makePlot - whether to plot a sequence or not (boolean)

basename = 'Echo';
fixedPt = pulseSpacings(end)+1000;
cycleLength = fixedPt+2100;
nbrRepeats = 1;

pg = PatternGen(qubit);

numPulses = 1;
HahnBlock = {pg.pulse('QId', 'width', pulseSpacings./2), pg.pulse('Yp'), pg.pulse('QId', 'width', pulseSpacings./2)};
patseq = {[...
    {pg.pulse('X90p')}, ...
    repmat(HahnBlock, [1, numPulses]), ...
    {pg.pulse('U90p', 'angle', pulsePhases)}, ...
    ]};

calseq = {{pg.pulse('QId')},{pg.pulse('QId')},{pg.pulse('Xp')},{pg.pulse('Xp')}};

seqParams = struct(...
    'basename', basename, ...
    'suffix', '', ...
    'numSteps', length(pulseSpacings), ...
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
awgs = {'TekAWG', 'BBNAPS'};

compileSequences(seqParams, patternDict, measChannels, awgs, makePlot);
end
