function APE_ZDRAGSequence(qubit, deltaScan, makePlot)
%APE_ZDRAGSequence Calibrate the DRAG parameter through a flip-flop seuquence.
% APE_ZDRAGSequence(qubit, deltaScan, makePlot)
%   qubit - target qubit e.g. 'q1'
%   deltaScan - delta parameter to scan over e.g. linspace(-1,1,11)
%   makePlot - whether to plot a sequence or not (boolean)

basename = 'APE';
fixedPt = 6000;
cycleLength = 8000;
nbrRepeats = 1;

% if using SSB, set the frequency here
SSBFreq = 0e6;
pg = PatternGen(qubit, 'SSBFreq', SSBFreq, 'cycleLength', cycleLength);

numPsQId = 8; % number pseudoidentities
numDeltaSteps = length(deltaScan); %number of drag parameters (11)

sindex = 1;
% QId
% N applications of psuedoidentity
% X90p, (sequence of +/-X90p), U90p
% (1-numPsQId) of +/-X90p
for ct=1:numDeltaSteps
    curDelta = deltaScan(ct);
    patseq{sindex} = {pg.pulse('QId')};
    sindex=sindex+1;
    for j = 0:numPsQId
        patseq{sindex + j} = {CliffPulse(2, pg, curDelta)}; % X90p
        for k = 1:j
            patseq{sindex + j}(2*k:2*k+1) = {CliffPulse(2, pg, curDelta), CliffPulse(4, pg, curDelta)}; % X90p, X90m
        end
        patseq{sindex+j}{end+1} = CliffPulse(5, pg, curDelta); % Y90p
    end
    sindex = sindex + numPsQId+1;
end

% just a pi pulse for scaling
calseq={{pg.pulse('Xp')}};

seqParams = struct(...
    'basename', basename, ...
    'suffix', '', ...
    'numSteps', 1, ...
    'nbrRepeats', nbrRepeats, ...
    'fixedPt', fixedPt, ...
    'cycleLength', cycleLength, ...
    'measLength', 2000);
if ~isempty(calseq), calseq = {calseq}; end

qubitMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));
IQkey = qubitMap.(qubit).IQkey;

patternDict = containers.Map();
patternDict(IQkey) = struct('pg', pg, 'patseq', {patseq}, 'calseq', calseq, 'channelMap', qubitMap.(qubit));

measChannels = {'M1'};
awgs = {'TekAWG', 'BBNAPS1', 'BBNAPS2'};

compileSequences(seqParams, patternDict, measChannels, awgs, makePlot);
end

function outPulse = CliffPulse(cliffNum, pg, delta)
%Create a pulse from a clifford Number.  Cliffords are numbered with 1 based indexing:

%Figure out the approximate nutation frequency calibration from the
%X180 and the samplingRate
Xp = pg.pulse('Xp');
xpulse = Xp.getPulse(1,0);
nutFreq = 0.5/(sum(xpulse)/pg.samplingRate);

defaultParams = {'pType', 'arbAxisDRAG', 'nutFreq', nutFreq, 'delta', delta};

switch cliffNum
    case 1
        %Identity gate
        outPulse = pg.pulse('QId');
    case 2
        %X90
        outPulse = pg.pulse('X90p', 'polarAngle', pi/2, 'aziAngle', 0, defaultParams{:});
    case 3
        %X180
        outPulse = pg.pulse('Xp', 'polarAngle', pi/2, 'aziAngle', 0, defaultParams{:});
    case 4
        %Xm90
        outPulse = pg.pulse('X90m', 'polarAngle', pi/2, 'aziAngle', pi, defaultParams{:});
    case 5
        %Y90
        outPulse = pg.pulse('Y90p', 'polarAngle', pi/2, 'aziAngle', 0, defaultParams{:});
    case 6
        %Y180
        outPulse = pg.pulse('Yp', 'polarAngle', pi/2, 'aziAngle', 0, defaultParams{:});
    case 7
        %Ym90
        outPulse = pg.pulse('Y90m', 'polarAngle', pi/2, 'aziAngle', pi, defaultParams{:});
    case 8
        %Z90
        outPulse = pg.pulse('QId', 'rotAngle', pi/2, 'polarAngle', 0, 'aziAngle', 0, defaultParams{:});
    case 9
        %Z180
        outPulse = pg.pulse('QId', 'rotAngle', pi, 'polarAngle', 0, 'aziAngle', 0, defaultParams{:});
    case 10
        %Z90m
        outPulse = pg.pulse('QId', 'rotAngle', -pi/2, 'polarAngle', 0, 'aziAngle', 0, defaultParams{:});
    case 11
        %X+Y 180
        outPulse = pg.pulse('Up', 'angle', pi/4);
    case 12
        %X-Y 180
        outPulse = pg.pulse('Up', 'angle', -pi/4);
    case 13
        %X+Z (Hadamard)
        outPulse = pg.pulse('Up', 'polarAngle', pi/4, 'aziAngle', 0, defaultParams{:});
    case 14
        %X-Z (Hadamard)
        outPulse = pg.pulse('Up', 'polarAngle', pi/4, 'aziAngle', pi, defaultParams{:});
    case 15
        %Y+Z (Hadamard)
        outPulse = pg.pulse('Up', 'polarAngle', pi/4, 'aziAngle', pi/2, defaultParams{:});
    case 16
        %Y-Z (Hadamard)
        outPulse = pg.pulse('Up', 'polarAngle', pi/4, 'aziAngle', -pi/2, defaultParams{:});
    case 17
        %X+Y+Z 120
        outPulse = pg.pulse('Utheta', 'rotAngle', 2*pi/3, 'polarAngle', acos(1/sqrt(3)), 'aziAngle', pi/4, defaultParams{:});
    case 18
        %X+Y+Z -120 (equivalent to -X-Y-Z 120)
        outPulse = pg.pulse('Utheta', 'rotAngle', 2*pi/3, 'polarAngle', pi-acos(1/sqrt(3)), 'aziAngle', 5*pi/4, defaultParams{:});
    case 19
        %X-Y+Z 120
        outPulse = pg.pulse('Utheta', 'rotAngle', 2*pi/3, 'polarAngle', acos(1/sqrt(3)), 'aziAngle', -pi/4, defaultParams{:});
    case 20
        %X-Y+Z -120 (equivalent to -X+Y-Z 120)
        outPulse = pg.pulse('Utheta', 'rotAngle', 2*pi/3, 'polarAngle', pi-acos(1/sqrt(3)), 'aziAngle', 3*pi/4, defaultParams{:});
    case 21
        %X+Y-Z 120
        outPulse = pg.pulse('Utheta', 'rotAngle', 2*pi/3, 'polarAngle', pi-acos(1/sqrt(3)), 'aziAngle', pi/4, defaultParams{:});
    case 22
        %X+Y-Z -120 (equivalent to -X-Y+Z 120
        outPulse = pg.pulse('Utheta', 'rotAngle', 2*pi/3, 'polarAngle', acos(1/sqrt(3)), 'aziAngle', 5*pi/4, defaultParams{:});
    case 23
        %-X+Y+Z 120
        outPulse = pg.pulse('Utheta', 'rotAngle', 2*pi/3, 'polarAngle', acos(1/sqrt(3)), 'aziAngle', 3*pi/4, defaultParams{:});
    case 24
        %-X+Y+Z -120 (equivalent to X-Y-Z 120
        outPulse = pg.pulse('Utheta', 'rotAngle', 2*pi/3, 'polarAngle', pi-acos(1/sqrt(3)), 'aziAngle', -pi/4, defaultParams{:});
    otherwise
        error('Cliffords must be numbered between 1 and 24');
end

end