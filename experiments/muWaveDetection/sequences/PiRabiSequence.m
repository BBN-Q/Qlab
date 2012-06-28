function PiRabiSequence(makePlot)

if ~exist('makePlot', 'var')
    makePlot = true;
end

pathAWG = 'U:\AWG\PiRabi\';
pathAPS = 'U:\APS\PiRabi\';
basename = 'PiRabi';

fixedPt = 6000;
cycleLength = 16000;

numsteps = 80; 

% load config parameters from file
params = jsonlab.loadjson(getpref('qlab', 'pulseParamsBundleFile'));
qubitMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));

params.measDelay = -64;

q1Params = params.q1;
IQkey1 = qubitMap.q1.IQkey;
CRParams = params.CR;
IQkeyCR = qubitMap.CR.IQkey;

% if using SSB, set the frequency here
SSBFreq = 0e6;
pg1 = PatternGen('dPiAmp', q1Params.piAmp, 'dPiOn2Amp', q1Params.pi2Amp, 'dSigma', q1Params.sigma, 'dPulseType', q1Params.pulseType, 'dDelta', q1Params.delta, 'correctionT', params.(IQkey1).T, 'dBuffer', q1Params.buffer, 'dPulseLength', q1Params.pulseLength, 'cycleLength', cycleLength, 'linkList', params.(IQkey1).linkListMode, 'dmodFrequency',SSBFreq);

SSBFreq = -100e6;
CRParams.buffer = 0;
pgCR = PatternGen('dPiAmp', CRParams.piAmp, 'dPiOn2Amp', CRParams.pi2Amp, 'dSigma', CRParams.sigma, 'dPulseType', CRParams.pulseType, 'dDelta', CRParams.delta, 'correctionT', params.(IQkeyCR).T, 'dBuffer', CRParams.buffer, 'dPulseLength', CRParams.pulseLength, 'cycleLength', cycleLength, 'linkList', params.(IQkeyCR).linkListMode, 'dmodFrequency',SSBFreq);

minWidth = 140;%16+6*CRParams.sigma; 
stepsize = 4;
pulseLength = minWidth:stepsize:(numsteps-1)*stepsize+minWidth;
% pulseLength = 120*ones(numsteps,1);

% amps = 3800:15:4985;
amps = 1000;

patseq1  = {pg1.pulse('Xp'), pg1.pulse('QId', 'duration', pulseLength+32), pg1.pulse('Xp')};
patseqCR = {...
%     pgCR.pulse('Xtheta', 'pType', 'dragGaussOn', 'width', 3*CRParams.sigma, 'amp', amps), ...
%     pgCR.pulse('Xtheta', 'width', pulseLength-6*CRParams.sigma, 'pType', 'square', 'amp', amps*(1-exp(-4.5))), ...
%     pgCR.pulse('Xtheta', 'pType', 'dragGaussOff', 'width', 3*CRParams.sigma, 'amp', amps), ...
    pgCR.pulse('Xtheta', 'width', pulseLength, 'sigma', pulseLength/4, 'amp', amps), ...
    pgCR.pulse('QId', 'width', q1Params.pulseLength + q1Params.buffer+16), ...
    };

% patseqCR = {...
%     pgCR.pulse('Xtheta', 'width', pulseLength, 'sigma', pulseLength/4, 'amp', amps), ...
%     pgCR.pulse('QId', 'width', q1Params.pulseLength + q1Params.buffer), ...
%     pgCR.pulse('Xtheta', 'width', pulseLength, 'sigma', pulseLength/4, 'amp', amps), ...
%     pgCR.pulse('QId', 'width', q1Params.pulseLength + q1Params.buffer), ...
%     };

patseq1_2 = {pg1.pulse('QId')};

ch1 = zeros(2*numsteps, cycleLength);
ch2 = ch1;
ch3 = ch1;
ch4 = ch1;
ch1m1 = ch1; ch1m2 = ch1;
ch2m1 = ch1; ch2m2 = ch1;
ch3m1 = ch1; ch3m2 = ch1;
ch4m1 = ch1; ch4m2 = ch1;
delayDiff = params.(IQkeyCR).delay - params.(IQkey1).delay;

APSseqs1 = pg1.build(patseq1, numsteps, params.(IQkey1).delay, fixedPt, false);
APSseqs2 = pg1.build(patseq1_2, numsteps, params.(IQkey1).delay, fixedPt, false);
for n = 1:numsteps
    %Use the Tek for the CR pulse
	[patx paty] = pgCR.getPatternSeq(patseqCR, n, params.(IQkeyCR).delay, fixedPt);
	ch3(n, :) = patx + params.(IQkeyCR).offset;
	ch4(n, :) = paty + params.(IQkeyCR).offset;
    ch3m1(n, :) = pgCR.bufferPulse(patx, paty, 0, params.(IQkeyCR).bufferPadding, params.(IQkey1).bufferReset, params.(IQkey1).bufferDelay);

    % construct buffer for APS pulses
    [patx, paty] = pg1.linkListToPattern(APSseqs1, n);
    
    % remove difference of delays
    patx = circshift(patx, [0, delayDiff]);
    paty = circshift(paty, [0, delayDiff]);
    
    ch4m1(n, :) = pg1.bufferPulse(patx, paty, 0, params.(IQkey1).bufferPadding, params.(IQkey1).bufferReset, params.(IQkey1).bufferDelay);

    % second sequence without the pi's
    ch3(n+numsteps, :) = ch3(n, :);
    ch4(n+numsteps, :) = ch4(n, :);
    ch3m1(n+numsteps,:) = ch3m1(n,:);
    
    % construct buffer for APS pulses
    [patx, paty] = pg1.linkListToPattern(APSseqs2, n);
    
    % remove difference of delays
    patx = circshift(patx, [0, delayDiff]);
    paty = circshift(paty, [0, delayDiff]);
    
    ch4m1(numsteps+n, :) = pg1.bufferPulse(patx, paty, 0, params.(IQkey1).bufferPadding, params.(IQkey1).bufferReset, params.(IQkey1).bufferDelay);
end

% trigger at fixedPt-500
% measure from (fixedPt:fixedPt+measLength)
measLength = 8000;
measSeq = {pgCR.pulse('M', 'width', measLength)};
for n = 1:2*numsteps;
	ch1m1(n,:) = pgCR.makePattern([], fixedPt-500, ones(100,1), cycleLength);
	ch1m2(n,:) = int32(pgCR.getPatternSeq(measSeq, n, params.measDelay, fixedPt+measLength));
    ch4m2(n,:) = pgCR.makePattern([], 5, ones(100,1), cycleLength);
end

if makePlot
    myn = 19;
    figure
    plot(ch1(myn,:))
    hold on
    plot(ch2(myn,:), 'r')
    plot(ch3(myn,:), 'b--')
    plot(ch4(myn,:), 'r--')
    [ch5, ch6] = pg1.linkListToPattern(APSseqs1,myn);
    plot(ch5, 'm')
    plot(ch6, 'c')
    plot(5000*ch1m2(myn,:), 'g')
    plot(1000*ch2m1(myn,:), 'r')
    plot(5000*ch3m1(myn,:),'.')
    plot(5000*ch4m1(myn,:),'y.')
    grid on
    hold off
end

% add offsets to unused channels
ch1 = ch1 + params.TekAWG12.offset;
ch2 = ch2 + params.TekAWG12.offset;

% ch56seq = CRseq;
ch56seq = APSseqs1;
for n = 1:length(APSseqs2.linkLists)
   ch56seq.linkLists{end+1} = APSseqs2.linkLists{n};
end

% make APS file
strippedBasename = basename;
basename = [basename 'BBNAPS34'];
% make APS file
exportAPSConfig(tempdir, basename, ch56seq, ch56seq);
disp('Moving APS file to destination');
if ~exist(['U:\APS\' strippedBasename '\'], 'dir')
    mkdir(['U:\APS\' strippedBasename '\']);
end
pathAPS = ['U:\APS\' strippedBasename '\' basename '.h5'];
disp('Moving APS file to destination');
movefile([tempdir basename '.h5'], pathAPS);


% make TekAWG file
basename = strippedBasename;
options = struct('m21_high', 2.0, 'm41_high', 2.0);
TekPattern.exportTekSequence(tempdir, basename, ch1, ch1m1, ch1m2, ch2, ch2m1, ch2m2, ch3, ch3m1, ch3m2, ch4, ch4m1, ch4m2, options);
disp('Moving AWG file to destination');
movefile([tempdir basename '.awg'], [pathAWG basename '.awg']);
end
