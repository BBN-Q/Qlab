function [metainfo, segmentPoints] = Pi2CalChannelSequence(obj, qubit, direction, numPulses, makePlot)

if ~exist('direction', 'var')
    direction = 'X';
elseif ~strcmp(direction, 'X') && ~strcmp(direction, 'Y')
    warning('Unknown direction, assuming X');
    direction = 'X';
end
if ~exist('makePlot', 'var')
    makePlot = false;
end

[thisPath, ~] = fileparts(mfilename('fullpath'));
scriptName = fullfile(thisPath, 'Pi2Cal.py');
[status, result] = system(sprintf('python "%s" %s %s %d %f', scriptName, qubit, direction, numPulses, obj.channelParams.pi2Amp), '-echo');

nbrRepeats = 2;
segmentPoints = 1:nbrRepeats*(1+2*numPulses);

metainfo = obj.getMetaInfo('Pi2Cal');

end
