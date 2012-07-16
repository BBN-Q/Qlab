function PiCalSequence(varargin)

%varargin assumes qubit and then makePlot
qubit = 'q1';
makePlot = true;

if length(varargin) == 1
    qubit = varargin{1};
elseif length(varargin) == 2
    qubit = varargin{1};
    makePlot = varargin{2};
elseif length(varargin) > 2
    error('Too many input arguments.')
end


basename = 'PiCal';
fixedPt = 6000;
cycleLength = 16000;
nbrRepeats = 2;
numsteps = 1;


% load config parameters from files
params = jsonlab.loadjson(getpref('qlab', 'pulseParamsBundleFile'));
qParams = params.(qubit);
qubitMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));
IQkey = qubitMap.(qubit).IQkey;

% if using SSB, set the frequency here
SSBFreq = -100e6;

pg = PatternGen('dPiAmp', qParams.piAmp, 'dPiOn2Amp', qParams.pi2Amp, 'dSigma', qParams.sigma, 'dPulseType', qParams.pulseType, 'dDelta', qParams.delta, 'correctionT', params.(IQkey).T, 'dBuffer', qParams.buffer, 'dPulseLength', qParams.pulseLength, 'cycleLength', cycleLength, 'linkList', params.(IQkey).linkListMode, 'dmodFrequency',SSBFreq);


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


compiler = ['compileSequence' IQkey];
compileArgs = {basename, pg, patseq, calseq, numsteps, nbrRepeats, fixedPt, cycleLength, makePlot};
if exist(compiler, 'file') == 2 % check that the pulse compiler is on the path
    feval(compiler, compileArgs{:});
else
    error('Unable to find compiler for IQkey: %s',IQkey) 
end

end