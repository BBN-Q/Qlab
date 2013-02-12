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
    forceProgram = 0;
    aps = deviceDrivers.APS();
    aps.open(apsId, aps.FORCE_OPEN);
    
    if (~aps.is_open)
    	error('Could not open aps')
    end

    % initialize
    aps.verbose = 1;
    aps.init(forceProgram);
    aps.verbose = 0;

    % Stop APS if left running at end of last test
    aps.stop();
    
    useVarients = 1;
    validate = 0;
    miniLinkRepeat = 1;
    
    %% Get Link List Sequence and Convert To APS Format
    sequence = aps.LinkListSequences(1);
    wfLib = APSPattern.buildWaveformLibrary(sequence{1}.llpatxy, useVarients);
    [wf1, banks1] = APSPattern.convertLinkListFormat(sequence{1}.llpatxy,useVarients,wfLib,miniLinkRepeat);
    %[wf2, banks2] = APSPattern.convertLinkListFormat(sequence.llpaty,useVarients);
    
    % erase any existing link list memory
    aps.clearLinkListELL(0);
    aps.clearLinkListELL(1);
    %aps.clearLinkListELL(2);
    %aps.clearLinkListELL(3);
    
    % fill channel 0 waveform memory
    %aps.setFrequency(0, wf1.sample_rate);
    aps.loadWaveform(0, wf1.data);
    
    % copy same LL into channel 1 for test
    % aps.setFrequency(1, wf1.sample_rate);
    aps.loadWaveform(1, wf1.data);
    
    %aps.verbose = 1;
    
    fprintf('Sequence has %d bank(s)\n', length(banks1));
    for i = 1:length(banks1)
        cb = banks1{i};

        %cb.offset(end) = bitxor(cb.offset(end), aps.ELL_FIRST_ENTRY);

        % fill bank A
        aps.loadLinkListELL(0,cb.offset,cb.count, cb.trigger, cb.repeat, cb.length, 0, validate)
        % fill bank B
        aps.loadLinkListELL(0,cb.offset,cb.count, cb.trigger, cb.repeat, cb.length, 1, validate)
        aps.setLinkListRepeat(0,0);
        aps.setLinkListMode(0,aps.LL_ENABLE,aps.LL_CONTINUOUS);
        % same for channel 1 for test
        % fill bank A
        aps.loadLinkListELL(1,cb.offset,cb.count, cb.trigger, cb.repeat, cb.length, 0, validate)
        % fill bank B
        aps.loadLinkListELL(1,cb.offset,cb.count, cb.trigger, cb.repeat, cb.length, 1, validate)
        aps.setLinkListRepeat(1,0);
        aps.setLinkListMode(1,aps.LL_ENABLE,aps.LL_CONTINUOUS);
    end
    
    % get scope ready to measure
    scope = deviceDrivers.AgilentAP120();
    scope.setAll(settings.scope);
    scope.acquire();
    fprintf('Acquiring\n');
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
    [Amp_Q timesQ] = scope.transfer_waveform(2);
    figure(1);
    %foo = subplot(2,1,1);
    imagesc(Amp_I');
    xlabel('Time');
    ylabel('Segment');
    set(gca, 'YDir', 'normal');
    title('Ch 1 (I)');
    
    figure(2);
    imagesc(Amp_Q');
    xlabel('Time');
    ylabel('Segment');
    set(gca, 'YDir', 'normal');
    title('Ch 2 (Q)');
    
    aps.stop();
    aps.close();
    scope.disconnect();
end

    