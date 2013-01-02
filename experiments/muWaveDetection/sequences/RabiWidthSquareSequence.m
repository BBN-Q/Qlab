function RabiWidthSquareSequence(qubit, widths, makePlot)
%RabiWidthSquareSequence Rabi nutations by varying pulse width.
% RabiWidthSquareSequence(qubit, widths, makePlot)
%   qubit - target qubit e.g. 'q1'
%   widths - pulse widths to scan over e.g. 0:5:250

basename = 'RabiWidth';
fixedPt = max(widths) + 500;
cycleLength = fixedPt + 2100;
nbrRepeats = 1;

pg = PatternGen(qubit);

patseq = {{pg.pulse('Xtheta', 'amp', 4000, 'width', widths, 'pType', 'square')}};
calseq = [];

% prepare parameter structures for the pulse compiler
seqParams = struct(...
    'basename', basename, ...
    'suffix', '', ...
    'numSteps', length(widths), ...
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