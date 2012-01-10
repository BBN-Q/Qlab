function compileSequenceSSB12(basename, pg, patseq, calseq, numsteps, nbrRepeats, fixedPt, cycleLength, makePlot)

% load config parameters from file
load(getpref('qlab','pulseParamsBundleFile'), 'Ts', 'delays', 'measDelay', 'bufferDelays', 'bufferResets', 'bufferPaddings', 'offsets');

goodT = Ts('12');

nbrPatterns = length(patseq)*nbrRepeats;
calPatterns = length(calseq)*nbrRepeats;
segments = nbrPatterns*numsteps + calPatterns;
fprintf('Number of sequences: %i\n', segments);

% pre-allocate space
ch1 = zeros(segments, cycleLength);
ch2 = ch1; ch3 = ch1; ch4 = ch1;
ch1m1 = ch1; ch1m2 = ch1; ch2m1 = ch1; ch2m2 = ch1;
ch3m1 = ch1; ch3m2 = ch1; ch4m1 = ch1; ch4m2 = ch1;

timeStep = 1/1.2e9;
SSBFreq = -150e6;
tmpAngles = -2*pi*SSBFreq*timeStep*(0:(cycleLength-1))';

for n = 1:nbrPatterns;
    for stepct = 1:numsteps
        [patx paty] = pg.getPatternSeq(patseq{floor((n-1)/nbrRepeats)+1}, stepct, delays('12'), fixedPt);

        complexPulse = patx +1j*paty;
        complexPulse = complexPulse.*exp(1j*tmpAngles);
        xypairs = goodT*[real(complexPulse) imag(complexPulse)].';

        patx = xypairs(1,:);
        paty = xypairs(2,:);

        ch1((n-1)*stepct + stepct, :) = patx + offsets('12');
        ch2((n-1)*stepct + stepct, :) = paty + offsets('12');
        ch3m1((n-1)*stepct + stepct, :) = pg.bufferPulse(patx, paty, 0, bufferPaddings('12'), bufferResets('12'), bufferDelays('12'));
    end
end

for n = 1:calPatterns;
    [patx paty] = pg.getPatternSeq(calseq{floor((n-1)/nbrRepeats)+1}, 1, delays('12'), fixedPt);

    complexPulse = patx +1j*paty;
    complexPulse = complexPulse.*exp(1j*tmpAngles);
    xypairs = goodT*[real(complexPulse) imag(complexPulse)].';

    patx = xypairs(1,:);
    paty = xypairs(2,:);

    ch1(nbrPatterns*numsteps + n, :) = patx + offsets('12');
    ch2(nbrPatterns*numsteps + n, :) = paty + offsets('12');
    ch3m1(nbrPatterns*numsteps + n, :) = pg.bufferPulse(patx, paty, 0, bufferPaddings('12'), bufferResets('12'), bufferDelays('12'));
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
    plot(ch1(myn,:))
    hold on
    plot(ch2(myn,:), 'r')
    plot(5000*ch3m1(myn,:), 'k')
    plot(5000*ch1m1(myn,:),'.')
    plot(5000*ch1m2(myn,:), 'g')
    grid on
    hold off
end

% add offsets to unused channels
ch3 = ch3 + offsets('34');
ch4 = ch4 + offsets('34');

% make TekAWG file
options = struct('m21_high', 2.0, 'm41_high', 2.0);
TekPattern.exportTekSequence(tempdir, basename, ch1, ch1m1, ch1m2, ch2, ch2m1, ch2m2, ch3, ch3m1, ch3m2, ch4, ch4m1, ch4m2, options);
disp('Moving AWG file to destination');
pathAWG = ['U:\AWG\' basename '\' basename '.awg'];
movefile([tempdir basename '.awg'], pathAWG);

end