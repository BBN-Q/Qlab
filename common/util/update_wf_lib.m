function update_wf_lib(seqPath, seqName)

[thisPath, ~] = fileparts(mfilename('fullpath'));
scriptName = fullfile(thisPath, 'update_wf_lib.py');
[status, result] = system(sprintf('python "%s" "%s" %s %s', scriptName, getpref('qlab', 'PyQLabDir'), seqPath, seqName), '-echo');

end
