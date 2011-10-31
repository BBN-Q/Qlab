function StateTomoDecoupleSequence(makePlot)

if ~exist('makePlot', 'var')
    makePlot = true;
end
script = java.io.File(mfilename('fullpath'));
path = char(script.getParentFile().getParentFile().getParentFile().getParent());
addpath([path '/common/src'],'-END');
addpath([path '/common/src/util/'],'-END');

temppath = [char(script.getParent()) '\'];
pathAWG = 'U:\AWG\StateTomo\';
pathAPS = 'U:\APS\StateTomo\';

Q1pulse = 'Xp';
Q2pulse = 'QId';

basename = [Q1pulse Q2pulse 'DD'];

fixedPt = 13000;
cycleLength = 16000;

% load config parameters from file
parent_path = char(script.getParentFile.getParent());
cfg_path = [parent_path '/cfg/'];
load([cfg_path 'pulseParams.mat'], 'T', 'delay', 'measDelay', 'bufferDelay', 'bufferReset', 'bufferPadding', 'offset', 'piAmp', 'pi2Amp', 'sigma', 'pulseType', 'delta', 'buffer', 'pulseLength');
load([cfg_path 'pulseParams.mat'], 'T2', 'delay2', 'bufferDelay2', 'bufferReset2', 'bufferPadding2', 'offset2', 'piAmp2', 'pi2Amp2', 'sigma2', 'pulseType2', 'delta2', 'buffer2', 'pulseLength2');
load([cfg_path 'pulseParams.mat'], 'T3', 'delay3', 'bufferDelay3', 'bufferReset3', 'bufferPadding3', 'offset3', 'piAmp3', 'pi2Amp3', 'sigma3', 'pulseType3', 'delta3', 'buffer3', 'pulseLength3');

pg1 = PatternGen('dPiAmp', piAmp, 'dPiOn2Amp', pi2Amp, 'dSigma', sigma, 'dPulseType', pulseType, 'dDelta', delta, 'correctionT', T, 'dBuffer', buffer, 'dPulseLength', pulseLength, 'cycleLength', cycleLength);
pg2 = PatternGen('dPiAmp', piAmp2, 'dPiOn2Amp', pi2Amp2, 'dSigma', sigma2, 'dPulseType', pulseType2, 'dDelta', delta2, 'correctionT', T2, 'dBuffer', buffer2, 'dPulseLength', pulseLength2, 'cycleLength', cycleLength);
pg21 = PatternGen('dPiAmp', piAmp3, 'dPiOn2Amp', pi2Amp3, 'dSigma', sigma3, 'dPulseType', pulseType3, 'dDelta', delta3, 'correctionT', T3, 'dBuffer', buffer3, 'dPulseLength', pulseLength3, 'cycleLength', cycleLength);

%AWG5014 CHs (1,2) is Q1 single-qubit (pg1)
%AWG5014 CHs (3,4) is Q2 single-qubit (pg2)
%APS CHs (1,2) is drive Q1 at Q2 cross resonance (pg21)
delayQ1 = delay;
offsetQ1 = offset;
delayQ2 = delay2;
offsetQ2 = offset2;
delayCR21 = delay3;
offsetCR21 = offset3;

% decoupling pulses to sandwich around all single-qubit operations
decoupleQ1{1} = pg1.pulse('QId');
decoupleQ1{2} = pg1.pulse('QId');
decoupleQ2{1} = pg2.pulse('Xm');
decoupleQ2{2} = pg2.pulse('Xp');

PosPulsesQ1{1} = pg1.pulse('QId');
PosPulsesQ1{2} = pg1.pulse('Xp');
PosPulsesQ1{3} = pg1.pulse('X90p');
PosPulsesQ1{4} = pg1.pulse('Y90p');

PosPulsesQ2{1} = pg2.pulse('QId');
PosPulsesQ2{2} = pg2.pulse('Xp');
PosPulsesQ2{3} = pg2.pulse('X90p');
PosPulsesQ2{4} = pg2.pulse('Y90p');

nbrPosPulses = length(PosPulsesQ1);

numsteps = 1;
crossresstep = 10;
crossreswidths = 152+(0:crossresstep:(numsteps-1)*crossresstep);

ampCR = 5800; %8000
angle = 0;

for nindex = 1:numsteps
    currcrossreswidth = crossreswidths(nindex);  
    %basename = sprintf('CR21_%d',currcrossreswidth);
    
    prepPulseQ1 = pg1.pulse('QId');
    prepPulseQ2 = pg2.pulse('QId');
    prepPulseCR21 = {'QId'};
    
    processPulseQ1 = pg1.pulse(Q1pulse);
    processPulseQ2 = pg2.pulse(Q2pulse);
    processPulseCR21 = {'QId'};
    
    %ADD IN CALIBRATIONS

    patseqQ1{1}={pg1.pulse('QId')};
    patseqQ1{2}={pg1.pulse('QId')};
    patseqQ1{3}={pg1.pulse('QId')};
    patseqQ1{4}={pg1.pulse('QId')};
    patseqQ1{5}={pg1.pulse('Xp'),pg1.pulse('QId')};
    patseqQ1{6}={pg1.pulse('Xp'),pg1.pulse('QId')};
    patseqQ1{7}={pg1.pulse('Xp'),pg1.pulse('QId')};
    patseqQ1{8}={pg1.pulse('Xp'),pg1.pulse('QId')};
    patseqQ1{9}={pg1.pulse('QId')};
    patseqQ1{10}={pg1.pulse('QId')};
    patseqQ1{11}={pg1.pulse('QId')};
    patseqQ1{12}={pg1.pulse('QId')};
    patseqQ1{13}={pg1.pulse('Xp'),pg1.pulse('QId')};
    patseqQ1{14}={pg1.pulse('Xp'),pg1.pulse('QId')};
    patseqQ1{15}={pg1.pulse('Xp'),pg1.pulse('QId')};
    patseqQ1{16}={pg1.pulse('Xp'),pg1.pulse('QId')};

    patseqQ2{1}= {pg2.pulse('QId')};
    patseqQ2{2}= {pg2.pulse('QId')};
    patseqQ2{3}= {pg2.pulse('QId')};
    patseqQ2{4}= {pg2.pulse('QId')};
    patseqQ2{5}= {pg2.pulse('QId')};
    patseqQ2{6}= {pg2.pulse('QId')};
    patseqQ2{7}= {pg2.pulse('QId')};
    patseqQ2{8}= {pg2.pulse('QId')};
    patseqQ2{9}= {pg2.pulse('QId'),pg2.pulse('Xp')};
    patseqQ2{10}={pg2.pulse('QId'),pg2.pulse('Xp')};
    patseqQ2{11}={pg2.pulse('QId'),pg2.pulse('Xp')};
    patseqQ2{12}={pg2.pulse('QId'),pg2.pulse('Xp')};
    patseqQ2{13}={pg2.pulse('QId'),pg2.pulse('Xp')};
    patseqQ2{14}={pg2.pulse('QId'),pg2.pulse('Xp')};
    patseqQ2{15}={pg2.pulse('QId'),pg2.pulse('Xp')};
    patseqQ2{16}={pg2.pulse('QId'),pg2.pulse('Xp')};

    for dumindex = 1:16
        patseqCR21{dumindex} = {{'QId'}};
    end
    
    nbrRepeats = 4;
    for iindex = 1:nbrPosPulses
        for jindex = 1:nbrPosPulses
            for kindex=1:nbrRepeats
                patseqQ1{16+(iindex-1)*nbrPosPulses*nbrRepeats+(jindex-1)*nbrRepeats+kindex}=...
                    {prepPulseQ1,... % prepare (do nothing in this case)
                    decoupleQ1{1},processPulseQ1,decoupleQ1{2},... % process
                    decoupleQ1{1},PosPulsesQ1{iindex},decoupleQ1{2},... % Q1 tomography pulse
                    decoupleQ1{1},pg1.pulse('QId'),decoupleQ1{2}}; % Q2 tomography pulse
                patseqQ2{16+(iindex-1)*nbrPosPulses*nbrRepeats+(jindex-1)*nbrRepeats+kindex}=...
                    {prepPulseQ2,... % prepare (do nothing in this case)
                    decoupleQ2{1},processPulseQ2,decoupleQ2{2},... % process
                    decoupleQ2{1},pg2.pulse('QId'),decoupleQ2{2},... % Q1 tomography pulse
                    decoupleQ2{1},PosPulsesQ2{jindex},decoupleQ2{2},... % Q2 tomography pulse
                    };
                patseqCR21{16+(iindex-1)*nbrPosPulses*nbrRepeats+(jindex-1)*nbrRepeats+kindex}={prepPulseCR21,processPulseCR21,{'QId'}};
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

    patseqCR21{81} = {{'QId'}};
    patseqCR21{82} = {{'QId'}};
    patseqCR21{83} = {{'QId'}};
    patseqCR21{84} = {{'QId'}};
    
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
        %numsteps = 1;
        %[CR21_I_seq{n}, CR21_Q_seq{n}, ~, PulseCollectionCR] = pg21.build(patseqCR21{n}, numsteps, delayCR21, fixedPt, PulseCollectionCR);
    
        %patx = pg21.linkListToPattern(CR21_I_seq{n}, 1)';
        %paty = pg21.linkListToPattern(CR21_Q_seq{n}, 1)';
        %CR21buffer(n, :) = pg21.bufferPulse(patx, paty, 0, bufferPadding3, bufferReset3, bufferDelay3);
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
    
    if makePlot
        myn = 38;
        figure
        plot(Q1_I(myn,:))
        hold on
        plot(Q1_Q(myn,:), 'r')
        plot(Q2_I(myn,:),':')
        plot(Q2_Q(myn,:), 'r:')
        grid on
        hold off
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

    % unify LLs and waveform libs
%     ch5seq = CR21_I_seq{1}; ch6seq = CR21_Q_seq{1};
%     for n = 2:nbrPulses
%         for m = 1:length(CR21_I_seq{n}.linkLists)
%             ch5seq.linkLists{end+1} = CR21_I_seq{n}.linkLists{m};
%             ch6seq.linkLists{end+1} = CR21_Q_seq{n}.linkLists{m};
%         end
%     end
%     ch5seq.waveforms = deviceDrivers.APS.unifySequenceLibraryWaveformsSingle(CR21_I_seq);
%     ch6seq.waveforms = deviceDrivers.APS.unifySequenceLibraryWaveformsSingle(CR21_Q_seq);

    % make APS file
    %exportAPSConfig(temppath, basename, ch5seq, ch6seq, ch5seq, ch6seq);
    %disp('Moving APS file to destination');
    %movefile([temppath basename '.mat'], [pathAPS basename '.mat']);
    % make TekAWG file
    options = struct('m21_high', 2.0, 'm41_high', 2.0);
    TekPattern.exportTekSequence(temppath, basename, ch1, ch1m1, ch1m2, ch2, ch2m1, ch2m2, ch3, ch3m1, ch3m2, ch4, ch4m1, ch4m2, options);
    disp('Moving AWG file to destination');
    movefile([temppath basename '.awg'], [pathAWG basename '.awg']);
end
