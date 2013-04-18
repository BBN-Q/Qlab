function RamseyCalSequence(qubit, pulseSpacings, pulsePhases, makePlot)
%RamseyCalSequence Ramsey fringes with variable pulse spacing: pi/2-tau-pi/2
% RamseyCalSequence(qubit, pulseSpacings, pulsePhases, makePlot)
%   qubit - target qubit e.g. 'q1'
%   pulseSpacings - array of pulse spacings to scan over e.g. 60*(1:200)
%   pulsePhases - array or float of final pulse phases
%   makePlot - whether to plot a sequence or not (boolean)

basename = 'Ramsey';
fixedPt = pulseSpacings(end)+1000;
nbrRepeats = 1;

pg = PatternGen(qubit);

patseq = {{...
    pg.pulse('X90p'), ...
    pg.pulse('QId', 'width', pulseSpacings), ...
    pg.pulse('U90p', 'angle', pulsePhases)
   }};

calseq = {{pg.pulse('QId')}, {pg.pulse('QId')}, {pg.pulse('Xp')}, {pg.pulse('Xp')}};

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

measChannels = getpref('qlab','MeasCompileList');
awgs = getpref('qlab','AWGCompileList');

compileSequences(seqParams, patternDict, measChannels, awgs, makePlot);

end