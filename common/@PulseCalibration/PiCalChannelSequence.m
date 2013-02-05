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
    'piAmp', obj.pulseParams.piAmp);

patseq = cell(19,1);
patseq{1} = {pg.pulse('QId')};

% +X/Y rotations
pulse90p = pg.pulse([direction '90p']);
pulse180p   = pg.pulse([direction 'p']);
patseq(2:10) =  arrayfun(@(x) [{pulse90p}, repmat({pulse180p}, 1, x)], [0:8], 'UniformOutput', false);

% -X/Y rotations
pulse90m = pg.pulse([direction '90m']);
pulse180m   = pg.pulse([direction 'm']);
patseq(11:19) =  arrayfun(@(x) [{pulse90m}, repmat({pulse180m}, 1, x)], [0:8], 'UniformOutput', false);

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
