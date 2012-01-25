function RandomizedBenchmarking(makePlot)

if ~exist('makePlot', 'var')
    makePlot = true;
end

basename = 'RB';
fixedPt = 11000;
cycleLength = 15000;
nbrRepeats = 1;

% load config parameters from file
params = jsonlab.loadjson(getpref('qlab', 'pulseParamsBundleFile'));
qParams = params.q1; % choose target qubit here
IQkey = 'Tek12';
% if using SSB, uncomment the following line
% params.(IQkey).T = eye(2);
pg = PatternGen('dPiAmp', qParams.piAmp, 'dPiOn2Amp', qParams.pi2Amp, 'dSigma', qParams.sigma, 'dPulseType', qParams.pulseType, 'dDelta', qParams.delta, 'correctionT', params.(IQkey).T, 'dBuffer', qParams.buffer, 'dPulseLength', qParams.pulseLength, 'cycleLength', cycleLength, 'passThru', params.(IQkey).passThru);

% load in random Clifford sequences from text file
fid = fopen('RBsequences.txt');
if ~fid
    error('Could not open Clifford sequence list')
end

tline = fgetl(fid);
lnum = 1;
while ischar(tline)
    seqStrings{lnum} = textscan(tline, '%s');
    lnum = lnum + 1;
    tline = fgetl(fid);
end
fclose(fid);

% convert sequence strings into pulses
pulseLibrary = containers.Map();
for ii = 1:length(seqStrings)
    for jj = 1:length(seqStrings{ii}{1})
        pulseName = seqStrings{ii}{1}{jj};
        if ~isKey(pulseLibrary, pulseName)
            pulseLibrary(pulseName) = pg.pulse(pulseName);
        end
        currentSeq{jj} = pulseLibrary(pulseName);
    end
    patseq{ii} = currentSeq(1:jj);
end

calseq = {{pg.pulse('QId')},{pg.pulse('QId')},{pg.pulse('Xp')},{pg.pulse('Xp')}};

compileSequence12(basename, pg, patseq, calseq, 1, nbrRepeats, fixedPt, cycleLength, makePlot);

end