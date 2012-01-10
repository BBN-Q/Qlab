function PiCalSequence(makePlot)

if ~exist('makePlot', 'var')
    makePlot = true;
end

basename = 'PiCal';
fixedPt = 6000;
cycleLength = 10000;
nbrRepeats = 2;


% load config parameters from file
load(getpref('qlab','pulseParamsBundleFile'), 'Ts', 'delays', 'measDelay', 'bufferDelays', 'bufferResets', 'bufferPaddings', 'offsets', 'piAmps', 'pi2Amps', 'sigmas', 'pulseTypes', 'deltas', 'buffers', 'pulseLengths');
% if using SSB, uncomment the following line
Ts('12') = eye(2);
pg = PatternGen('dPiAmp', piAmps('q1'), 'dPiOn2Amp', pi2Amps('q1'), 'dSigma', sigmas('q1'), 'dPulseType', pulseTypes('q1'), 'dDelta', deltas('q1'), 'correctionT', Ts('12'), 'dBuffer', buffers('q1'), 'dPulseLength', pulseLengths('q1'), 'cycleLength', cycleLength);

% +X rotations
% QId
% X90p Xp
% X90p Xp Xp
% X90p Xp Xp Xp
% X90p Xp Xp Xp Xp
patseq{1}={pg.pulse('QId')};
patseq{2}={pg.pulse('X90p')};
patseq{3}={pg.pulse('X90p'),pg.pulse('Xp')};
patseq{4}={pg.pulse('X90p'),pg.pulse('Xp'),pg.pulse('Xp')};
patseq{5}={pg.pulse('X90p'),pg.pulse('Xp'),pg.pulse('Xp'),pg.pulse('Xp')};
patseq{6}={pg.pulse('X90p'),pg.pulse('Xp'),pg.pulse('Xp'),pg.pulse('Xp'),pg.pulse('Xp')};

% -X rotations
% QId
% X90m Xm
% X90m Xm Xm
% X90m Xm Xm Xm
% X90m Xm Xm Xm Xm
patseq{7}={pg.pulse('QId')};
patseq{8}={pg.pulse('X90m')};
patseq{9}={pg.pulse('X90m'),pg.pulse('Xm')};
patseq{10}={pg.pulse('X90m'),pg.pulse('Xm'),pg.pulse('Xm')};
patseq{11}={pg.pulse('X90m'),pg.pulse('Xm'),pg.pulse('Xm'),pg.pulse('Xm')};
patseq{12}={pg.pulse('X90m'),pg.pulse('Xm'),pg.pulse('Xm'),pg.pulse('Xm'),pg.pulse('Xm')};

% +Y rotations
% QId
% Y90p Yp
% Y90p Yp Yp
% Y90p Yp Yp Yp
% Y90p Yp Yp Yp Yp
patseq{13}={pg.pulse('QId')};
patseq{14}={pg.pulse('Y90p')};
patseq{15}={pg.pulse('Y90p'),pg.pulse('Yp')};
patseq{16}={pg.pulse('Y90p'),pg.pulse('Yp'),pg.pulse('Yp')};
patseq{17}={pg.pulse('Y90p'),pg.pulse('Yp'),pg.pulse('Yp'),pg.pulse('Yp')};
patseq{18}={pg.pulse('Y90p'),pg.pulse('Yp'),pg.pulse('Yp'),pg.pulse('Yp'),pg.pulse('Yp')};

% -Y rotations
% QId
% Y90m Ym
% Y90m Ym Ym
% Y90m Ym Ym Ym
% Y90m Ym Ym Ym Ym
patseq{19}={pg.pulse('QId')};
patseq{20}={pg.pulse('Y90m')};
patseq{21}={pg.pulse('Y90m'),pg.pulse('Ym')};
patseq{22}={pg.pulse('Y90m'),pg.pulse('Ym'),pg.pulse('Ym')};
patseq{23}={pg.pulse('Y90m'),pg.pulse('Ym'),pg.pulse('Ym'),pg.pulse('Ym')};
patseq{24}={pg.pulse('Y90m'),pg.pulse('Ym'),pg.pulse('Ym'),pg.pulse('Ym'),pg.pulse('Ym')};

% just a pi pulse for scaling
calseq={{pg.pulse('Xp')}};


compileSequenceSSB12(basename, pg, patseq, calseq, 1, nbrRepeats, fixedPt, cycleLength, makePlot);
end