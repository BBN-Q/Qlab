function status = updateAmpPhase(physChan, ampFactor, phaseSkew)
    [thisPath, ~] = fileparts(mfilename('fullpath'));
    scriptName = fullfile(thisPath, 'updateAmpPhase.py');
	[status, ~] = system(sprintf('python "%s" "%s" %s %f %f', scriptName, getpref('qlab', 'PyQLabDir'), physChan, ampFactor, phaseSkew));
end