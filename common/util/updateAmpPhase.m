function status = updateAmpPhase(physChan, ampFactor, phaseSkew)
	[status, ~] = system(sprintf('python updateAmpPhase.py "%s" %s %f %f', getpref('qlab', 'PyQLabDir'), physChan, ampFactor, phaseSkew));
end