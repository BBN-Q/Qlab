function [metainfo, segmentPoints] = rabiAmpChannelSequence(obj, qubit, makePlot)

if ~exist('makePlot', 'var')
    makePlot = false;
end

[thisPath, ~] = fileparts(mfilename('fullpath'));
scriptName = fullfile(thisPath, 'RabiAmp.py');
[status, result] = system(sprintf('python "%s" "%s" %s', scriptName, qubit), '-echo');

numsteps = 40; %should be even
stepsize = 2/numsteps;
amps = [-1:stepsize:-stepsize stepsize:stepsize:1];
segmentPoints = [amps amps];

metainfo = obj.getMetaInfo('Rabi');

end
