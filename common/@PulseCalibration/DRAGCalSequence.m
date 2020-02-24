function [metainfo, segmentPoints] = DRAGCalSequence(obj, qubit, deltas, nums_pulses)

if ~exist('makePlot', 'var')
    makePlot = false;
end

[thisPath, ~] = fileparts(mfilename('fullpath'));
scriptName = fullfile(thisPath, 'DRAGCal.py');
[status, result] = system(sprintf('python "%s" "%s" --deltas %s --nums_pulses %s', scriptName, qubit, sprintf('%f ', deltas), sprintf('%d ', nums_pulses)), '-echo');

segmentPoints = 1:length(nums_pulses)*length(deltas)+4;

metainfo = obj.getMetaInfo('DRAGCal');

end
