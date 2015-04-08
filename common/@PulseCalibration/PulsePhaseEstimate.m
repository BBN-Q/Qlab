function [filename, segmentPoints] = PulsePhaseEstimate(obj, qubit, direction, numPulses, amplitude)

[thisPath, ~] = fileparts(mfilename('fullpath'));
scriptName = fullfile(thisPath, 'PulsePhaseEstimate.py');
[status, result] = system(sprintf('python "%s" "%s" %s %s %d %f', scriptName, getpref('qlab', 'PyQLabDir'), qubit, direction, numPulses, amplitude), '-echo');

nbrRepeats = 2;
segmentPoints = 1:2*nbrRepeats*(numPulses+2);

filename = obj.getAWGFileNames('RepeatCal');

end

