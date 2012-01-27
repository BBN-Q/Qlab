function jayNullSequence(makePlot)

if ~exist('makePlot', 'var')
    makePlot = true;
end
script = java.io.File(mfilename('fullpath'));
path = char(script.getParentFile().getParentFile().getParentFile().getParent());
addpath([path '/common/src'],'-END');
addpath([path '/common/src/util/'],'-END');

temppath = [char(script.getParent()) '\'];
path = 'U:\AWG\Pi4\';
jayPulsePath = 'U:\Blake\outputX.dat';
basename = 'jayPulseAmp';

fixedPt = 8000;
cycleLength = 12000;

% load config parameters from file
parent_path = char(script.getParentFile.getParent());
cfg_path = [parent_path '/cfg/'];
load([cfg_path 'pulseParams.mat'], 'T', 'delay', 'measDelay', 'bufferDelay', 'bufferReset', 'bufferPadding', 'offset', 'piAmp', 'pi2Amp', 'sigma', 'pulseType', 'delta', 'buffer', 'pulseLength');
load([cfg_path 'pulseParams.mat'], 'T2', 'delay2', 'bufferDelay2', 'bufferReset2', 'bufferPadding2', 'offset2', 'piAmp2', 'pi2Amp2', 'sigma2', 'pulseType2', 'delta2', 'buffer2', 'pulseLength2');

pulseLength = 144;
pulseType = 'arbitrary';
arbDelta = 1.0;
pg1 = PatternGen('dPiAmp', piAmp, 'dPiOn2Amp', pi2Amp, 'dSigma', sigma, 'dPulseType', pulseType, 'dDelta', arbDelta, 'correctionT', T, 'dBuffer', buffer, 'dPulseLength', pulseLength, 'cycleLength', cycleLength);
pg2 = PatternGen('dPiAmp', piAmp2, 'dPiOn2Amp', pi2Amp2, 'dSigma', sigma2, 'dPulseType', pulseType2, 'dDelta', delta2, 'correctionT', T2, 'dBuffer', buffer2, 'dPulseLength', pulseLength2, 'cycleLength', cycleLength);
delayQ1 = delay;
offsetQ1 = offset;
delayQ2 = delay2;
offsetQ2 = offset2;

numsteps = 50;
step = 110;
minamp = 2500;
amps = 0:step:(numsteps-1)*step;
amps = amps + minamp;

patseq = {...
    pg1.pulse('QId', 'width', pulseLength2),...
    pg1.pulse('Xtheta', 'amp', amps, 'arbfname', jayPulsePath),...
    pg1.pulse('Xtheta', 'amp', amps, 'arbfname', jayPulsePath),...
    pg1.pulse('QId', 'width', pulseLength2)
    };
patseq2 = {...
    pg2.pulse('Xp'),...
    pg2.pulse('QId', 'width', pulseLength), ...
    pg2.pulse('QId', 'width', pulseLength), ...
    pg2.pulse('Xp')
    };

calseq = {{pg1.pulse('QId')},...
    {pg1.pulse('QId')},...
    {pg1.pulse('Xp', 'arbfname', jayPulsePath)},...
    {pg1.pulse('Xp', 'arbfname', jayPulsePath)},...
    {pg1.pulse('QId')},...
    {pg1.pulse('QId')},...
    {pg1.pulse('Xp', 'arbfname', jayPulsePath),pg1.pulse('QId', 'width', pulseLength2)},...
    {pg1.pulse('Xp', 'arbfname', jayPulsePath),pg1.pulse('QId', 'width', pulseLength2)}
    };
calseq2 = {{pg2.pulse('QId')},...
    {pg2.pulse('QId')},...
    {pg2.pulse('QId')},...
    {pg2.pulse('QId')},...
    {pg2.pulse('Xp')},...
    {pg2.pulse('Xp')},...
    {pg2.pulse('QId', 'width', pulseLength), pg2.pulse('Xp')},...
    {pg2.pulse('QId', 'width', pulseLength), pg2.pulse('Xp')}
    };

% pre-allocate space
numrepeats = 1;
ch1 = zeros(numrepeats*numsteps+length(calseq), cycleLength);
ch2 = ch1; ch3 = ch1; ch4 = ch1;
ch1m1 = ch1; ch1m2 = ch1; ch2m1 = ch1; ch2m2 = ch1;
ch3m1 = ch1; ch3m2 = ch1; ch4m1 = ch1; ch4m2 = ch1;

for n = 1:numrepeats*numsteps;
	[patx paty] = pg1.getPatternSeq(patseq, n, delayQ1, fixedPt);
	ch1(n, :) = patx + offsetQ1;
	ch2(n, :) = paty + offsetQ1;
    ch3m1(n, :) = pg1.bufferPulse(patx, paty, 0, bufferPadding, bufferReset, bufferDelay);
    
    [patx paty] = pg2.getPatternSeq(patseq2, n, delayQ2, fixedPt);
	ch3(n, :) = patx + offsetQ2;
	ch4(n, :) = paty + offsetQ2;
    ch4m1(n, :) = pg2.bufferPulse(patx, paty, 0, bufferPadding2, bufferReset2, bufferDelay2);
end

for n = 1:length(calseq);
	[patx paty] = pg1.getPatternSeq(calseq{n}, n, delayQ1, fixedPt);
	ch1(numrepeats*numsteps+n, :) = patx + offsetQ1;
	ch2(numrepeats*numsteps+n, :) = paty + offsetQ1;
    ch3m1(numrepeats*numsteps+n, :) = pg1.bufferPulse(patx, paty, 0, bufferPadding, bufferReset, bufferDelay);
    
    [patx paty] = pg2.getPatternSeq(calseq2{n}, n, delayQ2, fixedPt);
	ch3(numrepeats*numsteps+n, :) = patx + offsetQ2;
	ch4(numrepeats*numsteps+n, :) = paty + offsetQ2;
    ch4m1(numrepeats*numsteps+n, :) = pg2.bufferPulse(patx, paty, 0, bufferPadding2, bufferReset2, bufferDelay2);
end

numsteps = numrepeats*numsteps + length(calseq);

% trigger at beginning of measurement pulse
% measure from (6000:9000)
measLength = 3000;
measSeq = {pg1.pulse('M', 'width', measLength)};
for n = 1:numsteps;
	ch1m1(n,:) = pg1.makePattern([], fixedPt-500, ones(100,1), cycleLength);
	ch1m2(n,:) = int32(pg1.getPatternSeq(measSeq, n, measDelay, fixedPt+measLength));
end

if makePlot
    myn = 5;
    figure
    plot(ch1(myn,:));
    hold on
    plot(ch2(myn,:), 'r')
    plot(ch3(myn,:), ':')
    plot(ch4(myn,:),'r:')
    plot(5000*ch3m1(myn,:), 'k')
    plot(5000*ch1m2(myn,:), 'g')
    %plot(1000*ch3m1(myn,:))
    plot(5000*ch1m1(myn,:),'.')
    grid on
    hold off
end

% add offsets to unused channels
%ch1 = ch1 + offset;
%ch2 = ch2 + offset;
%ch3 = ch3 + offset2;
%ch4 = ch4 + offset2;

% make TekAWG file
options = struct('m21_high', 2.0, 'm41_high', 2.0);
TekPattern.exportTekSequence(temppath, basename, ch1, ch1m1, ch1m2, ch2, ch2m1, ch2m2, ch3, ch3m1, ch3m2, ch4, ch4m1, ch4m2, options);
disp('Moving AWG file to destination');
movefile([temppath basename '.awg'], [path basename '.awg']);
end
