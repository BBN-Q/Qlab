function [filename, segmentPoints] = PulsePhaseEstimate2q(obj, control, target, numPulses, amplitude)

[thisPath, ~] = fileparts(mfilename('fullpath'));
scriptName = fullfile(thisPath, 'PhaseEstimationSequence2q.py');
[status, result] = system(sprintf('python "%s" "%s" %s %s %d %f', scriptName, getpref('qlab', 'PyQLabDir'), control, target, numPulses, amplitude), '-echo');

segmentPoints = -1:0.25:numPulses+0.75;

filename = obj.getAWGFileNames('RepeatCal');

end

