function CR12StateTomoSequence(makePlot)

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


measDelay = -64;

q3Params = params.q3; 
IQkeyQ3 = 'BBNAPS12';
pgQ3 = PatternGen('dPiAmp', q3Params.piAmp, 'dPiOn2Amp', q3Params.pi2Amp, 'dSigma', q3Params.sigma, 'dPulseType', q3Params.pulseType, 'dDelta', q3Params.delta, 'correctionT', params.(IQkeyQ3).T, 'dBuffer', q3Params.buffer, 'dPulseLength', q3Params.pulseLength, 'cycleLength', cycleLength, 'passThru', params.(IQkeyQ3).passThru);

q2Params = params.q2; % choose target qubit here
IQkeyQ2 = 'TekAWG34';
pgQ2 = PatternGen('dPiAmp', q2Params.piAmp, 'dPiOn2Amp', q2Params.pi2Amp, 'dSigma', q2Params.sigma, 'dPulseType', q2Params.pulseType, 'dDelta', q2Params.delta, 'correctionT', params.(IQkeyQ2).T, 'dBuffer', q2Params.buffer, 'dPulseLength', q2Params.pulseLength, 'cycleLength', cycleLength, 'passThru', params.(IQkeyQ2).passThru);

CR32Params = params.CR32;
IQkeyCR = 'TekAWG34';
pgCR32 = PatternGen('dPiAmp', CR32Params.piAmp, 'dPiOn2Amp', CR32Params.pi2Amp, 'dSigma', CR32Params.sigma, 'dPulseType', CR32Params.pulseType, 'dDelta', CR32Params.delta, 'correctionT', params.(IQkeyCR).T, 'dBuffer', CR32Params.buffer, 'dPulseLength', CR32Params.pulseLength, 'cycleLength', cycleLength, 'passThru', params.(IQkeyCR).passThru);

%AWG5014 CHs (3,4) is Q2 single-qubit and CR drive
%APS CHs (1,2) is drive Q3 at 
delayDiff = params.(IQkeyCR).delay - params.(IQkeyQ3).delay;
clockCycle = max(q2Params.pulseLength+q2Params.buffer, q3Params.pulseLength+q3Params.buffer);

PosPulsesQ2{1} = pgQ2.pulse('QId', 'duration', clockCycle);
PosPulsesQ2{2} = pgQ2.pulse('Xp', 'duration', clockCycle);
PosPulsesQ2{3} = pgQ2.pulse('X90p', 'duration', clockCycle);
PosPulsesQ2{4} = pgQ2.pulse('Y90p', 'duration', clockCycle);

PosPulsesQ3{1} = pgQ3.pulse('QId', 'duration', clockCycle);
PosPulsesQ3{2} = pgQ3.pulse('Xp', 'duration', clockCycle);
PosPulsesQ3{3} = pgQ3.pulse('X90p', 'duration', clockCycle);
PosPulsesQ3{4} = pgQ3.pulse('Y90p', 'duration', clockCycle);

nbrPosPulses = length(PosPulsesQ2);

numsteps = 1;
crossresstep = 10;
crossreswidths = 1708+(0:crossresstep:(numsteps-1)*crossresstep);

patseqQ3 = cell(84,1);
patseqQ2CR = cell(84,1);

for nindex = 1:numsteps
    currcrossreswidth = crossreswidths(nindex);  
    %basename = sprintf('CR21_%d',currcrossreswidth);
    
    prepPulseQ2 = pgQ2.pulse('QId', 'duration', clockCycle);
    prepPulseQ3 = pgQ3.pulse('X90p', 'duration', clockCycle); %X90p
    
    processPulseQ3 = pgQ3.pulse('QId', 'width', currcrossreswidth);
    processPulsesCR32 = {pgCR32.pulse('Xp', 'pType', 'dragGaussOn', 'width', 3*CR32Params.sigma, 'duration', 3*CR32Params.sigma), pgCR32.pulse('Xp', 'width', currcrossreswidth-6*CR32Params.sigma, 'pType', 'square'), pgCR32.pulse('Xp', 'pType', 'dragGaussOff', 'width', 3*CR32Params.sigma, 'duration', 3*CR32Params.sigma)};
    
    %ADD IN CALIBRATIONS

    patseqQ3{1}={pgQ3.pulse('QId')};
    patseqQ3{2}={pgQ3.pulse('QId')};
    patseqQ3{3}={pgQ3.pulse('QId')};
    patseqQ3{4}={pgQ3.pulse('QId')};
    patseqQ3{5}={pgQ3.pulse('Xp')};
    patseqQ3{6}={pgQ3.pulse('Xp')};
    patseqQ3{7}={pgQ3.pulse('Xp')};
    patseqQ3{8}={pgQ3.pulse('Xp')};
    patseqQ3{9}={pgQ3.pulse('QId')};
    patseqQ3{10}={pgQ3.pulse('QId')};
    patseqQ3{11}={pgQ3.pulse('QId')};
    patseqQ3{12}={pgQ3.pulse('QId')};
    patseqQ3{13}={pgQ3.pulse('Xp')};
    patseqQ3{14}={pgQ3.pulse('Xp')};
    patseqQ3{15}={pgQ3.pulse('Xp')};
    patseqQ3{16}={pgQ3.pulse('Xp')};

    patseqQ2CR{1}= {pgQ2.pulse('QId')};
    patseqQ2CR{2}= {pgQ2.pulse('QId')};
    patseqQ2CR{3}= {pgQ2.pulse('QId')};
    patseqQ2CR{4}= {pgQ2.pulse('QId')};
    patseqQ2CR{5}= {pgQ2.pulse('QId')};
    patseqQ2CR{6}= {pgQ2.pulse('QId')};
    patseqQ2CR{7}= {pgQ2.pulse('QId')};
    patseqQ2CR{8}= {pgQ2.pulse('QId')};
    patseqQ2CR{9}= {pgQ2.pulse('Xp')};
    patseqQ2CR{10}={pgQ2.pulse('Xp')};
    patseqQ2CR{11}={pgQ2.pulse('Xp')};
    patseqQ2CR{12}={pgQ2.pulse('Xp')};
    patseqQ2CR{13}={pgQ2.pulse('Xp')};
    patseqQ2CR{14}={pgQ2.pulse('Xp')};
    patseqQ2CR{15}={pgQ2.pulse('Xp')};
    patseqQ2CR{16}={pgQ2.pulse('Xp')};

    nbrRepeats = 4;
    indexct = 1;
    for iindex = 1:nbrPosPulses
        for jindex = 1:nbrPosPulses
            for kindex=1:nbrRepeats
                patseqQ3{16+indexct}={prepPulseQ3,processPulseQ3,PosPulsesQ3{iindex}};
                patseqQ2CR{16+indexct}=[{prepPulseQ2},processPulsesCR32,{PosPulsesQ2{jindex}}];
                indexct = indexct+1;
            end
        end
    end
    
    patseqQ3{81} = {pgQ3.pulse('QId')};
    patseqQ3{82} = {pgQ3.pulse('QId')};
    patseqQ3{83} = {pgQ3.pulse('QId')};
    patseqQ3{84} = {pgQ3.pulse('QId')};

    patseqQ2CR{81} = {pgQ2.pulse('QId')};
    patseqQ2CR{82} = {pgQ2.pulse('QId')};
    patseqQ2CR{83} = {pgQ2.pulse('QId')};
    patseqQ2CR{84} = {pgQ2.pulse('QId')};

    nbrPulses = 4+16+nbrPosPulses^2*nbrRepeats;
    
    % pre-allocate space
    Q2CR_I = zeros(nbrPulses, cycleLength);
    Q2CR_Q = zeros(nbrPulses, cycleLength);
    Q3buffer = zeros(nbrPulses, cycleLength); Q2CRbuffer = zeros(nbrPulses, cycleLength);
    PulseCollectionCR = [];
    Q3_I_seq = cell(nbrPulses,1);  Q3_Q_seq = cell(nbrPulses,1); 
    for n = 1:nbrPulses
        % Q3, build for APS
        numsteps = 1;
        [Q3_I_seq{n}, Q3_Q_seq{n}, ~, PulseCollectionCR] = pgQ3.build(patseqQ3{n}, numsteps, params.(IQkeyQ3).delay, fixedPt, PulseCollectionCR);
        patxQ3 = pgQ3.linkListToPattern(Q3_I_seq{n}, 1)';
        patyQ3 = pgQ3.linkListToPattern(Q3_Q_seq{n}, 1)';
        patxQ3 = circshift(patxQ3, delayDiff);
        patyQ3 = circshift(patyQ3, delayDiff);
        Q3buffer(n, :) = pgQ3.bufferPulse(patxQ3, patyQ3, 0, params.(IQkeyQ3).bufferPadding, params.(IQkeyQ3).bufferReset, params.(IQkeyQ3).bufferDelay);

        % Q2 + CR build for TekAWG
        [patx paty] = pgQ2.getPatternSeq(patseqQ2CR{n}, n, params.(IQkeyCR).delay, fixedPt);
        Q2CR_I(n, :) = patx + params.(IQkeyCR).offset;
        Q2CR_Q(n, :) = paty + params.(IQkeyCR).offset;
        Q2CRbuffer(n, :) = pgQ2.bufferPulse(patx, paty, 0, params.(IQkeyQ2).bufferPadding, params.(IQkeyQ2).bufferReset, params.(IQkeyQ2).bufferDelay);

    end
    
    % trigger slave AWG (the APS) at beginning
    % trigger digitizer at beginning of measurement pulse
    measLength = 3000;
    measSeq = {pgQ2.pulse('M', 'width', measLength)};
    slaveTrigger = zeros(nbrPulses, cycleLength);
    measTrigger = zeros(nbrPulses, cycleLength);
    measCH = zeros(nbrPulses, cycleLength);
    
    for n = 1:nbrPulses
        measTrigger(n,:) = pgQ2.makePattern([], fixedPt-500, ones(100,1), cycleLength);
        measCH(n,:) = int32(pgQ2.getPatternSeq(measSeq, n, measDelay, fixedPt+measLength));
        slaveTrigger(n,:) = pgQ2.makePattern([], 5, ones(100,1), cycleLength);
    end

    % Channel assignment
    ch1 = params.TekAWG12.offset*ones(nbrPulses, cycleLength);
    ch1m1 = measTrigger;
    ch1m2 = measCH;
    ch2 = params.TekAWG12.offset*ones(nbrPulses, cycleLength);
    ch2m1 = zeros(nbrPulses, cycleLength);
    ch2m2 = slaveTrigger;
    ch3 = Q2CR_I;
    ch3m1 = Q3buffer;
    ch3m2 = zeros(nbrPulses, cycleLength);
    ch4 = Q2CR_Q;
    ch4m1 = Q2CRbuffer;
    ch4m2 = slaveTrigger;
    
    if makePlot
        myn = 38;
        figure
        plot(ch1(myn,:)-8192)
        hold on
        plot(ch2(myn,:)-8192, 'r')
        plot(ch3(myn,:)-8192, 'b')
        plot(ch4(myn,:)-8192, 'r')
        ch5 = pgQ3.linkListToPattern(Q3_I_seq{myn}, 1)';
        ch6 = pgQ3.linkListToPattern(Q3_I_seq{myn}, 1)';
        plot(ch5, 'm')
        plot(ch6, 'c')
        plot(2000*ch1m2(myn,:), 'g')
        plot(1000*ch3m1(myn,:), 'r')
        plot(1000*ch4m1(myn,:), 'r:')
        plot(2000*ch1m1(myn,:),':')
        grid on
        hold off
    end

    % unify LLs and waveform libs
    ch5seq = Q3_I_seq{1}; ch6seq = Q3_Q_seq{1};
    for n = 2:nbrPulses
        for m = 1:length(Q3_I_seq{n}.linkLists)
            ch5seq.linkLists{end+1} = Q3_I_seq{n}.linkLists{m};
            ch6seq.linkLists{end+1} = Q3_Q_seq{n}.linkLists{m};
        end
    end
    ch5seq.waveforms = APSPattern.unifySequenceLibraryWaveformsSingle(Q3_I_seq);
    ch6seq.waveforms = APSPattern.unifySequenceLibraryWaveformsSingle(Q3_Q_seq);

    % make APS file
    exportAPSConfig(tempdir, basename, ch5seq, ch6seq, ch5seq, ch6seq);
    disp('Moving APS file to destination');
    movefile([tempdir basename '.mat'], [pathAPS basename '.mat']);
    % make TekAWG file
    options = struct('m21_high', 2.0, 'm41_high', 2.0);
    TekPattern.exportTekSequence(tempdir, basename, ch1, ch1m1, ch1m2, ch2, ch2m1, ch2m2, ch3, ch3m1, ch3m2, ch4, ch4m1, ch4m2, options);
    disp('Moving AWG file to destination');
    movefile([tempdir basename '.awg'], [pathAWG basename '.awg']);
end

    
