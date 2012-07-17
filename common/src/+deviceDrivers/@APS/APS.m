%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Module Name : APS.m
%
% Author/Date : B.C. Donovan / 21-Oct-08
%
% Description : APS object for QLab Experiment Framework
%
%               Wraps libaps for access to APS unit.
%
% Restrictions/Limitations :
%
%   Requires libaps.dll and libaps.h
%
% Change Descriptions :
%
% Classification : Unclassified
%
% References :
%
%
%    Modified    By    Reason
%    --------    --    ------
%                BCD
%    10/5/2011   BRJ   Making compatible with expManager init sequence
%    30 Mar. 2012 CAR  HDF5 File Version. 
%
% $Author: bdonovan $
% $Date$
% $Locker:  $
% $Name:  $
% $Revision$

% Copyright (C) BBN Technologies Corp. 2008-2011
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

classdef APS < hgsetget
    properties
        library_path;
        library_name = 'libaps';
        device_id = 0;

        bit_file_path = '';
        expected_bit_file_ver = hex2dec('10');
        verbose = 0;
        
        num_channels = 4;
        chan_1;
        chan_2;
        chan_3;
        chan_4;
        channelStrs = {'chan_1', 'chan_2', 'chan_3', 'chan_4'};
        
        samplingRate = 1200;   % Global sampling rate in units of MHz (1200, 600, 300, 100, 40)
        triggerSource
    end
    properties %(Access = 'private')
        is_open = 0;
        bit_file_version = 0;
    end
    
    properties (Constant)
        ADDRESS_UNIT = 4;
        MAX_WAVEFORM_VALUE = 8191;        
        MAX_WAVFORM_LENGTH = 8192;
        MAX_LL_LENGTH = 512;

        % run modes
        RUN_SEQUENCE = 1;
        RUN_WAVEFORM = 0;

        % repeat modes
        CONTINUOUS = 0;
        ONESHOT = 1;
        
        FORCE_OPEN = 1; % not supported, drop??
        
        % for DEBUG methods
        LEDMODE_PLLSYNC = 1;
        LEDMODE_RUNNING = 2;
        TRIGGER_SOFTWARE = 1;
        TRIGGER_HARDWARE = 2;
        ALL_DACS = -1;
        
        DAC2_SERIALS = {'A6UQZB7Z','A6001nBU','A6001ixV', 'A6001nBT'};

    end
    
    methods
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Public Methods
        
        function obj = APS()
            % APS constructor
            
            % load DLL
            curPath = fileparts(mfilename('fullpath'));
            obj.library_path = [curPath filesep '..\..\..\..\hardware\APS\libaps-cpp\'];
            obj.load_library();
            
            % build path for bitfiles
            script_path = mfilename('fullpath');
            extended_path = '\APS';
            baseIdx = strfind(script_path,extended_path);
            
            obj.bit_file_path = script_path(1:baseIdx);
            
            % init channel structs and waveform objects
            channelStruct = @()(struct('amplitude', 1.0, 'offset', 0.0, 'enabled', false, 'trigDelay', 0, 'waveform', [], 'banks', []));
            for ct = 1:4
                obj.(obj.channelStrs{ct}) = channelStruct();
            end
        end
        
        function delete(obj)
            % APS Destructor
            if obj.is_open()
                obj.disconnect();
            end
        end
        
        function connect(obj,address)
            % address = device ID (number) or serial number (string)
            
            if isnumeric(address)
                val = obj.open(address);
            else
                val = obj.openBySerialNum(address);
            end
            
        end
        
        function disconnect(obj)
            try
                val = calllib(obj.library_name, 'disconnect_by_ID', obj.device_id);
            catch
                val = 0;
            end
            if (val == 0)
                fprintf('APS USB Connection Closed\n');
            else
                fprintf('Error closing APS USB Connection: %i\n', val);
            end
            obj.is_open = 0;
        end
        
        function setAll(obj,settings)
            % setAll sets up the APS with the parameters in the settings
            % struct
            obj.init();

            % set amplitude and offset before loading waveform data so that we
 			% only have to load it once.
			obj.librarycall('Clearing waveform cache', 'APS_ClearAllWaveforms');
            for ct = 1:4
                ch = obj.channelStrs{ct};
				obj.setAmplitude(ct, settings.(ch).amplitude);
				obj.setOffset(ct, settings.(ch).offset);
                obj.setEnabled(ct, settings.(ch).enabled);
            end
            settings = rmfield(settings, obj.channelStrs);
            
			% load AWG file before doing anything else
			if isfield(settings, 'seqfile')
				if ~isfield(settings, 'seqforce')
					settings.seqforce = false;
                end
                if ~isfield(settings, 'lastseqfile')
                    settings.lastseqfile = '';
                end
				
				% load an AWG file if the settings file is changed or if force == true
				if (~strcmp(settings.lastseqfile, settings.seqfile) || settings.seqforce)
					obj.loadConfig(settings.seqfile);
				end
			end
			settings = rmfield(settings, {'lastseqfile', 'seqfile', 'seqforce'});
			
            % parse remaining settings
			fields = fieldnames(settings);
			for j = 1:length(fields);
				name = fields{j};
                if ismember(name, methods(obj))
                    feval(['obj.' name], settings.(name));
                elseif ismember(name, properties(obj))
                    obj.(name) = settings.(name);
                end
            end
        end
        
        function init(obj, force, filename)
            % bare minimum commands to make the APS usable
            % if force = true, always load bit file        
            if ~exist('force', 'var')
                force = false;
            end

            if ~exist('filename','var')
                filename = [obj.bit_file_path obj.defaultBitFileName];
            end
            
            obj.librarycall('initAPS', [filename 0], force);
        end
        
        function loadWaveform(obj, ch, waveform)
            % id - channel (1-4)
            % waveform - int16 format waveform data (-8192, 8191) or float
            % data in the range (-1.0, 1.0)

            switch(class(waveform))
                case 'int16'
                    obj.librarycall('set_waveform_int', ch-1, waveform, length(waveform));
                case 'double'
                    obj.librarycall('set_waveform_float', ch-1, waveform, length(waveform));
                otherwise
                    error('Unhandled waveform data type');
            end
            obj.setEnabled(ch, 1);
        end
        
        function loadConfig(aps, filename)
            % loads a complete, 4 channel configuration file
            
            %Check the file version number
            assert(h5readatt(filename, '/', 'Version') == 1.6, 'Oops! This code expects version APS HDF5 version 1.6.')

            % clear channel data
            aps.librarycall('clear_channel_data');
            
            %See which channels are defined in this file
            channelDataFor = h5readatt(filename, '/', 'channelDataFor');
            
            %Now, the obvious thing to do is have one loop for the
            %channels, and load the waveform and then the LL for each
            %channel.  Unfortunately, it appears that there is an adverse
            %interaction between loadWaveform and loadLLData so they have
            %do be done for each channel separately! 
            for ch = 1:aps.num_channels
                if any(ch == channelDataFor)
                    channelStr = aps.channelStrs{ch};
                    
                    %Load and scale/shift waveform data if there is any
                    wfInfo = h5info(filename, ['/', channelStr, '/waveformLib']);
                    if wfInfo.Dataspace.Size > 0
                        aps.loadWaveform(ch, h5read(filename,['/', channelStr, '/waveformLib']));
                    end
                    
                end
            end
            
            %Redo the loop for loading the link lists. 
            for ch = 1:aps.num_channels
                if any(ch == channelDataFor)
                    channelStr = aps.channelStrs{ch};
                    %Load LL data if it exists
                    if(h5readatt(filename, ['/', channelStr], 'isLinkListData') == 1)
                        %Create the linkList structure from the hdf5file
                        for bankct = 1:h5readatt(filename, ['/', channelStr, '/linkListData'], 'numBanks')
                            bankStr = sprintf('bank%d',bankct);
                            bankGroupStr = ['/' , channelStr, '/linkListData/', bankStr];

                            count = h5read(filename, [bankGroupStr, '/count']);
                            offset = h5read(filename, [bankGroupStr, '/offset']);
                            repeat = h5read(filename, [bankGroupStr, '/repeat']);
                            trigger = h5read(filename, [bankGroupStr, '/trigger']);
                            length = h5readatt(filename, bankGroupStr, 'length');
                            aps.addLinkList(ch, offset, count, repeat, trigger, length);
                        end
                        repeatCount = h5readatt(filename, ['/', channelStr, '/linkListData'], 'repeatCount');
                        
                        aps.setLinkListRepeat(ch, repeatCount);
                        aps.set_run_mode(ch, aps.LL_ENABLE);
                    end
                end
            end
        end
        
        function run(aps)
            % global run method
            aps.librarycall('run');
        end
        
        function stop(aps)
            % global stop method
            aps.librarycall('stop');
        end
        
        function isr = isRunning(aps)
            isr = false;
            if aps.is_open
                val = aps.librarycall('get_running');
                if val > 0
                    isr = true;
                end
            end
        end
        
        function out = waitForAWGtoStartRunning(aps)
            % for compatibility with Tek driver
            % checks the state of the CSR to verify that a state machine
            % is running
            if ~aps.isRunning()
                aps.run();
            end
            out = true;
        end
        
        function aps = set.samplingRate(aps, rate)
            % sets the sampling rate for all channels/FPGAs
            % rate - sampling rate in MHz (1200, 600, 300, 100, 40)
            aps.librarycall('set_samplingRate',rate);
            aps.samplingRate = rate;
        end
        
        function rate = get.samplingRate(aps)
            % polls APS hardware to get current PLL Sample Rate
            % valid rates in MHz (1200, 600, 300, 100, 40)
            rate = aps.librarycall('get_samplingRate');
        end
        
        function aps = set.triggerSource(aps, trig)
            % sets internal or external trigger
            checkMap = containers.Map({...
	            'internal','external','int', 'ext'},...
                {aps.TRIGGER_SOFTWARE,aps.TRIGGER_HARDWARE,aps.TRIGGER_SOFTWARE,aps.TRIGGER_HARDWARE});
            
            trig = lower(trig);
            if not(checkMap.isKey(trig))
                error(['APS: Unrecognized trigger source value: ', trig]);
            else
                aps.librarycall('set_trigger_source', checkMap(trig));
                aps.triggerSource = trig;
            end
        end
        
        function val = setOffset(aps, ch, offset)
            % sets offset voltage of channel 
            val = aps.librarycall('set_channel_offset', ch-1, offset);
            aps.(['chan_' num2str(ch)]).offset = offset;
        end

		function val = setAmplitude(aps, ch, amplitude)
			% sets the scale factor of the channel
			val = aps.librarycall('set_channel_scale', ch-1, amplitude);
			aps.(['chan_' num2str(ch)]).amplitude = amplitude;
        end
        
        function val = setEnabled(aps, ch, enabled)
            % enables or disables a channel
            val = aps.librarycall('set_channel_enabled', ch-1, enabled);
            aps.(['chan_' num2str(ch)]).enabled = enabled;
        end

		function val = setTriggerDelay(aps, ch, delay)
            % sets delay of channel marker output WRT the analog output in
            % 4 sample increments (i.e. delay = 3 is a 12 sample delay)
            val = aps.librarycall('set_channel_trigDelay', ch-1, delay);
            aps.(['chan_' num2str(ch)]).trigDelay = delay;
        end
        
        function delay = getTriggerDelay(aps, ch)
            delay = aps.librarycall('get_channel_trigDelay',ch-1);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Private methods
        %
        % These methods are subject to change and should not be used by
        % external code.
        
        function load_library(obj)
            
            if strcmp(computer,'PCWIN64')
                libfname = 'libaps64.dll';
                obj.library_name = 'libaps64';
            elseif (ispc())
                libfname = 'libaps.dll';
            elseif (ismac())
                libfname = 'libaps.dylib';
            else
                libfname = 'libaps.so';
            end
            
            % build library path
            if ~libisloaded(obj.library_name)
                loadlibrary([obj.library_path libfname], [obj.library_path 'libaps.h']);
                calllib(obj.library_name, 'init');
            end
        end
        
        function val = librarycall(aps,func,varargin)
            % calls DLL methods with logging
            if ~(aps.is_open)
                warning('APS:librarycall','APS is not open');
                val = -1;
                return
            end
                        
            if size(varargin,2) == 0
                val = calllib(aps.library_name, func, aps.device_id);
            else
                val = calllib(aps.library_name, func, aps.device_id, varargin{:});
            end
        end
        
        function num_devices = enumerate(aps)
            %TODO
            % Return the number of devices and their serial numbers
            aps.num_devices = calllib(aps.library_name,'APS_NumDevices');
            num_devices = aps.num_devices;

            %Reset cell array
            aps.deviceSerials = cell(num_devices,1);
            %For each device load the serial number
            for ct = 1:num_devices
                [success, deviceSerial] = calllib(aps.library_name, 'APS_GetSerialNum',ct-1, blanks(64), 64);
                if success == 0
                    aps.deviceSerials{ct} = deviceSerial;
                else
                    error('Unable to get serial number');
                end
            end
        end
                
        function val = open(aps, id)
            % open by device ID
            if (aps.is_open)
                if (aps.device_id ~= id)
                    aps.disconnect();
                else
                    val = 0;
                    return;
                end
            end
            aps.device_id = id;
            
            %TODO
            % populate list of device id's and serials
%             aps.enumerate();
%             if id + 1 > aps.num_devices
%                 error('Device id %i not found.', id);
%             end
            val = calllib(aps.library_name, 'connect_by_ID', aps.device_id);
            if (val == 0)
                aps.is_open = 1;
            else
                error('Unable to open APS device.');
            end
        end
        
        function val = openBySerialNum(aps,serial)
            %TODO
%           % open by device ID
%             if (aps.is_open)
%                 if (aps.deviceSe ~= id)
%                     aps.disconnect();
%                     aps.device_id = id;
%                 else
%                     val = 0;
%                     return;
%                 end
%             end
%             
%             %TODO
%             % populate list of device id's and serials
% %             aps.enumerate();
% %             if id + 1 > aps.num_devices
% %                 error('Device id %i not found.', id);
% %             end
%             
%             val = aps.librarycall('open_by_serialNum',aps.device_id);
%             if (val == 0)
%                 aps.is_open = 1;
%             else
%                 error('Unable to open APS device.');
%             end
        end
        
%         function val = readBitFileVersion(aps)
%             val = aps.librarycall('APS_ReadBitFileVersion', aps.device_id);
%             aps.bit_file_version = val;
%             if val >= aps.ELL_VERSION
%                 aps.max_waveform_points = aps.ELL_MAX_WAVFORM;
%                 aps.max_ll_length = aps.ELL_MAX_LL;
%             end
%         end
        
        function fname = defaultBitFileName(obj)
            %TODO
            % current device's serial number is at index device_id + 1 in
            % deviceSerials cell array
%             if ismember(obj.deviceSerials{obj.device_id+1}, obj.DAC2_SERIALS)
%                 fname = 'mqco_dac2_latest.bit';
%             else
                fname = 'mqco_aps_latest.bit';
%             end
        end
        
        %% Private Waveform/Link list methods
        function addLinkList(aps,ch,offsets,counts, repeat, trigger, length)
            val = aps.librarycall('add_LL_bank',ch-1, length, offsets,counts,repeat,trigger);
            if (val < 0)
                error('addLinkList returned an error code of: %i\n', val);
            end
        end
        
        
        %% Private Triggering/Stopping methods
        function triggerFPGA_debug(aps, fpga)
            aps.librarycall('trigger_FPGA_debug',fpga);
        end
        
        function disableFPGA_debug(aps, fpga)
            aps.librarycall('disable_FPGA_debug', fpga);
        end
        
        function val = setRunMode(aps, ch, mode)
            % id : DAC channel (1-4)
            % mode : 1 = sequence, 0 = waveform
            val = aps.librarycall('set_run_mode',ch-1, mode);
        end
        
        function val = setRepeatMode(aps, ch, mode)
            % id : DAC channel (1-4)
            % mode : 1 = one-shot, 0 = continous
            val = aps.librarycall('set_repeat_mode', ch-1, mode);
        end
        
        %% Private mode methods
        function val = setLinkListRepeat(aps,ch, repeat)
            % TODO
%             val = aps.librarycall(sprintf('Dac: %i Link List Repeat: %i', ch-1, repeat), ...
%                 'APS_SetLinkListRepeat',repeat,ch-1);
        end
        
        function val = testPllSync(aps, ch, numRetries)
            % TODO
%             if ~exist('ch','var')
%                 ch = 1;
%             end
%             if ~exist('numRetries', 'var')
%                 numRetries = 10;
%             end
%             val = aps.librarycall(sprintf('Test Pll Sync: DAC: %i',ch), ...
%                 'APS_TestPllSync',ch, numRetries);
%             if val ~= 0
%                 fprintf('Warning: APS::testPllSync returned %i\n', val);
%             end
        end
        
        %% low-level setup and debug methods
        function readAllRegisters(aps, fpga)
            % TODO
%             val = aps.librarycall(sprintf('Read Registers'), ...
%                 'APS_ReadAllRegisters', fpga);
        end

        function val = readStatusCtrl(aps)
            % TODO
            %val = aps.librarycall('Read status/ctrl', 'APS_ReadStatusCtrl');
        end
        
        function regWriteTest(aps, addr)
            % TODO
%             val = aps.librarycall('Register write test', ...
%                 'APS_RegWriteTest', addr);
        end
        
        function setDebugLevel(aps, level)
            % sets logging level in libaps.log
            % level = {logERROR=0, logWARNING, logINFO, logDEBUG, logDEBUG1, logDEBUG2, logDEBUG3, logDEBUG4}
            calllib(aps.library_name, 'set_logging_level', level);
        end

    end
    methods(Static)

        
        % UnitTest of Link List Format Conversion
        % See: LinkListFormatUnitTest.m
        LinkListFormatUnitTest(sequence,useEndPadding)
        
        LinkListUnitTest(sequence, dc_offset)
        LinkListUnitTest2
        LinkListUnitTestC
                
        sequence = LinkListSequences(sequence)
        
        function aps = UnitTest(forceLoad)
            % work around for not knowing full name
            % of class - cannot use simply APS when in 
            % experiment framework
            if ~exist('forceLoad', 'var')
                forceLoad = 0;
            end
            classname = mfilename('class');
            
            % tests channel 0 & 1 output for basic bit file testing
            aps = eval(sprintf('%s();', classname));
            aps.verbose = 1;
            apsId = 0;
            
            fprintf('Openning Device: %i\n', apsId);
            aps.connect(apsId);
            
            if (~aps.is_open)
                error('Could not open aps')
            end

            % quieter debug info at this point
            aps.setDebugLevel(4);
            aps.init(forceLoad);
            %aps.setDebugLevel(3);

            wf = [zeros([1,2000]) 0.8*ones([1,2000])];
            
            for ch = 1:4
                aps.loadWaveform(ch, wf);
                aps.setRunMode(ch, aps.RUN_WAVEFORM);
            end

%             for ch = 1:4
%                 aps.setEnabled(ch, 1);
%             end
%             aps.loadConfig([aps.library_path filesep 'UnitTest.h5']);
            aps.triggerSource = 'external';
            aps.setDebugLevel(5);
            aps.run();
            keyboard
            aps.stop();
            aps.disconnect();
        end
    end
end
