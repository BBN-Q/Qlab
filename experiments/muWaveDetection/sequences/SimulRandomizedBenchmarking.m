function SimulRandomizedBenchmarking(makePlot)

if ~exist('makePlot', 'var')
    makePlot = true;
end

basename = 'SimulRB';
fixedPt = 11000;
cycleLength = 14000;

% load config parameters from file
params = jsonlab.loadjson(getpref('qlab', 'pulseParamsBundleFile'));
measDelay = -64;

q1Params = params.q1;
IQkeyQ1 = 'TekAWG12';
pgQ1 = PatternGen('dPiAmp', q1Params.piAmp, 'dPiOn2Amp', q1Params.pi2Amp, 'dSigma', q1Params.sigma, 'dPulseType', q1Params.pulseType, 'dDelta', q1Params.delta, 'correctionT', params.(IQkeyQ1).T, 'dBuffer', q1Params.buffer, 'dPulseLength', q1Params.pulseLength, 'cycleLength', cycleLength, 'passThru', params.(IQkeyQ1).passThru);

q2Params = params.q2;
IQkeyQ2 = 'TekAWG34';
pgQ2 = PatternGen('dPiAmp', q2Params.piAmp, 'dPiOn2Amp', q2Params.pi2Amp, 'dSigma', q2Params.sigma, 'dPulseType', q2Params.pulseType, 'dDelta', q2Params.delta, 'correctionT', params.(IQkeyQ2).T, 'dBuffer', q2Params.buffer, 'dPulseLength', q2Params.pulseLength, 'cycleLength', cycleLength, 'passThru', params.(IQkeyQ2).passThru);

q3Params = params.q3; 
IQkeyQ3 = 'BBNAPS12';
pgQ3 = PatternGen('dPiAmp', q3Params.piAmp, 'dPiOn2Amp', q3Params.pi2Amp, 'dSigma', q3Params.sigma, 'dPulseType', q3Params.pulseType, 'dDelta', q3Params.delta, 'correctionT', params.(IQkeyQ3).T, 'dBuffer', q3Params.buffer, 'dPulseLength', q3Params.pulseLength, 'cycleLength', cycleLength, 'passThru', params.(IQkeyQ3).passThru);

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

% load second sequence
fid = fopen('RBsequences2.txt');
if ~fid
    error('Could not open Clifford sequence list')
end

tline = fgetl(fid);
lnum = 1;
while ischar(tline)
    seqStrings2{lnum} = textscan(tline, '%s');
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
            pulseLibrary(pulseName) = pgQ1.pulse(pulseName);
        end
        currentSeq{jj} = pulseLibrary(pulseName);
    end
    patseqQ1{ii} = currentSeq(1:jj);
end
clear seqStrings

% convert sequence strings into pulses
pulseLibrary2 = containers.Map();
for ii = 1:length(seqStrings2)
    for jj = 1:length(seqStrings2{ii}{1})
        pulseName = seqStrings2{ii}{1}{jj};
        if ~isKey(pulseLibrary2, pulseName)
            pulseLibrary2(pulseName) = pgQ2.pulse(pulseName);
        end
        currentSeq{jj} = pulseLibrary2(pulseName);
    end
    patseqQ2{ii} = currentSeq(1:jj);
end
clear seqStrings2

if length(patseqQ1) ~= length(patseqQ2)
    error('Number of random sequences does not match')
end

% insert basic tomography into each random pair
%TomoPulsesQ1 = {{pulseLibrary('QId')},{pulseLibrary('Xp')},{pulseLibrary('QId')},{pulseLibrary('Xp')}};
%TomoPulsesQ2 = {{pulseLibrary2('QId')},{pulseLibrary2('QId')},{pulseLibrary2('Xp')},{pulseLibrary2('Xp')}};
TomoPulsesQ1 = { {}, {pulseLibrary('Xp')},  {pulseLibrary('QId')},  {pulseLibrary('Xp')}};
TomoPulsesQ2 = { {}, {pulseLibrary2('QId')}, {pulseLibrary2('Xp')}, {pulseLibrary2('Xp')}};

origPatseqQ1 = patseqQ1;
origPatseqQ2 = patseqQ2;
for ii = 1:length(origPatseqQ1)
    for jj = 1:length(TomoPulsesQ1)
        patseqQ1{ii+(jj-1)*length(origPatseqQ1)} = [origPatseqQ1{ii}, TomoPulsesQ1{jj}];
        patseqQ2{ii+(jj-1)*length(origPatseqQ2)} = [origPatseqQ2{ii}, TomoPulsesQ2{jj}];
    end
end

nbrPatterns = length(patseqQ1);
nbrRepeats = 2; % only used for cal sequences
calseqQ1 = {{pgQ1.pulse('QId')},{pgQ1.pulse('Xp')},{pgQ1.pulse('QId')},{pgQ1.pulse('Xp')}};
calseqQ2 = {{pgQ2.pulse('QId')},{pgQ2.pulse('QId')},{pgQ2.pulse('Xp')},{pgQ2.pulse('Xp')}};

% allocate space for a quarter of the sequences
nbrSets = 2;
segments = nbrPatterns/nbrSets;
fprintf('Number of segments in each set: %d\n', segments + nbrRepeats*length(calseqQ1));
ch1 = zeros(segments, cycleLength);
ch2 = ch1;
ch3 = ch1;
ch4 = ch1;
ch2m1 = ch1; ch2m2 = ch1;
ch3m1 = ch1; ch3m2 = ch1;
ch4m1 = ch1; ch4m2 = ch1;

disp ('Constructing first set');

for n = 1:segments;
    [patx paty] = pgQ1.getPatternSeq(patseqQ1{n}, 1, params.(IQkeyQ1).delay, fixedPt);
	ch1(n, :) = patx + params.(IQkeyQ1).offset;
	ch2(n, :) = paty + params.(IQkeyQ1).offset;
    ch3m1(n, :) = pgQ1.bufferPulse(patx, paty, 0, params.(IQkeyQ1).bufferPadding, params.(IQkeyQ1).bufferReset, params.(IQkeyQ1).bufferDelay);
    
    [patx paty] = pgQ2.getPatternSeq(patseqQ2{n}, 1, params.(IQkeyQ2).delay, fixedPt);
	ch3(n, :) = patx + params.(IQkeyQ2).offset;
	ch4(n, :) = paty + params.(IQkeyQ2).offset;
    ch4m1(n, :) = pgQ2.bufferPulse(patx, paty, 0, params.(IQkeyQ2).bufferPadding, params.(IQkeyQ2).bufferReset, params.(IQkeyQ2).bufferDelay);
end

% add calibration experiments
for n = 1:nbrRepeats*length(calseqQ1);
    [patx paty] = pgQ1.getPatternSeq(calseqQ1{floor((n-1)/nbrRepeats)+1}, 1, params.(IQkeyQ1).delay, fixedPt);
	ch1(segments + n, :) = patx + params.(IQkeyQ1).offset;
	ch2(segments + n, :) = paty + params.(IQkeyQ1).offset;
    ch3m1(segments + n, :) = pgQ1.bufferPulse(patx, paty, 0, params.(IQkeyQ1).bufferPadding, params.(IQkeyQ1).bufferReset, params.(IQkeyQ1).bufferDelay);
    
    [patx paty] = pgQ2.getPatternSeq(calseqQ2{floor((n-1)/nbrRepeats)+1}, 1, params.(IQkeyQ2).delay, fixedPt);
	ch3(segments + n, :) = patx + params.(IQkeyQ2).offset;
	ch4(segments + n, :) = paty + params.(IQkeyQ2).offset;
    ch4m1(segments + n, :) = pgQ2.bufferPulse(patx, paty, 0, params.(IQkeyQ2).bufferPadding, params.(IQkeyQ2).bufferReset, params.(IQkeyQ2).bufferDelay);
end

% trigger at fixedPt-500
% measure from (fixedPt:fixedPt+measLength)
measLength = 3000;
measSeq = {pgQ1.pulse('M', 'width', measLength)};
ch1m1 = repmat(pgQ1.makePattern([], fixedPt-500, ones(100,1), cycleLength), 1, segments + nbrRepeats*length(calseqQ1))';
ch1m2 = repmat(int32(pgQ1.getPatternSeq(measSeq, 1, measDelay, fixedPt+measLength)), 1, segments + nbrRepeats*length(calseqQ1))';
%ch4m2 = repmat(pgQ1.makePattern([], 5, ones(100,1), cycleLength), 1, segments + nbrRepeats*length(calseqQ1))';
%ch2m2 = ch4m2;

if makePlot
    myn = 25;
    figure
    plot(ch1(myn,:))
    hold on
    plot(ch2(myn,:), 'r')
    plot(ch3(myn,:), 'b--')
    plot(ch4(myn,:), 'r--')
    plot(5000*ch1m2(myn,:), 'g')
    plot(3000*ch3m1(myn,:), 'r:')
    plot(3000*ch4m1(myn,:), 'b:')
    grid on
    hold off
    
    figure; subplot(2,2,1); imagesc(ch1);
    subplot(2,2,2); imagesc(ch2);
    subplot(2,2,3); imagesc(ch3);
    subplot(2,2,4); imagesc(ch4);
end

% make first TekAWG file
options = struct('m21_high', 2.0, 'm41_high', 2.0);
TekPattern.exportTekSequence(tempdir, [basename '_1'], ch1, ch1m1, ch1m2, ch2, ch2m1, ch2m2, ch3, ch3m1, ch3m2, ch4, ch4m1, ch4m2, options);
disp('Moving AWG file to destination');
movefile([tempdir basename '_1.awg'], [pathAWG basename '_1.awg']);

disp ('Constructing second set');

for n = 1:segments;
    [patx paty] = pgQ1.getPatternSeq(patseqQ1{n+segments}, 1, params.(IQkeyQ1).delay, fixedPt);
	ch1(n, :) = patx + params.(IQkeyQ1).offset;
	ch2(n, :) = paty + params.(IQkeyQ1).offset;
    ch3m1(n, :) = pgQ1.bufferPulse(patx, paty, 0, params.(IQkeyQ1).bufferPadding, params.(IQkeyQ1).bufferReset, params.(IQkeyQ1).bufferDelay);
    
    [patx paty] = pgQ2.getPatternSeq(patseqQ2{n+segments}, 1, params.(IQkeyQ2).delay, fixedPt);
	ch3(n, :) = patx + params.(IQkeyQ2).offset;
	ch4(n, :) = paty + params.(IQkeyQ2).offset;
    ch4m1(n, :) = pgQ2.bufferPulse(patx, paty, 0, params.(IQkeyQ2).bufferPadding, params.(IQkeyQ2).bufferReset, params.(IQkeyQ2).bufferDelay);
end

if makePlot
    figure; subplot(2,2,1); imagesc(ch1);
    subplot(2,2,2); imagesc(ch2);
    subplot(2,2,3); imagesc(ch3);
    subplot(2,2,4); imagesc(ch4);
end

% make second TekAWG file
options = struct('m21_high', 2.0, 'm41_high', 2.0);
TekPattern.exportTekSequence(tempdir, [basename '_2'], ch1, ch1m1, ch1m2, ch2, ch2m1, ch2m2, ch3, ch3m1, ch3m2, ch4, ch4m1, ch4m2, options);
disp('Moving AWG file to destination');
movefile([tempdir basename '_2.awg'], [pathAWG basename '_2.awg']);

end