function SweepPulseBuffer(qubit, sweepPts, makePlot)
%SweepBufferPulse Sweep the pulse buffer to find the optimum value
% SweepBufferPulse(qubit, sweepPts, makePlot)
%   qubit - target qubit e.g. 'q1'
%   sweepPts - sweep points for the buffer delay
%   makePlot - whether to plot a sequence or not (boolean)
%   plotSeqNum (optional) - which sequence to plot (int)


basename = 'SweepBuffer';
fixedPt = 1000;
cycleLength = 3200;
nbrRepeats = 1;


% if using SSB, set the frequency here
SSBFreq = 0e6;
pg = PatternGen(qubit, 'SSBFreq', SSBFreq, 'cycleLength', cycleLength);

patseq = {{pg.pulse('QId')}, {pg.pulse('QId')},...
    {pg.pulse('Xtheta', 'pType', 'square', 'amp', 3400)}, {pg.pulse('Xtheta', 'pType', 'square', 'amp', 3400)}};
calseq = [];

% prepare parameter structures for the pulse compiler
seqParams = struct(...
    'basename', basename, ...
    'suffix', '', ...
    'numSteps', 1, ...
    'nbrRepeats', nbrRepeats, ...
    'fixedPt', fixedPt, ...
    'cycleLength', cycleLength, ...
    'measLength', 2000);
qubitMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));
IQkey = qubitMap.(qubit).IQkey;
if ~isempty(calseq), calseq = {calseq}; end
measChannels = {'M1'};
awgs = {'TekAWG', 'BBNAPS1', 'BBNAPS2'};

% load config parameters from files
expct = 1;

for bufferDelay = sweepPts
    
    %Update the buffer delay to the pattern gen
    pg.bufferDelay = bufferDelay;
    
    %Update the expt number
    seqParams.suffix = ['_', num2str(expct)];
    
    patternDict = containers.Map();
    patternDict(IQkey) = struct('pg', pg, 'patseq', {patseq}, 'calseq', calseq, 'channelMap', qubitMap.(qubit));
    compileSequences(seqParams, patternDict, measChannels, awgs, makePlot);
    expct = expct+1;
end

end
