function APESequence(makePlot)

if ~exist('makePlot', 'var')
    makePlot = true;
end

basename = 'APE';
fixedPt = 6000;
cycleLength = 10000;
nbrRepeats = 2;

% load config parameters from file
load(getpref('qlab','pulseParamsBundleFile'), 'Ts', 'delays', 'measDelay', 'bufferDelays', 'bufferResets', 'bufferPaddings', 'offsets', 'piAmps', 'pi2Amps', 'sigmas', 'pulseTypes', 'deltas', 'buffers', 'pulseLengths');
% if using SSB, uncomment the following line
Ts('12') = eye(2);
pg = PatternGen('dPiAmp', piAmps('q1'), 'dPiOn2Amp', pi2Amps('q1'), 'dSigma', sigmas('q1'), 'dPulseType', pulseTypes('q1'), 'dDelta', deltas('q1'), 'correctionT', Ts('12'), 'dBuffer', buffers('q1'), 'dPulseLength', pulseLengths('q1'), 'cycleLength', cycleLength);

angle = pi/2;
numPsQId = 5; % number pseudoidentities
numsteps = 11; %number of drag parameters
deltamax=1.0;
deltamin=-1.0;
delta=linspace(deltamin,deltamax,numsteps);

sindex = 0;
% QId
% N applications of psuedoidentity
% X90p, (sequence of +/-X90p), U90p
% (1-numPsQId) of +/-X90p
for i=1:numsteps
    sindex=sindex+1;
    patseq{sindex} = {pg.pulse('QId')};
    %patnames{sindex} = {{'QId'}};
    for j = 1:numPsQId
        patseq{sindex + j} = {pg.pulse('X90p', 'delta', delta(i))};
        %patnames{sindex + j} = {{'X90p'}};
        for k = 1:j
            patseq{sindex + j}(2*k:2*k+1) = {pg.pulse('X90p','delta',delta(i)),pg.pulse('X90m','delta',delta(i))};
            %patseq{sindex + j}(2*k:2*k+1) = {pg.pulse('Xp','delta',delta(i)),pg.pulse('Xm','delta',delta(i))};
            %patnames{sindex + j}(2*k:2*k+1) = {{'X90p'},{'X90m'}};
        end
        patseq{sindex+j}{2*(j+1)} = pg.pulse('U90p', 'angle', angle, 'delta', delta(i));
        %patnames{sindex+j}{2*(j+1)} = {'U90p'};
    end
    sindex = sindex + numPsQId;
end

% just a pi pulse for scaling
calseq={{pg.pulse('Xp')}};

compileSequenceSSB12(basename, pg, patseq, calseq, 1, nbrRepeats, fixedPt, cycleLength, makePlot);
end