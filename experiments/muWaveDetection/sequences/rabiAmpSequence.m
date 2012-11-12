function rabiAmpSequence(qubit, amps, makePlot, plotSeqNum)
%rabiAmpSequence Rabi nutations by varying pulse amplitude.
% rabiAmpSequence(qubit, amps, makePlot, plotSeqNum)
%   qubit - target qubit e.g. 'q1'
%   amps - pulse amplitudes to scan over e.g. -8000:200:8000
%   makePlot - whether to plot a sequence or not (boolean)
%   plotSeqNum (optional) - which sequence to plot (int)


basename = 'Rabi';
fixedPt = 1000;
cycleLength = 3100;
nbrRepeats = 1;

% if using SSB, set the frequency here
SSBFreq = 0e6;
% qParams.buffer = 0;
pg = PatternGen(qubit, 'SSBFreq', SSBFreq, 'cycleLength', cycleLength);
patseq = {{pg.pulse('Xtheta', 'amp', amps)}};
% patseq = {{pg.pulse('Xtheta', 'amp', amps), pg.pulse('QId', 'width', 120)}};
calseq = [];

% prepare parameter structures for the pulse compiler
seqParams = struct(...
    'basename', basename, ...
    'suffix', '', ...
    'numSteps', length(amps), ...
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

if ~makePlot
    plotSeqNum = 0;
end
compileSequences(seqParams, patternDict, measChannels, awgs, makePlot, plotSeqNum);

end
