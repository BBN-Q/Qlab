function TestAPSDelaySequence(makePlot)

if ~exist('makePlot', 'var')
    makePlot = true;
end

basename = 'TestAPSDelay';

fixedPt = 2000;
cycleLength = 4000;
nbrRepeats = 2;
numsteps = 1;

% load config parameters from file
params = jsonlab.loadjson(getpref('qlab', 'pulseParamsBundleFile'));
qubitMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));

controlQ = 'q2';
targetQ = 'q3';
q1Params = params.(controlQ);
IQkey1 = qubitMap.(controlQ).IQkey;
q2Params = params.(targetQ);
IQkey2 = qubitMap.(targetQ).IQkey;

SSBFreq = 0e6;
pg1 = PatternGen('dPiAmp', q1Params.piAmp, 'dPiOn2Amp', q1Params.pi2Amp, 'dSigma', q1Params.sigma, 'dPulseType', q1Params.pulseType, 'dDelta', q1Params.delta, 'correctionT', params.(IQkey1).T, 'dBuffer', q1Params.buffer, 'dPulseLength', q1Params.pulseLength, 'cycleLength', cycleLength, 'linkList', params.(IQkey1).linkListMode, 'dmodFrequency',SSBFreq);
pg2 = PatternGen('dPiAmp', q2Params.piAmp, 'dPiOn2Amp', q2Params.pi2Amp, 'dSigma', q2Params.sigma, 'dPulseType', q2Params.pulseType, 'dDelta', q2Params.delta, 'correctionT', params.(IQkey2).T, 'dBuffer', q2Params.buffer, 'dPulseLength', q2Params.pulseLength, 'cycleLength', cycleLength, 'linkList', params.(IQkey2).linkListMode, 'dmodFrequency',SSBFreq);


patSeq1 = {{pg1.pulse('Yp', 'pType', 'square', 'width', 100)}};
patSeq2 = {{pg2.pulse('Xp', 'pType', 'square', 'width', 100)}};

params.(IQkey1).delay = 0;
params.(IQkey2).delay = 0;

calSeq1 = [];
calSeq2 = [];


seqParams = struct(...
    'basename', basename, ...
    'suffix', '',...%num2str(expct), ...
    'numSteps', numsteps, ...
    'nbrRepeats', nbrRepeats, ...
    'fixedPt', fixedPt, ...
    'cycleLength', cycleLength, ...
    'measLength', 2000);
patternDict = containers.Map();
patternDict(IQkey1) = struct('pg', pg1, 'patseq', {patSeq1}, 'calseq', calSeq1, 'channelMap', qubitMap.(controlQ));
patternDict(IQkey2) = struct('pg', pg2, 'patseq', {patSeq2}, 'calseq', calSeq2, 'channelMap', qubitMap.(targetQ));
measChannels = {'M1'};
awgs = {'TekAWG', 'BBNAPS1'};

plotSeqNum = 1;

compileSequences(seqParams, patternDict, measChannels, awgs, makePlot, plotSeqNum);


end