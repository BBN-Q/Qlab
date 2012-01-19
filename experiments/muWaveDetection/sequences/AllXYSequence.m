function AllXYSequence(makePlot)

if ~exist('makePlot', 'var')
    makePlot = true;
end

basename = 'AllXY';
fixedPt = 6000;
cycleLength = 10000;
nbrRepeats = 2;


% load config parameters from file
load(getpref('qlab','pulseParamsBundleFile'), 'Ts', 'delays', 'measDelay', 'bufferDelays', 'bufferResets', 'bufferPaddings', 'offsets', 'piAmps', 'pi2Amps', 'sigmas', 'pulseTypes', 'deltas', 'buffers', 'pulseLengths');
% if using SSB, uncomment the following line
% Ts('12') = eye(2);
pg = PatternGen('dPiAmp', piAmps('q1'), 'dPiOn2Amp', pi2Amps('q1'), 'dSigma', sigmas('q1'), 'dPulseType', pulseTypes('q1'), 'dDelta', deltas('q1'), 'correctionT', Ts('12'), 'dBuffer', buffers('q1'), 'dPulseLength', pulseLengths('q1'), 'cycleLength', cycleLength);

% ground state:
% QId
% Xp Xm
% Yp Ym
% Xp Xp
% Yp Yp
% Xp Yp
% Yp Xp
% Yp Xm
% Xp Ym

patseq{1}={pg.pulse('QId')};

patseq{2}={pg.pulse('Xp'),pg.pulse('Xm')};
patseq{3}={pg.pulse('Yp'),pg.pulse('Ym')};
patseq{4}={pg.pulse('Xp'),pg.pulse('Xp')};
patseq{5}={pg.pulse('Yp'),pg.pulse('Yp')};

patseq{6}={pg.pulse('Xp'),pg.pulse('Yp')};
patseq{7}={pg.pulse('Yp'),pg.pulse('Xp')};

patseq{8}={pg.pulse('Yp'),pg.pulse('Xm')};
patseq{9}={pg.pulse('Xp'),pg.pulse('Ym')};

% superposition state:
% -1 * eps error
% X90p
% Y90p
% X90m
% Y90m

% 0 * eps error (phase sensitive)
% X90p Y90p
% Y90p X90p
% X90m Y90m
% Y90m X90m

% +1 * eps error
% Xp Y90p
% Yp X90p
% Xp Y90m
% Yp X90m
% X90p Yp (phase sensitive)
% Y90p Xp (phase sensitive)

% +3 * eps error
% Xp X90p
% Yp Y90p
% Xm X90m
% Ym Y90m

patseq{10}={pg.pulse('X90p')};
patseq{11}={pg.pulse('Y90p')};
patseq{12}={pg.pulse('X90m')};
patseq{13}={pg.pulse('Y90m')};

patseq{14}={pg.pulse('X90p'), pg.pulse('Y90p')};
patseq{15}={pg.pulse('Y90p'), pg.pulse('X90p')};
patseq{16}={pg.pulse('X90m'), pg.pulse('Y90m')};
patseq{17}={pg.pulse('Y90m'), pg.pulse('X90m')};


patseq{18}={pg.pulse('Xp'),pg.pulse('Y90p')};
patseq{19}={pg.pulse('Yp'),pg.pulse('X90p')};
patseq{20}={pg.pulse('Xp'),pg.pulse('Y90m')};
patseq{21}={pg.pulse('Yp'),pg.pulse('X90m')};
patseq{22}={pg.pulse('X90p'),pg.pulse('Yp')};
patseq{23}={pg.pulse('Y90p'),pg.pulse('Xp')};


patseq{24}={pg.pulse('Xp'),pg.pulse('X90p')};
patseq{25}={pg.pulse('Yp'),pg.pulse('Y90p')};
patseq{26}={pg.pulse('Xm'),pg.pulse('X90m')};
patseq{27}={pg.pulse('Ym'),pg.pulse('Y90m')};

% excited state;
% Xp
% Xm
% Yp
% Ym
% X90p X90p
% X90m X90m
% Y90p Y90p
% Y90m Y90m

patseq{28} = {pg.pulse('QId'),pg.pulse('Xp')};
patseq{29} = {pg.pulse('QId'),pg.pulse('Xm')};
patseq{30} = {pg.pulse('QId'),pg.pulse('Yp')};
patseq{31} = {pg.pulse('QId'),pg.pulse('Ym')};

patseq{32} = {pg.pulse('X90p'),pg.pulse('X90p')};
patseq{33} = {pg.pulse('X90m'),pg.pulse('X90m')};
patseq{34} = {pg.pulse('Y90p'),pg.pulse('Y90p')};
patseq{35} = {pg.pulse('Y90m'),pg.pulse('Y90m')};

%for iindex = 1:nbrPulses
%    for jindex = 1:nbrPulses
%        patseq{(iindex-1)*nbrPulses+jindex} = {AllPulses{iindex}, AllPulses{jindex}};
%    end
%end

% just a pi pulse for scaling
calseq={};

compileSequence12(basename, pg, patseq, calseq, 1, nbrRepeats, fixedPt, cycleLength, makePlot);

end