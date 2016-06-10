function UpdateWfLib(seqPath, seqName)

[thisPath, ~] = fileparts(mfilename('fullpath'));
scriptName = fullfile(thisPath, 'UpdateWfLib.py');
[status, result] = system(sprintf('python "%s" "%s" %s %s', scriptName, getpref('qlab', 'PyQLabDir'), seqPath, seqName), '-echo');

end
