function PiCalSequence(makePlot)

if ~exist('makePlot', 'var')
    makePlot = true;
end

basename = 'PiCal';
fixedPt = 6000;
cycleLength = 10000;
nbrRepeats = 2;

% load config parameters from file
params = jsonlab.loadjson(getpref('qlab', 'pulseParamsBundleFile'));
qParams = params.q1; % choose target qubit here
IQkey = 'Tek12';
% if using SSB, uncomment the following line
% params.(IQkey).T = eye(2);
pg = PatternGen('dPiAmp', qParams.piAmp, 'dPiOn2Amp', qParams.pi2Amp, 'dSigma', qParams.sigma, 'dPulseType', qParams.pulseType, 'dDelta', qParams.delta, 'correctionT', params.(IQkey).T, 'dBuffer', qParams.buffer, 'dPulseLength', qParams.pulseLength, 'cycleLength', cycleLength, 'linkList', params.(IQkey).passThru);

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


compileSequence12(basename, pg, patseq, calseq, 1, nbrRepeats, fixedPt, cycleLength, makePlot);
end