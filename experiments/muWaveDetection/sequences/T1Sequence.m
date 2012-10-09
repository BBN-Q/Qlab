function T1Sequence(qubit, pulseSpacings, makePlot, plotSeqNum)
%T1Sequence T1 measurement by inversion-recovery.
% T1Sequence(qubit, pulseSpacings, makePlot, plotSeqNum)
%   qubit - target qubit e.g. 'q1'
%   pulseSpacings - pulse spacings to scan over e.g. 120*(1:150);
%   makePlot - whether to plot a sequence or not (boolean)
%   plotSeqNum (optional) - which sequence to plot (int)

basename = 'T1';
fixedPt = pulseSpacings(end)+1000;
cycleLength = fixedPt+2000; 
nbrRepeats = 1;

% load config parameters from file
params = jsonlab.loadjson(getpref('qlab', 'pulseParamsBundleFile'));
qParams = params.(qubit);
qubitMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));
IQkey = qubitMap.(qubit).IQkey;

% if using SSB, set the frequency here
SSBFreq = 0e6;
pg = PatternGen('dPiAmp', qParams.piAmp, 'dPiOn2Amp', qParams.pi2Amp, 'dSigma', qParams.sigma, 'dPulseType', qParams.pulseType, 'dDelta', qParams.delta, 'correctionT', params.(IQkey).T,'bufferDelay',params.(IQkey).bufferDelay,'bufferReset',params.(IQkey).bufferReset,'bufferPadding',params.(IQkey).bufferPadding, 'dBuffer', qParams.buffer, 'dPulseLength', qParams.pulseLength, 'cycleLength', cycleLength, 'linkList', params.(IQkey).linkListMode, 'dmodFrequency',SSBFreq);

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
patternDict = containers.Map();
if ~isempty(calseq), calseq = {calseq}; end
patternDict(IQkey) = struct('pg', pg, 'patseq', {patseq}, 'calseq', calseq, 'channelMap', qubitMap.(qubit));
measChannels = {'M1'};
awgs = {'TekAWG', 'BBNAPS'};

if ~makePlot
    plotSeqNum = 0;
end
compileSequences(seqParams, patternDict, measChannels, awgs, makePlot, plotSeqNum);
end
