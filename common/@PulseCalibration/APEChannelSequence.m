function [filename, segmentPoints] = APEChannelSequence(obj, qubit, deltas, makePlot)

if ~exist('makePlot', 'var')
    makePlot = false;
end

[thisPath, ~] = fileparts(mfilename('fullpath'));
scriptName = fullfile(thisPath, 'APE.py');
[status, result] = system(sprintf('python "%s" "%s" %s --deltas %f', scriptName, getpref('qlab', 'PyQLabDir'), qubit, deltas), '-echo');

numPsId = 8;
segmentPoints = 1:numPsId*(1 + length(deltas));

filename = obj.getAWGFileNames('APE');

end