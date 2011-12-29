function CR21StateTomoSequence(makePlot)

if ~exist('makePlot', 'var')
    makePlot = true;
end
script = java.io.File(mfilename('fullpath'));
path = char(script.getParentFile().getParentFile().getParentFile().getParent());
addpath([path '/common/src'],'-END');
addpath([path '/common/src/util/'],'-END');

temppath = [char(script.getParent()) '\'];
pathAWG = 'U:\AWG\CrossRes\';
pathAPS = 'U:\APS\CrossRes\';

fixedPt = 13000;
cycleLength = 16000;

% load config parameters from file
parent_path = char(script.getParentFile.getParent());
cfg_path = [parent_path '/cfg/'];
load([cfg_path 'pulseParamBundles.mat'], 'Ts', 'delays', 'measDelay', 'bufferDelays', 'bufferResets', 'bufferPaddings', 'offsets', 'piAmps', 'pi2Amps', 'sigmas', 'pulseTypes', 'deltas', 'buffers', 'pulseLengths');

pg1 = PatternGen('dPiAmp', piAmps('q1'), 'dPiOn2Amp', pi2Amps('q1'), 'dSigma', sigmas('q1'), 'dPulseType', pulseTypes('q1'), 'dDelta', deltas('q1'), 'correctionT', Ts('12'), 'dBuffer', buffers('q1'), 'dPulseLength', pulseLengths('q1'), 'cycleLength', cycleLength);
pg2 = PatternGen('dPiAmp', piAmps('q2'), 'dPiOn2Amp', pi2Amps('q2'), 'dSigma', sigmas('q2'), 'dPulseType', pulseTypes('q2'), 'dDelta', deltas('q2'), 'correctionT', Ts('34'), 'dBuffer', buffers('q2'), 'dPulseLength', pulseLengths('q2'), 'cycleLength', cycleLength);
pg21 = PatternGen('dPiAmp', piAmps('q1q2'), 'dPiOn2Amp', pi2Amps('q1q2'), 'dSigma', sigmas('q1q2'), 'dPulseType', pulseTypes('q1q2'), 'dDelta', deltas('q1q2'), 'correctionT', Ts('56'), 'dBuffer', buffers('q1q2'), 'dPulseLength', pulseLengths('q1q2'), 'cycleLength', cycleLength, 'passThru', true);
%pg21 = PatternGen('dPiAmp', piAmp3, 'dPiOn2Amp', pi2Amp3, 'dSigma', sigma3, 'dPulseType', pulseType3, 'dDelta', delta3, 'correctionT', T3, 'dBuffer', buffer3, 'dPulseLength', pulseLength3, 'cycleLength', cycleLength);

%AWG5014 CHs (1,2) is Q1 single-qubit (pg1)
%AWG5014 CHs (3,4) is Q2 single-qubit (pg2)
%APS CHs (1,2) is drive Q1 at Q2 cross resonance (pg21)
delayQ1 = delays('12');
offsetQ1 = offsets('12');
delayQ2 = delays('34');
offsetQ2 = offsets('34');
delayCR21 = delays('56');
offsetCR21 = offsets('56');
clockCycle = max(pulseLengths('q1'), pulseLengths('q2'));
bufferPadding = bufferPaddings('12');
bufferReset = bufferResets('12');
bufferDelay = bufferDelays('12');
bufferPadding2 = bufferPaddings('34');
bufferReset2 = bufferResets('34');
bufferDelay2 = bufferDelays('34');
bufferPadding3 = bufferPaddings('56');
bufferReset3 = bufferResets('56');
bufferDelay3 = bufferDelays('56');

PosPulsesQ1{1} = pg1.pulse('QId', 'duration', clockCycle);
PosPulsesQ1{2} = pg1.pulse('Xp', 'duration', clockCycle);
PosPulsesQ1{3} = pg1.pulse('X90p', 'duration', clockCycle);
PosPulsesQ1{4} = pg1.pulse('Y90p', 'duration', clockCycle);

PosPulsesQ2{1} = pg2.pulse('QId', 'duration', clockCycle);
PosPulsesQ2{2} = pg2.pulse('Xp', 'duration', clockCycle);
PosPulsesQ2{3} = pg2.pulse('X90p', 'duration', clockCycle);
PosPulsesQ2{4} = pg2.pulse('Y90p', 'duration', clockCycle);

nbrPosPulses = length(PosPulsesQ1);

numsteps = 1;
crossresstep = 10;
crossreswidths = 924+(0:crossresstep:(numsteps-1)*crossresstep);

ampCR = 5800; %8000
%angle = 102*(pi/180);
angle = 0;
%deltastep=0.1;
%delta4s=-2.5-(0:deltastep:(numsteps-1)*deltastep);

for nindex = 1:numsteps
    currcrossreswidth = crossreswidths(nindex);  
    %currcrossreswidth = 236;
    %currdeltaCR12 = delta4s(nindex);
    %stringcurrdelta4 = 10*currdeltaCR12;
    currdeltaCR12 = deltas('q1q2');
    basename = sprintf('CR21_%d',currcrossreswidth);
    
    %basename = sprintf('CR21Dm%d',nindex);
    prepPulseQ1 = pg1.pulse('X90p', 'duration', clockCycle);
    prepPulseQ2 = pg2.pulse('QId', 'duration', clockCycle);
    prepPulseCR21 = pg21.pulse('QId', 'duration', clockCycle);
    
    processPulseQ1 = pg1.pulse('QId', 'width', currcrossreswidth);
    processPulseQ2 = pg2.pulse('QId', 'width', currcrossreswidth);
    processPulseCR21 = pg21.pulse('Utheta', 'amp', ampCR, 'angle', angle, 'width', currcrossreswidth, 'pType', 'square');
    % jerry had the CR21 pulse type as 'dragSq'
    
    %ADD IN CALIBRATIONS

    patseqQ1{1}={pg1.pulse('QId')};
    patseqQ1{2}={pg1.pulse('QId')};
    patseqQ1{3}={pg1.pulse('QId')};
    patseqQ1{4}={pg1.pulse('QId')};
    patseqQ1{5}={pg1.pulse('Xp')};
    patseqQ1{6}={pg1.pulse('Xp')};
    patseqQ1{7}={pg1.pulse('Xp')};
    patseqQ1{8}={pg1.pulse('Xp')};
    patseqQ1{9}={pg1.pulse('QId')};
    patseqQ1{10}={pg1.pulse('QId')};
    patseqQ1{11}={pg1.pulse('QId')};
    patseqQ1{12}={pg1.pulse('QId')};
    patseqQ1{13}={pg1.pulse('Xp')};
    patseqQ1{14}={pg1.pulse('Xp')};
    patseqQ1{15}={pg1.pulse('Xp')};
    patseqQ1{16}={pg1.pulse('Xp')};

    patseqQ2{1}= {pg2.pulse('QId')};
    patseqQ2{2}= {pg2.pulse('QId')};
    patseqQ2{3}= {pg2.pulse('QId')};
    patseqQ2{4}= {pg2.pulse('QId')};
    patseqQ2{5}= {pg2.pulse('QId')};
    patseqQ2{6}= {pg2.pulse('QId')};
    patseqQ2{7}= {pg2.pulse('QId')};
    patseqQ2{8}= {pg2.pulse('QId')};
    patseqQ2{9}= {pg2.pulse('Xp')};
    patseqQ2{10}={pg2.pulse('Xp')};
    patseqQ2{11}={pg2.pulse('Xp')};
    patseqQ2{12}={pg2.pulse('Xp')};
    patseqQ2{13}={pg2.pulse('Xp')};
    patseqQ2{14}={pg2.pulse('Xp')};
    patseqQ2{15}={pg2.pulse('Xp')};
    patseqQ2{16}={pg2.pulse('Xp')};

    for dumindex = 1:16
        patseqCR21{dumindex} = {pg21.pulse('QId')};
    end
    
    nbrRepeats = 4;
    for iindex = 1:nbrPosPulses
        for jindex = 1:nbrPosPulses
            for kindex=1:nbrRepeats
                patseqQ1{16+(iindex-1)*nbrPosPulses*nbrRepeats+(jindex-1)*nbrRepeats+kindex}={prepPulseQ1,processPulseQ1,PosPulsesQ1{iindex}};
                patseqQ2{16+(iindex-1)*nbrPosPulses*nbrRepeats+(jindex-1)*nbrRepeats+kindex}={prepPulseQ2,processPulseQ2,PosPulsesQ2{jindex}};
                patseqCR21{16+(iindex-1)*nbrPosPulses*nbrRepeats+(jindex-1)*nbrRepeats+kindex}={prepPulseCR21,processPulseCR21,pg21.pulse('QId', 'duration', clockCycle)};
            end
        end
    end
    
    patseqQ1{81} = {pg1.pulse('QId')};
    patseqQ1{82} = {pg1.pulse('QId')};
    patseqQ1{83} = {pg1.pulse('QId')};
    patseqQ1{84} = {pg1.pulse('QId')};

    patseqQ2{81} = {pg2.pulse('QId')};
    patseqQ2{82} = {pg2.pulse('QId')};
    patseqQ2{83} = {pg2.pulse('QId')};
    patseqQ2{84} = {pg2.pulse('QId')};

    patseqCR21{81} = {pg21.pulse('QId')};
    patseqCR21{82} = {pg21.pulse('QId')};
    patseqCR21{83} = {pg21.pulse('QId')};
    patseqCR21{84} = {pg21.pulse('QId')};
    
    nbrPulses = 4+16+nbrPosPulses^2*nbrRepeats;
    
    % pre-allocate space
    Q1_I = zeros(nbrPulses, cycleLength);
    Q1_Q = Q1_I;
    Q2_I = Q1_I;
    Q2_Q = Q1_I;
    Q1buffer = Q1_I; Q2buffer = Q1_I; CR21buffer = Q1_I;
    PulseCollectionCR = [];
    
    for n = 1:nbrPulses
        % Q1
        [patx paty] = pg1.getPatternSeq(patseqQ1{n}, n, delayQ1, fixedPt);
        Q1_I(n, :) = patx + offsetQ1;
        Q1_Q(n, :) = paty + offsetQ1;
        Q1buffer(n, :) = pg1.bufferPulse(patx, paty, 0, bufferPadding, bufferReset, bufferDelay);
        
        % Q2
        [patx paty] = pg2.getPatternSeq(patseqQ2{n}, n, delayQ2, fixedPt);
        Q2_I(n, :) = patx + offsetQ2;
        Q2_Q(n, :) = paty + offsetQ2;
        Q2buffer(n, :) = pg1.bufferPulse(patx, paty, 0, bufferPadding2, bufferReset2, bufferDelay2);
        
        % CR21, build for APS
        numsteps = 1;
        [CR21_I_seq{n}, CR21_Q_seq{n}, ~, PulseCollectionCR] = pg21.build(patseqCR21{n}, numsteps, delayCR21, fixedPt, PulseCollectionCR);
    
        patx = pg21.linkListToPattern(CR21_I_seq{n}, 1)';
        paty = pg21.linkListToPattern(CR21_Q_seq{n}, 1)';
        CR21buffer(n, :) = pg21.bufferPulse(patx, paty, 0, bufferPadding3, bufferReset3, bufferDelay3);
    end
    
    % trigger slave AWG (the APS) at beginning
    % trigger digitizer at beginning of measurement pulse
    measLength = 3000;
    measSeq = {pg1.pulse('M', 'width', measLength)};
    slaveTrigger = zeros(nbrPulses, cycleLength);
    measTrigger = zeros(nbrPulses, cycleLength);
    measCH = zeros(nbrPulses, cycleLength);
    
    for n = 1:nbrPulses
        measTrigger(n,:) = pg1.makePattern([], fixedPt-500, ones(100,1), cycleLength);
        measCH(n,:) = int32(pg1.getPatternSeq(measSeq, n, measDelay, fixedPt+measLength));
        slaveTrigger(n,:) = pg1.makePattern([], 5, ones(100,1), cycleLength);
    end

    % Channel assignment
    %AWG5014 CHs (1,2) is Q1 single-qubit (pg1)
    %AWG5014 CHs (3,4) is Q2 single-qubit (pg2)
    %APS CHs (1,2) is drive Q1 at Q2 cross resonance (pg21)
    ch1 = Q1_I;
    ch1m1 = measTrigger;
    ch1m2 = measCH;
    ch2 = Q1_Q;
    ch2m1 = CR21buffer;
    ch2m2 = slaveTrigger;
    ch3 = Q2_I;
    ch3m1 = Q1buffer;
    ch3m2 = zeros(nbrPulses, cycleLength);
    ch4 = Q2_Q;
    ch4m1 = Q2buffer;
    ch4m2 = slaveTrigger;
    
    if makePlot
        myn = 38;
        figure
        plot(ch1(myn,:))
        hold on
        plot(ch2(myn,:), 'r')
        plot(ch3(myn,:), ':')
        plot(ch4(myn,:), 'r:')
        ch5 = pg21.linkListToPattern(CR21_I_seq{myn}, 1)';
        ch6 = pg21.linkListToPattern(CR21_Q_seq{myn}, 1)';
        plot(ch5, 'm')
        plot(ch6, 'c')
        plot(5000*ch1m2(myn,:), 'g')
        plot(1000*ch3m1(myn,:), 'r')
        plot(5000*ch1m1(myn,:),'.')
        grid on
        hold off
    end

    % unify LLs and waveform libs
    ch5seq = CR21_I_seq{1}; ch6seq = CR21_Q_seq{1};
    for n = 2:nbrPulses
        for m = 1:length(CR21_I_seq{n}.linkLists)
            ch5seq.linkLists{end+1} = CR21_I_seq{n}.linkLists{m};
            ch6seq.linkLists{end+1} = CR21_Q_seq{n}.linkLists{m};
        end
    end
    ch5seq.waveforms = deviceDrivers.APS.unifySequenceLibraryWaveformsSingle(CR21_I_seq);
    ch6seq.waveforms = deviceDrivers.APS.unifySequenceLibraryWaveformsSingle(CR21_Q_seq);

    % make APS file
    exportAPSConfig(temppath, basename, ch5seq, ch6seq, ch5seq, ch6seq);
    disp('Moving APS file to destination');
    movefile([temppath basename '.mat'], [pathAPS basename '.mat']);
    % make TekAWG file
    options = struct('m21_high', 2.0, 'm41_high', 2.0);
    TekPattern.exportTekSequence(temppath, basename, ch1, ch1m1, ch1m2, ch2, ch2m1, ch2m2, ch3, ch3m1, ch3m2, ch4, ch4m1, ch4m2, options);
    disp('Moving AWG file to destination');
    movefile([temppath basename '.awg'], [pathAWG basename '.awg']);
end

    
