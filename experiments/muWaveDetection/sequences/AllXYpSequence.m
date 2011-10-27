function AllXYpSequence(makePlot)

if ~exist('makePlot', 'var')
    makePlot = true;
end
script = java.io.File(mfilename('fullpath'));
path = char(script.getParentFile().getParentFile().getParentFile().getParent());
addpath([path '/common/src'],'-END');
addpath([path '/common/src/util/'],'-END');

temppath = [char(script.getParent()) '\'];
path = 'U:\AWG\AllXY\';
basename = 'AllXYp';

fixedPt = 6000;
cycleLength = 10000;
numsteps = 50;

% load config parameters from file
parent_path = char(script.getParentFile.getParent());
cfg_path = [parent_path '/cfg/'];
load([cfg_path 'pulseParams.mat'], 'T', 'delay', 'measDelay', 'bufferDelay', 'bufferReset', 'bufferPadding', 'offset', 'piAmp', 'pi2Amp', 'sigma', 'pulseType', 'delta', 'buffer', 'pulseLength');

pg = PatternGen('dPiAmp', piAmp, 'dPiOn2Amp', pi2Amp, 'dSigma', sigma, 'dPulseType', pulseType, 'dDelta', delta, 'correctionT', T, 'dBuffer', buffer, 'dPulseLength', pulseLength, 'cycleLength', cycleLength);

% ground state:
% QId

% Xp Xp
% Yp Yp
% Xp Yp
% Yp Xp

patseq{1}={pg.pulse('QId')};

patseq{2}={pg.pulse('Xp'),pg.pulse('Xp')};
patseq{3}={pg.pulse('Yp'),pg.pulse('Yp')};

patseq{4}={pg.pulse('Xp'),pg.pulse('Yp')};
patseq{5}={pg.pulse('Yp'),pg.pulse('Xp')};

% superposition state:
% -1 * eps error
% X90p
% Y90p

% 0 * eps error (phase sensitive)
% X90p Y90p
% Y90p X90p

% +1 * eps error
% Xp Y90p
% Yp X90p
% X90p Yp (phase sensitive)
% Y90p Xp (phase sensitive)

% +3 * eps error
% Xp X90p
% Yp Y90p

patseq{6}={pg.pulse('X90p')};
patseq{7}={pg.pulse('Y90p')};

patseq{8}={pg.pulse('X90p'), pg.pulse('Y90p')};
patseq{9}={pg.pulse('Y90p'), pg.pulse('X90p')};


patseq{10}={pg.pulse('Xp'),pg.pulse('Y90p')};
patseq{11}={pg.pulse('Yp'),pg.pulse('X90p')};
patseq{12}={pg.pulse('X90p'),pg.pulse('Yp')};
patseq{13}={pg.pulse('Y90p'),pg.pulse('Xp')};


patseq{14}={pg.pulse('Xp'),pg.pulse('X90p')};
patseq{15}={pg.pulse('Yp'),pg.pulse('Y90p')};

% excited state;
% Xp
% Yp
% X90p X90p
% Y90p Y90p

patseq{16} = {pg.pulse('QId'),pg.pulse('Xp')};
patseq{17} = {pg.pulse('QId'),pg.pulse('Yp')};

patseq{18} = {pg.pulse('X90p'),pg.pulse('X90p')};
patseq{19} = {pg.pulse('Y90p'),pg.pulse('Y90p')};

%for iindex = 1:nbrPulses
%    for jindex = 1:nbrPulses
%        patseq{(iindex-1)*nbrPulses+jindex} = {AllPulses{iindex}, AllPulses{jindex}};
%    end
%end

% double every pulse
nbrPatterns = 2*length(patseq);
fprintf('Number of sequences: %i\n', nbrPatterns);
ch1 = zeros(nbrPatterns, cycleLength);
ch2 = ch1;
ch3m1 = ch1;

for kindex = 1:nbrPatterns;
	[patx paty] = pg.getPatternSeq(patseq{floor((kindex-1)/2)+1}, 1, delay, fixedPt);
	ch1(kindex, :) = patx + offset;
	ch2(kindex, :) = paty + offset;
    ch3m1(kindex, :) = pg.bufferPulse(patx, paty, 0, bufferPadding, bufferReset, bufferDelay);
end

% trigger at beginning of measurement pulse
% measure from (6000:9000)
measLength = 3000;
measSeq = {pg.pulse('M', 'width', measLength)};
ch1m1 = zeros(nbrPatterns, cycleLength);
ch1m2 = zeros(nbrPatterns, cycleLength);
for n = 1:nbrPatterns;
	ch1m1(n,:) = pg.makePattern([], fixedPt-500, ones(100,1), cycleLength);
	ch1m2(n,:) = int32(pg.getPatternSeq(measSeq, n, measDelay, fixedPt+measLength));
end

if makePlot
    myn = 20;
    figure
    plot(ch1(myn,:))
    hold on
    plot(ch2(myn,:), 'r')
    plot(5000*ch3m1(myn,:), 'k')
    plot(5000*ch1m1(myn,:),'.')
    plot(5000*ch1m2(myn,:), 'g')
    grid on
    hold off

    figure
    subplot(2,1,1)
    imagesc(ch1);
    subplot(2,1,2)
    imagesc(ch2);
end

% fill remaining channels with empty stuff
ch3 = zeros(nbrPatterns, cycleLength);
ch4 = zeros(nbrPatterns, cycleLength);
ch2m1 = ch3;
ch2m2 = ch4;
ch3 = ch3 + offset;
ch4 = ch4 + offset;

% make TekAWG file
TekPattern.exportTekSequence(temppath, basename, ch1, ch1m1, ch1m2, ch2, ch2m1, ch2m2, ch3, ch3m1, ch2m2, ch4, ch2m1, ch2m2);
disp('Moving AWG file to destination');
movefile([temppath basename '.awg'], [path basename '.awg']);
end

