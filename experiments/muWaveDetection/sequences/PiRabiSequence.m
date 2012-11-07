function PiRabiSequence(makePlot)

if ~exist('makePlot', 'var')
    makePlot = true;
end

basename = 'PiRabi';
fixedPt = 4000;
cycleLength = 6000;
nbrRepeats = 1;

numsteps = 80;

% load config parameters from file
params = jsonlab.loadjson(getpref('qlab', 'pulseParamsBundleFile'));
qubitMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));

controlQ = 'q1';
targetQ = 'q3';
q1Params = params.(controlQ);
IQkey1 = qubitMap.(controlQ).IQkey;
q2Params = params.(targetQ);
IQkey2 = qubitMap.(targetQ).IQkey;
CRParams = params.CR;
IQkeyCR = qubitMap.CR.IQkey;

% if using SSB, set the frequency here
SSBFreq = 0e6;
pg1 = PatternGen('dPiAmp', q1Params.piAmp, 'dPiOn2Amp', q1Params.pi2Amp, 'dSigma', q1Params.sigma, 'dPulseType', q1Params.pulseType, 'dDelta', q1Params.delta, 'correctionT', params.(IQkey1).T, 'dBuffer', q1Params.buffer, 'dPulseLength', q1Params.pulseLength, 'cycleLength', cycleLength, 'linkList', params.(IQkey1).linkListMode, 'dmodFrequency',SSBFreq);

SSBFreq = 0e6;
pg2 = PatternGen('dPiAmp', q2Params.piAmp, 'dPiOn2Amp', q2Params.pi2Amp, 'dSigma', q2Params.sigma, 'dPulseType', q2Params.pulseType, 'dDelta', q2Params.delta, 'correctionT', params.(IQkey2).T, 'dBuffer', q2Params.buffer, 'dPulseLength', q2Params.pulseLength, 'cycleLength', cycleLength, 'linkList', params.(IQkey2).linkListMode, 'dmodFrequency',SSBFreq);

SSBFreq = 0;
CRParams.buffer = 0;
pgCR = PatternGen('dPiAmp', CRParams.piAmp, 'dPiOn2Amp', CRParams.pi2Amp, 'dSigma', CRParams.sigma, 'dPulseType', CRParams.pulseType, 'dDelta', CRParams.delta, 'correctionT', params.(IQkeyCR).T, 'dBuffer', CRParams.buffer, 'dPulseLength', CRParams.pulseLength, 'cycleLength', cycleLength, 'linkList', params.(IQkeyCR).linkListMode, 'dmodFrequency',SSBFreq);

minWidth = 16+4*CRParams.sigma; %16+6*CRParams.sigma; 
stepsize = 4;
pulseLength = minWidth:stepsize:(numsteps-1)*stepsize+minWidth;
% pulseLength = 160;
% angle = linspace(0, pi, numsteps);
angle = 1.193;
% amps = 3800:15:4985;
amps = 4000;
clockCycle = q1Params.pulseLength+q1Params.buffer;

patseq1  = {...
    {pg1.pulse('Xp'), pg1.pulse('QId', 'duration', pulseLength), pg1.pulse('Xp'), pg1.pulse('QId', 'duration', pulseLength), pg1.pulse('QId')},...
    {pg1.pulse('Xp'), pg1.pulse('QId', 'duration', pulseLength), pg1.pulse('Xp')}...
    };
patseqCR = {...
    pgCR.pulse('Utheta', 'angle', angle, 'pType', 'dragGaussOn', 'width', 2*CRParams.sigma, 'amp', amps), ...
    pgCR.pulse('Utheta', 'angle', angle, 'width', pulseLength-4*CRParams.sigma, 'pType', 'square', 'amp', amps*(1-exp(-2))), ...
    pgCR.pulse('Utheta', 'angle', angle, 'pType', 'dragGaussOff', 'width', 2*CRParams.sigma, 'amp', amps), ...
    pgCR.pulse('QId', 'width', clockCycle), ...
    pgCR.pulse('Utheta', 'angle', angle+pi, 'pType', 'dragGaussOn', 'width', 2*CRParams.sigma, 'amp', amps), ...
    pgCR.pulse('Utheta', 'angle', angle+pi, 'width', pulseLength-4*CRParams.sigma, 'pType', 'square', 'amp', amps*(1-exp(-2))), ...
    pgCR.pulse('Utheta', 'angle', angle+pi, 'pType', 'dragGaussOff', 'width', 2*CRParams.sigma, 'amp', amps), ...
    pgCR.pulse('QId', 'duration', clockCycle) ...
    };

% patseq2 = {{pg2.pulse('U90p', 'angle', pi/2)}, {pg2.pulse('U90p', 'angle', pi/2)}};
patseq2 = {{pg2.pulse('X90p')}, {pg2.pulse('X90p')}};
patseqCR = repmat({patseqCR}, 1, 2);

% patseqCR = {...
%     pgCR.pulse('Xtheta', 'width', pulseLength, 'sigma', pulseLength/4, 'amp', amps), ...
%     pgCR.pulse('QId', 'width', q1Params.pulseLength + q1Params.buffer), ...
%     pgCR.pulse('Xtheta', 'width', pulseLength, 'sigma', pulseLength/4, 'amp', amps), ...
%     pgCR.pulse('QId', 'width', q1Params.pulseLength + q1Params.buffer), ...
%     };

% calseq1 = [];
% calseqCR = [];
calseq1 = {{pg1.pulse('QId')}, {pg1.pulse('QId')}};
calseq2 = {{pg2.pulse('QId')}, {pg2.pulse('Xp')}};
calseqCR = {{pgCR.pulse('QId')}, {pgCR.pulse('QId')}};

seqParams = struct(...
    'basename', basename, ...
    'suffix', '', ...
    'numSteps', numsteps, ...
    'nbrRepeats', nbrRepeats, ...
    'fixedPt', fixedPt, ...
    'cycleLength', cycleLength, ...
    'measLength', 2000);
patternDict = containers.Map();
if ~isempty(calseq1), calseq1 = {calseq1}; end
if ~isempty(calseq2), calseq2 = {calseq2}; end
if ~isempty(calseqCR), calseqCR = {calseqCR}; end
patternDict(IQkey1) = struct('pg', pg1, 'patseq', {patseq1}, 'calseq', calseq1, 'channelMap', qubitMap.(controlQ));
patternDict(IQkey2) = struct('pg', pg2, 'patseq', {patseq2}, 'calseq', calseq2, 'channelMap', qubitMap.(targetQ));
patternDict(IQkeyCR) = struct('pg', pgCR, 'patseq', {patseqCR}, 'calseq', calseqCR, 'channelMap', qubitMap.CR);
measChannels = {'M1'};
awgs = {'TekAWG', 'BBNAPS1', 'BBNAPS2'};

plotSeqNum = 70;

compileSequences(seqParams, patternDict, measChannels, awgs, makePlot, plotSeqNum);

end
