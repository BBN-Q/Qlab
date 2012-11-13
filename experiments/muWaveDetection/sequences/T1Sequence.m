function T1Sequence(qubit, pulseSpacings, makePlot)
%T1Sequence T1 measurement by inversion-recovery.
% T1Sequence(qubit, pulseSpacings, makePlot, plotSeqNum)
%   qubit - target qubit e.g. 'q1'
%   pulseSpacings - pulse spacings to scan over e.g. 120*(1:150);
%   makePlot - whether to plot a sequence or not (boolean)

basename = 'T1';
fixedPt = pulseSpacings(end)+1000;
cycleLength = fixedPt+2000; 
nbrRepeats = 1;

% if using SSB, set the frequency here
SSBFreq = 0e6;
pg = PatternGen(qubit, 'SSBFreq', SSBFreq, 'cycleLength', cycleLength);

patseq = {{...
    pg.pulse('Xp'), ...
    pg.pulse('QId', 'width', pulseSpacings) ...
    }};

calseq = {{pg.pulse('QId')}, {pg.pulse('QId')}, {pg.pulse('Xp')}, {pg.pulse('Xp')}};

% compiler = ['compileSequence' IQkey];
% compileArgs = {basename, pg, patseq, calseq, numsteps, nbrRepeats, fixedPt, cycleLength, makePlot};
% if exist(compiler, 'file') == 2 % check that the pulse compiler is on the path
%     feval(compiler, compileArgs{:});
% else
%     error('Unable to find compiler for IQkey: %s',IQkey) 
% end
seqParams = struct(...
    'basename', basename, ...
    'suffix', '', ...
    'numSteps', length(pulseSpacings), ...
    'nbrRepeats', nbrRepeats, ...
    'fixedPt', fixedPt, ...
    'cycleLength', cycleLength, ...
    'measLength', 2000);
if ~isempty(calseq), calseq = {calseq}; end

qubitMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));
IQkey = qubitMap.(qubit).IQkey;

patternDict = containers.Map();
patternDict(IQkey) = struct('pg', pg, 'patseq', {patseq}, 'calseq', calseq, 'channelMap', qubitMap.(qubit));

measChannels = {'M1'};
awgs = {'TekAWG', 'BBNAPS1', 'BBNAPS2'};

compileSequences(seqParams, patternDict, measChannels, awgs, makePlot);
end
