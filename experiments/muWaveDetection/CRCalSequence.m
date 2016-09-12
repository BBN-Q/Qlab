function [filename, segmentPoints] = CRCalSequence(control, target, caltype, length, varargin)
if ~isempty(varargin)
    amplitude = varargin{1};
else
    amplitude = 0.8;
end
[thisPath, ~] = fileparts(mfilename('fullpath'));
scriptName = fullfile(thisPath, 'CRCal.py');
[status, result] = system(sprintf('python "%s" "%s" %s %s %f %f %f', scriptName, getpref('qlab', 'PyQLabDir'), control, target, caltype, length, amplitude), '-echo');

end
