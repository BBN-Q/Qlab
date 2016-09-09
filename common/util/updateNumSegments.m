function status = updateNumSegments(nbrSegments)
    [thisPath, ~] = fileparts(mfilename('fullpath'));
    scriptName = fullfile(thisPath, 'updateNumSegments.py');
	[status, ~] = system(sprintf('python "%s" "%s" %d', scriptName, getpref('qlab', 'PyQLabDir'), nbrSegments));
end