function SPAMSequence(makePlot)

%Y90-(X180-Y180-X180-Y180)^n to determine phase difference between quadrature channels

if ~exist('makePlot', 'var')
    makePlot = true;
end
basename = 'SPAM';
fixedPt = 6000;
cycleLength = 10000;
nbrRepeats = 1;

% load config parameters from file
load(getpref('qlab','pulseParamsBundleFile'));
% if using SSB, uncomment the following line
% Ts('12') = eye(2);
IQkey = 'BBNAPS12';
pg = PatternGen('dPiAmp', piAmps('q1'), 'dPiOn2Amp', pi2Amps('q1'), 'dSigma', sigmas('q1'), 'dPulseType', pulseTypes('q1'), 'dDelta', deltas('q1'), 'correctionT', Ts('12'), 'dBuffer', buffers('q1'), 'dPulseLength', pulseLengths('q1'), 'cycleLength', cycleLength, 'passThru', passThrus(IQkey));

angleShift = -7*pi/180;
SPAMBlock = {pg.pulse('Xp'),pg.pulse('Up','angle',pi/2+angleShift),pg.pulse('Xp'),pg.pulse('Up','angle',pi/2+angleShift)};

patseq = {};

for SPAMct = 0:10
    patseq{end+1} = {pg.pulse('Y90p')};
    for ct = 0:SPAMct
        patseq{end} = [patseq{end}, SPAMBlock];
    end
    patseq{end} = [patseq{end}, {pg.pulse('X90m')}];
end

calseq = {};
calseq{end+1} = {pg.pulse('QId')};
calseq{end+1} = {pg.pulse('QId')};
calseq{end+1} = {pg.pulse('Xp')};
calseq{end+1} = {pg.pulse('Xp')};
    

compileSequenceBBNAPS12(basename, pg, patseq, calseq, 1, nbrRepeats, fixedPt, cycleLength, makePlot);
end