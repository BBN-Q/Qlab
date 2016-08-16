function [filename, segmentPoints] = PulsePhaseEstimate(obj, qubit, direction, numPulses, amplitude)

[thisPath, ~] = fileparts(mfilename('fullpath'));
scriptName = fullfile(thisPath, 'PhaseEstimationSequence.py');
[status, result] = system(sprintf('python "%s" %s %s %d %f', scriptName, qubit, direction, numPulses, amplitude), '-echo');

segmentPoints = -1:0.25:numPulses+0.75;

filename = obj.getAWGFileNames('RepeatCal');

end
