function TwirlSequence(seq)

[thisPath, ~] = fileparts(mfilename('fullpath'));
scriptName = fullfile(thisPath, 'TwirlSequence.py');
[status, result] = system(sprintf('python "%s" "%s" "%s" %d', scriptName, getpref('qlab', 'PyQLabDir'), 'C:\Users\qlab\Documents\Julia\Twirl', seq), '-echo');

end
