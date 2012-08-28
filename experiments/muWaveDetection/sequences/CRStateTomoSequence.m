function CRStateTomoSequence(makePlot)

if ~exist('makePlot', 'var')
    makePlot = true;
end

basename = 'CrossRes';

fixedPt = 2000;
cycleLength = 4000;
nbrRepeats = 2;
numsteps = 1;

% load config parameters from file
params = jsonlab.loadjson(getpref('qlab', 'pulseParamsBundleFile'));
qubitMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));

controlQ = 'q3';
targetQ = 'q1';
q1Params = params.(controlQ);
IQkey1 = qubitMap.(controlQ).IQkey;
q2Params = params.(targetQ);
IQkey2 = qubitMap.(targetQ).IQkey;
CRParams = params.CR;
IQkeyCR = qubitMap.CR.IQkey;

% CRWidths = 96:8:320;
% expct = 1;
% for CRWidth = CRWidths

% if using SSB, set the frequency here
SSBFreq = 0e6;
pg1 = PatternGen('dPiAmp', q1Params.piAmp, 'dPiOn2Amp', q1Params.pi2Amp, 'dSigma', q1Params.sigma, 'dPulseType', q1Params.pulseType, 'dDelta', q1Params.delta, 'correctionT', params.(IQkey1).T, 'dBuffer', q1Params.buffer, 'dPulseLength', q1Params.pulseLength, 'cycleLength', cycleLength, 'linkList', params.(IQkey1).linkListMode, 'dmodFrequency',SSBFreq);

SSBFreq = 0e6;
pg2 = PatternGen('dPiAmp', q2Params.piAmp, 'dPiOn2Amp', q2Params.pi2Amp, 'dSigma', q2Params.sigma, 'dPulseType', q2Params.pulseType, 'dDelta', q2Params.delta, 'correctionT', params.(IQkey2).T, 'dBuffer', q2Params.buffer, 'dPulseLength', q2Params.pulseLength, 'cycleLength', cycleLength, 'linkList', params.(IQkey2).linkListMode, 'dmodFrequency',SSBFreq);

SSBFreq = 0e6;
CRParams.buffer = 0;
pgCR = PatternGen('dPiAmp', CRParams.piAmp, 'dPiOn2Amp', CRParams.pi2Amp, 'dSigma', CRParams.sigma, 'dPulseType', CRParams.pulseType, 'dDelta', CRParams.delta, 'correctionT', params.(IQkeyCR).T, 'dBuffer', CRParams.buffer, 'dPulseLength', CRParams.pulseLength, 'cycleLength', cycleLength, 'linkList', params.(IQkeyCR).linkListMode, 'dmodFrequency',SSBFreq);

clockCycle = max(q1Params.pulseLength+q1Params.buffer, q2Params.pulseLength+q2Params.buffer);

TomoPulsesQ1{1} = pg1.pulse('QId', 'duration', clockCycle);
TomoPulsesQ1{2} = pg1.pulse('Xp', 'duration', clockCycle);
TomoPulsesQ1{3} = pg1.pulse('X90p', 'duration', clockCycle);
TomoPulsesQ1{4} = pg1.pulse('Y90p', 'duration', clockCycle);

TomoPulsesQ2{1} = pg2.pulse('QId', 'duration', clockCycle);
TomoPulsesQ2{2} = pg2.pulse('Xp', 'duration', clockCycle);
TomoPulsesQ2{3} = pg2.pulse('X90p', 'duration', clockCycle);
TomoPulsesQ2{4} = pg2.pulse('Y90p', 'duration', clockCycle);

nbrTomoPulses = length(TomoPulsesQ1);

prepPulseQ1 = pg1.pulse('Y90p', 'duration', clockCycle);
%prepPulseQ1 = pg1.pulse('QId', 'duration', clockCycle);
prepPulseQ2 = pg2.pulse('QId', 'duration', clockCycle); 

patseq1 = cell(20,1);
patseq2 = cell(20,1);
patseqCR = cell(20,1);

CRWidth = 16;
CRAmp = 0;
processPulseQ1 = pg1.pulse('QId', 'width', CRWidth+16);
processPulseQ2 = pg2.pulse('QId', 'width', CRWidth+16);
processPulsesCR = {pgCR.pulse('QId','width', CRWidth)};
% processPulsesCR = [{pgCR.pulse('Xtheta', 'pType', 'dragGaussOn', 'width', 2.5*CRParams.sigma, 'amp', CRAmp)},...
%         {pgCR.pulse('Xtheta', 'width', CRWidth-5*CRParams.sigma, 'pType', 'square', 'amp', CRAmp)},...
%         {pgCR.pulse('Xtheta', 'pType', 'dragGaussOff', 'width', 2.5*CRParams.sigma, 'amp', CRAmp)},...
%         {pgCR.pulse('QId', 'duration', clockCycle + 8 )}...
%         ];

%ADD IN CALIBRATIONS

patseq1{1}={pg1.pulse('QId')};
patseq1{2}={pg1.pulse('Xp')};
patseq1{3}={pg1.pulse('QId')};
patseq1{4}={pg1.pulse('Xp')};

patseq2{1}= {pg2.pulse('QId')};
patseq2{2}={pg2.pulse('QId')};
patseq2{3}= {pg2.pulse('Xp')};
patseq2{4}={pg2.pulse('Xp')};

patseqCR{1} = {pgCR.pulse('QId')};
patseqCR{2} = {pgCR.pulse('QId')};
patseqCR{3} = {pgCR.pulse('QId')};
patseqCR{4} = {pgCR.pulse('QId')};

indexct = 1;
for ct1 = 1:nbrTomoPulses
    for ct2 = 1:nbrTomoPulses
        patseq1{4+indexct} = {prepPulseQ1, processPulseQ1, TomoPulsesQ1{ct1}};
        patseq2{4+indexct} = {prepPulseQ2, processPulseQ2, TomoPulsesQ2{ct2}};
        patseqCR{4+indexct} = processPulsesCR;
        indexct = indexct+1;
    end
end

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
patternDict(IQkey1) = struct('pg', pg1, 'patseq', {patseq1}, 'calseq', calseq, 'channelMap', qubitMap.(controlQ));
patternDict(IQkey2) = struct('pg', pg2, 'patseq', {patseq2}, 'calseq', calseq, 'channelMap', qubitMap.(targetQ));
patternDict(IQkeyCR) = struct('pg', pgCR, 'patseq', {patseqCR}, 'calseq', calseq, 'channelMap', qubitMap.CR);
measChannels = {'M1'};
awgs = {'TekAWG', 'BBNAPS'};

plotSeqNum = 10;

compileSequences(seqParams, patternDict, measChannels, awgs, makePlot, plotSeqNum);

% expct = expct + 1;
% end


end