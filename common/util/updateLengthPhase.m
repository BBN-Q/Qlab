function status = updateLengthPhase(qubit, length, phase)
    [thisPath, ~] = fileparts(mfilename('fullpath'));
    scriptName = fullfile(thisPath, 'updateLengthPhaseParams.py');
	[status, ~] = system(sprintf('python "%s" "%s" %s %.9f %.4f', scriptName, getpref('qlab', 'PyQLabDir'), qubit, length, phase));
end