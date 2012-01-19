function Pi2CalSequence(makePlot)

if ~exist('makePlot', 'var')
    makePlot = true;
end

basename = 'Pi2Cal';
fixedPt = 6000;
cycleLength = 10000;
nbrRepeats = 2;


numPi2s = 9; % number of odd numbered pi/2 sequences for each rotation direction

% load config parameters from file
load(getpref('qlab','pulseParamsBundleFile'), 'Ts', 'delays', 'measDelay', 'bufferDelays', 'bufferResets', 'bufferPaddings', 'offsets', 'piAmps', 'pi2Amps', 'sigmas', 'pulseTypes', 'deltas', 'buffers', 'pulseLengths');
% if using SSB, uncomment the following line
% Ts('12') = eye(2);
pg = PatternGen('dPiAmp', piAmps('q1'), 'dPiOn2Amp', pi2Amps('q1'), 'dSigma', sigmas('q1'), 'dPulseType', pulseTypes('q1'), 'dDelta', deltas('q1'), 'correctionT', Ts('12'), 'dBuffer', buffers('q1'), 'dPulseLength', pulseLengths('q1'), 'cycleLength', cycleLength);

pulseLib = containers.Map();
pulses = {'QId', 'X90p', 'X90m', 'Y90p', 'Y90m'};
for p = pulses
    pname = cell2mat(p);
    pulseLib(pname) = pg.pulse(pname);
end

sindex = 1;

% +X rotations
% QId
% (1, 3, 5, 7, 9, 11, 13, 15, 17, 19) x X90p
patseq{sindex} = {pulseLib('QId')};
for j = 1:numPi2s
    for k = 1:(1+2*(j-1))
        patseq{sindex + j}{k} = pulseLib('X90p');
    end
end
sindex = sindex + numPi2s + 1;

% -X rotations
% QId
% (1, 3, 5, 7, 9, 11, ...) x X90m
patseq{sindex} = {pulseLib('QId')};
for j = 1:numPi2s
    for k = 1:(1+2*(j-1))
        patseq{sindex + j}{k} = pulseLib('X90m');
    end
end
sindex = sindex + numPi2s + 1;

% +Y rotations
% QId
% (1, 3, 5, 7, 9, 11) x Y90p
patseq{sindex} = {pulseLib('QId')};
for j = 1:numPi2s
    for k = 1:(1+2*(j-1))
        patseq{sindex + j}{k} = pulseLib('Y90p');
    end
end
sindex = sindex + numPi2s + 1;

% -Y rotations
% QId
% (1, 3, 5, 7, 9, 11) x Y90m
patseq{sindex} = {pulseLib('QId')};
for j = 1:numPi2s
    for k = 1:(1+2*(j-1))
        patseq{sindex + j}{k} = pulseLib('Y90m');
    end
end

% just a pi pulse for scaling
calseq={{pg.pulse('Xp')}};


compileSequence12(basename, pg, patseq, calseq, 1, nbrRepeats, fixedPt, cycleLength, makePlot);
end