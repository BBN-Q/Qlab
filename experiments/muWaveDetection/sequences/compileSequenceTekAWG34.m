function compileSequenceTekAWG34(basename, pg, patseq, calseq, numSteps, nbrRepeats, fixedPt, cycleLength, makePlot, plotIdx, seqSuffix)

if ~exist('plotIdx', 'var')
    plotIdx = 20;
end

if ~exist('seqSuffix', 'var')
    seqSuffix = '';
end

% load config parameters from file
params = jsonlab.loadjson(getpref('qlab', 'pulseParamsBundleFile'));
params.measDelay = -64;
ChParams = params.TekAWG34;

nbrPatterns = length(patseq)*nbrRepeats;
calPatterns = length(calseq)*nbrRepeats;
numSegments = nbrPatterns*numSteps + calPatterns;
fprintf('Number of sequences: %i\n', numSegments);

% pre-allocate space
ch1 = zeros(numSegments, cycleLength);
ch2 = ch1; ch3 = ch1; ch4 = ch1;
ch1m1 = ch1; ch1m2 = ch1; ch2m1 = ch1; ch2m2 = ch1;
ch3m1 = ch1; ch3m2 = ch1; ch4m1 = ch1; ch4m2 = ch1;

for n = 1:nbrPatterns;
    for stepct = 1:numSteps
        [patx paty] = pg.getPatternSeq(patseq{floor((n-1)/nbrRepeats)+1}, stepct, ChParams.delay, fixedPt);

        ch3((n-1)*numSteps + stepct, :) = patx + ChParams.offset;
        ch4((n-1)*numSteps + stepct, :) = paty + ChParams.offset;
        ch4m1((n-1)*numSteps + stepct, :) = pg.bufferPulse(patx, paty, 0, ChParams.bufferPadding, ChParams.bufferReset, ChParams.bufferDelay);
    end
end

for n = 1:calPatterns;
    [patx paty] = pg.getPatternSeq(calseq{floor((n-1)/nbrRepeats)+1}, 1, ChParams.delay, fixedPt);

    ch3(nbrPatterns*numSteps + n, :) = patx + ChParams.offset;
    ch4(nbrPatterns*numSteps + n, :) = paty + ChParams.offset;
    ch4m1(nbrPatterns*numSteps + n, :) = pg.bufferPulse(patx, paty, 0, ChParams.bufferPadding, ChParams.bufferReset, ChParams.bufferDelay);
end

% trigger at beginning of measurement pulse
% measure from (6000:9000)
qubitMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));
IQkey = qubitMap.('M1').IQkey;
SSBFreq = +10e6;
ChParams = params.(IQkey);
pgM = PatternGen('correctionT', ChParams.T,'bufferDelay',ChParams.bufferDelay,'bufferReset',ChParams.bufferReset,'bufferPadding',ChParams.bufferPadding, 'cycleLength', cycleLength, 'linkList', ChParams.linkListMode, 'dmodFrequency',SSBFreq);

measLength = 2000;
measSeq = {pgM.pulse('Xtheta', 'pType', 'tanh', 'sigma', 1, 'buffer', 0, 'amp', 8191, 'width', measLength)};
ch1m1 = repmat(pg.makePattern([], fixedPt-500, ones(100,1), cycleLength), 1, numSegments)';
measSeq = pgM.build(measSeq, 1, params.(IQkey).delay, fixedPt+measLength, false);
ch4m2 = repmat(pg.makePattern([], 5, ones(100,1), cycleLength), 1, numSegments)';
[patx,paty] = pgM.linkListToPattern(measSeq, 1);
% remove difference of delays
delayDiff = params.TekAWG12.delay - ChParams.delay;
patx = circshift(patx, [0, delayDiff]);
paty = circshift(paty, [0, delayDiff]);
ch1m2 = repmat(pg.bufferPulse(patx, paty, 0, ChParams.bufferPadding, ChParams.bufferReset, ChParams.bufferDelay), 1, numSegments)';

if makePlot
    myn = plotIdx;
    figure
    plot(ch3(myn,:))
    hold on
    plot(ch4(myn,:), 'r')
    plot(5000*ch4m1(myn,:), 'k')
    plot(5000*ch1m1(myn,:),'.')
    plot(5000*ch1m2(myn,:), 'g')
    [measI, measQ] = pgM.linkListToPattern(measSeq, 1);
    plot(measI, 'c')
    plot(measQ, 'y')
    grid on
    hold off
end

strippedBasename = basename;
basename = [basename 'BBNAPS34'];
% make APS file
exportAPSConfig(tempdir, basename, measSeq, measSeq);
disp('Moving APS file to destination');
if ~exist(['U:\APS\' strippedBasename '\'], 'dir')
    mkdir(['U:\APS\' strippedBasename '\']);
end
pathAPS = ['U:\APS\' strippedBasename '\' basename '.h5'];
movefile([tempdir basename '.h5'], pathAPS);

% add offsets to unused channels
ch1 = ch1 + params.TekAWG12.offset;
ch2 = ch2 + params.TekAWG12.offset;

% make TekAWG file
% strippedBasename = basename;
basename = [strippedBasename 'TekAWG34' seqSuffix];
options = struct('m21_high', 2.0, 'm41_high', 2.0);
TekPattern.exportTekSequence(tempdir, basename, ch1, ch1m1, ch1m2, ch2, ch2m1, ch2m2, ch3, ch3m1, ch3m2, ch4, ch4m1, ch4m2, options);
disp('Moving AWG file to destination');
if ~exist(['U:\AWG\' strippedBasename '\'], 'dir')
    mkdir(['U:\AWG\' strippedBasename '\']);
end
pathAWG = ['U:\AWG\' strippedBasename '\' basename '.awg'];
movefile([tempdir basename '.awg'], pathAWG);

end