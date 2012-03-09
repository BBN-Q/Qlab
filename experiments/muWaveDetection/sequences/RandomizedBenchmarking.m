function RandomizedBenchmarking(varargin)

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

basename = 'RB';
fixedPt = 20000; %15000
cycleLength = 24000; %19000
nbrRepeats = 1;
introduceError = 0;
errorAmp = 0.2;

% load config parameters from file
params = jsonlab.loadjson(getpref('qlab', 'pulseParamsBundleFile'));
qParams = params.(qubit);
qubitMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));
IQkey = qubitMap.(qubit).IQkey;

% if using SSB, set the frequency here
SSBFreq = -150e6;

pg = PatternGen('dPiAmp', qParams.piAmp, 'dPiOn2Amp', qParams.pi2Amp, 'dSigma', qParams.sigma, 'dPulseType', qParams.pulseType, 'dDelta', qParams.delta, 'correctionT', params.(IQkey).T, 'dBuffer', qParams.buffer, 'dPulseLength', qParams.pulseLength, 'cycleLength', cycleLength, 'linkList', params.(IQkey).linkListMode, 'dmodFrequency',SSBFreq);

% load in random Clifford sequences from text file
FID = fopen('RBsequences-long.txt');
% FID = fopen('RB-interleave-Y90p.txt');
if ~FID
    error('Could not open Clifford sequence list')
end

%Read in each line
tmpArray = textscan(FID, '%s','delimiter','\n');
fclose(FID);
%Split each line
seqStrings = cellfun(@(x) textscan(x,'%s'), tmpArray{1});

% convert sequence strings into pulses
pulseLibrary = containers.Map();
for ii = 1:length(seqStrings)
    for jj = 1:length(seqStrings{ii})
        pulseName = seqStrings{ii}{jj};
        if ~isKey(pulseLibrary, pulseName)
            % intentionally introduce an error in one of the
            % pulses, if desired
            if introduceError && strcmp(pulseName, 'X90p')
                pulseLibrary(pulseName) = pg.pulse('Xtheta', 'amp', qParams.pi2Amp*(1+errorAmp));
            else
                pulseLibrary(pulseName) = pg.pulse(pulseName);
            end
        end
        currentSeq{jj} = pulseLibrary(pulseName);
    end
    patseq{ii} = currentSeq(1:jj);
end

calseq = {{pg.pulse('QId')},{pg.pulse('QId')},{pg.pulse('Xp')},{pg.pulse('Xp')}};


compiler = ['compileSequence' IQkey];
compileArgs = {basename, pg, patseq, calseq, 1, nbrRepeats, fixedPt, cycleLength, makePlot};
if exist(compiler, 'file') == 2 % check that the pulse compiler is on the path
    feval(compiler, compileArgs{:});
end


end