function SPAMSequence(varargin)

%Y90-(X180-Y180-X180-Y180)^n to determine phase difference between quadrature channels

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
%angleShift = 8.5*pi/180;
angleShifts = (pi/180)*(-2:0.5:2);

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
awgs = {'TekAWG', 'BBNAPS'};

compileSequences(seqParams, patternDict, measChannels, awgs, makePlot, 20);
end
