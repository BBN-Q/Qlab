function CRStateTomoSequence(controlQ, targetQ, makePlot)

basename = 'CrossRes';

fixedPt = 2000;
cycleLength = 4100;
nbrRepeats = 2;
numsteps = 1;

% load config parameters from file
params = jsonlab.loadjson(getpref('qlab', 'pulseParamsBundleFile'));
qubitMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));

% if using SSB, set the frequency here
SSBFreq = 0e6;
pg1 = PatternGen(controlQ, 'SSBFreq', SSBFreq, 'cycleLength', cycleLength);

SSBFreq = 0e6;
pg2 = PatternGen(targetQ, 'SSBFreq', SSBFreq, 'cycleLength', cycleLength);

SSBFreq = 0;
pgCR = PatternGen('CR', 'SSBFreq', SSBFreq, 'cycleLength', cycleLength, 'buffer', 0);

q1Params = params.(controlQ);
IQkey1 = qubitMap.(controlQ).IQkey;
q2Params = params.(targetQ);
IQkey2 = qubitMap.(targetQ).IQkey;
CRParams = params.CR;
IQkeyCR = qubitMap.CR.IQkey;

expct = 1;
% CRWidths = 64:4:132;
% for CRWidth = CRWidths
angles = 0:pi/64:pi;
% for angle = angles
% if using SSB, set the frequency here
SSBFreq = 0e6;
pg1 = PatternGen(controlQ, 'SSBFreq', SSBFreq, 'cycleLength', cycleLength);

SSBFreq = 0e6;
pg2 = PatternGen(targetQ, 'SSBFreq', SSBFreq, 'cycleLength', cycleLength);

SSBFreq = 0;
pgCR = PatternGen('CR', 'SSBFreq', SSBFreq, 'cycleLength', cycleLength, 'buffer', 0);

channelParams = jsonlab.loadjson(getpref('qlab', 'pulseParamsBundleFile'));
clockCycle = max(channelParams.(controlQ).pulseLength+channelParams.(controlQ).buffer,...
                        channelParams.(targetQ).pulseLength+channelParams.(targetQ).buffer);
CRParams = channelParams.CR;

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
% prepPulseQ1 = pg1.pulse('Xp', 'duration', clockCycle);
prepPulseQ2 = pg2.pulse('QId', 'duration', clockCycle); 

patSeq1 = cell(16,1);
patSeq2 = cell(16,1);
patSeqCR = cell(16,1);

CRWidth = 160;
angle = 0;
CRAmp = 8000;

%%%%%%%%%%%%%% Refocussed %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% processPulseQ1 = pg1.pulse('Xp', 'duration', 2*CRWidth+clockCycle);
% processPulseQ2 = pg2.pulse('QId', 'width', 2*CRWidth+clockCycle);
% processPulsesCR = {...
%     pgCR.pulse('Utheta', 'angle', angle, 'pType', 'dragGaussOn', 'width', 2*CRParams.sigma, 'amp', CRAmp), ...
%     pgCR.pulse('Utheta', 'angle', angle, 'width', CRWidth-4*CRParams.sigma, 'pType', 'square', 'amp', CRAmp*(1-exp(-2))), ...
%     pgCR.pulse('Utheta', 'angle', angle, 'pType', 'dragGaussOff', 'width', 2*CRParams.sigma, 'amp', CRAmp), ...
%     pgCR.pulse('QId', 'width', clockCycle+24), ...
%     pgCR.pulse('Utheta', 'angle', angle+pi, 'pType', 'dragGaussOn', 'width', 2*CRParams.sigma, 'amp', CRAmp), ...
%     pgCR.pulse('Utheta', 'angle', angle+pi, 'width', CRWidth-4*CRParams.sigma, 'pType', 'square', 'amp', CRAmp*(1-exp(-2))), ...
%     pgCR.pulse('Utheta', 'angle', angle+pi, 'pType', 'dragGaussOff', 'width', 2*CRParams.sigma, 'amp', CRAmp), ...
%     pgCR.pulse('QId', 'duration', clockCycle+8) ...
%     };


%%%%%%%%%%%%%% Regular %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
processPulseQ1 = pg1.pulse('QId', 'duration', CRWidth);
processPulseQ2 = pg2.pulse('QId', 'duration', CRWidth);
processPulsesCR = {...
    pgCR.pulse('Utheta', 'angle', angle, 'pType', 'dragGaussOn', 'width', 2*CRParams.sigma, 'amp', CRAmp), ...
    pgCR.pulse('Utheta', 'angle', angle, 'width', CRWidth-4*CRParams.sigma, 'pType', 'square', 'amp', CRAmp*(1-exp(-2))), ...
    pgCR.pulse('Utheta', 'angle', angle, 'pType', 'dragGaussOff', 'width', 2*CRParams.sigma, 'amp', CRAmp)};


%%%%%%%%%%%%%% QId testing %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% processPulsesCR = {pgCR.pulse('QId','width', CRWidth)};

indexct = 1;
for ct1 = 1:nbrTomoPulses
    for ct2 = 1:nbrTomoPulses
        patSeq1{indexct} = {prepPulseQ1, processPulseQ1, TomoPulsesQ1{ct1}};
        patSeq2{indexct} = {prepPulseQ2, processPulseQ2, TomoPulsesQ2{ct2}};
        patSeqCR{indexct} = {processPulsesCR{:}, pgCR.pulse('QId', 'duration', clockCycle)};
        indexct = indexct+1;
    end
end

%ADD IN CALIBRATIONS
calSeq1{1}={pg1.pulse('QId')};
calSeq1{2}={pg1.pulse('Xp')};
calSeq1{3}={pg1.pulse('QId')};
calSeq1{4}={pg1.pulse('Xp')};
calSeq2{1}= {pg2.pulse('QId')};
calSeq2{2}={pg2.pulse('QId')};
calSeq2{3}= {pg2.pulse('Xp')};
calSeq2{4}={pg2.pulse('Xp')};
calSeqCR{1} = {pgCR.pulse('QId')};
calSeqCR{2} = {pgCR.pulse('QId')};
calSeqCR{3} = {pgCR.pulse('QId')};
calSeqCR{4} = {pgCR.pulse('QId')};

seqParams = struct(...
    'basename', basename, ...
    'suffix', '',... %num2str(expct),...%num2str(expct), ...
    'numSteps', numsteps, ...
    'nbrRepeats', nbrRepeats, ...
    'fixedPt', fixedPt, ...
    'cycleLength', cycleLength, ...
    'measLength', 2000);

qubitMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));
IQkey1 = qubitMap.(controlQ).IQkey;
IQkey2 = qubitMap.(targetQ).IQkey;
IQkeyCR = qubitMap.CR.IQkey;

patternDict = containers.Map();
patternDict(IQkey1) = struct('pg', pg1, 'patseq', {patSeq1}, 'calseq', {calSeq1}, 'channelMap', qubitMap.(controlQ));
patternDict(IQkey2) = struct('pg', pg2, 'patseq', {patSeq2}, 'calseq', {calSeq2}, 'channelMap', qubitMap.(targetQ));
patternDict(IQkeyCR) = struct('pg', pgCR, 'patseq', {patSeqCR}, 'calseq', {calSeqCR}, 'channelMap', qubitMap.CR);

measChannels = {'M1'};
awgs = {'TekAWG', 'BBNAPS1', 'BBNAPS2'};

compileSequences(seqParams, patternDict, measChannels, awgs, makePlot);

expct = expct + 1;

% end


end