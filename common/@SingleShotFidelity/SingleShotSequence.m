function SingleShotSequence(obj, qubit)

[thisPath, ~] = fileparts(mfilename('fullpath'));
scriptName = fullfile(thisPath, 'SingleShotSequence.py');
[status, result] = system(sprintf('python "%s" "%s" %s', scriptName, getpref('qlab', 'PyQLabDir'), qubit), '-echo');

end