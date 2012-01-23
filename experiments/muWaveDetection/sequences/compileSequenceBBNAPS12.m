function compileSequenceBBNAPS12(basename, pg, patseq, calseq, numsteps, nbrRepeats, fixedPt, cycleLength, makePlot)

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
delayDiff = delays('TekAWG12') - delays('BBNAPS12');
PulseCollection = [];

for n = 1:nbrPatterns;
    [I_seq{n}, Q_seq{n}, ~, PulseCollection] = pg.build(patseq{floor((n-1)/nbrRepeats)+1}, numsteps, delays('BBNAPS12'), fixedPt, PulseCollection);

    for stepct = 1:numsteps
        patx = pg.linkListToPattern(I_seq{n}, stepct)';
        paty = pg.linkListToPattern(Q_seq{n}, stepct)';
        
        % remove difference of delays
        patx = circshift(patx, delayDiff);
        paty = circshift(paty, delayDiff);
        ch3m1((n-1)*stepct + stepct, :) = pg.bufferPulse(patx, paty, 0, bufferPaddings('BBNAPS12'), bufferResets('BBNAPS12'), bufferDelays('BBNAPS12'));
    end
end

for n = 1:calPatterns;
    [I_seq{nbrPatterns + n}, Q_seq{nbrPatterns + n}, ~, PulseCollection] = pg.build(calseq{floor((n-1)/nbrRepeats)+1}, 1, delays('BBNAPS12'), fixedPt, PulseCollection);
    patx = pg.linkListToPattern(I_seq{nbrPatterns + n}, 1)';
    paty = pg.linkListToPattern(Q_seq{nbrPatterns + n}, 1)';

    % remove difference of delays
    patx = circshift(patx, delayDiff);
    paty = circshift(paty, delayDiff);
    ch3m1(nbrPatterns*numsteps + n, :) = pg.bufferPulse(patx, paty, 0, bufferPaddings('BBNAPS12'), bufferResets('BBNAPS12'), bufferDelays('BBNAPS12'));
end

% trigger at beginning of measurement pulse
% measure from (6000:9000)
% turn off 'passThru' when creating non-APS pulses
pg.passThru = 0;
measLength = 3000;
measSeq = {pg.pulse('M', 'width', measLength)};
ch1m1 = repmat(pg.makePattern([], fixedPt-500, ones(100,1), cycleLength), 1, segments)';
ch1m2 = repmat(int32(pg.getPatternSeq(measSeq, n, measDelay, fixedPt+measLength)), 1, segments)';
ch4m2 = repmat(pg.makePattern([], 5, ones(100,1), cycleLength), 1, segments)';
ch2m2 = ch4m2;

% unify LLs and waveform libs
ch5seq = I_seq{1}; ch6seq = Q_seq{1};
for n = 2:(nbrPatterns+calPatterns)
    for m = 1:length(I_seq{n}.linkLists)
        ch5seq.linkLists{end+1} = I_seq{n}.linkLists{m};
        ch6seq.linkLists{end+1} = Q_seq{n}.linkLists{m};
    end
end
ch5seq.waveforms = deviceDrivers.APS.unifySequenceLibraryWaveformsSingle(I_seq);
ch6seq.waveforms = deviceDrivers.APS.unifySequenceLibraryWaveformsSingle(Q_seq);


if makePlot
    myn = 10;
    figure
    ch5 = pg.linkListToPattern(ch5seq, myn);
    ch6 = pg.linkListToPattern(ch6seq, myn);
    plot(ch5)
    hold on
    plot(ch6, 'r')
    plot(5000*ch3m1(myn,:), 'k')
    plot(5000*ch1m1(myn,:),'.')
    plot(5000*ch1m2(myn,:), 'g')
    grid on
    hold off
end

% add offsets to unused channels
ch1 = ch1 + offsets('TekAWG12');
ch2 = ch2 + offsets('TekAWG12');
ch3 = ch3 + offsets('TekAWG34');
ch4 = ch4 + offsets('TekAWG34');

strippedBasename = basename;
basename = [basename 'BBNAPS12'];
% make APS file
%exportAPSConfig(tempdir, basename, ch5seq, ch6seq);
exportAPSConfig(tempdir, basename, ch5seq, ch6seq, ch5seq, ch6seq);
disp('Moving APS file to destination');
if ~exist(['U:\APS\' strippedBasename '\'], 'dir')
    mkdir(['U:\APS\' strippedBasename '\']);
end
pathAPS = ['U:\APS\' strippedBasename '\' basename '.mat'];
movefile([tempdir basename '.mat'], pathAPS);
% make TekAWG file
options = struct('m21_high', 2.0, 'm41_high', 2.0);
TekPattern.exportTekSequence(tempdir, basename, ch1, ch1m1, ch1m2, ch2, ch2m1, ch2m2, ch3, ch3m1, ch3m2, ch4, ch4m1, ch4m2, options);
disp('Moving AWG file to destination');
if ~exist(['U:\AWG\' strippedBasename '\'], 'dir')
    mkdir(['U:\AWG\' strippedBasename '\']);
end
pathAWG = ['U:\AWG\' strippedBasename '\' basename '.awg'];
movefile([tempdir basename '.awg'], pathAWG);

end