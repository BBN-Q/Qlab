function status = updateAmpPhase(physChan, ampFactor, phaseSkew)
    [thisPath, ~] = fileparts(mfilename('fullpath'));
    scriptName = fullfile(thisPath, 'updateAmpPhase.py');
	[status, ~] = system(sprintf('python "%s" "%s" %s %.4f %.2f', scriptName, getpref('qlab', 'PyQLabDir'), physChan, ampFactor, phaseSkew));
end