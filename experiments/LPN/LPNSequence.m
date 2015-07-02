function LPNSequence(ndataq, seqtype, seqkey, ancilla, data1, data2, data3, data4, CR1, CR2, CR3)

[thisPath, ~] = fileparts(mfilename('fullpath'));
scriptName = fullfile(thisPath, 'LPNSequence.py');
[status, result] = system(sprintf('python "%s" "%s" %d %s %s %s %s %s %s %s %s %s %s', scriptName, getpref('qlab', 'PyQLabDir'), ndataq, seqtype, seqkey, ancilla, data1, data2, data3, data4, CR1, CR2, CR3), '-echo');

end
