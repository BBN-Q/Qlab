function [filename, segmentPoints] = rabiAmpChannelSequence(obj, qubit, makePlot)

if ~exist('makePlot', 'var')
    makePlot = false;
end

[status, result] = system(sprintf('python RabiAmp.py "%s" %s', getpref('qlab', 'PyQLabDir'), qubit));

numsteps = 40; %should be even
stepsize = 1/numsteps;
amps = [-1:stepsize:-stepsize stepsize:stepsize:1];
segmentPoints = [amps amps];

filename = obj.getAWGFileNames('Rabi');

end
