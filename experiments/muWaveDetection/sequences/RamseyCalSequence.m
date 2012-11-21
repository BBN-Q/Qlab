function RamseyCalSequence(qubit, pulseSpacings, pulsePhases, makePlot)
%RamseyCalSequence Ramsey fringes with variable pulse spacing: pi/2-tau-pi/2
% RamseyCalSequence(qubit, pulseSpacings, pulsePhases, makePlot)
%   qubit - target qubit e.g. 'q1'
%   pulseSpacings - array of pulse spacings to scan over e.g. 60*(1:200)
%   pulsePhases - array or float of final pulse phases
%   makePlot - whether to plot a sequence or not (boolean)

basename = 'Ramsey';
fixedPt = pulseSpacings(end)+1000;
cycleLength = fixedPt+2000; 
nbrRepeats = 1;

% if using SSB, set the frequency here
SSBFreq = 0e6;
pg = PatternGen(qubit, 'SSBFreq', SSBFreq, 'cycleLength', cycleLength);

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