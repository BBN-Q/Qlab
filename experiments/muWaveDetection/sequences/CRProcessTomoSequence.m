function CRProcessTomoSequence(makePlot)

if ~exist('makePlot', 'var')
    makePlot = true;
end

basename = 'CrossRes';

fixedPt = 1000;
cycleLength = 3000;
nbrRepeats = 1;
numsteps = 1;

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

% CRAmps = 4200:5:4600;
expct = 1;
% for CRAmp = CRAmps

%4 Pulse version
% PosPulsesQ1{1} = pg1.pulse('QId', 'duration', clockCycle);
% PosPulsesQ1{2} = pg1.pulse('Xp', 'duration', clockCycle);
% PosPulsesQ1{3} = pg1.pulse('X90p', 'duration', clockCycle);
% PosPulsesQ1{4} = pg1.pulse('Y90p', 'duration', clockCycle);
%
% PosPulsesQ2{1} = pg2.pulse('QId', 'duration', clockCycle);
% PosPulsesQ2{2} = pg2.pulse('Xp', 'duration', clockCycle);
% PosPulsesQ2{3} = pg2.pulse('X90p', 'duration', clockCycle);
% PosPulsesQ2{4} = pg2.pulse('Y90p', 'duration', clockCycle);

%6-Pulse Set ('QId', 'Xp', 'X90p', 'Y90p', 'X90m', 'Y90m')
numPulses = 6;
pulseSet = {'QId', 'Xp', 'X90p', 'Y90p', 'X90m', 'Y90m'};

for prepct1 = 1:numPulses
    for prepct2 = 1:numPulses
        
        
        % if using SSB, set the frequency here
        SSBFreq = 0e6;
        pg1 = PatternGen(controlQ, 'SSBFreq', SSBFreq, 'cycleLength', cycleLength);

        SSBFreq = 0e6;
        pg2 = PatternGen(targetQ, 'SSBFreq', SSBFreq, 'cycleLength', cycleLength);

        SSBFreq = 0e6;
        pgCR = PatternGen('CR, 'SSBFreq', SSBFreq, 'cycleLength', cycleLength, 'buffer', 0);
        clockCycle = max(q1Params.pulseLength+q1Params.buffer, q2Params.pulseLength+q2Params.buffer);
        
        
        SPAMPulsesQ1 = cell(numPulses,1); SPAMPulsesQ2 = cell(numPulses,1);
        for ct = 1:numPulses
            SPAMPulsesQ1{ct} = pg1.pulse(pulseSet{ct}, 'duration',clockCycle);
            SPAMPulsesQ2{ct} = pg2.pulse(pulseSet{ct}, 'duration',clockCycle);
        end
        
        
        CRWidth = 96;
        CRAmp = 4000;

        processPulseQ1 = pg1.pulse('Xp', 'duration', 2*CRWidth+clockCycle+24);
        processPulseQ2 = pg2.pulse('QId', 'width', 2*CRWidth+clockCycle+24);
        
%         processPulseQ1 = pg1.pulse('QId', 'width', CRWidth+16);
%         processPulseQ2 = pg2.pulse('QId', 'width', CRWidth+16);
%         processPulsesCR = {pgCR.pulse('QId','width', CRWidth)};
%         processPulsesCR = [{pgCR.pulse('Xtheta', 'pType', 'dragGaussOn', 'width', 2*CRParams.sigma, 'amp', CRAmp)},...
%                 {pgCR.pulse('Xtheta', 'width', CRWidth-4*CRParams.sigma, 'pType', 'square', 'amp', CRAmp)},...
%                 {pgCR.pulse('Xtheta', 'pType', 'dragGaussOff', 'width', 2*CRParams.sigma, 'amp', CRAmp)},...
%                 {pgCR.pulse('QId', 'duration', 2*clockCycle + 8 )}...
%                ];
angle = 1.718;
processPulsesCR = {...
    pgCR.pulse('Utheta', 'angle', angle, 'pType', 'dragGaussOn', 'width', 2*CRParams.sigma, 'amp', CRAmp), ...
    pgCR.pulse('Utheta', 'angle', angle, 'width', CRWidth-4*CRParams.sigma, 'pType', 'square', 'amp', CRAmp*(1-exp(-2))), ...
    pgCR.pulse('Utheta', 'angle', angle, 'pType', 'dragGaussOff', 'width', 2*CRParams.sigma, 'amp', CRAmp), ...
    pgCR.pulse('QId', 'width', clockCycle+24), ...
    pgCR.pulse('Utheta', 'angle', angle+pi, 'pType', 'dragGaussOn', 'width', 2*CRParams.sigma, 'amp', CRAmp), ...
    pgCR.pulse('Utheta', 'angle', angle+pi, 'width', CRWidth-4*CRParams.sigma, 'pType', 'square', 'amp', CRAmp*(1-exp(-2))), ...
    pgCR.pulse('Utheta', 'angle', angle+pi, 'pType', 'dragGaussOff', 'width', 2*CRParams.sigma, 'amp', CRAmp), ...
    pgCR.pulse('QId', 'duration', 2*clockCycle+8) ...
    };

           
        patSeq1 = cell(numPulses^2,1);
        patSeq2 = cell(numPulses^2,1);
        patSeqCR = cell(numPulses^2,1);
        indexct = 1;
        for measct1 = 1:numPulses
            for measct2 = 1:numPulses
                patSeq1{indexct}= {SPAMPulsesQ1{prepct1}, SPAMPulsesQ1{1}, processPulseQ1, SPAMPulsesQ1{measct1}, SPAMPulsesQ1{1}};
                patSeq2{indexct}= {SPAMPulsesQ2{1}, SPAMPulsesQ2{prepct2}, processPulseQ2, SPAMPulsesQ2{1}, SPAMPulsesQ2{measct2}};
                patSeqCR{indexct} = processPulsesCR;
                indexct = indexct+1;
            end
        end
        
        %ADD IN CALIBRATIONS
        calSeq1 = cell(4,1);
        calSeq1{1}={pg1.pulse('QId')};
        calSeq1{2}={pg1.pulse('QId')};
        calSeq1{3}={pg1.pulse('Xp')};
        calSeq1{4}={pg1.pulse('Xp')};
        
        calSeq2 = cell(4,1);
        calSeq2{1}= {pg2.pulse('QId')};
        calSeq2{2}={pg2.pulse('Xp')};
        calSeq2{3}= {pg2.pulse('QId')};
        calSeq2{4}={pg2.pulse('Xp')};
        
        calSeqCR = cell(4,1);
        calSeqCR{1} = {pgCR.pulse('QId')};
        calSeqCR{2} = {pgCR.pulse('QId')};
        calSeqCR{3} = {pgCR.pulse('QId')};
        calSeqCR{4} = {pgCR.pulse('QId')};
        
%         patSeq1 = [];
%         patSeq2 = [];
%         patSeqCR = [];
        
        seqParams = struct(...
            'basename', basename, ...
            'suffix', num2str(expct),...%num2str(expct), ...
            'numSteps', numsteps, ...
            'nbrRepeats', nbrRepeats, ...
            'fixedPt', fixedPt, ...
            'cycleLength', cycleLength, ...
            'measLength', 2000);
        patternDict = containers.Map();
        patternDict(IQkey1) = struct('pg', pg1, 'patseq', {patSeq1}, 'calseq', {calSeq1}, 'channelMap', qubitMap.(controlQ));
        patternDict(IQkey2) = struct('pg', pg2, 'patseq', {patSeq2}, 'calseq', {calSeq2}, 'channelMap', qubitMap.(targetQ));
        patternDict(IQkeyCR) = struct('pg', pgCR, 'patseq', {patSeqCR}, 'calseq', {calSeqCR}, 'channelMap', qubitMap.CR);
        measChannels = {'M1'};
        awgs = {'TekAWG', 'BBNAPS'};

        plotSeqNum = 1;

        compileSequences(seqParams, patternDict, measChannels, awgs, makePlot, plotSeqNum);
        
        expct = expct + 1;
    end
end


end