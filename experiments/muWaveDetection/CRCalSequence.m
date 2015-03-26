function [filename, segmentPoints] = CRCalSequence(control, target, CR, caltype, length)

[thisPath, ~] = fileparts(mfilename('fullpath'));
scriptName = fullfile(thisPath, 'CRCal.py');
[status, result] = system(sprintf('python "%s" "%s" %s %s %s %d %d', scriptName, getpref('qlab', 'PyQLabDir'), control, target, CR, caltype, length), '-echo');

end
