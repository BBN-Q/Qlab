function RBSequence(qubit_t, qubit_c, CR)

[thisPath, ~] = fileparts(mfilename('fullpath'));
scriptName = fullfile(thisPath, 'RB2QSequence.py');
[status, result] = system(sprintf('python "%s" "%s" %s %s %s', scriptName, getpref('qlab', 'PyQLabDir'), qubit_t, qubit_c, CR), '-echo');

end
