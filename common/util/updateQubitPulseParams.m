function status = updateQubitPulseParams(qubit, params)
    [thisPath, ~] = fileparts(mfilename('fullpath'));
    scriptName = fullfile(thisPath, 'updateQubitPulseParams.py');
	[status, ~] = system(sprintf('python "%s" "%s" %s %.4f %.4f %.4f', scriptName, getpref('qlab', 'PyQLabDir'), qubit, params.piAmp, params.pi2Amp, params.dragScaling));
end