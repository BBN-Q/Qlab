function OverhurtQProcess2Q(makePlot)

if ~exist('makePlot', 'var')
    makePlot = true;
end

pathAWG = 'U:\AWG\OverhurtQProcess\';
basename = 'OverhurtQProcess2Q';

fixedPt = 1000;
cycleLength = 5000;

% load config parameters from file
params = jsonlab.loadjson(getpref('qlab', 'pulseParamsBundleFile'));
qubitMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));
params.measDelay = -64;

q1Params = params.q1;
IQkey1 = qubitMap.q1.IQkey;
q2Params = params.q2;
IQkey2 = qubitMap.q2.IQkey;

% if using SSB, set the frequency here
SSBFreq = 0e6;
pg1 = PatternGen('dPiAmp', q1Params.piAmp, 'dPiOn2Amp', q1Params.pi2Amp, 'dSigma', q1Params.sigma, 'dPulseType', q1Params.pulseType, 'dDelta', q1Params.delta, 'correctionT', params.(IQkey1).T, 'dBuffer', q1Params.buffer, 'dPulseLength', q1Params.pulseLength, 'cycleLength', cycleLength, 'linkList', params.(IQkey1).linkListMode, 'dmodFrequency',SSBFreq);
pg2 = PatternGen('dPiAmp', q2Params.piAmp, 'dPiOn2Amp', q2Params.pi2Amp, 'dSigma', q2Params.sigma, 'dPulseType', q2Params.pulseType, 'dDelta', q2Params.delta, 'correctionT', params.(IQkey2).T, 'dBuffer', q2Params.buffer, 'dPulseLength', q2Params.pulseLength, 'cycleLength', cycleLength, 'linkList', params.(IQkey2).linkListMode, 'dmodFrequency',SSBFreq);

%AWG5014 is qubit control pulses

%Tomography gate sets

%4-Pulse Set (QId, Xp, X90p, Y90p)
%gateSet = [1, 3, 2, 5];

%6-Pulse Set ('QId', 'Xp', 'X90p', 'Y90p', 'X90m', 'Y90m')
%gateSet = [1, 3, 2, 5, 4, 7];

%12-Pulse Set
% gateSet = [1, 3, 6, 9, 21, 19, 23, 18, 17, 20, 24, 22];

% Hey antonio, here's the pulse you want use x and y  pi and +- pi/2 gates
% 
% identity
% 1) I
% 
% the three pi rotations
% 2) x_pi
% 3) y_pi
% 4) x_pi y_pi
% 
% and then all eight combinations of +- pi/2 where you dont do a pi or
% the idenitiy
% 
% 5) x_pi/2 y_pi/2
% 6) x_pi/2 y_-pi/2
% 7) x_-pi/2 y_pi/2
% 8) x_-pi/2 y_-pi/2
% 9) y_pi/2 x_pi/2
% 10) y_pi/2 x_-pi/2
% 11) y_-pi/2 x_pi/2
% 12) y_-pi/2 x_-pi/2

gateSet{1} = {'QId'};
gateSet{2} = {'Xp'};
gateSet{3} = {'Yp'};
gateSet{4} = {'Xp','Yp'};
gateSet{5} = {'X90p','Y90p'};
gateSet{6} = {'X90p','Y90m'};
gateSet{7} = {'X90m','Y90p'};
gateSet{8} = {'X90m','Y90m'};
gateSet{9} = {'Y90p','X90p'};
gateSet{10} = {'Y90p','X90m'};
gateSet{11} = {'Y90m','X90p'};
gateSet{12} = {'Y90m','X90m'};

numGates = length(gateSet);


processPulseQ1 = pg1.pulse('QId');
processPulseQ2 = pg2.pulse('X90p');

%Create the measurement and preppulses
gateSetQ1 = cell(numGates,1);
gateSetQ2 = cell(numGates,1);

for ct = 1:numGates
%     gateSetQ1{ct} = CliffPulse(gateSet(ct), pg1);
%     gateSetQ2{ct} = CliffPulse(gateSet(ct), pg2);
    switch length(gateSet{ct})
        case 1
            gateSetQ1{ct} = {pg1.pulse(gateSet{ct}{1})};
            gateSetQ2{ct} = {pg2.pulse(gateSet{ct}{1})};
        case 2
            gateSetQ1{ct} = {pg1.pulse(gateSet{ct}{1}), pg1.pulse(gateSet{ct}{2})};
            gateSetQ2{ct} = {pg2.pulse(gateSet{ct}{1}), pg2.pulse(gateSet{ct}{2})};
    end            
end

%calibration sequences
calseqsQ1 = cell(4,1);
calseqsQ2 = cell(4,1);
calseqsQ1{1} = {pg1.pulse('QId')};
calseqsQ2{1} = {pg2.pulse('QId')};
calseqsQ1{2} = {pg1.pulse('QId')};
calseqsQ2{2} = {pg2.pulse('Xp')};
calseqsQ1{3} = {pg1.pulse('Xp')};
calseqsQ2{3} = {pg2.pulse('QId')};
calseqsQ1{4} = {pg1.pulse('Xp')};
calseqsQ2{4} = {pg2.pulse('Xp')};


%Create all the gate sequences
for prepct1 = 1:numGates
    indexct = 1;
    patseq1 = cell(numGates^3+length(calseqsQ1),1);
    patseq2 = cell(numGates^3+length(calseqsQ1),1);

    for prepct2 = 1:numGates
        for measct1 = 1:numGates
            for measct2 = 1:numGates
%                 patseq1{indexct} = {gateSetQ1{prepct1}, processPulseQ1, gateSetQ1{measct1}};
%                 patseq2{indexct} = {gateSetQ2{prepct2}, processPulseQ2, gateSetQ2{measct2}};
                patseq1{indexct} = [gateSetQ1{prepct1}, {processPulseQ1}, gateSetQ1{measct1}];
                patseq2{indexct} = [gateSetQ2{prepct2}, {processPulseQ2}, gateSetQ2{measct2}];
                indexct = indexct+1;
            end
        end
    end
    
    patseq1(end-3:end) = calseqsQ1(:);
    patseq2(end-3:end) = calseqsQ2(:);
    
    
    %Initialize all the channels
    ch1 = zeros(length(patseq1), cycleLength, 'double');
    ch2 = ch1;
    ch3 = ch1;
    ch4 = ch1;
    ch1m1 = zeros(length(patseq1), cycleLength, 'uint8'); ch1m2 = ch1m1;
    ch2m1 = ch1m1; ch2m2 = ch1m1;
    ch3m1 = ch1m1; ch3m2 = ch1m1;
    ch4m1 = ch1m1; ch4m2 = ch1m1;
    
    for n = 1:length(patseq1);
        [patx paty] = pg1.getPatternSeq(patseq1{n}, 1, params.(IQkey1).delay, fixedPt);
        ch3(n, :) = patx + params.(IQkey1).offset;
        ch4(n, :) = paty + params.(IQkey1).offset;
        ch4m1(n, :) = pg1.bufferPulse(patx, paty, 0, params.(IQkey1).bufferPadding, params.(IQkey1).bufferReset, params.(IQkey1).bufferDelay);
        
        [patx paty] = pg2.getPatternSeq(patseq2{n}, 1, params.(IQkey2).delay, fixedPt);
        ch1(n, :) = patx + params.(IQkey2).offset;
        ch2(n, :) = paty + params.(IQkey2).offset;
        ch3m1(n, :) = pg2.bufferPulse(patx, paty, 0, params.(IQkey2).bufferPadding, params.(IQkey2).bufferReset, params.(IQkey2).bufferDelay);
        
    end
    
    
    
    % trigger at fixedPt-500
    % measure from (fixedPt:fixedPt+measLength)
    measLength = 4000;
    measSeq = {pg1.pulse('M', 'width', measLength)};
    for n = 1:length(patseq1);
        ch1m1(n,:) = uint8(pg1.makePattern([], fixedPt-500, ones(100,1), cycleLength));
        ch1m2(n,:) = uint8(pg1.getPatternSeq(measSeq, n, params.measDelay, fixedPt+measLength));
        ch4m2(n,:) = uint8(pg1.makePattern([], 5, ones(100,1), cycleLength));
    end
    
    if makePlot
        myn = 14;
        figure
        plot(ch1(myn,:))
        hold on
        plot(ch2(myn,:), 'r')
        plot(ch3(myn,:), 'b--')
        plot(ch4(myn,:), 'r--')
        %ch5 = pg21.linkListToPattern(ch5seq, myn)';
        %ch6 = pg21.linkListToPattern(ch6seq, myn)';
        %plot(ch5, 'm')
        %plot(ch6, 'c')
        plot(5000*ch1m2(myn,:), 'g')
        plot(1000*ch2m1(myn,:), 'r')
        plot(5000*ch3m1(myn,:),'.')
        plot(5000*ch4m1(myn,:),'y.')
        grid on
        hold off
    end
    
    
    % make TekAWG file
    options = struct('m21_high', 2.0, 'm41_high', 2.0);
    TekPattern.exportTekSequence(tempdir, basename, ch1, ch1m1, ch1m2, ch2, ch2m1, ch2m2, ch3, ch3m1, ch3m2, ch4, ch4m1, ch4m2, options);
    disp('Moving AWG file to destination');
    movefile([tempdir basename '.awg'], [pathAWG basename '_' num2str(prepct1) '.awg']);
    
end

end




function outPulse = CliffPulse(cliffNum, pg)
%Create a pulse from a clifford Number.  Cliffords are numbered with 1 based indexing:

%Figure out the approximate nutation frequency calibration from the
%X180 and the the samplingRate
Xp = pg.pulse('Xp');
xpulse = Xp(1,0);
nutFreq = 0.5/(sum(xpulse)/pg.samplingRate);

defaultParams = {'pType', 'arbAxisDRAG', 'nutFreq', nutFreq, 'sampRate', pg.samplingRate, 'delta', 0};

switch cliffNum
    case 1
        %Identity gate
        outPulse = pg.pulse('QId');
    case 2
        %X90
        outPulse = pg.pulse('X90p');
    case 3
        %X180
        outPulse = pg.pulse('Xp');
    case 4
        %Xm90
        outPulse = pg.pulse('X90m');
    case 5
        %Y90
        outPulse = pg.pulse('Y90p');
    case 6
        %Y180
        outPulse = pg.pulse('Yp');
    case 7
        %Ym90
        outPulse = pg.pulse('Y90m');
    case 8
        %Z90
        outPulse = pg.pulse('QId', 'rotAngle', pi/2, 'polarAngle', 0, 'aziAngle', 0, defaultParams{:});
    case 9
        %Z180
        outPulse = pg.pulse('QId', 'rotAngle', pi, 'polarAngle', 0, 'aziAngle', 0, defaultParams{:});
    case 10
        %Z90m
        outPulse = pg.pulse('QId', 'rotAngle', -pi/2, 'polarAngle', 0, 'aziAngle', 0, defaultParams{:});
    case 11
        %X+Y 180
        outPulse = pg.pulse('Up', 'angle', pi/4);
    case 12
        %X-Y 180
        outPulse = pg.pulse('Up', 'angle', -pi/4);
    case 13
        %X+Z (Hadamard)
        outPulse = pg.pulse('Up', 'polarAngle', pi/4, 'aziAngle', 0, defaultParams{:});
    case 14
        %X-Z (Hadamard)
        outPulse = pg.pulse('Up', 'polarAngle', pi/4, 'aziAngle', pi, defaultParams{:});
    case 15
        %Y+Z (Hadamard)
        outPulse = pg.pulse('Up', 'polarAngle', pi/4, 'aziAngle', pi/2, defaultParams{:});
    case 16
        %Y-Z (Hadamard)
        outPulse = pg.pulse('Up', 'polarAngle', pi/4, 'aziAngle', -pi/2, defaultParams{:});
    case 17
        %X+Y+Z 120
        outPulse = pg.pulse('Utheta', 'rotAngle', 2*pi/3, 'polarAngle', acos(1/sqrt(3)), 'aziAngle', pi/4, defaultParams{:});
    case 18
        %X+Y+Z -120 (equivalent to -X-Y-Z 120)
        outPulse = pg.pulse('Utheta', 'rotAngle', 2*pi/3, 'polarAngle', pi-acos(1/sqrt(3)), 'aziAngle', 5*pi/4, defaultParams{:});
    case 19
        %X-Y+Z 120
        outPulse = pg.pulse('Utheta', 'rotAngle', 2*pi/3, 'polarAngle', acos(1/sqrt(3)), 'aziAngle', -pi/4, defaultParams{:});
    case 20
        %X-Y+Z -120 (equivalent to -X+Y-Z 120)
        outPulse = pg.pulse('Utheta', 'rotAngle', 2*pi/3, 'polarAngle', pi-acos(1/sqrt(3)), 'aziAngle', 3*pi/4, defaultParams{:});
    case 21
        %X+Y-Z 120
        outPulse = pg.pulse('Utheta', 'rotAngle', 2*pi/3, 'polarAngle', pi-acos(1/sqrt(3)), 'aziAngle', pi/4, defaultParams{:});
    case 22
        %X+Y-Z -120 (equivalent to -X-Y+Z 120
        outPulse = pg.pulse('Utheta', 'rotAngle', 2*pi/3, 'polarAngle', acos(1/sqrt(3)), 'aziAngle', 5*pi/4, defaultParams{:});
    case 23
        %-X+Y+Z 120
        outPulse = pg.pulse('Utheta', 'rotAngle', 2*pi/3, 'polarAngle', acos(1/sqrt(3)), 'aziAngle', 3*pi/4, defaultParams{:});
    case 24
        %-X+Y+Z -120 (equivalent to X-Y-Z 120
        outPulse = pg.pulse('Utheta', 'rotAngle', 2*pi/3, 'polarAngle', pi-acos(1/sqrt(3)), 'aziAngle', -pi/4, defaultParams{:});
    otherwise
        error('Cliffords must be numbered between 1 and 24');
end

end
