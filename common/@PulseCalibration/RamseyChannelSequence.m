function [filename, segmentPoints] = RamseyChannelSequence(obj, qubit)
%RamseyChannelSequence Ramsey fringes with variable pulse spacing: pi/2-tau-pi/2
% RamseyChannelSequence(qubit)
%   qubit - target qubit e.g. 'q1'

%We step fairly slowly to capture far off-resonance qubits
%Stepping at 50ns we should be able to capture up to 10MHz off-resonance
%Going out to 10us should give ~100kHz resolution
pulseSpacings = 60:60:12000;
pulsePhases = 0;

basename = 'Ramsey';
fixedPt = pulseSpacings(end)+1000;
nbrRepeats = 1;

pg = PatternGen(qubit);

patseq = {{...
    pg.pulse('X90p'), ...
    pg.pulse('QId', 'width', pulseSpacings), ...
    pg.pulse('U90p', 'angle', pulsePhases)
   }};

% calseq = {{pg.pulse('QId')}, {pg.pulse('QId')}, {pg.pulse('Xp')}, {pg.pulse('Xp')}};
calseq = [];

seqParams = struct(...
    'basename', basename, ...
    'suffix', '', ...
    'numSteps', length(pulseSpacings), ...
    'nbrRepeats', nbrRepeats, ...
    'fixedPt', fixedPt);
patternDict = containers.Map();
if ~isempty(calseq), calseq = {calseq}; end
qubitMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));
IQkey = qubitMap.(qubit).IQkey;
patternDict(IQkey) = struct('pg', pg, 'patseq', {patseq}, 'calseq', calseq, 'channelMap', qubitMap.(qubit));

measChannels = {obj.settings.measurement};
awgs = fieldnames(obj.AWGs)';

compileSequences(seqParams, patternDict, measChannels, awgs, false);

filename = obj.getAWGFileNames(basename);
segmentPoints = pulseSpacings/1.2;
end