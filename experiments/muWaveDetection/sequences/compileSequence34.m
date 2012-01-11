function compileSequence34(basename, pg, patseq, calseq, numsteps, nbrRepeats, fixedPt, cycleLength, makePlot)

% load config parameters from file
load(getpref('qlab','pulseParamsBundleFile'), 'Ts', 'delays', 'measDelay', 'bufferDelays', 'bufferResets', 'bufferPaddings', 'offsets');

nbrPatterns = length(patseq)*nbrRepeats;
calPatterns = length(calseq)*nbrRepeats;
segments = nbrPatterns*numsteps + calPatterns;
fprintf('Number of sequences: %i\n', segments);

% pre-allocate space
ch1 = zeros(segments, cycleLength);
ch2 = ch1; ch3 = ch1; ch4 = ch1;
ch1m1 = ch1; ch1m2 = ch1; ch2m1 = ch1; ch2m2 = ch1;
ch3m1 = ch1; ch3m2 = ch1; ch4m1 = ch1; ch4m2 = ch1;

for n = 1:nbrPatterns;
    for stepct = 1:numsteps
        [patx paty] = pg.getPatternSeq(patseq{floor((n-1)/nbrRepeats)+1}, stepct, delays('34'), fixedPt);

        ch3((n-1)*stepct + stepct, :) = patx + offsets('34');
        ch4((n-1)*stepct + stepct, :) = paty + offsets('34');
        ch4m1((n-1)*stepct + stepct, :) = pg.bufferPulse(patx, paty, 0, bufferPaddings('34'), bufferResets('34'), bufferDelays('34'));
    end
end

for n = 1:calPatterns;
    [patx paty] = pg.getPatternSeq(calseq{floor((n-1)/nbrRepeats)+1}, 1, delays('34'), fixedPt);

    ch3(nbrPatterns*numsteps + n, :) = patx + offsets('34');
    ch4(nbrPatterns*numsteps + n, :) = paty + offsets('34');
    ch4m1(nbrPatterns*numsteps + n, :) = pg.bufferPulse(patx, paty, 0, bufferPaddings('34'), bufferResets('34'), bufferDelays('34'));
end

% trigger at beginning of measurement pulse
% measure from (6000:9000)
measLength = 3000;
measSeq = {pg.pulse('M', 'width', measLength)};
ch1m1 = repmat(pg.makePattern([], fixedPt-500, ones(100,1), cycleLength), 1, segments)';
ch1m2 = repmat(int32(pg.getPatternSeq(measSeq, n, measDelay, fixedPt+measLength)), 1, segments)';


if makePlot
    myn = 20;
    figure
    plot(ch3(myn,:))
    hold on
    plot(ch4(myn,:), 'r')
    plot(5000*ch4m1(myn,:), 'k')
    plot(5000*ch1m1(myn,:),'.')
    plot(5000*ch1m2(myn,:), 'g')
    grid on
    hold off
end

% add offsets to unused channels
ch1 = ch1 + offsets('12');
ch2 = ch2 + offsets('12');

% make TekAWG file
strippedBasename = basename;
basename = [basename '34'];
options = struct('m21_high', 2.0, 'm41_high', 2.0);
TekPattern.exportTekSequence(tempdir, basename, ch1, ch1m1, ch1m2, ch2, ch2m1, ch2m2, ch3, ch3m1, ch3m2, ch4, ch4m1, ch4m2, options);
disp('Moving AWG file to destination');
pathAWG = ['U:\AWG\' strippedBasename '\' basename '.awg'];
movefile([tempdir basename '.awg'], pathAWG);

end