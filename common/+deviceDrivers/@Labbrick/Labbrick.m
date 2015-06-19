% Labbrick microwave source drive
%
% Author(s): Blake Johnson
% Date created: Tues Aug 2 2011

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
classdef (Sealed) Labbrick < deviceDrivers.lib.uWSource
    % Class-specific constant properties
    properties (Constant = true)
        MAX_DEVICES = 64;
        MAX_RETRIES = 3;
    end % end constant properties
    
    
    % Class-specific private properties
    properties (Access = private)
        devID;
        open = 0;
        serialNum = 1;
        model = 'LMS-103';
        max_power = 10; % dBm
        min_power = -40; % dBm
        max_freq = 10; % GHz
        min_freq = 5; % GHz
        pulseModeEnabled = 0;
        
        % status codes from vnx_fmssynth.h
        STATUS_INVALID_DEVID     = hex2dec('80000000') % MSB is set if the device ID is invalid
        STATUS_DEV_CONNECTED     = hex2dec('00000001') % LSB is set if a device is connected
        STATUS_DEV_OPENED        = hex2dec('00000002') % set if the device is opened
        STATUS_SWP_ACTIVE        = hex2dec('00000004') % set if the device is sweeping
        STATUS_SWP_UP            = hex2dec('00000008') % set if the device is sweeping up in frequency
        STATUS_SWP_REPEAT        = hex2dec('00000010') % set if the device is in continuous sweep mode
        STATUS_SWP_BIDIRECTIONAL = hex2dec('00000020') % set if the device is in bidirectional sweep mode
        STATUS_PLL_LOCKED        = hex2dec('00000040') % set if the PLL lock status is TRUE (both PLL's are locked)
        STATUS_FAST_PULSE_OPTION = hex2dec('00000080') % set if the fast pulse mode option is installed
    end % end private properties
    
    % Device properties correspond to instrument parameters
    properties (Access = public)
        output
        frequency
        power
        phase
        mod
        alc
        pulse
        pulseSource = 'ext';
        
        pllLocked;
        
        % device specific
        refSource
    end % end device properties
    
    methods
        %Constructor
        function obj = Labbrick()
            % load DLL
            % build library path
            path = [fileparts(mfilename('fullpath')) filesep];
            if ~libisloaded('vnx_fmsynth')
                loadlibrary([path 'vnx_fmsynth.dll'], [path 'vnx_fmsynth.h']);
                calllib('vnx_fmsynth', 'fnLMS_SetTestMode', false);
            end
        end

        %Destructor
        function delete(obj)
            if ~isempty(obj.devID)
                obj.disconnect();
            end
        end
        
        % open the connection to the Labbrick with the given serial number
        function connect(obj, serial)
            if ~isnumeric(serial)
                serial = str2double(serial);
            end
            obj.serialNum = serial;
            
            % find the devID of the Labbrick with the given serial number
            [devIDs, serial_nums] = obj.enumerate();
            obj.devID = devIDs(serial_nums == serial);
            if isempty(obj.devID)
                error('Could not find a Labbrick with serial %i', serial);
            end
            status = calllib('vnx_fmsynth', 'fnLMS_InitDevice', obj.devID);
            if status ~= 0
                error('Could not open device with id: %i, returned error %i', [obj.devID status])
            end
            
            % populate some device properties
            obj.open = 1;
            obj.max_power = calllib('vnx_fmsynth', 'fnLMS_GetMaxPwr', obj.devID) / 4;
            obj.min_power = calllib('vnx_fmsynth', 'fnLMS_GetMinPwr', obj.devID) / 4;
            obj.max_freq = calllib('vnx_fmsynth', 'fnLMS_GetMaxFreq', obj.devID) / 1e8;
            obj.min_freq = calllib('vnx_fmsynth', 'fnLMS_GetMinFreq', obj.devID) / 1e8;
        end
        
        function disconnect(obj)
            if obj.open
                status = calllib('vnx_fmsynth', 'fnLMS_CloseDevice', obj.devID);
                if status ~= 0
                    warning('LABBRICK:DISCONNECT', ...
                        'Error closing device id: %i, returned status: %i.', [obj.devID, status]);
                end
            obj.open = 0;
            end
        end
        
        function flag = get_dev_status(obj, status_code)
           val = calllib('vnx_fmsynth', 'fnLMS_GetDeviceStatus', obj.devID);
           flag = (bitand(val, status_code) == status_code);
        end
        
        % get a list of connected Labbricks
        % NB: There is a bug in the Labbrick DLL that causes
        % fnLMS_GetDevInfo to only return device IDs in order until it
        % encounters an opened device. Device IDs seem to be assigned in
        % serial number order, so for example, if you open 1690 (devID = 1), then a
        % device with serial number 1691 (devID = 2) will not show up in a subsequent
        % call to fnLMS_GetDevInfo. To deal with this, we store the IDs and
        % serial numbers in persistent variables, and only update them if
        % these lists are empty or if the number of connected devices
        % increases
        function [ids, serials] = enumerate(obj)
            persistent previous_num_devices devIDs serial_nums
            if isempty(previous_num_devices)
                previous_num_devices = 0;
            end
            
            %num_devices = calllib('vnx_fmsynth','fnLMS_GetNumDevices');
            
            %if (num_devices > previous_num_devices) || isempty(devIDs)
            if isempty(devIDs)
                num_devices = calllib('vnx_fmsynth','fnLMS_GetNumDevices');
                devIDs = zeros(1, num_devices);
                serial_nums = zeros(1, num_devices);
                [~, devIDs] = calllib('vnx_fmsynth', 'fnLMS_GetDevInfo', devIDs);
                for i = 1:num_devices
                    id = devIDs(i);
                    serial_nums(i) = calllib('vnx_fmsynth', 'fnLMS_GetSerialNumber', id);
                end
                previous_num_devices = num_devices;
            end
            %previous_num_devices = num_devices;
            ids = devIDs;
            serials = serial_nums;
        end
        
        % get model name
        function name = model_name(obj)
            [~, obj.model] = calllib('vnx_fmsynth', 'fnLMS_GetModelName', obj.devID, '          ');
            name = obj.model;
        end
		
		% Instrument parameter accessors
        % getters
        function val = get.frequency(obj)
            % returns frequency in 10s of Hz
            val = calllib('vnx_fmsynth', 'fnLMS_GetFrequency', obj.devID) * 10;
            % convert to GHz
            val = val/1e9;
        end
        function val = get.power(obj)
            % returns power as attenuation from the max output power, in an integer multiple of 0.25dBm.
            attenuation = calllib('vnx_fmsynth', 'fnLMS_GetPowerLevel', obj.devID) / 4;
            val = obj.max_power - attenuation;
        end

        function val = get.output(obj)
            val = calllib('vnx_fmsynth', 'fnLMS_GetRF_On', obj.devID);
        end
        function val = get.mod(obj)
            % not supported by the hardare
            val = 0;
        end

        function val = get.pulse(obj)
            % warning, driver only returns information about whether internal
            % pulse mode is active
            if strcmp(obj.pulseSource, 'int')
                val = calllib('vnx_fmsynth', 'fnLMS_GetPulseMode', obj.devID);
            else
                val = obj.pulseModeEnabled;
            end
        end
        function val = get.pulseSource(obj)
            devVal = calllib('vnx_fmsynth', 'fnLMS_GetUseInternalPulseMod', obj.devID);
            %if val == false, val = 'int'; end
            %if val == true, val = 'ext'; end
            val = obj.pulseSource;
        end
        
        function val = get.refSource(obj)
            val = calllib('vnx_fmsynth', 'fnLMS_GetUseInternalRef', obj.devID);
            if val == true, val = 'int'; end
            if val == false, val = 'ext'; end
        end
        
        function val = get.pllLocked(obj)
            val = obj.get_dev_status(obj.STATUS_PLL_LOCKED);
        end
        
        % property setters
        function obj = set.frequency(obj, value)
            % value: frequency to set in GHz
            
            % error check that the frequency is within the bounds of
            % the device
            if value > obj.max_freq
                value = obj.max_freq;
                warning('Frequency out of range');
            elseif value < obj.min_freq
                value = obj.min_freq;
                warning('Frequency out of range');
            end
            
            % write frequency in 10s of Hz
            calllib('vnx_fmsynth', 'fnLMS_SetFrequency', obj.devID, value*1e8);
        end
        function obj = set.power(obj, value)
            % error check power level within bounds of the device
            if value > obj.max_power
                value = obj.max_power;
                warning('Power out of range');
            elseif value < obj.min_power
                value = obj.min_power;
                warning('Power out of range');
            end
            
            % write power as a multiple of 0.25dBm
            value = int32(value*4);
            %fprintf('Writing value %i\n', value);
            calllib('vnx_fmsynth', 'fnLMS_SetPowerLevel', obj.devID, value);
        end
        function obj = set.output(obj, value)
            % don't know why I need them, but without the pause commands
            % the SetRFOn command is occasionally ignored
            pause(0.1);
            calllib('vnx_fmsynth', 'fnLMS_SetRFOn', obj.devID, obj.cast_boolean(value));
            pause(0.1);
        end

        function obj = set.mod(obj, ~)
            %not supported by hardware
        end
        
        function obj = set.pulse(obj, value)
            obj.pulseModeEnabled = obj.cast_boolean(value);
            
            switch obj.pulseSource
                case 'int'
                    calllib('vnx_fmsynth', 'fnLMS_SetUseExternalPulseMod', obj.devID, false);
                    calllib('vnx_fmsynth', 'fnLMS_EnableInternalPulseMod', obj.devID, obj.pulseModeEnabled);
                case 'ext'
                    calllib('vnx_fmsynth', 'fnLMS_EnableInternalPulseMod', obj.devID, false);
                    calllib('vnx_fmsynth', 'fnLMS_SetUseExternalPulseMod', obj.devID, obj.pulseModeEnabled);
                otherwise
                    disp('Labbrick: Unknown pulse source');
            end
        end
        function obj = set.pulseSource(obj, value)            
            % Validate input
            value = lower(value);
            checkMapObj = containers.Map({'int','internal','ext','external'},...
                {false,false,true,true});
            if not (checkMapObj.isKey(value))
                error('Invalid input');
            end
            if checkMapObj(value)
                obj.pulseSource = 'ext';
            else
                obj.pulseSource = 'int';
            end
            
            if obj.pulseModeEnabled
                obj.pulse = 1; % set the pulse parameter to update the device
            end
        end
        
        function obj = set.refSource(obj, value)
            % Validate input
            checkMapObj = containers.Map({'int','internal','ext','external'},...
                {true,true,false,false});
            if not (checkMapObj.isKey( lower(value) ))
                error('Invalid input');
            end
            
            calllib('vnx_fmsynth', 'fnLMS_SetUseInternalRef', obj.devID, checkMapObj(lower(value)));
          
            if (strncmpi(value,'ext', 3) )
              % test for PLL lock
              retries = 0;
              while (~obj.pllLocked && (retries < obj.MAX_RETRIES))
                retries = retries + 1;
                pause(0.5);
              end
              if (~obj.pllLocked) 
                  error('Labbrick PLL is not locked');
              end
            end
        end
    end % end instrument parameter accessors
    
    methods (Static)
       
        %Helper function to cast boolean inputs to 'on'/'off' strings
        function out = cast_boolean(in)
            if isnumeric(in)
                out = logical(in);
            elseif ischar(in)
                checkMapObj = containers.Map({'on','1','off','0'},...
                    {true, true, false, false});
                assert(checkMapObj.isKey(lower(in)), 'Invalid input');
                out = checkMapObj(lower(in));
            elseif islogical(in)
                out = in;
            else
                error('Unable to cast to boolean');
            end
        end
        
    end
    
end % end class definition
