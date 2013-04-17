function RabiWidthSquareSequence(qubit, widths, makePlot)
%RabiWidthSquareSequence Rabi nutations by varying pulse width.
% RabiWidthSquareSequence(qubit, widths, makePlot)
%   qubit - target qubit e.g. 'q1'
%   widths - pulse widths to scan over e.g. 0:5:250

basename = 'RabiWidth';
fixedPt = max(widths) + 500;
nbrRepeats = 1;

pg = PatternGen(qubit);

patseq = {{pg.pulse('Utheta', 'amp', 4000, 'width', widths, 'pType', 'square', 'angle', pi/4)}};
calseq = [];

% prepare parameter structures for the pulse compiler
seqParams = struct(...
    'basename', basename, ...
    'suffix', '', ...
    'numSteps', length(widths), ...
    'nbrRepeats', nbrRepeats, ...
    'fixedPt', fixedPt + getpref('qlab','MeasLength')+100, ...
    'cycleLength', cycleLength, ...
    'measLength', getpref('qlab','MeasLength'));
patternDict = containers.Map();
if ~isempty(calseq), calseq = {calseq}; end

qubitMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));
IQkey = qubitMap.(qubit).IQkey;

patternDict(IQkey) = struct('pg', pg, 'patseq', {patseq}, 'calseq', calseq, 'channelMap', qubitMap.(qubit));

measChannels = getpref('qlab','MeasCompileList');
awgs = getpref('qlab','AWGCompileList');

compileSequences(seqParams, patternDict, measChannels, awgs, makePlot);

end