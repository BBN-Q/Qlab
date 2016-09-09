function status = updateQubitFreq(qubit, frequency)
	%frequency: SSB in Hz
    [thisPath, ~] = fileparts(mfilename('fullpath'));
    scriptName = fullfile(thisPath, 'updateQubitFreq.py');
	[status, ~] = system(sprintf('python "%s" "%s" %s %.6f', scriptName, getpref('qlab', 'PyQLabDir'), qubit, frequency));
end