function TriggerSequenceAPS()

pathAPS = 'U:\APS\Trigger\';
basename = 'Trigger';

fixedPt = 6000;
cycleLength = 10000;

% load config parameters from file

pg = PatternGen('linkList', true);

patseq = {pg.pulse('QId')};

IQseq = pg.build(patseq, 1, 0, fixedPt, false);


% make APS file
exportAPSConfig(tempdir, basename, IQseq, IQseq);
disp('Moving APS file to destination');
movefile([tempdir basename '.h5'], [pathAPS basename '.h5']);
end
