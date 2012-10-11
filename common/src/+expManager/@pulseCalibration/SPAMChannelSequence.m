function [filename, nbrPatterns] = SPAMChannelSequence(obj, qubit, makePlot)

if ~exist('makePlot', 'var')
    makePlot = false;
end

pathAWG = 'U:\AWG\SPAM\';
basename = 'SPAM';
fixedPt = 6000;
cycleLength = 8000;
nbrRepeats = 1;

% load config parameters from files
params = jsonlab.loadjson(getpref('qlab', 'pulseParamsBundleFile'));
qParams = params.(qubit);

qubitMap = obj.channelMap.(qubit);
IQkey = qubitMap.IQkey;

pg = PatternGen(...
    'dPiAmp', obj.pulseParams.piAmp, ...
    'dPiOn2Amp', obj.pulseParams.pi2Amp, ...
    'dSigma', qParams.sigma, ...
    'dPulseType', obj.pulseParams.pulseType, ...
    'dDelta', obj.pulseParams.delta, ...
    'correctionT', obj.pulseParams.T, ...
    'dBuffer', qParams.buffer, ...
    'dPulseLength', qParams.pulseLength, ...
    'cycleLength', cycleLength, ...
    'linkList', params.(IQkey).linkListMode, ...
    'dmodFrequency', obj.pulseParams.SSBFreq ...
    );


numPsQId = 10; % number pseudoidentities
angleShifts = (pi/180)*(-2:0.5:2);

patseq = {};

for angleShift = angleShifts
    patseq{end+1} = {pg.pulse('QId')};
    SPAMBlock = {pg.pulse('Xp'),pg.pulse('Up','angle',pi/2+angleShift),pg.pulse('Xp'),pg.pulse('Up','angle',pi/2+angleShift)};
     for SPAMct = 0:numPsQId
        patseq{end+1} = {pg.pulse('Y90p')};
        for ct = 0:SPAMct
            patseq{end} = [patseq{end}, SPAMBlock];
        end
        patseq{end} = [patseq{end}, {pg.pulse('X90m')}];
     end
end
calseq = {{pg.pulse('Xp')}};

nbrPatterns = nbrRepeats*(length(patseq) + length(calseq));

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
patternDict(IQkey) = struct('pg', pg, 'patseq', {patseq}, 'calseq', calseq, 'channelMap', qubitMap);
measChannels = {'M1'};
awgs = cellfun(@(x) x.InstrName, obj.awgParams, 'UniformOutput',false);

compileSequences(seqParams, patternDict, measChannels, awgs, makePlot, 20);

for awgct = 1:length(awgs)
    switch awgs{awgct}(1:6)
        case 'TekAWG'
            filename{awgct} = [pathAWG basename '-' awgs{awgct}, '.awg'];
        case 'BBNAPS'
            filename{awgct} = [pathAWG basename '-', awgs{awgct}, '.h5'];
        otherwise
            error('Unknown AWG type.');
    end
end

end