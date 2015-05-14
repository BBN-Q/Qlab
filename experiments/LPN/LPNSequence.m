function LPNSequence(seqtype, seqkey, ancilla, data1, data2, data3, CR1, CR2, CR3)

[thisPath, ~] = fileparts(mfilename('fullpath'));
scriptName = fullfile(thisPath, 'LPNSequence.py');
[status, result] = system(sprintf('python "%s" "%s" %s %s %s %s %s %s %s %s %s', scriptName, getpref('qlab', 'PyQLabDir'), seqtype, seqkey, ancilla, data1, data2, data3, CR1, CR2, CR3), '-echo');

end
