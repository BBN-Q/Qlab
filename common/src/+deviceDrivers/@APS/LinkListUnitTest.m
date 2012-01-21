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
singleBankTest = 0;
hardCodeSeq = 1;

% get sequences to load
% sequences - user selected by passing as paramater
% sequences1 hard coded echo sequence
% sequences2 hard coded URamsey sequence
if standalone
    sequences = LinkListSequences(sequence);
    sequences1 = LinkListSequences(1);
    sequences2 = LinkListSequences(4);
else
    %sequences = deviceDrivers.APS.LinkListSequences(sequence);
    sequences1 = deviceDrivers.APS.LinkListSequences(sequence);
    %sequences2 = deviceDrivers.APS.LinkListSequences(sequence);
end

% group sequences together and then merge waveform library
% so that both sequences may be programmed into link list without
% changing the memory
%unifySecs = sequences1;
%for i = 1:length(sequences2)
%    unifySecs{end+1} = sequences2{i};
%end

% merge sequence
%[unifiedX unifiedY] = aps.unifySequenceLibraryWaveforms(unifySecs);
% build the library
%unifiedX = aps.buildWaveformLibrary(unifiedX, useVarients);

miniLinkRepeat = 1000; %10

for seq = 1:length(sequences1)
    
    if ~hardCodeSeq
        sequence = sequences1{seq};
        [wf, banks] = aps.convertLinkListFormat(sequence.llpatx,useVarients,miniLinkRepeat);
        banks1 = banks;
        banks2 = banks;
        wf2 = wf;
    else
        sequence1 = sequences1{seq};
        %sequence2 = sequences2{seq};
        %[wf, banks1] = aps.convertLinkListFormat(sequence1.llpatx,useVarients,unifiedX,miniLinkRepeat);
        %[wf2, banks2] = aps.convertLinkListFormat(sequence2.llpatx,useVarients,unifiedX,miniLinkRepeat);
        wfLib = aps.buildWaveformLibrary(sequence1.llpatx, useVarients);
        [wf, banks1] = aps.convertLinkListFormat(sequence1.llpatx,useVarients,wfLib,miniLinkRepeat);
        wf2 = wf;
        banks2 = banks1;
    end
    drawnow
    
    % erase any existing link list memory
    aps.clearLinkListELL(0);
    aps.clearLinkListELL(1);
    
    %aps.setFrequency(0,wf.sample_rate, 0);
    aps.loadWaveform(0, wf.data, wf.offset);
    
    %aps.setFrequency(1,wf2.sample_rate, 0);
    aps.loadWaveform(1, wf2.data, wf2.offset);
        
    if singleBankTest
        
        for i = 1:length(banks1)
            cb = banks1{i};
            
            %cb.offset(end) = bitxor(cb.offset(end), aps.ELL_FIRST_ENTRY);
            
            aps.loadLinkListELL(0,cb.offset,cb.count, cb.trigger, cb.repeat, cb.length, 0, validate)
            aps.loadLinkListELL(0,cb.offset,cb.count, cb.trigger, cb.repeat, cb.length, 1, validate)
            %aps.setLinkListRepeat(0,10000);
            aps.setLinkListRepeat(0,1);
            aps.setLinkListMode(0,aps.LL_ENABLE,aps.LL_CONTINUOUS);
            aps.triggerWaveform(0,aps.TRIGGER_HARDWARE);
            keyboard
            aps.disableFpga(0)
        end
    else
        setTrigger = 0;
        for repeatTest = 1:1
            curBank = 0;
            altBank = [1 0];
            cb1 = banks1{1};
            cb2 = banks2{1};
            linkList16 = convertGUIFormat(wf, cb1, cb2);
            %keyboard
            % fill bank A and bank B on channel 0
            aps.loadLinkListELL(0,cb1.offset,cb1.count, cb1.trigger, cb1.repeat, cb1.length, 0, validate)
            aps.loadLinkListELL(0,cb2.offset,cb2.count, cb2.trigger, cb2.repeat, cb2.length, 1, validate)
            
            % fill bank A only on channel 1
            %aps.loadLinkListELL(1,cb1.offset,cb1.count, cb1.trigger, cb1.repeat, cb1.length, 0, validate)
            %aps.loadLinkListELL(1,cb2.offset,cb2.count, cb2.trigger, cb2.repeat, cb2.length, 0, validate)
            
            curBank = 0;
            
            if ~setTrigger
                aps.setLinkListRepeat(0,1);
                aps.setLinkListMode(0,aps.LL_ENABLE,aps.LL_CONTINUOUS);
                
                
                %aps.setLinkListRepeat(1,1);
                %aps.setLinkListMode(1,aps.LL_ENABLE,aps.LL_CONTINUOUS);
                
                aps.triggerWaveform(0,aps.TRIGGER_HARDWARE);
                %aps.triggerWaveform(1,aps.TRIGGER_HARDWARE);
                %keyboard
                %aps.triggerFpga(0,aps.TRIGGER_HARDWARE);
                
                aps.triggerWaveform(3,aps.TRIGGER_SOFTWARE);
                setTrigger = 1;
            end
            
            keyboard
            
            for i = 1:10
                fprintf('Entry %i/%i curBank = %i\n', i, length(banks1), curBank );
                val = curBank;
                while val == curBank
                    val = aps.readLinkListStatus(0);
                    fprintf('Link List Status = %i nextBank = %i\n',val, altBank(val+1));
                    pause(.1)
                end
                fprintf('Link List Status = %i nextBank = %i\n',val, altBank(val+1));
                aps.loadLinkListELL(0,cb1.offset,cb1.count, cb1.trigger, cb1.repeat, cb1.length, altBank(val+1), validate)

                checkVal = aps.readLinkListStatus(0);
                if checkVal ~= curBank
                    fprintf('Error: Bank switched during bank update\n');
                end
                curBank = val;
            end
            pause(1)
        end
    end
end

aps.pauseFpga(0);
aps.pauseFpga(2);
aps.close()

end
