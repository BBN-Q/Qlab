function PiRabiSequence(makePlot)

if ~exist('makePlot', 'var')
    makePlot = true;
end

basename = 'PiRabi';
fixedPt = 6000;
cycleLength = 10000;
nbrRepeats = 1;

numsteps = 80;

% load config parameters from file
params = jsonlab.loadjson(getpref('qlab', 'pulseParamsBundleFile'));
qubitMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));

q1Params = params.q1;
IQkey1 = qubitMap.q1.IQkey;
CRParams = params.CR;
IQkeyCR = qubitMap.CR.IQkey;

% if using SSB, set the frequency here
SSBFreq = 0e6;
pg1 = PatternGen('dPiAmp', q1Params.piAmp, 'dPiOn2Amp', q1Params.pi2Amp, 'dSigma', q1Params.sigma, 'dPulseType', q1Params.pulseType, 'dDelta', q1Params.delta, 'correctionT', params.(IQkey1).T, 'dBuffer', q1Params.buffer, 'dPulseLength', q1Params.pulseLength, 'cycleLength', cycleLength, 'linkList', params.(IQkey1).linkListMode, 'dmodFrequency',SSBFreq);

SSBFreq = 0;
CRParams.buffer = 0;
pgCR = PatternGen('dPiAmp', CRParams.piAmp, 'dPiOn2Amp', CRParams.pi2Amp, 'dSigma', CRParams.sigma, 'dPulseType', CRParams.pulseType, 'dDelta', CRParams.delta, 'correctionT', params.(IQkeyCR).T, 'dBuffer', CRParams.buffer, 'dPulseLength', CRParams.pulseLength, 'cycleLength', cycleLength, 'linkList', params.(IQkeyCR).linkListMode, 'dmodFrequency',SSBFreq);

minWidth = 16+6*CRParams.sigma; %16+6*CRParams.sigma; 
stepsize = 4;
pulseLength = minWidth:stepsize:(numsteps-1)*stepsize+minWidth;
% pulseLength = 120*ones(numsteps,1);

% amps = 3800:15:4985;
amps = 4000;

patseq1  = {...
    {pg1.pulse('Xp'), pg1.pulse('QId', 'duration', pulseLength+32), pg1.pulse('Xp')},...
    {pg1.pulse('QId')}...
    };
patseqCR = {...
    pgCR.pulse('Xtheta', 'pType', 'dragGaussOn', 'width', 3*CRParams.sigma, 'amp', amps), ...
    pgCR.pulse('Xtheta', 'width', pulseLength-6*CRParams.sigma, 'pType', 'square', 'amp', amps*(1-exp(-4.5))), ...
    pgCR.pulse('Xtheta', 'pType', 'dragGaussOff', 'width', 3*CRParams.sigma, 'amp', amps) ...
%     pgCR.pulse('Xtheta', 'width', pulseLength, 'sigma', pulseLength/4, 'amp', amps), ...
%     pgCR.pulse('QId', 'width', q1Params.pulseLength + q1Params.buffer+16), ...
    };

patseqCR = repmat({patseqCR}, 1, 2);

% patseqCR = {...
%     pgCR.pulse('Xtheta', 'width', pulseLength, 'sigma', pulseLength/4, 'amp', amps), ...
%     pgCR.pulse('QId', 'width', q1Params.pulseLength + q1Params.buffer), ...
%     pgCR.pulse('Xtheta', 'width', pulseLength, 'sigma', pulseLength/4, 'amp', amps), ...
%     pgCR.pulse('QId', 'width', q1Params.pulseLength + q1Params.buffer), ...
%     };

calseq = [];

seqParams = struct(...
    'basename', basename, ...
    'suffix', '', ...
    'numSteps', numsteps, ...
    'nbrRepeats', nbrRepeats, ...
    'fixedPt', fixedPt, ...
    'cycleLength', cycleLength, ...
    'measLength', 2000);
patternDict = containers.Map();
if ~isempty(calseq), calseq = {calseq}; end
patternDict(IQkey1) = struct('pg', pg1, 'patseq', {patseq1}, 'calseq', calseq, 'channelMap', qubitMap.q1);
patternDict(IQkeyCR) = struct('pg', pgCR, 'patseq', {patseqCR}, 'calseq', calseq, 'channelMap', qubitMap.CR);
measChannels = {'M1'};
awgs = {'TekAWG', 'BBNAPS'};

plotSeqNum = 10;

compileSequences(seqParams, patternDict, measChannels, awgs, makePlot, plotSeqNum);

end
