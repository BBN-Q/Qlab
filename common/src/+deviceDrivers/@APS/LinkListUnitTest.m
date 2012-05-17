function LinkListUnitTest(sequence, dc_offset)

%% APS Enhanced Link List Unit Test
%%
%% Gets Pattern Generator and produces link lists from pattern generator
%% Downloads resulting waveform library and banks into APS memory
%% Test Status
%% Last Tested: Not yet tested
%% $Rev$
%%

% Uses PatternGen Link List Generator to develop link lists

forceProgram = 0;

%% Open APS Device

% work around for not knowing full name
% of class - can not use simply APS when in
% experiment framework
classname = mfilename('class');

if isempty(classname)
    standalone = true;
else
    standalone = false;
end

% tests channel 0 & 1 output for basic bit file testing
if standalone
    aps = APS();
    addpath('../','-END');
else
    addpath('../../common/src/','-END');
    addpath('../../common/src/util/','-END');
    aps = eval(sprintf('%s();', classname));
end

% utility function for writing out bank memory to a mat file for
% use with the GUI
    function linkList16 = convertGUIFormat(wf,bankA,bankB)
        linkList16.bankA.offset = bankA.offset;
        linkList16.bankA.count  = bankA.count;
        linkList16.bankA.trigger= bankA.trigger;
        linkList16.bankA.repeat = bankA.repeat;
        linkList16.bankA.length = length(linkList16.bankA.offset);
        
        if exist('bankB','var')
            linkList16.bankB.offset = bankB.offset;
            linkList16.bankB.count  = bankB.count;
            linkList16.bankB.trigger= bankB.trigger;
            linkList16.bankB.repeat = bankB.repeat;
            linkList16.bankB.length = length(linkList16.bankB.offset);
        end
        linkList16.repeatCount = 10;
        linkList16.waveformLibrary = wf.data;
    end

apsId = 0;
aps.open(apsId, aps.FORCE_OPEN);
aps.verbose = 0;

% initialize
aps.init(forceProgram);

% Stop APS if left running at end of last test
aps.stop();

%% Get Link List Sequency and Convert To APS Format
% this is currently ignored
if ~exist('sequence', 'var') || isempty(sequence)
    sequence = 1;
end

if ~exist('dc_offset', 'var') || isempty(dc_offset)
    dc_offset = 0;
end

% load waveform for trigger
wf2 = APSWaveform();
wf2.data = [ones([1,100]) zeros([1,3000])];

if (aps.setFrequency(3,100) ~= 0)
    keyboard
end
aps.loadWaveform(3,wf2.get_vector(),0);

%%

useVarients = 0; %1
validate = 0;
hardCodeSeq = 1;

% get sequences to load
% sequences - user selected by passing as paramater
% sequences1 hard coded echo sequence
% sequences2 hard coded URamsey sequence
if standalone
    sequence1 = LinkListSequences(1);
    sequence2 = LinkListSequences(4);
else
    sequence1 = deviceDrivers.APS.LinkListSequences(1);
    sequence2 = deviceDrivers.APS.LinkListSequences(4);
end

miniLinkRepeat = 1000; %10

[xWfLib, yWfLib] = APSPattern.buildWaveformLibrary(sequence1{1}.llpatxy, useVarients);
[wf, xbanks] = APSPattern.convertLinkListFormat(sequence1{1}.llpatxy, useVarients, xWfLib, miniLinkRepeat);
[wf2, ybanks] = APSPattern.convertLinkListFormat(sequence1{1}.llpatxy, useVarients, yWfLib, miniLinkRepeat);

banks1 = xbanks;
banks2 = ybanks;

drawnow

% erase any existing link list memory
aps.clearLinkListELL(0);
aps.clearLinkListELL(1);

%aps.setFrequency(0,wf.sample_rate, 0);
aps.loadWaveform(0, wf.data, wf.offset);

%aps.setFrequency(1,wf2.sample_rate, 0);
aps.loadWaveform(1, wf2.data, wf2.offset);


setTrigger = 0;

altBank = [1 0];
cb1 = banks1{1};
cb2 = banks2{1};

%linkList16 = convertGUIFormat(wf, cb1, cb2);

% fill bank A and bank B on channel 0
aps.loadLinkListELL(0,cb1.offset,cb1.count, cb1.trigger, cb1.repeat, cb1.length, 0, validate)
aps.loadLinkListELL(0,cb2.offset,cb2.count, cb2.trigger, cb2.repeat, cb2.length, 1, validate)



curBank = 0;


aps.setLinkListRepeat(0,5);
aps.setLinkListMode(0,aps.LL_ENABLE,aps.LL_CONTINUOUS);
aps.setFrequency(0,300);
    
    
aps.triggerWaveform(0,aps.TRIGGER_SOFTWARE);

    
keyboard

for i = 1:10000
    fprintf('Entry %i/%i curBank = %i\n', i, length(banks1), curBank );
    val = curBank;
    while val == curBank
        val = aps.readLinkListStatus(0);
        fprintf('Link List Status = %i nextBank = %i\n',val, altBank(val+1));
        pause(.5)
    end
    curBank = val;
    fprintf('Link List Status = %i nextBank = %i\n',val, altBank(val+1));
    aps.loadLinkListELL(0,cb1.offset,cb1.count, cb1.trigger, cb1.repeat, cb1.length, altBank(val+1), validate)
    
    checkVal = aps.readLinkListStatus(0);
    if checkVal ~= curBank
        fprintf('Error: Bank switched during bank update\n');
    end
end
pause(1)




aps.pauseFpga(0);
aps.pauseFpga(2);
aps.close()

end
