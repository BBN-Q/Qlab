function [filename, segmentPoints] = RamseyChannelSequence(obj, qubit, RamseyStop, nSteps)


[thisPath, ~] = fileparts(mfilename('fullpath'));
scriptName = fullfile(thisPath, 'RamseySequence.py');
[status, result] = system(sprintf('python "%s" %s %f %d', scriptName, qubit, RamseyStop*1e-9, nSteps), '-echo');


RamseyStep = RamseyStop/(nSteps-1);
segmentPoints = 0:RamseyStep:RamseyStop;

filename = obj.getAWGFileNames('Ramsey');

end
