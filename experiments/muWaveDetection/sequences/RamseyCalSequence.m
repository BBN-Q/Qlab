function RamseyCalSequence(qubit, pulseSpacings, pulsePhases, makePlot, plotSeqNum)
%RamseyCalSequence Ramsey fringes with variable pulse spacing: pi/2-tau-pi/2
% RamseyCalSequence(qubit, pulseSpacings, pulsePhases, makePlot, plotSeqNum)
%   qubit - target qubit e.g. 'q1'
%   pulseSpacings - array of pulse spacings to scan over e.g. 60*(1:200)
%   pulsePhases - array or float of final pulse phases
%   makePlot - whether to plot a sequence or not (boolean)
%   plotSeqNum (optional) - which sequence to plot (int)

basename = 'Ramsey';
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
patternDict(IQkey) = struct('pg', pg, 'patseq', {patseq}, 'calseq', calseq, 'channelMap', qubitMap.(qubit));
measChannels = {'M1'};
awgs = {'TekAWG', 'BBNAPS1', 'BBNAPS2'};

if ~makePlot
    plotSeqNum = 0;
end

compileSequences(seqParams, patternDict, measChannels, awgs, makePlot, plotSeqNum);
end