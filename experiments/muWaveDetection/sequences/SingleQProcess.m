function SingleQProcess(varargin)

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

basename = 'SingleQProcess';
fixedPt = 3000;
cycleLength = 13000;
nbrRepeats = 2;

% load config parameters from file
params = jsonlab.loadjson(getpref('qlab', 'pulseParamsBundleFile'));
qParams = params.(qubit);
qubitMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));
IQkey = qubitMap.(qubit).IQkey;

% if using SSB, set the frequency here
SSBFreq = 0e6;

pg = PatternGen('dPiAmp', qParams.piAmp, 'dPiOn2Amp', qParams.pi2Amp, 'dSigma', qParams.sigma, 'dPulseType', qParams.pulseType, 'dDelta', qParams.delta, 'correctionT', params.(IQkey).T, 'dBuffer', qParams.buffer, 'dPulseLength', qParams.pulseLength, 'cycleLength', cycleLength, 'linkList', params.(IQkey).linkListMode, 'dmodFrequency',SSBFreq);

patseq = {};

pulses = {'QId', 'Xp', 'X90p', 'Y90p', 'X90m', 'Y90m'};
pulseLib = struct();
for i = 1:length(pulses)
    pulseLib.(pulses{i}) = pg.pulse(pulses{i});
end

%The map we want to characterize
%Figure out the approximate nutation frequency calibration from the
%X180 and the the samplingRate
Xp = pg.pulse('Xp');
xpulse = Xp(1,0);
nutFreq = 0.5/(sum(xpulse)/pg.samplingRate);

process = pg.pulse('Up', 'polarAngle', pi/4, 'aziAngle', 0, 'pType', 'arbAxisDRAG', 'nutFreq', nutFreq, 'sampRate', pg.samplingRate, 'delta', 0);

for ii = 1:6
    for jj = 1:6
        patseq{end+1} = { pulseLib.(pulses{ii}), process, pulseLib.(pulses{jj}) };
    end
end
                

calseq = {};
calseq{end+1} = {pg.pulse('QId')};
calseq{end+1} = {pg.pulse('Xp')};

compiler = ['compileSequence' IQkey];
compileArgs = {basename, pg, patseq, calseq, 1, nbrRepeats, fixedPt, cycleLength, makePlot, 15};
if exist(compiler, 'file') == 2 % check that the pulse compiler is on the path
    feval(compiler, compileArgs{:});
end

end
