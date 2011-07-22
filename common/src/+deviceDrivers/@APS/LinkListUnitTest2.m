function LinkListUnitTest2
    % load a sequence on the APS and measure it with the Acqiris card
    
    %addpath('../../','-END');
    addpath('util/','-END');
    
    % get acqiris setings
    % build library path
    script_path = mfilename('fullpath');
    schString = [filesep '@APS'];
    idx = strfind(script_path,schString);
    script_path = [script_path(1:idx) '@APS' filesep];
    cfg_name = [script_path 'unit_test.cfg'];
    if exist(cfg_name, 'file')
        settings = parseParamFile(cfg_name);
    else
        settings = struct();
    end
    
    apsId = 0;
    aps = deviceDrivers.APS();
    aps.open(apsId, aps.FORCE_OPEN);
    
    if (~aps.is_open)
    	error('Could not open aps')
    end

    aps.verbose = 1;

    %% Load Bit File
    ver = aps.readBitFileVersion();
    fprintf('Found Bit File Version: 0x%s\n', dec2hex(ver));
    if ver ~= aps.expected_bit_file_ver
        aps.loadBitFile();
        ver = aps.readBitFileVersion();
        fprintf('Found Bit File Version: 0x%s\n', dec2hex(ver));
    end
    
    % Pause APS if left running at end of last test
    aps.pauseFpga(0);
    aps.pauseFpga(2);

    aps.verbose = 0;
    
    useVarients = 1;
    validate = 0;
    
    %% Get Link List Sequence and Convert To APS Format
    sequence = aps.LinkListSequences(1);
    [wf1, banks1] = aps.convertLinkListFormat(sequence{1}.llpatx,useVarients);
    %[wf2, banks2] = aps.convertLinkListFormat(sequence.llpaty,useVarients);
    
    % erase any existing link list memory
    aps.clearLinkListELL(0);
    aps.clearLinkListELL(1);
    %aps.clearLinkListELL(2);
    %aps.clearLinkListELL(3);
    
    % fill channel 0 waveform memory
    aps.setFrequency(0, wf1.sample_rate);
    aps.loadWaveform(0, wf1.data, wf1.offset);
    
    % copy same LL into channel 1 for test
    aps.setFrequency(1, wf1.sample_rate);
    aps.loadWaveform(1, wf1.data, wf1.offset);
    
    aps.verbose = 1;
    
    fprintf('Sequence has %d bank(s)\n', length(banks1));
    for i = 1:length(banks1)
        cb = banks1{i};

        %cb.offset(end) = bitxor(cb.offset(end), aps.ELL_FIRST_ENTRY);

        % fill bank A
        aps.loadLinkListELL(0,cb.offset,cb.count, cb.trigger, cb.repeat, cb.length, 0, validate)
        % fill bank B
        aps.loadLinkListELL(0,cb.offset,cb.count, cb.trigger, cb.repeat, cb.length, 1, validate)
        aps.setLinkListRepeat(0,100);
        aps.setLinkListMode(0,aps.LL_ENABLE,aps.LL_CONTINUOUS);
        
        % same for channel 1 for test
        % fill bank A
        aps.loadLinkListELL(1,cb.offset,cb.count, cb.trigger, cb.repeat, cb.length, 0, validate)
        % fill bank B
        aps.loadLinkListELL(1,cb.offset,cb.count, cb.trigger, cb.repeat, cb.length, 1, validate)
        aps.setLinkListRepeat(1,100);
        aps.setLinkListMode(1,aps.LL_ENABLE,aps.LL_CONTINUOUS);
    end
    
    % get scope ready to measure
    scope = deviceDrivers.AgilentAP120();
    scope.setAll(settings.scope);
    scope.acquire();
    pause(0.5);
    %aps.triggerFpga(0,aps.TRIGGER_HARDWARE);
    aps.triggerWaveform(0,aps.TRIGGER_HARDWARE);
    %aps.triggerWaveform(1,aps.TRIGGER_HARDWARE);
    success = scope.wait_for_acquisition(10);
    if success ~= 0
        error('failed to acquire waveform')
    end
    
    % download data and display it
    [Amp_I timesI] = scope.transfer_waveform(1);
    %[Amp_Q timesQ] = scope.transfer_waveform(2);
    figure(1);
    %foo = subplot(2,1,1);
    imagesc(Amp_I');
    xlabel('Time');
    ylabel('Segment');
    set(gca, 'YDir', 'normal');
    title('Ch 1 (I)');
    
    aps.disableFpga(0);
    aps.close();
    scope.disconnect();
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

    