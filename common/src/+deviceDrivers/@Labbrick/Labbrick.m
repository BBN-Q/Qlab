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
classdef (Sealed) Labbrick < deviceDrivers.lib.deviceDriverBase
    % Class-specific constant properties
    properties (Constant = true)
        MAX_DEVICES = 64;
    end % end constant properties
    
    
    % Class-specific private properties
    properties (Access = private)
        devID = 1;
        serialNum = 1;
        model = 'LMS-103';
        max_power = 10; % dBm
        min_power = -40; % dBm
        max_freq = 10; % GHz
        min_freq = 5; % GHz
    end % end private properties
    
    
    % Class-specific public properties
    properties (Access = public)
        
    end % end public properties
    
    
    % Device properties correspond to instrument parameters
    properties (Access = public)
        output
        frequency
        power
        phase
        mod
        alc
        pulse
        pulseSource
        IQ
        IQ_Adjust
        IQ_IOffset
        IQ_QOffset
        IQ_Skew
        
        % device specific
        freq_reference
    end % end device properties
    
    % Class-specific private methods
    methods (Access = private)
        
    end % end private methods
    
    methods
        function obj = Labbrick()
            % load DLL
            % build library path
            script = java.io.File(mfilename('fullpath'));
            path = [char(script.getParent()) '\'];
            if ~libisloaded('vnx_fmsynth')
                [notfound warnings] = loadlibrary([path 'vnx_fmsynth.dll'], ...
                    [path 'vnx_fmsynth.h']);
                calllib('vnx_fmsynth', 'fnLMS_SetTestMode', false);
            end
        end

		% instrument meta-setter
		function setAll(obj, settings)
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
            fprintf('Connecting to devID %i\n', obj.devID);
            status = calllib('vnx_fmsynth', 'fnLMS_InitDevice', obj.devID);
            if status ~= 0
                error('Could not open device with id: %i, returned error %i', [obj.devID status])
            end
            
            % populate some device properties
            obj.max_power = calllib('vnx_fmsynth', 'fnLMS_GetMaxPwr', obj.devID) / 4;
            obj.min_power = calllib('vnx_fmsynth', 'fnLMS_GetMinPwr', obj.devID) / 4;
            obj.max_freq = calllib('vnx_fmsynth', 'fnLMS_GetMaxFreq', obj.devID) / 1e8;
            obj.min_freq = calllib('vnx_fmsynth', 'fnLMS_GetMinFreq', obj.devID) / 1e8;
        end
        
        function disconnect(obj)
            status = calllib('vnx_fmsynth', 'fnLMS_CloseDevice', obj.devID);
            if status ~= 0
                warning('LABBRICK:DISCONNECT', ...
                    'Error closing device id: %i, returned status: %i.', [obj.devID, status]);
            end
        end
        
        % get a list of connected Labbricks
        function [devIDs, serial_nums] = enumerate(obj)
            num_devices = calllib('vnx_fmsynth','fnLMS_GetNumDevices');
            
            devIDs = zeros(1, num_devices);
            serial_nums = zeros(1, num_devices);
            [~, devIDs] = calllib('vnx_fmsynth', 'fnLMS_GetDevInfo', devIDs);
            for i = 1:num_devices
                id = devIDs(i);
                serial_nums(i) = calllib('vnx_fmsynth', 'fnLMS_GetSerialNumber', id);
            end
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
        function val = get.phase(obj)
            % not supported by the hardware
            val = 0;
        end
        function val = get.output(obj)
            val = calllib('vnx_fmsynth', 'fnLMS_GetRF_On', obj.devID);
        end
        function val = get.mod(obj)
            % not supported by the hardare
            val = 0;
        end
        function val = get.alc(obj)
            % not supported by the hardware
            val = 0;
        end
        function val = get.pulse(obj)
            val = calllib('vnx_fmsynth', 'fnLMS_GetPulseMode', obj.devID);
        end
        function val = get.pulseSource(obj)
            val = calllib('vnx_fmsynth', 'fnLMS_GetUseInternalPulseMod', obj.devID);
            if val == false, val = 'int'; end
            if val == true, val = 'ext'; end
        end
        
        % IQ options not supported by the hardware
        function val = get.IQ(obj)
            val = 0;
        end
        function val = get.IQ_Adjust(obj)
            val = 0;
        end
        function val = get.IQ_IOffset(obj)
            val = 0;
        end
        function val = get.IQ_QOffset(obj)
            val = 0;
        end
        function val = get.IQ_Skew(obj)
            val = 0;
        end
        
        function val = get.freq_reference(obj)
            val = calllib('vnx_fmsynth', 'fnLMS_GetUseInternalRef', obj.devID);
            if val == true, val = 'int'; end
            if val == false, val = 'ext'; end
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
            if isnumeric(value)
                value = num2str(value);
            end
            
            % Validate input
            checkMapObj = containers.Map({'on','1','off','0'},...
                {true, true, false, false});
            if not (checkMapObj.isKey( lower(value) ))
                error('Invalid input');
            end

            calllib('vnx_fmsynth', 'fnLMS_SetRFOn', obj.devID, checkMapObj(value));
        end
        % set phase in degrees
        function obj = set.phase(obj, value)
            % not supported by hardware
        end
        function obj = set.mod(obj, value)
            %not supported by hardware
        end
        function obj = set.alc(obj, value)
        end
        
        function obj = set.pulse(obj, value)
            if isnumeric(value)
                value = num2str(value);
            end
            
            % Validate input
            checkMapObj = containers.Map({'on','1','off','0'},...
                {true, true, false, false});
            if not (checkMapObj.isKey( lower(value) ))
                error('Invalid input');
            end
            
            calllib('vnx_fmsynth', 'fnLMS_EnableInternalPulseMod', obj.devID, checkMapObj(value));
        end
        function obj = set.pulseSource(obj, value)            
            % Validate input
            checkMapObj = containers.Map({'int','internal','ext','external'},...
                {false,false,true,true});
            if not (checkMapObj.isKey( lower(value) ))
                error('Invalid input');
            end
            
            calllib('vnx_fmsynth', 'fnLMS_SetUseExternalPulseMod', obj.devID, checkMapObj(value));
        end
        function obj = set.IQ(obj, value)
        end
        
        function obj = set.IQ_Adjust(obj, value)
        end
        
        function obj = set.IQ_IOffset(obj, value)
        end
        
        function obj = set.IQ_QOffset(obj, value)
        end
        
        function obj = set.IQ_Skew(obj, value)
        end
        
        function obj = set.freq_reference(obj, value)
            % Validate input
            checkMapObj = containers.Map({'int','internal','ext','external'},...
                {true,true,false,false});
            if not (checkMapObj.isKey( lower(value) ))
                error('Invalid input');
            end
            
            calllib('vnx_fmsynth', 'fnLMS_SetUseInternalRef', obj.devID, checkMapObj(value));
        end
    end % end instrument parameter accessors
    
    
end % end class definition
