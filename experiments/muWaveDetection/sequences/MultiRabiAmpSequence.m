function MultiRabiAmpSequence(q1, q2, amps, makePlot)
%RabiAmpSequence Rabi nutations by varying pulse amplitude.
% RabiAmpSequence(qubit, amps, makePlot)
%   qubit - target qubit e.g. 'q1'
%   amps - pulse amplitudes to scan over e.g. -8000:200:8000
%   makePlot - whether to plot a sequence or not (boolean)


basename = 'Rabi';
fixedPt = 1000;
nbrRepeats = 1;

pg1 = PatternGen(q1);
pg2 = PatternGen(q2);

patseq1 = {{pg1.pulse('Xtheta', 'amp', amps)}};
patseq2 = {{pg2.pulse('Xtheta', 'amp', amps)}};
calseq = [];

% prepare parameter structures for the pulse compiler
seqParams = struct(...
    'basename', basename, ...
    'suffix', '', ...
    'numSteps', length(amps), ...
    'nbrRepeats', nbrRepeats, ...
    'fixedPt', fixedPt, ...
    'cycleLength', fixedPt + getpref('qlab','MeasLength')+100, ...
    'measLength', getpref('qlab','MeasLength'));
patternDict = containers.Map();
if ~isempty(calseq), calseq = {calseq}; end

qubitMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));

patternDict(qubitMap.(q1).IQkey) = struct('pg', pg1, 'patseq', {patseq1}, 'calseq', calseq, 'channelMap', qubitMap.(q1));
patternDict(qubitMap.(q2).IQkey) = struct('pg', pg2, 'patseq', {patseq2}, 'calseq', calseq, 'channelMap', qubitMap.(q2));

measChannels = getpref('qlab','MeasCompileList');
awgs = getpref('qlab','AWGCompileList');

compileSequences(seqParams, patternDict, measChannels, awgs, makePlot);

end
