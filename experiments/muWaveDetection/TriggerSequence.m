% clear all;
% clear classes;
% clear import;
addpath('../../common/src','-END');
addpath('../../common/src/util/','-END');

path = 'U:\AWG\Trigger\';
%path = '';
basename = 'Trigger';
delay = 0;
fixedPt = 2000;
cycleLength = 3500;
offset = 8192;
pg = PatternGen;
numsteps = 1;

ch1 = zeros(numsteps, cycleLength);
ch1(:,:) = offset;
ch2 = ch1;

ch1m1 = zeros(numsteps, cycleLength);
for n = 1:numsteps;
	ch1m1(n,:) = pg.makePattern(ones(100,1), 200, [], cycleLength);
end
ch1m2 = zeros(numsteps, cycleLength);

% fill remaining channels with empty stuff
ch3 = zeros(numsteps, cycleLength) + offset;
ch2m1 = zeros(numsteps, cycleLength);
ch2m2 = zeros(numsteps, cycleLength);

% make TekAWG file
TekPattern.exportTekSequence(path, basename, ch1, ch1m1, ch1m2, ch2, ch2m1, ch2m2, ch3, ch2m1, ch2m2, ch3, ch2m1, ch2m2);
