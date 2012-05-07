function PiRabiSequence(makePlot)

if ~exist('makePlot', 'var')
    makePlot = true;
end

pathAWG = 'U:\AWG\PiRabi\';
pathAPS = 'U:\APS\PiRabi\';
basename = 'PiRabi';

fixedPt = 6000;
cycleLength = 16000;

numsteps = 31; 

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

SSBFreq = 0e6;
CRParams.buffer = 0;
pgCR = PatternGen('dPiAmp', CRParams.piAmp, 'dPiOn2Amp', CRParams.pi2Amp, 'dSigma', CRParams.sigma, 'dPulseType', CRParams.pulseType, 'dDelta', CRParams.delta, 'correctionT', params.(IQkeyCR).T, 'dBuffer', CRParams.buffer, 'dPulseLength', CRParams.pulseLength, 'cycleLength', cycleLength, 'linkList', params.(IQkeyCR).linkListMode, 'dmodFrequency',SSBFreq);

minWidth = 16+6*CRParams.sigma; 
stepsize = 4;
pulseLength = minWidth:stepsize:(numsteps-1)*stepsize+minWidth;

amps = 6500:50:8000;
pulseLength = 300*ones(numsteps,1);

patseq1  = {pg1.pulse('Xp'), pg1.pulse('QId', 'duration', pulseLength), pg1.pulse('Xp')};
% patseqCR = {...
%     pgCR.pulse('Xtheta', 'pType', 'gaussOn', 'width', 3*CRParams.sigma, 'amp', 8000), ...
%     pgCR.pulse('Xtheta', 'width', pulseLength-6*CRParams.sigma, 'pType', 'square', 'amp', 8000), ...
%     pgCR.pulse('Xtheta', 'pType', 'gaussOff', 'width', 3*CRParams.sigma, 'amp', 8000), ...
%     pgCR.pulse('QId', 'width', q1Params.pulseLength + q1Params.buffer)...
%     };
patseq1_2 = {pg1.pulse('QId')};


for stepct=1:numsteps
    patseqCR{stepct} = [{pgCR.pulse('Xtheta', 'pType', 'dragGaussOn', 'width', 3*CRParams.sigma, 'amp', amps(stepct))},...
        {pgCR.pulse('Xtheta', 'width', pulseLength(stepct)-6*CRParams.sigma, 'pType', 'square', 'amp', amps(stepct))},...
        {pgCR.pulse('Xtheta', 'pType', 'dragGaussOff', 'width', 3*CRParams.sigma, 'amp', amps(stepct))},...
        {pgCR.pulse('QId', 'width', q1Params.pulseLength + q1Params.buffer )}...
        ];

%     patseqCR{stepct} = [ {pgCR.pulse('Xtheta', 'amp', amps(stepct))},...
%         {pgCR.pulse('QId', 'width', q1Params.pulseLength + q1Params.buffer )}...
%          ];
end



ch1 = zeros(2*numsteps, cycleLength);
ch2 = ch1;
ch3 = ch1;
ch4 = ch1;
ch1m1 = ch1; ch1m2 = ch1;
ch2m1 = ch1; ch2m2 = ch1;
ch3m1 = ch1; ch3m2 = ch1;
ch4m1 = ch1; ch4m2 = ch1;
delayDiff = params.(IQkey1).delay - params.(IQkeyCR).delay;

for n = 1:numsteps;
	[patx paty] = pg1.getPatternSeq(patseq1, n, params.(IQkey1).delay, fixedPt);
	ch3(n, :) = patx + params.(IQkey1).offset;
	ch4(n, :) = paty + params.(IQkey1).offset;
    ch4m1(n, :) = pg1.bufferPulse(patx, paty, 0, params.(IQkey1).bufferPadding, params.(IQkey1).bufferReset, params.(IQkey1).bufferDelay);
    
%     [patx paty] = pgCR.getPatternSeq(patseqCR, n, params.(IQkey2).delay, fixedPt);
% 	ch3(n, :) = patx + params.(IQkey2).offset;
% 	ch4(n, :) = paty + params.(IQkey2).offset;
%     ch4m1(n, :) = pgCR.bufferPulse(patx, paty, 0, params.(IQkey2).bufferPadding, params.(IQkey2).bufferReset, params.(IQkey2).bufferDelay);
    
    [CRseq{n}] = pgCR.build(patseqCR{n}, 1, params.(IQkeyCR).delay, fixedPt);
    % construct buffer for APS pulses
    [patx, paty] = pgCR.linkListToPattern(CRseq{n}, 1);
    % remove difference of delays
    patx = circshift(patx, delayDiff);
    paty = circshift(paty, delayDiff);
    
    ch3m1(n, :) = pgCR.bufferPulse(patx, paty, 0, params.(IQkeyCR).bufferPadding, params.(IQkeyCR).bufferReset, params.(IQkeyCR).bufferDelay);

    % second sequence without the pi's
    ch1(n+numsteps, :) = ch1(n, :);
    ch2(n+numsteps, :) = ch2(n, :);
    
    [patx paty] = pg1.getPatternSeq(patseq1_2, n, params.(IQkey1).delay, fixedPt);
	ch3(n+numsteps, :) = patx + params.(IQkey1).offset;
	ch4(n+numsteps, :) = paty + params.(IQkey1).offset;
    ch4m1(n+numsteps, :) = pg1.bufferPulse(patx, paty, 0, params.(IQkey1).bufferPadding, params.(IQkey1).bufferReset, params.(IQkey1).bufferDelay);

    ch3m1(n+numsteps, :) = ch3m1(n, :);
end

% trigger at fixedPt-500
% measure from (fixedPt:fixedPt+measLength)
measLength = 9600;
measSeq = {pg1.pulse('M', 'width', measLength)};
for n = 1:2*numsteps;
	ch1m1(n,:) = pg1.makePattern([], fixedPt-500, ones(100,1), cycleLength);
	ch1m2(n,:) = int32(pg1.getPatternSeq(measSeq, n, params.measDelay, fixedPt+measLength));
    ch4m2(n,:) = pg1.makePattern([], 5, ones(100,1), cycleLength);
end

if makePlot
    myn = 25;
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

% add offsets to unused channels
ch1 = ch1 + params.TekAWG12.offset;
ch2 = ch2 + params.TekAWG12.offset;

ch56seq = CRseq{1};
for n = 2:length(CRseq)
    for m = 1:length(CRseq{n}.linkLists)
        ch56seq.linkLists{end+1} = CRseq{n}.linkLists{m};
    end
end

% make APS file
strippedBasename = basename;
basename = [basename 'BBNAPS12'];
% make APS file
exportAPSConfig(tempdir, basename, ch56seq, ch56seq);
disp('Moving APS file to destination');
if ~exist(['U:\APS\' strippedBasename '\'], 'dir')
    mkdir(['U:\APS\' strippedBasename '\']);
end
pathAPS = ['U:\APS\' strippedBasename '\' basename '.mat'];
disp('Moving APS file to destination');
movefile([tempdir basename '.mat'], pathAPS);


% make TekAWG file
basename = strippedBasename;
options = struct('m21_high', 2.0, 'm41_high', 2.0);
TekPattern.exportTekSequence(tempdir, basename, ch1, ch1m1, ch1m2, ch2, ch2m1, ch2m2, ch3, ch3m1, ch3m2, ch4, ch4m1, ch4m2, options);
disp('Moving AWG file to destination');
movefile([tempdir basename '.awg'], [pathAWG basename '.awg']);
end
