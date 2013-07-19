function [filename, segmentPoints] = PiCalChannelSequence(obj, qubit, direction, numPulses, makePlot)

if ~exist('direction', 'var')
    direction = 'X';
elseif ~strcmp(direction, 'X') && ~strcmp(direction, 'Y')
    warning('Unknown direction, assuming X');
    direction = 'X';
end
if ~exist('makePlot', 'var')
    makePlot = false;
end

[status, result] = system(sprintf('python "%s" %s %s %d %f', getpref('qlab', 'PyQLabDir'), qubit, direction, numPulses, obj.channelParams.pi2Amp));

nbrRepeats = 2;
segmentPoints = 1:nbrRepeats*(1+2*numPulses);

filename = obj.getAWGFileNames('PiCal');

end
