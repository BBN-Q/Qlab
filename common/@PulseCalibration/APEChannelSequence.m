function [filename, segmentPoints] = APEChannelSequence(obj, qubit, deltas, makePlot)

if ~exist('makePlot', 'var')
    makePlot = false;
end

[thisPath, ~] = fileparts(mfilename('fullpath'));
scriptName = fullfile(thisPath, 'APE.py');
[status, result] = system(sprintf('python "%s" "%s" --deltas %s', scriptName, qubit, sprintf('%f ', deltas)), '-echo');

numPsId = 8;
segmentPoints = 1:(1+numPsId)*length(deltas)+1;

filename = obj.getAWGFileNames('APE');

end
