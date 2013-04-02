function T1Sequence(qubit, pulseSpacings, makePlot)
%T1Sequence T1 measurement by inversion-recovery.
% T1Sequence(qubit, pulseSpacings, makePlot)
%   qubit - target qubit e.g. 'q1'
%   pulseSpacings - pulse spacings to scan over e.g. 120*(1:150);
%   makePlot - whether to plot a sequence or not (boolean)

basename = 'T1';
fixedPt = pulseSpacings(end)+1000;
cycleLength = fixedPt+4000; 
nbrRepeats = 1;

pg = PatternGen(qubit);

patseq = {{...
    pg.pulse('Xp'), ...
    pg.pulse('QId', 'width', pulseSpacings) ...
    }};

calseq = {{pg.pulse('QId')}, {pg.pulse('QId')}, {pg.pulse('Xp')}, {pg.pulse('Xp')}};

seqParams = struct(...
    'basename', basename, ...
    'suffix', '', ...
    'numSteps', length(pulseSpacings), ...
    'nbrRepeats', nbrRepeats, ...
    'fixedPt', fixedPt, ...
    'cycleLength', cycleLength, ...
    'measLength', 3000);
if ~isempty(calseq), calseq = {calseq}; end

qubitMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));
IQkey = qubitMap.(qubit).IQkey;

patternDict = containers.Map();
patternDict(IQkey) = struct('pg', pg, 'patseq', {patseq}, 'calseq', calseq, 'channelMap', qubitMap.(qubit));

measChannels = {'M1'};
awgs = {'TekAWG', 'BBNAPS1', 'BBNAPS2'};

compileSequences(seqParams, patternDict, measChannels, awgs, makePlot);
end
