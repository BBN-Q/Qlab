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

classdef APS < deviceDrivers.lib.deviceDriverBase
    properties
        library_path = './lib/';
        library_name = 'libaps';
        device_id = 0;
        num_devices;
        deviceSerials = {}; % cell array of serial numbers indexed by the (device_id+1)'s
        message_manager = [];
        bit_file_path = '';
        expected_bit_file_ver = hex2dec('10');
        Address = 0;
        verbose = 0;
        
        mock_aps = 0;

        % temporary boolean to enable use of c waveforms instead of
        % APSWaveform
        use_c_waveforms = false; 
        
        num_channels = 4;
        chan_1;
        chan_2;
        chan_3;
        chan_4;
        channelStrs = {'chan_1', 'chan_2', 'chan_3', 'chan_4'};
        
        samplingRate = 1200;   % Global sampling rate in units of MHz (1200, 600, 300, 100, 40)
        triggerSource = 'internal';  % Global trigger source ('internal', or 'external')
    end
    properties %(Access = 'private')
        is_open = 0;
        bit_file_programmed = 0;
        max_waveform_points = 8192;
        max_ll_length = 512;
        bit_file_version = 0;
        ELL_VERSION = hex2dec('10');
        
        % variables used to adjust link list padding
        pendingLength = 0;
        expectedLength = 0;
        currentLength = 0;

    end
    
    properties (Constant)
        ADDRESS_UNIT = 4;
        MIN_PAD_SIZE = 4;
        MIN_LL_ENTRY_COUNT = 3;
        MAX_WAVEFORM_VALUE = 8191;
        
        ELL_MAX_WAVFORM = 8192;
        ELL_MAX_LL = 512;
        ELL_MIN_COUNT = 3;
        
        %% ELL Linklist Masks and Contants
        ELL_ADDRESS            = hex2dec('07FF');
        ELL_TIME_AMPLITUDE     = hex2dec('8000');
        ELL_TIME_AMPLITUDE_BIT = 16;
        ELL_LL_TRIGGER         = hex2dec('8000');
        ELL_LL_TRIGGER_BIT     = 16;
        ELL_ZERO               = hex2dec('4000');
        ELL_ZERO_BIT           = 15;
        ELL_VALID_TRIGGER      = hex2dec('2000');
        ELL_VALID_TRIGGER_BIT  = 14;
        ELL_FIRST_ENTRY        = hex2dec('1000');
        ELL_FIRST_ENTRY_BIT    = 13;
        ELL_LAST_ENTRY         = hex2dec('800');
        ELL_LAST_ENTRY_BIT     = 12;
        ELL_TA_MAX             = hex2dec('FFFF');
        ELL_TRIGGER_DELAY      = hex2dec('3FFF');
        ELL_TRIGGER_MODE_SHIFT = 14;
        ELL_TRIGGER_DELAY_UNIT = 3.333e-9;
        ELL_NO_TRIGGER_BIT     = 16;
        
        LL_ENABLE = 1;
        LL_DISABLE = 0;
        LL_CONTINUOUS = 0;
        LL_ONESHOT = 1;
        LL_DC = 1;
        
        TRIGGER_SOFTWARE = 1;
        TRIGGER_HARDWARE = 2;
        
        LEDMODE_PLLSYNC = 1;
        LEDMODE_RUNNING = 2;
        
        ALL_DACS = -1;
        FORCE_OPEN = 1;
        
        FPGA0 = 0;
        FPGA1 = 2;
        
        DAC2_SERIALS = {'A6UQZB7Z','A6001nBU','A6001ixV', 'A6001nBT'};

    end
    
    methods
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Public Methods
        
        function d = APS()
            % APS constructor
            d = d@deviceDrivers.lib.deviceDriverBase('APS');
            d.load_library();
            
            buffer = libpointer('stringPtr','                            ');
            calllib(d.library_name,'APS_ReadLibraryVersion', buffer,length(buffer.Value));
            d.log(sprintf('Loaded %s', buffer.Value));
            
            % build path for bitfiles
            script_path = mfilename('fullpath');
            extended_path = '\APS';
            baseIdx = strfind(script_path,extended_path);
            
            d.bit_file_path = script_path(1:baseIdx);
            
            % init channel structs and waveform objects
            channelStruct = @()(struct('amplitude', 1.0, 'offset', 0.0, 'enabled', false));
            for ct = 1:4
                d.(d.channelStrs{ct}) = channelStruct();
                d.(d.channelStrs{ct}).waveform = APSWaveform();
            end
        end
        
        function delete(obj)
            % APS Destructor
            if obj.is_open()
                obj.close();
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
            obj.close()
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
        
        function init(obj, force)
            % bare minimum commands to make the APS usable
            % if force = true, always load bit file
            if ~exist('force', 'var')
                force = false;
            end
            
            % Determine if APS needs to be programmed
            bitFileVer = obj.readBitFileVersion();
            if ~isnumeric(bitFileVer) || bitFileVer ~= obj.expected_bit_file_ver || obj.readPllStatus() ~= 0 || force
                status = obj.loadBitFile();
                if status < 0
                    error('Failed to program FPGA');
                end

                % set all channels to 1.2 GS/s
                obj.setFrequency(0, 1200, 0);
                obj.setFrequency(2, 1200, 0);
                
                % reset status/CTRL in case setFrequency screwed things up
                obj.resetStatusCtrl();
                
                % test PLL sync on each FPGA
                status = obj.testPllSync(1) || obj.testPllSync(2);
                if status ~= 0
                    error('APS failed to initialize');
                end
                
                % align DAC data clock boundaries
                obj.setupDACs();

				% clear waveform caches
				obj.librarycall('Clearing waveform cache', 'APS_ClearAllWaveforms');
                
                % set all channel offsets to zero
                %for ch=1:4, obj.setOffset(ch, 0); end
                
				% update LED mode to show run state
                obj.setLEDMode(3, obj.LEDMODE_RUNNING);
            end
            
            obj.bit_file_programmed = 1;
        end
        
        function loadWaveform(aps, id, waveform, offset, validate, storeWaveform)
            % id - channel (1-4)
            % waveform - int16 format waveform data (-8192, 8191)
            % offset - waveform memory offset (think memory location, not
            %   shift of zero), integer multiple of 4
            % validate - bool, reads back waveform data
            % storeWaveform - bool, when true stores the waveform data in the driver
            %
            % Use of this method disables link list mode. If you intend to
            % use sequence mode, use loadConfig() instead.
            if aps.mock_aps
                aps.log('Mock load waveform')
                return 
            end
            
            if ~(aps.is_open)
                warning('APS:loadWaveForm','APS is not open');
                return
            end
            if isempty(waveform)
                error('APS:loadWaveform','Waveform is required');
                return
            end
            
            if ~exist('offset','var')
                offset = 0;
            end
            
            if ~exist('validate','var')
                validate = 0;
            end
            
            if ~exist('storeWaveform','var')
                storeWaveform = 1;
            end
            
            aps.log(sprintf('Loading Waveform length: %i into DAC%i ', length(waveform),id-1));
            val = calllib(aps.library_name,'APS_LoadWaveform', aps.device_id,waveform,length(waveform),offset, id-1, validate, storeWaveform);
            if (val < 0)
                errordlg(sprintf('APS_LoadWaveform returned an error code of: %i\n', val), ...
                    'Programming Error');
            end
            aps.log('Done');
            aps.setEnabled(id, 1);
        end
        
        function loadConfig(aps, filename)
            % loads a complete, 4 channel configuration file
            
            %Check the file version number
            assert(h5readatt(filename, '/', 'Version') == 1.6, 'Oops! This code expects version APS HDF5 version 1.6.')

            % clear old link list data
            aps.clearLinkListELL(0);
            aps.clearLinkListELL(1);
            aps.clearLinkListELL(2);
            aps.clearLinkListELL(3);
            
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
                        tmpLinkList = struct();
                        %Create the linkList structure from the hdf5file
                        for bankct = 1:h5readatt(filename, ['/', channelStr, '/linkListData'], 'numBanks')
                            bankStr = sprintf('bank%d',bankct);
                            bankGroupStr = ['/' , channelStr, '/linkListData/', bankStr];
                            tmpLinkList.(bankStr) = struct();
                            tmpLinkList.(bankStr).count = h5read(filename, [bankGroupStr, '/count']);
                            tmpLinkList.(bankStr).offset = h5read(filename, [bankGroupStr, '/offset']);
                            tmpLinkList.(bankStr).repeat = h5read(filename, [bankGroupStr, '/repeat']);
                            tmpLinkList.(bankStr).trigger = h5read(filename, [bankGroupStr, '/trigger']);
                            tmpLinkList.(bankStr).length = h5readatt(filename, bankGroupStr, 'length');
                        end
                        tmpLinkList.repeatCount = h5readatt(filename, ['/', channelStr, '/linkListData'], 'repeatCount');
                        
                        %Add the LL data to the wf
                        wf = aps.(channelStr).waveform;
                        wf.ellData = tmpLinkList;
                        wf.ell = true;
                        %Do some error checking
                        if wf.check_ell_format()
                            
                            wf.have_link_list = true;
                            ell = wf.get_ell_link_list();
                            
                            %For now we just directly load the first two
                            %banks into bankA and bankB
                            if isfield(ell,'bank1') && ell.bank1.length > 0
                                bankA = ell.bank1;
                                aps.loadLinkListELL(ch-1,bankA.offset,bankA.count, ...
                                    bankA.trigger, bankA.repeat, bankA.length, 0);
                            end
                            if isfield(ell,'bank2') && ~isempty(ell.bank2) && ell.bank2.length > 0
                                bankB = ell.bank2;
                                aps.loadLinkListELL(ch-1,bankB.offset,bankB.count, ...
                                    bankB.trigger, bankB.repeat, bankB.length, 1);
                            end
                            
                            %aps.setLinkListRepeat(ch,ell.repeatCount);
                            aps.setLinkListRepeat(ch,0);
                            aps.setLinkListMode(ch, aps.LL_ENABLE, aps.LL_CONTINUOUS);
                        end
                        % update channel waveform object
                        aps.(channelStr).waveform = wf;
                        
                    end
                end
            end
        end
        
        function run(aps)
            % global run method
            
            trigger_type = aps.TRIGGER_SOFTWARE;
            if strcmp(aps.triggerSource, 'external')
                trigger_type = aps.TRIGGER_HARDWARE;
            end
            
            aps.librarycall('Running', 'APS_Run', trigger_type);
        end
        
        function stop(aps)
            % global stop method
            aps.disableFpga(aps.ALL_DACS);
        end
        
        function isr = isRunning(aps)
            isr = false;
            if aps.is_open

                
                val = aps.librarycall('Checking if running', 'APS_IsRunning', 3);
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
            if aps.samplingRate ~= rate
                aps.setFrequency(0, rate, 0);
                aps.setFrequency(2, rate, 0);
                aps.testPllSync(1);
                aps.testPllSync(2);
            end
            aps.samplingRate = rate;
        end
        
        function [rate1] = get.samplingRate(aps)
            % polls APS hardware to get current PLL Sample Rate
            % valid rates in MHz (1200, 600, 300, 100, 40)
            rate1 = aps.getFrequency(0);
            rate2 = aps.getFrequency(2);
            if rate1 ~= rate2
                fprintf('Expected sampling rate to be the same for each DAC read [%i %i]\n', rate1, rate2)
            end
        end
        
        function aps = set.triggerSource(aps, trig)
            % sets internal or external trigger
            checkMap = containers.Map({...
	            'internal','external',...
                'int', 'ext'
	            },{'internal','external','internal','external'});
            
            trig = lower(trig);
            if not(checkMap.isKey(trig))
                error(['APS: Unrecognized trigger source value: ', trig]);
            else
                aps.triggerSource = checkMap(trig);
            end
        end
        
        function val = setOffset(aps, ch, offset)
            % sets offset voltage of channel for time/amplitude zero
            % entries
            val = aps.librarycall('Set channel offset','APS_SetChannelOffset', ch-1, offset);
            aps.(['chan_' num2str(ch)]).offset = offset;
        end

		function val = setAmplitude(aps, ch, amplitude)
			% sets the scale factor of the channel
			val = aps.librarycall('Set channel scale', 'APS_SetWaveformScale', ch-1, amplitude);
			aps.(['chan_' num2str(ch)]).amplitude = amplitude;
        end
        
        function val = setEnabled(aps, ch, enabled)
            % enables or disables a channel
            val = aps.librarycall('Set channel enabled', 'APS_SetWaveformEnabled', ch-1, enabled);
            aps.(['chan_' num2str(ch)]).enabled = enabled;
        end

		function val = setTriggerDelay(aps, ch, delay)
            % sets delay of channel marker output WRT the analog output in
            % 4 sample increments (i.e. delay = 3 is a 12 sample delay)
            val = aps.librarycall('Set channel trigger delay','APS_SetTriggerDelay', ch-1, delay);
            aps.(['chan_' num2str(ch)]).trigDelay = delay;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Private methods
        %
        % These methods are subject to change and should not be used by
        % external code.
        
        function log(aps,line)
            if ~isempty(aps.message_manager)
                aps.message_manager.disp(line)
            else
                if aps.verbose
                    disp(line)
                end
            end
        end
        
        function load_library(d, reloadLibrary)
            
            if ~exist('reloadLibrary','var')
                reloadLibrary = 0;
            end
            
            if strcmp(computer,'PCWIN64')
                libfname = 'libaps64.dll';
                d.library_name = 'libaps64';
            elseif (ispc())
                libfname = 'libaps.dll';
            elseif (ismac())
                libfname = 'libaps.dylib';
            else
                libfname = 'libaps.so';
            end
            
            if reloadLibrary && libisloaded(d.library_name)
                unloadlibrary(d.library_name)
            end
            
            % build library path
            script = mfilename('fullpath');
            script = java.io.File(script);
            path = char(script.getParent());
            d.library_path = [path filesep 'lib' filesep];
            if ~libisloaded(d.library_name)
                [notfound warnings] = loadlibrary([d.library_path libfname], ...
                    [d.library_path 'libaps.h']);
            end
        end
        
        function val = librarycall(aps,mesg,func,varargin)
            % calls DLL methods with logging
            if ~(aps.is_open)
                warning('APS:librarycall','APS is not open');
                val = -1;
                return
            end
            if (aps.verbose)
                aps.log(mesg);
            end
                        
            if size(varargin,2) == 0
                val = calllib(aps.library_name, func, aps.device_id);
            else
                val = calllib(aps.library_name, func, aps.device_id, varargin{:});
            end
            if (aps.verbose)
                aps.log('Done');
            end
        end
        
        function num_devices = enumerate(aps)
            % Return the number of devices and their serial numbers
            
            % Library may not be opened if a stale object is left in
            % memory by matlab. So we reopen on if need be.
            aps.load_library()

            if aps.mock_aps && aps.num_devices == 0
                aps.num_devices = 1;
            else

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
        end
                
        function val = open(aps, id, force)
            % open by device ID
            if (aps.is_open)
                aps.close()
            end
            
            if exist('id','var')
                aps.device_id = id;
            end
            
            if ~exist('force','var')
                force = 0;
            end
            
            % populate list of device id's and serials
            aps.enumerate();
            if id + 1 > aps.num_devices
                error('Device id %i not found.', id);
            end
            
            val = calllib(aps.library_name,'APS_Open' ,aps.device_id, force);
            if (val == 0)
                aps.log(sprintf('APS USB Connection Opened'));
                aps.is_open = 1;
            elseif (val == 1)
                aps.log(sprintf('Could not open device %i.', aps.device_id))
                aps.log(sprintf('Device may be open by a different process'));
            elseif (val == 2)
                aps.log(sprintf('APS Device Not Found'));
            else
                aps.log(sprintf('Unknown return from libaps: %i', val));
            end
        end
        
        function val = openBySerialNum(aps,serial)
            % open by serial number
            if (aps.is_open)
                aps.close()
            end
            
            % populate list of device id's and serials
            aps.enumerate();
            if ~ismember(serial, aps.deviceSerials)
                error('Device id %i not found.', id);
            end
            
            val = calllib(aps.library_name,'APS_OpenBySerialNum' ,serial);
            if (val >= 0)
                aps.log(sprintf('APS USB Connection Opened'));
                aps.is_open = 1;
                aps.device_id = val;
            elseif (val == -1)
                aps.log(sprintf('Could not open device %i.', aps.device_id))
                aps.log(sprintf('Device may be open by a different process'));
            elseif (val == -2)
                aps.log(sprintf('APS Device Not Found'));
            else
                aps.log(sprintf('Unknown return from LIBAPS: %i', val));
            end
        end
        
        function close(aps)
            try
                val = calllib(aps.library_name,'APS_Close',aps.device_id);
            catch
                val = 0;
            end
            if (val == 0)
                aps.log(sprintf('APS USB Connection Closed\n'));
            else
                aps.log(sprintf('Error closing APS USB Connection: %i\n', val));
            end
            aps.is_open = 0;
        end
        
        function val = readBitFileVersion(aps)
            if aps.mock_aps
                 val = aps.ELL_VERSION;
                 return
            end
            val = calllib(aps.library_name,'APS_ReadBitFileVersion', aps.device_id);
            aps.bit_file_version = val;
            if val >= aps.ELL_VERSION
                aps.max_waveform_points = aps.ELL_MAX_WAVFORM;
                aps.max_ll_length = aps.ELL_MAX_LL;
            end
        end
        
        function val = programFPGA(aps, data, bytecount,sel, expectedVersion)
            if ~(aps.is_open)
                warning('APS:ProgramFPGA','APS is not open');
                return
            end
            aps.log('Programming FPGA ');
            val = calllib(aps.library_name,'APS_ProgramFpga',aps.device_id,data, bytecount, sel, expectedVersion);
            if (val < 0)
                errordlg(sprintf('APS_ProgramFPGA returned an error code of: %i\n', val), ...
                    'Programming Error');
            end
            aps.log('Done');
        end
        
        function fname = defaultBitFileName(obj)
            % current device's serial number is at index device_id + 1 in
            % deviceSerials cell array
            if ismember(obj.deviceSerials{obj.device_id+1}, obj.DAC2_SERIALS)
                fname = 'mqco_dac2_latest.bit';
            else
                fname = 'mqco_aps_latest.bit';
            end
        end
        
        function val = loadBitFile(aps,filename)
            
            if ~exist('filename','var')
                filename = [aps.bit_file_path aps.defaultBitFileName];
            end
            
            if ~(aps.is_open)
                warning('APS:loadBitFile','APS is not open');
                return
            end

            aps.setupVCX0();
            aps.setupPLL();
            
            % assume we are programming both FPGA with the same bit file
            Sel = 3;
            
            aps.log(sprintf('Loading bit file: %s', filename));
            [DataFileID, FOpenMessage] = fopen(filename, 'r');
            if ~isempty(FOpenMessage)
                error('APS:loadBitFile', 'Input DataFile Not Found');
            end
            
            [DataVec, DataCount] = fread(DataFileID, inf, 'uint8=>uint8');
            aps.log(sprintf('Read %i bytes.', DataCount));
            
            val = aps.programFPGA(DataVec, DataCount, Sel, aps.expected_bit_file_ver);
            fclose(DataFileID);
        end
        
        %% Private Waveform/Link list methods
        function storeAPSWaveform(aps, waveform, dac)
            if ~strcmp(class(waveform), 'APSWaveform')
                error('APS:storeAPSWaveform:params', 'waveform must be of class APSWaveform')
            end
                
            % store waveform data
            
            if (waveform.dataMode == waveform.REAL_DATA)
                functionCall = 'APS_SetWaveformFloat';
            else
                functionCall = 'APS_SetWaveformInt';
            end
            
            val = calllib(aps.library_name,functionCall, aps.device_id, dac, ...
                waveform.data, length(waveform.data));
            if (val < 0), error('APS:storeAPSWaveform:set', 'error in set waveform'),end;

            % set offset
            
            val = aps.librarycall('Setting waveform offet','APS_SetWaveformOffset', dac, waveform.offset);
            
            % set scale
            
            val = aps.librarycall('Setting wavform scale','APS_SetWaveformScale', dac, waveform.scale_factor);
       
            return
            % check for link list data
            if wf.have_link_list
               ell = wf.get_ell_link_list();
               if isfield(ell,'bankA') && ell.bankA.length > 0
                            
                   bankA = ell.bankA;
                   
                   % store link list
                   val = aps.librarycall('Storing LL BankA','APS_SetLinkList',dac,bankA.offset,bankA.count, ...
                       bankA.trigger, bankA.repeat, bankA.length, 0);
               end
               
               if isfield(ell,'bankB')
                   bankB = ell.bankB;
                   val = aps.librarycall('Storing LL BankB','APS_SetLinkList',dac,bankB.offset,bankB.count, ...
                       bankB.trigger, bankB.repeat, bankB.length, 1);
               end
               
               %aps.setLinkListRepeat(ch-1,ell.repeatCount);
               aps.setLinkListRepeat(ch-1,10000);
            end
        end
        
        function loadAPSWaveforms(aps)
            val = aps.librarycall('Loading waveforms','APS_LoadAllWaveforms');
        end
        
        
        function loadLinkList(aps,id,offsets,counts, ll_len)
            trigger = [];
            repeat = [];
            bank = 0;
            aps.loadLinkListELL(aps,id,offsets,counts, trigger, repeat, ll_len, bank)
        end
        
        function loadLinkListELL(aps,id,offsets,counts, trigger, repeat, ll_len, bank, validate)
            if ~(aps.is_open)
                warning('APS:loadLinkListELL','APS is not open');
                return
            end
            
            if ~exist('validate','var')
                validate = 0;
            end
            
            aps.log(sprintf('Loading Link List length: %i into DAC%i bank %i ', ll_len,id, bank));
            val = calllib(aps.library_name,'APS_LoadLinkList',aps.device_id, offsets,counts,trigger,repeat,ll_len,id,bank, validate);
            if (val < 0)
                errordlg(sprintf('APS_LoadLinkList returned an error code of: %i\n', val), ...
                    'Programming Error');
            end
            aps.log('Done');
        end
        
        function clearLinkListELL(aps,id)
            aps.librarycall('Clear Bank 0','APS_ClearLinkListELL',id,0); % bank 0
            aps.librarycall('Clear Bank 1','APS_ClearLinkListELL',id,1); % bank 1
        end
        
        %% Private Triggering/Stopping methods
        
        function triggerWaveform(aps,id,trigger_type)
            val = aps.librarycall(sprintf('Trigger Waveform %i Type: %i', id, trigger_type), ...
                'APS_TriggerDac',id,trigger_type);
        end
        
        function pauseWaveform(aps,id)
            % deprecated
            val = aps.librarycall(sprintf('Pause Waveform %i', id), 'APS_PauseDac',id);
        end
        
        function disableWaveform(aps,id)
            val = aps.librarycall(sprintf('Disable Waveform %i', id), 'APS_DisableDac',id);
        end
        
        function triggerFpga(aps,id,trigger_type)
            val = aps.librarycall(sprintf('Trigger Waveform %i Type: %i', id, trigger_type), ...
                'APS_TriggerFpga',id,trigger_type);
        end
        
        function pauseFpga(aps,id)
            % deprecated
            val = aps.librarycall(sprintf('Pause Waveform %i', id), 'APS_PauseFpga',id);
        end
        
        function disableFpga(aps,id)
            val = aps.librarycall(sprintf('Disable Waveform %i', id), 'APS_DisableFpga',id);
        end
        
        %% Private mode methods
        
        function val = setLinkListMode(aps, ch, enable, mode)
            % id : DAC channel (1-4)
            % enable : 1 = on, 0 = off
            % mode : 1 = one shot, 0 = continuous
            val = aps.librarycall(sprintf('Dac: %i Link List Enable: %i Mode: %i', ch-1, enable, mode), ...
                'APS_SetLinkListMode',enable,mode,ch-1);
        end
        
        function val = setLinkListRepeat(aps,ch, repeat)
            val = aps.librarycall(sprintf('Dac: %i Link List Repeat: %i', ch-1, repeat), ...
                'APS_SetLinkListRepeat',repeat,ch-1);
        end
        
        function val = setLEDMode(aps, fpga, mode)
            val = aps.librarycall(sprintf('Setting LED mode: %i', mode), ...
                'APS_SetLEDMode', fpga, mode);
        end
        
        function val = testPllSync(aps, ch, numRetries)
            if ~exist('ch','var')
                ch = 1;
            end
            if ~exist('numRetries', 'var')
                numRetries = 10;
            end
            val = aps.librarycall(sprintf('Test Pll Sync: DAC: %i',ch), ...
                'APS_TestPllSync',ch, numRetries);
            if val ~= 0
                fprintf('Warning: APS::testPllSync returned %i\n', val);
            end
        end
        
        function val = readPllStatus(aps)
           % read FPGA1
           val1 = aps.librarycall('Read PLL Sync FPGA1','APS_ReadPllStatus', 1);
           % read FPGA2
           val2 = aps.librarycall('Read PLL Sync FPGA2','APS_ReadPllStatus', 2);
           % functions return 0 on success;
           val = val1 && val2;
        end
        
        function val = setFrequency(aps,ch, freq, testLock)
            if ~exist('testLock','var')
                testLock = 1;
            end
            val = aps.librarycall(sprintf('Dac: %i Freq : %i', ch, freq), ...
                'APS_SetPllFreq',ch,freq,testLock);
            if val ~= 0
                fprintf('Warning: APS::setFrequency returned %i\n', val);
            end
        end
        
        function [freq] = getFrequency(aps,dac)
            % poll hardware for DAC PLL frequency
            freq = aps.librarycall('Get SampleRate', 'APS_GetPllFreq', dac);
            if freq < 0
                fprintf('Warning: APS::getFrequency returned error %i\n', freq);
            end
        end
        
        %% low-level setup and debug methods
        function val = setupPLL(aps)
            val = aps.librarycall('Setup PLL', 'APS_SetupPLL');
        end
        
        function val = setupVCX0(aps)
            val = aps.librarycall('Setup VCX0', 'APS_SetupVCXO');
        end
        
        function val = setupDACs(aps)
           val = aps.librarycall('Setup DACs', 'APS_SetupDACs');
        end

        function readAllRegisters(aps, fpga)
            val = aps.librarycall(sprintf('Read Registers'), ...
                'APS_ReadAllRegisters', fpga);
        end
        
        function testWaveformMemory(aps, ch, numBytes)
            val = aps.librarycall(sprintf('Test WaveformMemory'), ...
                'APS_TestWaveformMemory',ch,numBytes);
        end
        
        function val =  readLinkListStatus(aps,id)
            val = aps.librarycall(sprintf('Read Link List Status'), ...
                'APS_ReadLinkListStatus',id);
        end

        
        function setModeR5(aps)
            aps.bit_file = 'cbl_aps2_r5_d6ma_fx.bit';
            aps.expected_bit_file_ver = 5;
        end
        
        function val = BIT(aps)
           % read FPGA1
           val1 = aps.librarycall('WriteRegBIT','APS_WriteRegBIT');
           
        end
        
        function val = threadTest(aps)
           % read FPGA1
           val1 = aps.librarycall('WriteRegBIT','APS_StartLinkListThread',0);
           pause(1);
           val1 = aps.librarycall('WriteRegBIT','APS_StartLinkListThread',1);
           pause(10);
           val1 = aps.librarycall('WriteRegBIT','APS_StopLinkListThread',1);
           pause(2);
           val1 = aps.librarycall('WriteRegBIT','APS_StopLinkListThread',0);
           
        end

        function unload_library(aps)
            if libisloaded(aps.library_name)
                unloadlibrary(aps.library_name)
            end
        end


        function val = readStatusCtrl(aps)
            val = aps.librarycall('Read status/ctrl', 'APS_ReadStatusCtrl');
        end
        
        function resetStatusCtrl(aps)
            aps.librarycall('Reset status/ctrl', 'APS_ResetStatusCtrl');
        end
        
        function resetChecksums(aps, fpga)
            aps.librarycall('Reset checksum register', 'APS_ResetCheckSum', fpga);
        end
        
        function regWriteTest(aps, addr)
            val = aps.librarycall('Register write test', ...
                'APS_RegWriteTest', addr);
        end
        
        function setDebugLevel(aps, level)
            calllib(aps.library_name, 'APS_SetDebugLevel', level);
        end
        
        function startThreads(aps, channel)
            val = aps.librarycall('Start threads', 'APS_StartLinkListThread', channel);
        end
        
        function stopThreads(aps, channel)
             val = aps.librarycall('Start threads', 'APS_StopLinkListThread', channel);
        end
    end
    methods(Static)
                
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function wf = getNewWaveform()
            % Utility function to get a APS wavform object from APS Driver
            
            % TODO: wrap this with the c library
            try
                wf = APSWaveform();
            catch
                % if APSWaveform is not on the path
                % attempt to add the util directory to the path
                % and reload the waveform
                path = mfilename('fullpath');
                % search path
                spath = ['common' filesep 'src'];
                idx = strfind(path,spath);
                path = [path(1:idx+length(spath)) 'util'];
                addpath(path);
                wf = APSWaveform();
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% External Functions (See external files)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %% UnitTest of Link List Format Conversion
        %% See: LinkListFormatUnitTest.m
        LinkListFormatUnitTest(sequence,useEndPadding)
        
        LinkListUnitTest(sequence, dc_offset)
        LinkListUnitTest2
        LinkListUnitTestC
                
        sequence = LinkListSequences(sequence)
        
        function aps = UnitTest(skipLoad)
            % work around for not knowing full name
            % of class - can not use simply APS when in 
            % experiment framework
            classname = mfilename('class');
            
            % tests channel 0 & 1 output for basic bit file testing
            aps = eval(sprintf('%s();', classname));
            aps.verbose = 1;
            apsId = 0;
            
            fprintf('Openning Device: %i\n', apsId);
            aps.open(apsId);
            
            if (~aps.is_open)
                aps.close();
                aps.open(apsId);
                if (~aps.is_open)
                    error('Could not open aps')
                end
            end

            aps.init()
            
            offset = 0;
            validate = 0;
            storeWaveform = 1;

            wf = aps.getNewWaveform();
            wf.data = [zeros([1,2000]) ones([1,2000])];
            wf.set_scale_factor(0.8);
            wf.dataMode = wf.REAL_DATA;
            
            for ch = 0:3
                aps.loadWaveform(ch, wf.get_vector(), offset, validate,storeWaveform);
                aps.(sprintf('chan_%d', ch+1)).enabled = 1;
            end
            
            aps.run();
            keyboard
            aps.stop();
            aps.close();
      
        end
        
        function aps = UnitTestCWaveform()
            % work around for not knowing full name
            % of class - can not use simply APS when in 
            % experiment framework
            classname = mfilename('class');
            
            % tests channel 0 & 1 output for basic bit file testing
            aps = eval(sprintf('%s();', classname));
            aps.verbose = 1;
            apsId = 0;
            
            fprintf('Openning Device: %i\n', apsId);

            aps.use_c_waveforms = true;
            
            aps.open(apsId);
            aps.loadBitFile();
            aps.setDebugLevel(1);
            
            offset = 0;
            validate = 0;
            storeWaveform = 1;

            wf = aps.getNewWaveform();
            wf.data = 0:1/1000:1;
            wf.data = wf.data(1:1000) * 8192.0;
            wf.set_scale_factor(1.0);

            fprintf('Setting Sample Rate\n');
            aps.samplingRate = 1200;
            
            fprintf('Storing waveforms\n')
            for ch = 0:3
                chS = sprintf('chan_%i',ch+1);
                aps.(chS).waveform = wf;
                aps.(chS).enabled = 1;
                aps.storeAPSWaveform(ch,wf);
            end
            
            
            running = 1;
            
            while running
                fprintf('APS::Run\n')
                aps.run()
                keyboard
                aps.stop()
            end

            aps.close();
        end
    end
end
