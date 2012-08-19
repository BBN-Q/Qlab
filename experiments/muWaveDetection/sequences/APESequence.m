function APESequence(qubit, deltaScan, makePlot, plotSeqNum)
%APESequence Calibrate the DRAG parameter through a flip-flop seuquence.
% APESequence(qubit, deltaScan, makePlot, plotSeqNum)
%   qubit - target qubit e.g. 'q1'
%   deltaScan - delta parameter to scan over e.g. linspace(-1,1,11)
%   makePlot - whether to plot a sequence or not (boolean)
%   plotSeqNum (optional) - which sequence to plot (int)

basename = 'APE';
fixedPt = 6000;
cycleLength = 8000;
nbrRepeats = 1;

% load config parameters from files
params = jsonlab.loadjson(getpref('qlab', 'pulseParamsBundleFile'));
qParams = params.(qubit);
qubitMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));
IQkey = qubitMap.(qubit).IQkey;

% if using SSB, set the frequency here
SSBFreq = 0e6;

pg = PatternGen('dPiAmp', qParams.piAmp, 'dPiOn2Amp', qParams.pi2Amp, 'dSigma', qParams.sigma, 'dPulseType', qParams.pulseType, 'dDelta', qParams.delta, 'correctionT', params.(IQkey).T, 'dBuffer', qParams.buffer, 'dPulseLength', qParams.pulseLength, 'cycleLength', cycleLength, 'linkList', params.(IQkey).linkListMode, 'dmodFrequency',SSBFreq);


angle = pi/2;
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
        patseq{sindex + j} = {pg.pulse('X90p', 'delta', curDelta)};
        for k = 1:j
            patseq{sindex + j}(2*k:2*k+1) = {pg.pulse('X90p','delta',curDelta),pg.pulse('X90m','delta',curDelta)};
        end
        patseq{sindex+j}{end+1} = pg.pulse('U90p', 'angle', angle, 'delta', curDelta);
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
patternDict = containers.Map();
if ~isempty(calseq), calseq = {calseq}; end
patternDict(IQkey) = struct('pg', pg, 'patseq', {patseq}, 'calseq', calseq, 'channelMap', qubitMap.(qubit));
measChannels = {'M1'};
awgs = {'TekAWG', 'BBNAPS'};

if ~makePlot
    plotSeqNum = 0;
end

compileSequences(seqParams, patternDict, measChannels, awgs, makePlot, plotSeqNum);
end