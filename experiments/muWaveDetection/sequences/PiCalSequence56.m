function PiCalSequence56(makePlot)

if ~exist('makePlot', 'var')
    makePlot = true;
end

pathAWG = 'U:\AWG\PiCal\';
pathAPS = 'U:\APS\PiCal\';
basename = 'PiCal56';

fixedPt = 6000;
cycleLength = 10000;

% load config parameters from file
load(getpref('qlab','pulseParamsBundleFile'), 'Ts', 'delays', 'measDelay', 'bufferDelays', 'bufferResets', 'bufferPaddings', 'offsets', 'piAmps', 'pi2Amps', 'sigmas', 'pulseTypes', 'deltas', 'buffers', 'pulseLengths');

pg21 = PatternGen('dPiAmp', piAmps('q1q2'), 'dPiOn2Amp', pi2Amps('q1q2'), 'dSigma', sigmas('q1q2'), 'dPulseType', pulseTypes('q1q2'), 'dDelta', deltas('q1q2'), 'correctionT', Ts('56'), 'dBuffer', buffers('q1q2'), 'dPulseLength', pulseLengths('q1q2'), 'cycleLength', cycleLength, 'passThru', true);
pg1 = PatternGen('dPiAmp', piAmps('q1'), 'dPiOn2Amp', pi2Amps('q1'), 'dSigma', sigmas('q1'), 'dPulseType', pulseTypes('q1'), 'dDelta', deltas('q1'), 'correctionT', Ts('12'), 'dBuffer', buffers('q1'), 'dPulseLength', pulseLengths('q1'), 'cycleLength', cycleLength);
pg2 = PatternGen('dPiAmp', piAmps('q2'), 'dPiOn2Amp', pi2Amps('q2'), 'dSigma', sigmas('q2'), 'dPulseType', pulseTypes('q2'), 'dDelta', deltas('q2'), 'correctionT', Ts('34'), 'dBuffer', buffers('q2'), 'dPulseLength', pulseLengths('q2'), 'cycleLength', cycleLength);

pg = pg21;

% +X rotations
% QId
% X90p
% X90p Xp
% X90p Xp Xp
% X90p Xp Xp Xp
% X90p Xp Xp Xp Xp
patseq{1}={{'QId'}};
patseq{2}={{'X90p'}};
patseq{3}={{'X90p'},{'Xp'}};
patseq{4}={{'X90p'},{'Xp'},{'Xp'}};
patseq{5}={{'X90p'},{'Xp'},{'Xp'},{'Xp'}};

% -X rotations
% QId
% X90m
% X90m Xm
% X90m Xm Xm
% X90m Xm Xm Xm
% X90m Xm Xm Xm Xm
patseq{6}={{'QId'}};
patseq{7}={{'X90m'}};
patseq{8}={{'X90m'},{'Xm'}};
patseq{9}={{'X90m'},{'Xm'},{'Xm'}};
patseq{10}={{'X90m'},{'Xm'},{'Xm'},{'Xm'}};

% +Y rotations
% QId
% Y90p
% Y90p Yp
% Y90p Yp Yp
% Y90p Yp Yp Yp
% Y90p Yp Yp Yp Yp
patseq{11}={{'QId'}};
patseq{12}={{'Y90p'}};
patseq{13}={{'Y90p'},{'Yp'}};
patseq{14}={{'Y90p'},{'Yp'},{'Yp'}};
patseq{15}={{'Y90p'},{'Yp'},{'Yp'},{'Yp'}};

% -Y rotations
% QId
% Y90m
% Y90m Ym
% Y90m Ym Ym
% Y90m Ym Ym Ym
% Y90m Ym Ym Ym Ym
patseq{16}={{'QId'}};
patseq{17}={{'Y90m'}};
patseq{18}={{'Y90m'},{'Ym'}};
patseq{19}={{'Y90m'},{'Ym'},{'Ym'}};
patseq{20}={{'Y90m'},{'Ym'},{'Ym'},{'Ym'}};

% just a pi pulse for scaling
patseq{21}={{'Xp'}};

% double every pulse
nbrPatterns = 2*length(patseq);
fprintf('Number of sequences: %i\n', nbrPatterns);

% pre-allocate space
ch1 = zeros(nbrPatterns, cycleLength);
ch2 = ch1; ch3 = ch1; ch4 = ch1;
ch1m1 = ch1; ch1m2 = ch1; ch2m1 = ch1; ch2m2 = ch1;
ch3m1 = ch1; ch3m2 = ch1; ch4m1 = ch1; ch4m2 = ch1;
delayDiff = delays('34') - delays('56');
PulseCollectionQ2 = [];

for kindex = 1:nbrPatterns;
    [Q2_I_seq{kindex}, Q2_Q_seq{kindex}, ~, PulseCollectionQ2] = pg21.build(patseq{floor((kindex-1)/2)+1}, 1, delays('56'), fixedPt, PulseCollectionQ2);
    patx = pg21.linkListToPattern(Q2_I_seq{kindex}, 1)';
    paty = pg21.linkListToPattern(Q2_Q_seq{kindex}, 1)';
    % remove difference of delays
    patx = circshift(patx, delayDiff);
    paty = circshift(paty, delayDiff);
    ch2m1(kindex, :) = pg2.bufferPulse(patx, paty, 0, bufferPaddings('34'), bufferResets('34'), bufferDelays('34'));
end

% trigger at beginning of measurement pulse
% measure from (6000:9500)
measLength = 3500;
measSeq = {pg2.pulse('M', 'width', measLength)};

for n = 1:nbrPatterns;
	ch1m1(n,:) = pg2.makePattern([], fixedPt-500, ones(100,1), cycleLength);
	ch1m2(n,:) = int32(pg2.getPatternSeq(measSeq, n, measDelay, fixedPt+measLength));
    ch4m2(n,:) = pg2.makePattern([], 5, ones(100,1), cycleLength);
end

% unify LLs and waveform libs
ch5seq = Q2_I_seq{1}; ch6seq = Q2_Q_seq{1};
for n = 2:nbrPatterns
    for m = 1:length(Q2_I_seq{n}.linkLists)
        ch5seq.linkLists{end+1} = Q2_I_seq{n}.linkLists{m};
        ch6seq.linkLists{end+1} = Q2_Q_seq{n}.linkLists{m};
    end
end
ch5seq.waveforms = deviceDrivers.APS.unifySequenceLibraryWaveformsSingle(Q2_I_seq);
ch6seq.waveforms = deviceDrivers.APS.unifySequenceLibraryWaveformsSingle(Q2_Q_seq);

if makePlot
    myn = 20;
    ch5 = pg.linkListToPattern(ch5seq, myn);
    ch6 = pg.linkListToPattern(ch6seq, myn);
    figure
    plot(ch5)
    hold on
    plot(ch6, 'r')
    plot(5000*ch2m1(myn,:), 'k')
    plot(5000*ch1m1(myn,:),'.')
    plot(5000*ch1m2(myn,:), 'g')
    grid on
    hold off
end

% add offsets to unused channels
ch1 = ch1 + offsets('12');
ch2 = ch2 + offsets('12');
ch3 = ch3 + offsets('34');
ch4 = ch4 + offsets('34');
ch2m2 = ch4m2;

% make APS file
%exportAPSConfig(tempdir, basename, ch5seq, ch6seq);
exportAPSConfig(tempdir, basename, ch5seq, ch6seq, ch5seq, ch6seq);
disp('Moving APS file to destination');
movefile([tempdir basename '.mat'], [pathAPS basename '.mat']);
% make TekAWG file
options = struct('m21_high', 2.0, 'm41_high', 2.0);
TekPattern.exportTekSequence(tempdir, basename, ch1, ch1m1, ch1m2, ch2, ch2m1, ch2m2, ch3, ch3m1, ch3m2, ch4, ch4m1, ch4m2, options);
disp('Moving AWG file to destination');
movefile([tempdir basename '.awg'], [pathAWG basename '.awg']);
end
