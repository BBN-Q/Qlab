function LinkListUnitTest(sequence)

% APS Enhanced Link List Unit Test
%
% Gets Pattern Generator and produces link lists from pattern generator
% Downloads resulting waveform library and banks into APS memory
% Last Tested: Not yet tested

% Uses PatternGen Link List Generator to develop link lists

% Open APS Device

% work around for not knowing full name
% of class - can not use simply APS when in
% experiment framework
classname = mfilename('class');

if isempty(classname)
    standalone = true;
else
    standalone = false;
end

import deviceDrivers.APS
% tests channel 0 & 1 output for basic bit file testing
if standalone
    addpath('../','-END');
else
    %addpath('../../common/src/','-END');
    %addpath('../../common/src/util/','-END');
    
end
aps = APS();

apsId = 0;
aps.connect(apsId);

% initialize
forceProgram = 0;
aps.init(forceProgram);

% Stop APS if left running at end of last test
aps.stop();

% Get Link List Sequence and Convert To APS Format
if ~exist('sequence', 'var') || isempty(sequence)
    sequence = 1;
end

% load waveform for trigger
wf2 = [ones([1,100]) zeros([1,3000])];
aps.loadWaveform(3, wf2);
aps.loadWaveform(4, wf2);


% get sequences to load
% sequence is user selected by passing as paramater
sequence1 = APS.LinkListSequences(sequence);

% TODO, allow C loading of things like:
%APSPattern.exportAPSconfig('./', 'LinkListUnitTest', sequence1{1}.llpatxy);
% Instead, we'll use the four channel version
APSPattern.exportAPSConfig('./', 'LinkListUnitTest', sequence1{1}.llpatxy, sequence1{1}.llpatxy);

aps.loadConfig('./LinkListUnitTest.h5');
aps.triggerSource = 'internal';
aps.run();
    
keyboard

aps.stop();
aps.disconnect();

end
