function SPAMSequence(qubit, angleShifts, makePlot, plotSeqNum)
%SPAMSequence Calibrates angle between X and Y quadratures with repeated XY
%blocks
% SPAMSequence(qubit, angleShifts, makePlot, plotSeqNum)
%   qubit - target qubit e.g. 'q1'
%   angleShifts - phase shifts to scan over e.g. (pi/180)*(-2.5:0.5:2.5)
%   makePlot - whether to plot a sequence or not (boolean)
%   plotSeqNum (optional) - which sequence to plot (int)

%Y90-(X180-Y180-X180-Y180)^n to determine phase difference between quadrature channels


basename = 'SPAM';
fixedPt = 6000;
cycleLength = 15000;
nbrRepeats = 1;

% load config parameters from file
params = jsonlab.loadjson(getpref('qlab', 'pulseParamsBundleFile'));
qParams = params.(qubit);
qubitMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));
IQkey = qubitMap.(qubit).IQkey;

% if using SSB, set the frequency here
SSBFreq = 0e6;

pg = PatternGen('dPiAmp', qParams.piAmp, 'dPiOn2Amp', qParams.pi2Amp, 'dSigma', qParams.sigma, 'dPulseType', qParams.pulseType, 'dDelta', qParams.delta, 'correctionT', params.(IQkey).T, 'dBuffer', qParams.buffer, 'dPulseLength', qParams.pulseLength, 'cycleLength', cycleLength, 'linkList', params.(IQkey).linkListMode, 'dmodFrequency',SSBFreq);
patseq = {};

for angleShift = angleShifts
    SPAMBlock = {pg.pulse('Xp'),pg.pulse('Up','angle',pi/2+angleShift),pg.pulse('Xp'),pg.pulse('Up','angle',pi/2+angleShift)};
     for SPAMct = 0:10
        patseq{end+1} = {pg.pulse('Y90p')};
        for ct = 0:SPAMct
            patseq{end} = [patseq{end}, SPAMBlock];
        end
        patseq{end} = [patseq{end}, {pg.pulse('X90m')}];
     end
    patseq{end+1} = {pg.pulse('QId')};
end
calseq = {};
calseq{end+1} = {pg.pulse('Xp')};
calseq{end+1} = {pg.pulse('Xp')};

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
awgs = {'TekAWG', 'BBNAPS1', 'BBNAPS2'};
if ~makePlot
    plotSeqNum = 0;
end
compileSequences(seqParams, patternDict, measChannels, awgs, makePlot, plotSeqNum);
end
