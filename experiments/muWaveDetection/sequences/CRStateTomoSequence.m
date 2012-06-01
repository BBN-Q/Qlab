function CRStateTomoSequence(makePlot)

if ~exist('makePlot', 'var')
    makePlot = true;
end

pathAWG = 'U:\AWG\CrossRes\';
pathAPS = 'U:\APS\CrossRes\';
basename = 'CrossRes';

fixedPt = 2000;
cycleLength = 12000;

% load config parameters from file
params = jsonlab.loadjson(getpref('qlab', 'pulseParamsBundleFile'));
qubitMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));
params.measDelay = -64;

q1Params = params.q1;
IQkey1 = qubitMap.q1.IQkey;
q2Params = params.q2;
IQkey2 = qubitMap.q2.IQkey;
CRParams = params.CR;
IQkeyCR = qubitMap.CR.IQkey;

CRAmps = 4200:5:4600;
expct = 1;
for CRAmp = CRAmps

% if using SSB, set the frequency here
SSBFreq = 0e6;
pg1 = PatternGen('dPiAmp', q1Params.piAmp, 'dPiOn2Amp', q1Params.pi2Amp, 'dSigma', q1Params.sigma, 'dPulseType', q1Params.pulseType, 'dDelta', q1Params.delta, 'correctionT', params.(IQkey1).T, 'dBuffer', q1Params.buffer, 'dPulseLength', q1Params.pulseLength, 'cycleLength', cycleLength, 'linkList', params.(IQkey1).linkListMode, 'dmodFrequency',SSBFreq);

pg2 = PatternGen('dPiAmp', q2Params.piAmp, 'dPiOn2Amp', q2Params.pi2Amp, 'dSigma', q2Params.sigma, 'dPulseType', q2Params.pulseType, 'dDelta', q2Params.delta, 'correctionT', params.(IQkey2).T, 'dBuffer', q2Params.buffer, 'dPulseLength', q2Params.pulseLength, 'cycleLength', cycleLength, 'linkList', params.(IQkey2).linkListMode, 'dmodFrequency',SSBFreq);

SSBFreq = 0e6;
CRParams.buffer = 0;
pgCR = PatternGen('dPiAmp', CRParams.piAmp, 'dPiOn2Amp', CRParams.pi2Amp, 'dSigma', CRParams.sigma, 'dPulseType', CRParams.pulseType, 'dDelta', CRParams.delta, 'correctionT', params.(IQkeyCR).T, 'dBuffer', CRParams.buffer, 'dPulseLength', CRParams.pulseLength, 'cycleLength', cycleLength, 'linkList', params.(IQkeyCR).linkListMode, 'dmodFrequency',SSBFreq);


%AWG5014 is qubit control pulses
%APS CHs (1,2) is CR drive at Q2's frequency
delayDiff = params.(IQkey1).delay - params.(IQkeyCR).delay;
clockCycle = max(q1Params.pulseLength+q1Params.buffer, q2Params.pulseLength+q2Params.buffer);

PosPulsesQ1{1} = pg1.pulse('QId', 'duration', clockCycle);
PosPulsesQ1{2} = pg1.pulse('Xp', 'duration', clockCycle);
PosPulsesQ1{3} = pg1.pulse('X90p', 'duration', clockCycle);
PosPulsesQ1{4} = pg1.pulse('Y90p', 'duration', clockCycle);

PosPulsesQ2{1} = pg2.pulse('QId', 'duration', clockCycle);
PosPulsesQ2{2} = pg2.pulse('Xp', 'duration', clockCycle);
PosPulsesQ2{3} = pg2.pulse('X90p', 'duration', clockCycle);
PosPulsesQ2{4} = pg2.pulse('Y90p', 'duration', clockCycle);

nbrPosPulses = length(PosPulsesQ1);

prepPulseQ1 = pg1.pulse('Y90p', 'duration', clockCycle);
prepPulseQ2 = pg2.pulse('QId', 'duration', clockCycle); %X90p

patseq1 = cell(20,1);
patseq2 = cell(20,1);
patseqCR = cell(20,1);

CRWidth = 204;
% CRAmp = 4370;
processPulseQ1 = pg1.pulse('QId', 'width', CRWidth);
processPulseQ2 = pg2.pulse('QId', 'width', CRWidth);
% processPulsesCR = {pgCR.pulse('QId','width', CRWidth)};
processPulsesCR = [{pgCR.pulse('Xtheta', 'pType', 'dragGaussOn', 'width', 3*CRParams.sigma, 'amp', CRAmp)},...
        {pgCR.pulse('Xtheta', 'width', CRWidth-6*CRParams.sigma, 'pType', 'square', 'amp', CRAmp)},...
        {pgCR.pulse('Xtheta', 'pType', 'dragGaussOff', 'width', 3*CRParams.sigma, 'amp', CRAmp)},...
        {pgCR.pulse('QId', 'width', q1Params.pulseLength + q1Params.buffer )}...
        ];

%ADD IN CALIBRATIONS

patseq1{1}={pg1.pulse('QId')};
patseq1{2}={pg1.pulse('QId')};
patseq1{3}={pg1.pulse('Xp')};
patseq1{4}={pg1.pulse('Xp')};

patseq2{1}= {pg2.pulse('QId')};
patseq2{2}={pg2.pulse('Xp')};
patseq2{3}= {pg2.pulse('QId')};
patseq2{4}={pg2.pulse('Xp')};

patseqCR{1} = {pgCR.pulse('QId')};
patseqCR{2} = {pgCR.pulse('QId')};
patseqCR{3} = {pgCR.pulse('QId')};
patseqCR{4} = {pgCR.pulse('QId')};

indexct = 1;
for ct1 = 1:nbrPosPulses
    for ct2 = 1:nbrPosPulses
        patseq1{4+indexct}={prepPulseQ1,processPulseQ1, PosPulsesQ1{ct1}};
        patseq2{4+indexct}= {prepPulseQ2,processPulseQ2,PosPulsesQ2{ct2}};
        patseqCR{4+indexct} = processPulsesCR;
        indexct = indexct+1;
    end
end

ch1 = zeros(length(patseq1), cycleLength);
ch2 = ch1;
ch3 = ch1;
ch4 = ch1;
ch1m1 = ch1; ch1m2 = ch1;
ch2m1 = ch1; ch2m2 = ch1;
ch3m1 = ch1; ch3m2 = ch1;
ch4m1 = ch1; ch4m2 = ch1;
delayDiff = params.(IQkey1).delay - params.(IQkeyCR).delay;

for n = 1:length(patseq1);
    [patx paty] = pg1.getPatternSeq(patseq1{n}, 1, params.(IQkey1).delay, fixedPt);
	ch3(n, :) = patx + params.(IQkey1).offset;
	ch4(n, :) = paty + params.(IQkey1).offset;
    ch4m1(n, :) = pg1.bufferPulse(patx, paty, 0, params.(IQkey1).bufferPadding, params.(IQkey1).bufferReset, params.(IQkey1).bufferDelay);
    
    [patx paty] = pg2.getPatternSeq(patseq2{n}, 1, params.(IQkey2).delay, fixedPt);
    ch1(n, :) = patx + params.(IQkey2).offset;
    ch2(n, :) = paty + params.(IQkey2).offset;
    ch3m1(n, :) = pg2.bufferPulse(patx, paty, 0, params.(IQkey2).bufferPadding, params.(IQkey2).bufferReset, params.(IQkey2).bufferDelay);
    
    CRseq{n} = pgCR.build(patseqCR{n}, 1, params.(IQkeyCR).delay, fixedPt, true);
    % construct buffer for APS pulses
    [patx, paty] = pgCR.linkListToPattern(CRseq{n}, 1);
    % remove difference of delays
    patx = circshift(patx, [0, delayDiff]);
    paty = circshift(paty, [0, delayDiff]);
    
    tmpGate = pgCR.bufferPulse(patx, paty, 0, params.(IQkeyCR).bufferPadding, params.(IQkeyCR).bufferReset, params.(IQkeyCR).bufferDelay);

    ch3m1(n, :) = ch3m1(n,:) | tmpGate';

end

% trigger at fixedPt-500
% measure from (fixedPt:fixedPt+measLength)
measLength = 8000;
measSeq = {pg1.pulse('M', 'width', measLength)};
for n = 1:length(patseq1);
	ch1m1(n,:) = pg1.makePattern([], fixedPt-500, ones(100,1), cycleLength);
	ch1m2(n,:) = int32(pg1.getPatternSeq(measSeq, n, params.measDelay, fixedPt+measLength));
    ch4m2(n,:) = pg1.makePattern([], 5, ones(100,1), cycleLength);
end

ch56seq = CRseq{1};
for n = 2:length(CRseq)
    for m = 1:length(CRseq{n}.linkLists)
        ch56seq.linkLists{end+1} = CRseq{n}.linkLists{m};
    end
end

if makePlot
    myn = 4;
    figure
    plot(ch1(myn,:))
    hold on
    plot(ch2(myn,:), 'r')
    plot(ch3(myn,:), 'b--')
    plot(ch4(myn,:), 'r--')
    [ch5, ch6] = pgCR.linkListToPattern(ch56seq, myn);
    plot(ch5, 'm')
    plot(ch6, 'c')
    plot(5000*ch1m2(myn,:), 'g')
    plot(1000*ch2m1(myn,:), 'r')
    plot(5000*ch3m1(myn,:),'.')
    plot(5000*ch4m1(myn,:),'y.')
    grid on
    hold off
end


% make APS file
strippedBasename = basename;
% basename = [basename 'BBNAPS34'];
% make APS file
exportAPSConfig(tempdir, basename, ch56seq, ch56seq);
disp('Moving APS file to destination');
if ~exist(['U:\APS\' strippedBasename '\'], 'dir')
    mkdir(['U:\APS\' strippedBasename '\']);
end
pathAPS = ['U:\APS\' strippedBasename '\' basename sprintf('_%d.h5', expct)];
disp('Moving APS file to destination');
movefile([tempdir basename '.h5'], pathAPS);


% make TekAWG file
basename = strippedBasename;
options = struct('m21_high', 2.0, 'm41_high', 2.0);
TekPattern.exportTekSequence(tempdir, basename, ch1, ch1m1, ch1m2, ch2, ch2m1, ch2m2, ch3, ch3m1, ch3m2, ch4, ch4m1, ch4m2, options);
disp('Moving AWG file to destination');
movefile([tempdir basename '.awg'], [pathAWG basename sprintf('_%d.awg', expct)]);

expct = expct + 1;
end


end