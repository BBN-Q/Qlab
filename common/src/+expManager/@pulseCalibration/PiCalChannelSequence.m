function [filename, nbrPatterns] = PiCalChannelSequence(obj, qubit, direction, makePlot)

if ~exist('direction', 'var')
    direction = 'X';
elseif ~strcmp(direction, 'X') && ~strcmp(direction, 'Y')
    warning('Unknown direction, assuming X');
    direction = 'X';
end
if ~exist('makePlot', 'var')
    makePlot = false;
end

basename = 'PiCal';

fixedPt = 6000;
cycleLength = 9000;

pg = PatternGen(qubit,...
    'pi2Amp', obj.pulseParams.pi2Amp,...
    'piAmp', obj.pulseParams.piAmp,...
    'SSBFreq', obj.pulseParams.SSBFreq,...
    'cycleLength', cycleLength);

patseq{1} = {pg.pulse('QId')};

% +X/Y rotations
X90p = pg.pulse([direction '90p']);
Xp   = pg.pulse([direction 'p']);
patseq{2}={X90p};
patseq{3}={X90p, Xp};
patseq{4}={X90p, Xp, Xp};
patseq{5}={X90p, Xp, Xp, Xp};
patseq{6}={X90p, Xp, Xp, Xp, Xp};
patseq{7}={X90p, Xp, Xp, Xp, Xp, Xp};
patseq{8}={X90p, Xp, Xp, Xp, Xp, Xp, Xp};
patseq{9}={X90p, Xp, Xp, Xp, Xp, Xp, Xp, Xp};
patseq{10}={X90p, Xp, Xp, Xp, Xp, Xp, Xp, Xp, Xp};

% -X/Y rotations
X90m = pg.pulse([direction '90m']);
Xm   = pg.pulse([direction 'm']);
patseq{11}={X90m};
patseq{12}={X90m, Xm};
patseq{13}={X90m, Xm, Xm};
patseq{14}={X90m, Xm, Xm, Xm};
patseq{15}={X90m, Xm, Xm, Xm, Xm};
patseq{16}={X90m, Xm, Xm, Xm, Xm, Xm};
patseq{17}={X90m, Xm, Xm, Xm, Xm, Xm, Xm};
patseq{18}={X90m, Xm, Xm, Xm, Xm, Xm, Xm, Xm};
patseq{19}={X90m, Xm, Xm, Xm, Xm, Xm, Xm, Xm, Xm};

nbrRepeats = 2;
nbrPatterns = nbrRepeats*length(patseq);
numsteps = 1;

calseq = [];

% prepare parameter structures for the pulse compiler
seqParams = struct(...
    'basename', basename, ...
    'suffix', '', ...
    'numSteps', numsteps, ...
    'nbrRepeats', nbrRepeats, ...
    'fixedPt', fixedPt, ...
    'cycleLength', cycleLength, ...
    'measLength', 2000);
patternDict = containers.Map();
if ~isempty(calseq), calseq = {calseq}; end

qubitMap = obj.channelMap.(qubit);
IQkey = qubitMap.IQkey;

patternDict(IQkey) = struct('pg', pg, 'patseq', {patseq}, 'calseq', calseq, 'channelMap', qubitMap);
measChannels = {'M1'};
awgs = cellfun(@(x) x.InstrName, obj.awgParams, 'UniformOutput',false);

compileSequences(seqParams, patternDict, measChannels, awgs, makePlot);

filename = obj.getAWGFileNames(basename);

end
