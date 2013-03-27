% Bindings to the libaps driver for Matlab
% Requires a build32/64 directory with dlls

% Original author: Brian Donovan
% Date: 21 Oct. 2008

% Copyright 2010 Raytheon BBN Technologies
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
%
%     http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.

classdef APS < hgsetget
    
    properties
        library_path; %path to the shared library 
        library_name; %name of the dll
        deviceID; %FTDI device ID
        deviceSerial; %FTDI device serial number for identification

        bit_file_path; %path to the FPGA bit file

        samplingRate = 1200;   % Global sampling rate in units of MHz (1200, 600, 300, 100, 40)
        triggerSource
        triggerInterval
        miniLLRepeat
    end
    
    properties %(Access = 'private')
        is_open = 0;
        bit_file_version = 0;
        NUM_CHANNELS = 4;
    end
    
    properties (Constant)
        
        APS_ROOT = '../../../../hardware/APS'; 

        EXPECTED_BIT_FILE_VERSION = hex2dec('1');

        ADDRESS_UNIT = 4;
        MAX_WAVEFORM_VALUE = 8191;        
        MAX_WAVFORM_LENGTH = 32768;

        % run modes
        RUN_SEQUENCE = 1;
        RUN_WAVEFORM = 0;

        % repeat modes
        CONTINUOUS = 1;
        TRIGGERED = 0;

        % trigger modes
        TRIGGER_INTERNAL = 0;
        TRIGGER_EXTERNAL = 1;
        
        % for DEBUG methods
        LEDMODE_PLLSYNC = 1;
        LEDMODE_RUNNING = 2;

        ALL_DACS = -1;
        
        DAC2_SERIALS = {'A6UQZB7Z','A6001nBU','A6001ixV', 'A6001nBT', 'A6001nBS'};

    end
    
    methods
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Public Methods
        
        function obj = APS()
            % APS constructor
            
            % load DLL
            curPath = fileparts(mfilename('fullpath'));
            obj.library_path = fullfile(curPath, obj.APS_ROOT, 'libaps-cpp');
            obj.load_library();
            
            % build path for bitfiles
            obj.bit_file_path = fullfile(curPath, obj.APS_ROOT, 'bitfiles');
        end
        
        function delete(obj)
            %delete APS Destructor
            % APS.delete closes the connection before the APS object is
            % deleted. 

            if obj.is_open()
                obj.disconnect();
            end
        end
        
        function [numDevices, deviceSerials] = enumerate(aps)
            % Return the number of devices and their serial numbers
            numDevices = calllib(aps.library_name,'get_numDevices');

            %Reset cell array
            deviceSerials = cell(numDevices,1);
            %For each device load the serial number
            for ct = 1:numDevices
                deviceSerials{ct} = calllib(aps.library_name, 'get_deviceSerial',ct-1, blanks(64));
            end
        end

        function connect(aps,address)
            %connect - Connect to an APS unit by deviceID or serial number.
            % APS.connect(address) opens the USB connection to a particular
            % device.  The device can be specified as an integer or device
            % serial string. 
            %
            % Examples:
            %   aps.connect(0);
            %   aps.connect('A6UQZB7Z')
        
            if (aps.is_open)
                aps.disconnect();
            end
            
            %Rennumerate to catch any changes in devices plugged in
            [numDevices, deviceSerials] = aps.enumerate();
            
            deviceID_re = '^\d+';
            if ~isempty(regexp(address, deviceID_re, 'once'))
                address = str2double(address);
            end
            if isnumeric(address)
                if address > numDevices
                    error('Oops! There are not that many APS units connected.');
                end
                aps.deviceID = address;
                aps.deviceSerial = deviceSerials{address+1};
                val = calllib(aps.library_name, 'connect_by_ID', aps.deviceID);
            else
                aps.deviceSerial = address;
                aps.deviceID = calllib(aps.library_name, 'serial2ID', address);
                val = calllib(aps.library_name, 'connect_by_serial', address);
            end
            
            if (val == 0)
                aps.is_open = 1;
            else
                error('Unable to open APS device.');
            end

        end
        
        function disconnect(obj)
            %disconnect Close the USB connection.
            try
                val = calllib(obj.library_name, 'disconnect_by_ID', obj.deviceID);
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
            %setAll - Sets up the APS with a settings structure
            % APS.setAll(settings)
            % The settings structure can contain
            %  settings.
            %           chan_x.amplitude
            %           chan_x.offset
            %           chan_x.enabled
            %  settings.seqfile - hdf5 sequence file
            %  settings.seqforce - force reload of file
            
            obj.init();

            %Setup some defaults 
            if(~isfield(settings, 'seqforce'))
                settings.seqforce = 0;
            end
            if(~isfield(settings, 'lastseqfile'))
                settings.lastseqfile = '';
            end
            
            %If we are going to call loadConfig below, we can clear all channel data first
            if (~strcmp(settings.lastseqfile, settings.seqfile) || settings.seqforce)
				obj.libraryCall('clear_channel_data');
            end
			
            %Set the channel parameters;  set amplitude and offset before loading waveform data so that we
 			% only have to load it once.

            channelStrs = {'chan_1','chan_2','chan_3','chan_4'};
            for ct = 1:4
                ch = channelStrs{ct};
				obj.setAmplitude(ct, settings.(ch).amplitude);
				obj.setOffset(ct, settings.(ch).offset);
                obj.setEnabled(ct, settings.(ch).enabled);
            end
            settings = rmfield(settings, channelStrs);
            
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
                    obj.setRunMode(1,1); obj.setRunMode(3,1);
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
                    if ~isempty(settings.(name))
                        obj.(name) = settings.(name);
                    end
                end
            end
        end
        
        function init(obj, force, filename)
            %init - Initialize an APS from power up. 
            % APS.init(force (false), filename)  Initializes a an APS using
            % the FPGA bit file in filename and the forces reloading the
            % bitfile according to force. 
            
            %Setup the defaults
            if ~exist('force', 'var')
                force = false;
            end

            if ~exist('filename','var')
                filename = fullfile(obj.bit_file_path, obj.defaultBitFileName);
            end
            
%             if ~exist(filename,'file')
%                error(sprintf('APS: bitfile %s not found ', filename));
%             end
            
            %Call the dll with a null-terminated string
            err = obj.libraryCall('initAPS', [filename 0], force);
            if (err < 0)
               error(sprintf('APS: initAPS : %i', err));
            end
        end
        
        function loadWaveform(obj, ch, waveform)
            %loadWaveform - loads a waveform vector into memory
            % APS.loadWaveform(ch, waveform)
            %   ch - channel (1-4)
            %   waveform - int16 format waveform data (-8192, 8191) or
            %       float data in the range (-1.0, 1.0)
            assert((ch>0) && (ch<5), 'Oops! The channel must be in the range 1 through 4');
            assert(length(waveform)<=obj.MAX_WAVFORM_LENGTH, 'Oops! Your waveform must be less than %d points', obj.MAX_WAVFORM_LENGTH+1)
            switch(class(waveform))
                case 'int16'
                    obj.libraryCall('set_waveform_int', ch-1, waveform, length(waveform));
                case 'double'
                    obj.libraryCall('set_waveform_float', ch-1, waveform, length(waveform));
                otherwise
                    error('Unhandled waveform data type');
            end
            obj.setEnabled(ch, 1);
        end
        
        function loadConfig(aps, filename)
            %loadConfig - Loads a complete, 4 channel configuration hdf5 sequence file
            % APS.loadConfig(filename) 
            %   filename - full path to hdf5 sequence file
            
            status = aps.libraryCall('load_sequence_file', [filename 0]);
            assert(status == 0, 'load_sequence_file returned error code %d', status);
        end
        
        function loadLL(obj, ch, addr, count, trigger1, trigger2, repeat)
            %loadLL - Directly loads link list data into memory (if it fits)
            % APS.loadLL(ch, addr, count, trigger1, trigger2, repeat)
            %  ch - channel to load (1-4)
            %  addr - vector of addresses
            %  count - vector of counts
            %  trigger1 - vector of I channel triggers
            %  trigger2 - vector of Q channel triggers
            %  repeat - vector of repeats
            obj.libraryCall('set_LL_data_IQ', ch-1, length(addr), addr, count, trigger1, trigger2, repeat);
        end

        function run(aps)
            %run - Starts the aps 
            % APS.run() Will ready the APS to recieve external hardware triggers or
            % start the sequence/waveform playing if in internal trigger
            % mode.
            aps.libraryCall('run');
        end
        
        function stop(aps)
            %stop - Stops the APS unit output. 
            aps.libraryCall('stop');
        end
        
        function isr = isRunning(aps)
            %isRunning - Checks whether the APS is running. 
            % runValue = APS.isRunning().   Checks the state of the CSR to verify that a state machine
            % is running

            isr = false;
            if aps.is_open
                val = aps.libraryCall('get_running');
                if val > 0
                    isr = true;
                end
            end
        end
        
        function out = waitForAWGtoStartRunning(aps)
            %waitForAWGtoStartRunning - Wraps APS.isRunning for consistency with the Tek5014 driver. 
            % for compatibility with Tek driver
%             if ~aps.isRunning()
%                 aps.run();
%             end
            out = true;
        end
        
        function aps = set.samplingRate(aps, rate)
            % sets the sampling rate for all channels/FPGAs
            % rate - sampling rate in MHz (1200, 600, 300, 100, 40)
            aps.libraryCall('set_sampleRate',rate);
            aps.samplingRate = rate;
        end
        
        function rate = get.samplingRate(aps)
            % polls APS hardware to get current PLL Sample Rate
            % valid rates in MHz (1200, 600, 300, 100, 40)
            rate = aps.libraryCall('get_sampleRate');
        end
        
        function aps = set.triggerSource(aps, trig)
            % sets internal or external trigger
            checkMap = containers.Map({...
	            'internal','external','int', 'ext'},...
                {aps.TRIGGER_INTERNAL,aps.TRIGGER_EXTERNAL,aps.TRIGGER_INTERNAL,aps.TRIGGER_EXTERNAL});
            
            trig = lower(trig);
            if not(checkMap.isKey(trig))
                error(['APS: Unrecognized trigger source value: ', trig]);
            else
                aps.libraryCall('set_trigger_source', checkMap(trig));
                aps.triggerSource = trig;
            end
        end
        
        function source = get.triggerSource(obj)
            valueMap = containers.Map({obj.TRIGGER_INTERNAL, obj.TRIGGER_EXTERNAL},...
                {'internal', 'external'});
            source = valueMap(obj.libraryCall('get_trigger_source'));
        end
        
        function aps = set.triggerInterval(aps, interval)
            aps.libraryCall('set_trigger_interval', interval);
            aps.triggerInterval = interval;
        end
        
        function value = get.triggerInterval(aps)
            value = aps.libraryCall('get_trigger_interval');
        end
        
        function aps = set.miniLLRepeat(aps, repeatValue)
            aps.libraryCall('set_miniLL_repeat', repeatValue);
            aps.miniLLRepeat = repeatValue;
        end
        
        function value = get.miniLLRepeat(aps)
            value =  aps.readRegister(1, 9);
        end
        
        function val = setOffset(aps, ch, offset)
            %setOffset - Sets the channel offset. 
            % APS.setOffset(ch, offset)
            %   ch - channel (1-4)
            %   offset - channel offset (-1,1)
            val = aps.libraryCall('set_channel_offset', ch-1, offset);
        end
        
        function val = getOffset(aps, ch)
            %getOffset - Gets the channel offset. 
            % APS.getOffset(ch)
            %   ch - channel (1-4)
            val = aps.libraryCall('get_channel_offset', ch-1);
        end

		function val = setAmplitude(aps, ch, amplitude)
            %setAmplitude - Sets the channel amplitude scaling. 
            %APS.setAmplitude(ch, amplitude)
            %   ch - channel (1-4)
            %   amplitude - channel amplitude (float, but waveform may be clipped)
			val = aps.libraryCall('set_channel_scale', ch-1, amplitude);
        end

		function val = getAmplitude(aps, ch)
            %getAmplitude - Gets the channel amplitude scaling. 
            %APS.setAmplitude(ch)
            %   ch - channel (1-4)
			val = aps.libraryCall('get_channel_scale', ch-1);
        end
        
        function val = setEnabled(aps, ch, enabled)
            %setEnabled - Sets whether channel output is enabled or disabled 
            % APS.setEnabled(ch, enabled)
            %   ch - channel (1-4)
            %   enabled - channel enabled (bool)
            val = aps.libraryCall('set_channel_enabled', ch-1, enabled);
        end

        function val = getEnabled(aps, ch)
            %getEnabled - Sets whether channel output is enabled or disabled 
            % APS.getEnabled(ch)
            %   ch - channel (1-4)
            val = aps.libraryCall('get_channel_enabled', ch-1);
        end

		function val = setTriggerDelay(aps, ch, delay)
            %setTriggerDelay - sets delay of channel marker output with respect
            % to the analog output in 4 sample increments (e.g. delay = 3 is a 
            % 12 sample delay).
            % APS.setTriggerDelay(ch, delay)
            %   ch - channel (1-4)
            %   delay - trigger delay in 4 sample units
            val = aps.libraryCall('set_channel_trigDelay', ch-1, delay);
        end
        
        function delay = getTriggerDelay(aps, ch)
            %getTriggerDelay - Returns the current trigger delay (in four
            %sample units for a channel.
            % APS.getTriggerDelay(ch)
            %   ch - channel (1-4)
            delay = aps.libraryCall('get_channel_trigDelay',ch-1);
        end

		function val = setRunMode(aps, ch, mode)
            %setRunMode - Sets the APS in sequence or waveform mode.
            %Waveform mode will simply play the channel waveform memory.
            %Sequence mode will play the link-list sequence. 
            % APS.setRunMode(ch, mode)
            %   ch - channel (1-4)
            %   mode - run mode (1 = sequence; 0 = waveform)
            val = aps.libraryCall('set_run_mode',ch-1, mode);
        end
        
        function val = setRepeatMode(aps, ch, mode)
            %setRunMode - Sets the APS to either output a single shot or
            %loop continuously. 
            % APS.setRepeatMode(ch, mode)
            %   ch - channel (1-4)
            %   mode - run mode (1 = continuous, 0 = triggered)
            val = aps.libraryCall('set_repeat_mode', ch-1, mode);
        end
        
        function setDebugLevel(aps, level)
            % sets logging level in libaps.log
            % level = {logERROR=0, logWARNING, logINFO, logDEBUG, logDEBUG1, logDEBUG2, logDEBUG3, logDEBUG4}
            calllib(aps.library_name, 'set_logging_level', level);
        end
        
        function val = readRegister(aps, fpga, addr)
            val = aps.libraryCall('read_register', fpga, addr);
        end

        
    end %public methods

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Private methods
    %
    % These methods are subject to change.
    
    methods (Access = protected) 
        function load_library(obj)
            %Helper functtion to load the platform dependent library
            switch computer()
                case 'PCWIN64'
                    libfname = [filesep 'build64' filesep 'libaps64.dll'];
                    obj.library_name = 'libaps64';
                    protoFile = @obj.libaps64;
                case 'PCWIN'
                    libfname = [filesep 'build32' filesep 'libaps.dll'];
                    obj.library_name = 'libaps';
                    protoFile = @obj.libaps32;
                case 'MACI64'
                    libfname = 'libaps.dylib';
                    error('Need prototype file setup for OS X');
                case 'GLNXA64'
                    libfname = 'libaps.so';
                    error('Need prototype file setup for Linux');
                otherwise
                    error('Unsupported platform.');
            end
            
            % build library path and load it if necessary
            if ~libisloaded(obj.library_name)
                loadlibrary([obj.library_path libfname], protoFile);
                %Initialize the APSRack in the library
                calllib(obj.library_name, 'init');
            end
        end
        
        function val = libraryCall(aps,func,varargin)
            %Helper function to pass through to calllib with the APS device ID first 
            if ~(aps.is_open)
                error('APS:libraryCall','APS is not open');
            end
                        
            if size(varargin,2) == 0
                val = calllib(aps.library_name, func, aps.deviceID);
            else
                val = calllib(aps.library_name, func, aps.deviceID, varargin{:});
            end
        end
        
        function val = readBitFileVersion(aps)
            val = aps.libraryCall('read_bitfile_version');
        end
        
        function fname = defaultBitFileName(obj)
            %The older model DACII's have different bit files than the
            %newer model APS units so we have to switch appropriately. 
            % current device's serial number is at index deviceID + 1 in
            % deviceSerials cell array
            if ismember(obj.deviceSerial, obj.DAC2_SERIALS)
                fname = 'mqco_dac2_latest';
            else
                fname = 'mqco_aps_latest';
            end
        end
        
        %% Private Waveform/Link list methods
        function addLinkList(aps, ch, offsets, counts, repeat, trigger, length)
            %Adds a LL bank to a channel
            % val = aps.libraryCall('add_LL_bank',ch-1, length, offsets,counts,repeat,trigger);
            % if (val < 0)
            %     error('addLinkList returned an error code of: %i\n', val);
            % end
            %
            % Not available in current firmware
        end
        
        %% Private mode methods
        function val = setLinkListRepeat(aps, repeat)
            % Set the number of times each miniLL will be looped (0 = no repeats)
            aps.libraryCall('set_miniLL_repeat', repeat)
        end
        
        function val = testPllSync(aps, ch, numRetries)
            % TODO
%             val = aps.libraryCall('APS_TestPllSync',ch, numRetries);
%             if val ~= 0
%                 fprintf('Warning: APS::testPllSync returned %i\n', val);
%             end
        end
        
        %% low-level setup and debug methods
        function readAllRegisters(aps, fpga)
            % TODO
%             val = aps.libraryCall(sprintf('Read Registers'), ...
%                 'APS_ReadAllRegisters', fpga);
        end

        function val = readStatusCtrl(aps)
            % TODO
            %val = aps.libraryCall('Read status/ctrl', 'APS_ReadStatusCtrl');
        end
        
        function regWriteTest(aps, addr)
            % TODO
%             val = aps.libraryCall('Register write test', ...
%                 'APS_RegWriteTest', addr);
        end
        

    end
    methods(Static)

        
        % UnitTest of Link List Format Conversion
        % See: LinkListFormatUnitTest.m
        LinkListFormatUnitTest(sequence,useEndPadding)
        
        LinkListUnitTest(sequence, dc_offset)
        LinkListUnitTest2
                
        sequence = LinkListSequences(sequence)
        
        %Reference prototype file for fast loading of shared library
        [methodinfo,structs,enuminfo,ThunkLibName]=libaps64
        [methodinfo,structs,enuminfo,ThunkLibName]=libaps32
        
            
        function UnitTest(forceLoad)
            % work around for not knowing full name of class - cannot use simply
            % APS when in experiment framework
            if ~exist('forceLoad', 'var')
                forceLoad = 0;
            end
            classname = mfilename('class');
            
            % tests channel 0 & 1 output for basic bit file testing
            aps = eval(sprintf('%s();', classname));
            apsId = 0;
            
            fprintf('Openning Device: %i\n', apsId);
            aps.connect(apsId);
            
            if (~aps.is_open)
                error('Could not open aps')
            end

            aps.init(forceLoad);
            fprintf('Current bitfile version: %d\n', aps.readBitFileVersion())

            %Load a square wave
            wf = [zeros([1,2000]) 0.8*ones([1,2000])];
            for ch = 1:4
                aps.loadWaveform(ch, wf);
                aps.setRunMode(ch, aps.RUN_WAVEFORM);
            end
            
            aps.triggerSource = 'external';
            %aps.setDebugLevel(5);
            aps.run();
            keyboard
            aps.stop();

            aps.loadConfig(fullfile(aps.library_path, '..', 'examples', 'Ramsey.h5'));
            aps.triggerSource = 'external';
            %aps.setDebugLevel(5);
            aps.run();
            keyboard
            aps.stop();
            aps.disconnect();
        end
    end
end
