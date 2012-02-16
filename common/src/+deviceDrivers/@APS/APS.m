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
%
% $Author: bdonovan $
% $Date$
% $Locker:  $
% $Name:  $
% $Revision$

% Copyright (C) BBN Technologies Corp. 2008-2011
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

classdef APS < deviceDrivers.lib.deviceDriverBase
    %APS Summary of this class goes here
    %   Detailed explanation goes here
    properties
        library_path = './lib/';
        library_name = 'libaps';
        device_id = 0;
        num_devices;
        deviceSerials = {}
        message_manager =[];
        bit_file_path = '';
        bit_file = 'mqco_dac2_latest.bit';
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
        
        samplingRate = 1200;   % Global sampling rate in units of MHz (1200, 600, 300, 100, 40)
        triggerSource = 'internal';  % Global trigger source ('internal', or 'external')
        is_running = false;
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
        
        ALL_DACS = -1;
        FORCE_OPEN = 1;
        
        FPGA0 = 0;
        FPGA1 = 2;
        
        channelStruct = struct('amplitude', 1.0, 'offset', 0.0, 'enabled', false, 'waveform', []);
    end
    
    methods
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function d = APS()
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
            d.chan_1 = d.channelStruct;
            d.chan_1.waveform = APSWaveform();
            d.chan_2 = d.channelStruct;
            d.chan_2.waveform = APSWaveform();
            d.chan_3 = d.channelStruct;
            d.chan_3.waveform = APSWaveform();
            d.chan_4 = d.channelStruct;
            d.chan_4.waveform = APSWaveform();
        end
        
        %Destructor
        function delete(obj)
            if obj.is_open()
                obj.close();
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function connect(obj,address)
            
            % Experiment Framework function for connecting to
            % A APS, allow numeric or serial number based
            % addressing
            
            if isnumeric(address)
                val = obj.open(address);
            else
                val = obj.openBySerialNum(address);
            end
            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function disconnect(obj)
            obj.close()
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function log(aps,line)
            if ~isempty(aps.message_manager)
                aps.message_manager.disp(line)
            else
                if aps.verbose
                    disp(line)
                end
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function load_library(d)
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
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %Return the number of devices and their serial numbers
        function num_devices = enumerate(aps)
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
        
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % setAll is called as part of the Experiment initialize instruments
        function setAll(obj,settings)
            obj.init();

            % read in channel settings so we know how to scale waveform
            % data
            ch_fields = {'chan_1', 'chan_2', 'chan_3', 'chan_4'};
            for i = 1:length(ch_fields)
                ch = ch_fields{i};
                obj.(ch).amplitude = settings.(ch).amplitude;
                obj.(ch).offset = settings.(ch).offset;
                obj.(ch).enabled = settings.(ch).enabled;
            end
            settings = rmfield(settings, ch_fields);
            
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
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function val = open(aps,id, force)
            if (aps.is_open)
                aps.close()
            end
            
            if exist('id','var')
                aps.device_id = id;
            end
            
            if ~exist('force','var')
                force = 0;
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
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function val = openBySerialNum(aps,serialNum)
            if (aps.is_open)
                aps.close()
            end
            
            val = calllib(aps.library_name,'APS_OpenBySerialNum' ,serialNum);
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
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
        
        function init(obj, force)
            % bare minimum commands to make the APS usable
            % if force = true, always load bit file
            if ~exist('force', 'var')
                force = false;
            end
            
            % Determine if APS needs to be programmed
            bitFileVer = obj.readBitFileVersion();
            if ~isnumeric(bitFileVer) || bitFileVer ~= obj.expected_bit_file_ver || obj.readPllStatus() ~= 0 || force
                obj.loadBitFile();

                % set all channels to 1.2 GS/s
                obj.setFrequency(0, 1200, 0);
                obj.setFrequency(2, 1200, 0);
                
                % test PLL sync on each FPGA
                status = obj.testPllSync(0) || obj.testPllSync(2);
                if status ~= 0
                    error('APS failed to initialize');
                end
                
                % set all channel offsets to zero
                for ch=1:4, obj.setOffset(ch, 0); end
            end
            
            obj.bit_file_programmed = 1;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
        
        function isr = isRunning(aps)
            isr = false;
            if aps.is_open
                val = calllib(aps.library_name,'APS_IsRunning',aps.device_id);
                if val > 0
                    isr = true;
                end
            end
        end
        
        function dbgForceELLMode(aps)
            %% Force constants to ELL mode for debug testing
            aps.max_waveform_points = aps.ELL_MAX_WAVFORM;
            aps.max_ll_length = aps.ELL_MAX_LL;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function val = programFPGA(aps, data, bytecount,sel)
            if ~(aps.is_open)
                warning('APS:ProgramFPGA','APS is not open');
                return
            end
            aps.log('Programming FPGA ');
            val = calllib(aps.library_name,'APS_ProgramFpga',aps.device_id,data, bytecount,sel);
            if (val < 0)
                errordlg(sprintf('APS_ProgramFPGA returned an error code of: %i\n', val), ...
                    'Programming Error');
            end
            aps.log('Done');
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function val = loadBitFile(aps,filename)
            
            if ~exist('filename','var')
                filename = [aps.bit_file_path aps.bit_file];
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
            eval(['[DataFileID, FOpenMessage] = fopen(''', filename, ''', ''r'');']);
            if ~isempty(FOpenMessage)
                error('APS:loadBitFile', 'Input DataFile Not Found');
            end
            
            [filename, permission, machineformat, encoding] = fopen(DataFileID);
            %eval(['disp(''Machine Format = ', machineformat, ''');']);
            
            [DataVec, DataCount] = fread(DataFileID, inf, 'uint8=>uint8');
            aps.log(sprintf('Read %i bytes.', DataCount));
            
            val = aps.programFPGA(DataVec, DataCount,Sel);
            fclose(DataFileID);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% Waveform / Link List Load Functions
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function loadWaveform(aps,id,waveform,offset,validate, useSlowWrite)
            % id - channel (0-3)
            % waveform - int16 format waveform data (-8192, 8191)
            % offset - waveform memory offset (think memory location, not
            %   shift of zero), integer multiple of 4
            % validate - bool, reads back waveform data
            % useSlowWrite - bool, when false uses a faster buffered write
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
            
            if ~exist('useSlowWrite','var')
                useSlowWrite = 0;
            end
            
            aps.log(sprintf('Loading Waveform length: %i into DAC%i ', length(waveform),id));
            val = calllib(aps.library_name,'APS_LoadWaveform', aps.device_id,waveform,length(waveform),offset, id, validate, useSlowWrite);
            if (val < 0)
                errordlg(sprintf('APS_LoadWaveform returned an error code of: %i\n', val), ...
                    'Programming Error');
            end
            aps.log('Done');
        end
        
        function storeAPSWaveform(aps, waveform, dac)
            if ~strcmp(class(waveform), 'APSWaveform')
                error('APS:storeAPSWaveform:params', 'waveform must be of class APSWaveform')
            end
                
            % store waveform data
            
            val = aps.librarycall('Storing waveform','APS_SetWaveform', dac, waveform.data, length(waveform));
            if (val < 0), error('APS:storeAPSWaveform:set', 'error in set waveform'),end;
           
            % set offset
            
            val = aps.librarycall('Setting waveform offet','APS_SetWaveformOffset', dac, waveform.offset);
            
            % set scale
            
            val = aps.librarycall('Setting wavform scale','APS_SetWaveformScale', dac, waveform.scale_factor);
            
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
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function loadLinkList(aps,id,offsets,counts, ll_len)
            trigger = [];
            repeat = [];
            bank = 0;
            aps.loadLinkListELL(aps,id,offsets,counts, trigger, repeat, ll_len, bank)
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function clearLinkListELL(aps,id)
            aps.librarycall('Clear Bank 0','APS_ClearLinkListELL',id,0); % bank 0
            aps.librarycall('Clear Bank 1','APS_ClearLinkListELL',id,1); % bank 1
        end
        
        function loadConfig(aps, filename)
            % loads a complete, 4 channel configuration file
            
            % pseudocode:
            % open file
            % foreach channel
            %   load and scale/shift waveform data
            %   save channel waveform lib in chan_i struct
            %   clear old link list data
            %   load link list data (if any)
            %   save channel LL data in chan_i struct
            %   set link list mode
            
            % clear existing variable names
            clear Version WaveformLibs LinkLists
            load(filename)
            % if any channel has a link list, all channels must have a link
            % list
            % TODO: add more error checking
            if length(LinkLists) > 1 && (length(WaveformLibs) ~= length(LinkLists))
                error('Malformed config file')
            end
            
            % clear old link list data
            aps.clearLinkListELL(0);
            aps.clearLinkListELL(1);
            aps.clearLinkListELL(2);
            aps.clearLinkListELL(3);
            
            % load waveform data
            wf = APSWaveform();
            for ch = 1:aps.num_channels
                if ch <= length(WaveformLibs) && ~isempty(WaveformLibs{ch})
                    % load and scale/shift waveform data
                    wf.set_vector(WaveformLibs{ch});
                    wf.set_offset(aps.(['chan_' num2str(ch)]).offset);
                    wf.set_scale_factor(aps.(['chan_' num2str(ch)]).amplitude);
                    aps.loadWaveform(ch-1, wf.prep_vector());
                    aps.(['chan_' num2str(ch)]).waveform = wf;
                    
                    % set zero register value
                    offset = aps.(['chan_' num2str(ch)]).offset;
                    aps.setOffset(ch, offset);
                end
            end
            
            % load LL data (if any)
            for ch = 1:aps.num_channels
                wf = aps.(['chan_' num2str(ch)]).waveform;
                
                if ch <= length(LinkLists) && ~isempty(LinkLists{ch})
                    wf.ellData = LinkLists{ch};
                    wf.ell = true;
                    if wf.check_ell_format()
                        
                        wf.have_link_list = 1;
                    
                        ell = wf.get_ell_link_list();
                        if isfield(ell,'bankA') && ell.bankA.length > 0
                            
                            bankA = ell.bankA;
                            aps.loadLinkListELL(ch-1,bankA.offset,bankA.count, ...
                                bankA.trigger, bankA.repeat, bankA.length, 0);
                        end

                        if isfield(ell,'bankB') && ~isempty(ell.bankB) && ell.bankB.length > 0
                            bankB = ell.bankB;
                            aps.loadLinkListELL(ch-1,bankB.offset,bankB.count, ...
                                bankB.trigger, bankB.repeat, bankB.length, 1);
                        end

                        %aps.setLinkListRepeat(ch-1,ell.repeatCount);
                        aps.setLinkListRepeat(ch-1,10000);
                        %aps.setLinkListRepeat(ch-1,0);
                    end
                    aps.setLinkListMode(ch-1, aps.LL_ENABLE, aps.LL_CONTINUOUS);
                end
                
                % update channel waveform object
                aps.(['chan_' num2str(ch)]).waveform = wf;
            end
            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% Trigger / Pause / Disable Waveform or FPGA
        %% setLinkListMode
        %% setFrequency
        %%
        %% These function share a common base function to wrap libaps
        %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function val = librarycall(aps,mesg,func,varargin)
            % common base call for a number of functions
            if ~(aps.is_open)
                warning('APS:librarycall','APS is not open');
                val = -1;
                return
            end
            if (aps.verbose)
                aps.log(mesg);
            end
                        
            switch size(varargin,2)
                case 0
                    val = calllib(aps.library_name,func,aps.device_id);
                case 1
                    val = calllib(aps.library_name,func,aps.device_id, varargin{1});
                case 2
                    val = calllib(aps.library_name,func,aps.device_id, varargin{1}, varargin{2});
                case 3
                    val = calllib(aps.library_name,func,aps.device_id, varargin{1}, varargin{2}, varargin{3});
                otherwise
                    error('More than 3 varargin arguments to librarycall are not supported\n');
            end
            if (aps.verbose)
                aps.log('Done');
            end
        end
        
        function triggerWaveform(aps,id,trigger_type)
            val = aps.librarycall(sprintf('Trigger Waveform %i Type: %i', id, trigger_type), ...
                'APS_TriggerDac',id,trigger_type);
        end
        
        function pauseWaveform(aps,id)
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
            val = aps.librarycall(sprintf('Pause Waveform %i', id), 'APS_PauseFpga',id);
        end
        
        function disableFpga(aps,id)
            val = aps.librarycall(sprintf('Disable Waveform %i', id), 'APS_DisableFpga',id);
        end
        
        function run(aps)
            % global run method
            
            trigger_type = aps.TRIGGER_SOFTWARE;
            if strcmp(aps.triggerSource, 'external')
                trigger_type = aps.TRIGGER_HARDWARE;
            end
            
            % based upon enabled channels, trigger both FPGAs, a single
            % FPGA, or individuals DACs
            trigger = [false false false false];
            channels = {'chan_1','chan_2','chan_3','chan_4'};
            for i = 1:4
                trigger(i) = aps.(channels{i}).enabled;
            end
            
            triggeredFPGA = [false false];
            if trigger % all channels enabled
                aps.triggerFpga(aps.ALL_DACS, trigger_type);
                triggeredFPGA = [true true];
            elseif trigger(1:2) %FPGA0
                triggeredFPGA(1) = true;
                aps.triggerFpga(aps.FPGA0, trigger_type)
            elseif trigger(3:4) %FPGA1
                triggeredFPGA(2) = true;
                aps.triggerFpga(aps.FPGA1, trigger_type)
            end
            
            % look at individual channels
            % NOTE: Poorly defined syncronization between channels in this
            % case.
            for channel = 1:4
                if ~triggeredFPGA(ceil(channel / 2)) && trigger(channel)
                    aps.triggerWaveform(channel-1,trigger_type)
                end
            end
            aps.is_running = true;
        end
        
        function stop(aps)
            % global stop method
            aps.disableFpga(aps.ALL_DACS);
        end
        
        function out = waitForAWGtoStartRunning(aps)
            % for compatibility with Tek driver
            % checks the state of the CSR to verify that a state machine
            % is running
        
            % TODO!! Needs an appropriate method in C library.
            % Kludgy workaround for now.
            if ~aps.is_running
                aps.run();
            end
            out = true;
        end
        
        function setLinkListMode(aps, id, enable, mode)
            % id : DAC channel (0-3)
            % enable : 1 = on, 0 = off
            % mode : 1 = one shot, 0 = continuous
            val = aps.librarycall(sprintf('Dac: %i Link List Enable: %i Mode: %i', id, enable, mode), ...
                'APS_SetLinkListMode',enable,mode,id);
        end
        
        function setLinkListRepeat(aps,id, repeat)
            val = aps.librarycall(sprintf('Dac: %i Link List Repeat: %i', id, repeat), ...
                'APS_SetLinkListRepeat',repeat,id);
        end
        
        function val = testPllSync(aps, id, numSyncChannels)
            if ~exist('id','var')
                id = 0;
            end
            if ~exist('numSyncChannels', 'var')
                numSyncChannels = 4;
            end
            val = aps.librarycall('Test Pll Sync: DAC: %i','APS_TestPllSync',id, numSyncChannels);
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
        
        function val = setFrequency(aps,id, freq, testLock)
            if ~exist('testLock','var')
                testLock = 1;
            end
            val = aps.librarycall(sprintf('Dac: %i Freq : %i', id, freq), ...
                'APS_SetPllFreq',id,freq,testLock);
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
        
        function val = setOffset(aps, ch, offset)
            val = aps.librarycall('Set channel offset','APS_SetChannelOffset', ch-1, offset*aps.MAX_WAVEFORM_VALUE);
            aps.(['chan_' num2str(ch)]).offset = offset;
        end
        
        function setupPLL(aps)
            val = aps.librarycall('Setup PLL', 'APS_SetupPLL');
        end
        
        function setupVCX0(aps)
            val = aps.librarycall('Setup VCX0', 'APS_SetupVCXO');
        end
        
        function aps = set.samplingRate(aps, rate)
            % sets the sampling rate for all channels/FPGAs
            % rate - sampling rate in MHz (1200, 600, 300, 100, 40)
            if aps.samplingRate ~= rate
                aps.setFrequency(0, rate, 0);
                aps.setFrequency(2, rate, 0);
                aps.testPllSync(0);
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
        
        function readAllRegisters(aps)
            val = aps.librarycall(sprintf('Read Registers'), ...
                'APS_ReadAllRegisters');
        end
        
        function testWaveformMemory(aps, id, numBytes)
            val = aps.librarycall(sprintf('Test WaveformMemory'), ...
                'APS_TestWaveformMemory',id,numBytes);
        end
        
        function val =  readLinkListStatus(aps,id)
            val = aps.librarycall(sprintf('Read Link List Status'), ...
                'APS_ReadLinkListStatus',id);
        end
        
        function setModeR5(aps)
            aps.bit_file = 'cbl_aps2_r5_d6ma_fx.bit';
            aps.expected_bit_file_ver = 5;
        end
    end
    methods(Static)
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function unload_library()
            if libisloaded('libaps')
                unloadlibrary libaps
            end
        end
        
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
            
            fprintf('Reading Bitfiled Version: \n');
            
            ver = aps.readBitFileVersion();
            fprintf('Found Bit File Version: 0x%s\n', dec2hex(ver));
            if ver ~= aps.expected_bit_file_ver
                val = aps.loadBitFile();
                ver = aps.readBitFileVersion();
                fprintf('Found Bit File Version: 0x%s\n', dec2hex(ver));
            end

            validate = 0;
            useSlowWrite = 0;

            wf = aps.getNewWaveform();
            wf.data = [zeros([1,2000]) ones([1,2000])];
            wf.set_scale_factor(0.8);
            
            for ch = 0:3
                aps.setFrequency(ch, 1200)
                aps.loadWaveform(ch, wf.get_vector(), 0, validate,useSlowWrite);
                
            end
            
            aps.triggerFpga(0,1);
            aps.triggerFpga(2,1);
            keyboard
            aps.pauseFpga(0);
            aps.pauseFpga(2);
            aps.close();
      
        end
        
    end
end
