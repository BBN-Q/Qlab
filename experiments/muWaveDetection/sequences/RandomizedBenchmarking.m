function RandomizedBenchmarking(qubit, makePlot)

basename = 'RB';
fixedPt = 27000;
cycleLength = 30000;
nbrRepeats = 100;
introduceError = 0;
errorAmp = 0.2;

% if using SSB, set the frequency here
SSBFreq = 0e6;

pg = PatternGen(qubit);

% load in random Clifford sequences from text file
% FID = fopen('RBsequences-long.txt');
FID = fopen('RB_ISeqs.txt');
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

qubitMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));
IQkey = qubitMap.(qubit).IQkey;

patternDict(IQkey) = struct('pg', pg, 'patseq', {patseq}, 'calseq', calseq, 'channelMap', qubitMap.(qubit));
measChannels = {'M1'};
awgs = {'TekAWG', 'BBNAPS1', 'BBNAPS2'};

compileSequences(seqParams, patternDict, measChannels, awgs, makePlot);

end