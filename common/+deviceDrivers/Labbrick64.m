% Labbrick microwave source driver
%
% Author(s): Blake Johnson
% Date created: April 1, 2013

% Copyright 2013 Raytheon BBN Technologies
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
classdef (Sealed) Labbrick64 < deviceDrivers.lib.uWSource

    properties (Access = private)
        hid;
        open = 0;
        serialNum = 1;
        model = 'LMS-103';
    end
    
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
        
        % device specific
        freq_reference
    end % end device properties

    properties (Constant = true)
        vendor_id = sscanf('0x041f', '%i');
        product_id = sscanf('0x1220', '%i'); %0x1209 for LSG-451
        max_power = 10; % dBm
        min_power = -40; % dBm
        max_freq = 10; % GHz
        min_freq = 5; % GHz
    end
    
    methods
        %Constructor
        function obj = Labbrick64()
            % load DLL
            % build library path
            base_path = fileparts(mfilename('fullpath'));
            if ~libisloaded('hidapi')
                loadlibrary(fullfile(base_path, 'hidapi.dll'), fullfile(base_path, 'hidapi.h'));
            end
        end

        %Destructor
        function delete(obj)
            if ~isempty(obj.devID)
                obj.disconnect();
            end
        end
        
        % open the connection to the Labbrick with the given serial number
        function connect(obj, serialNum)
            obj.serialNum = serialNum;
            
            % check that the device exists
%             serial_nums = obj.enumerate();
%             if ~any(serial_nums == serialNum)
%                 error('Could not find a Labbrick with serial %i', serialNum);
%             end
%             obj.hid = calllib('hidapi', 'hid_open', obj.vendor_id, obj.product_id, uint16[serialNum 0]));
            obj.hid = calllib('hidapi', 'hid_open', obj.vendor_id, obj.product_id, []);
            if obj.hid.isNull
                error('Could not open device serial %s', serialNum);
            end
            
            obj.open = 1;
        end
        
        function disconnect(obj)
            if obj.open
                calllib('hidapi', 'hid_close', obj.hid);
                obj.hid = [];
            end
            obj.open = 0;
        end
        
        % get a list of connected Labbricks
        function serials = enumerate(obj)
            
            serials = {};
%             device_info = calllib('hidapi', 'hid_enumerate', obj.vendor_id, obj.product_id);
            device_info = calllib('hidapi', 'hid_enumerate', 0, 0);
            cur_device = device_info;
            
            while ~cur_device.isNull
                serials = [serials cur_device.value.serial_number];
                cur_device = cur_device.value.next;
            end

            calllib('hidapi', 'hid_free_enumeration', device_info);
        end

        function out = read(obj)
            read_buffer = zeros(1, 256, 'uint8');
            timeout = 100; % timeout in milliseconds
            [success, hid, out] = calllib('hidapi', 'hid_read_timeout', obj.hid, read_buffer, length(read_buffer), timeout);
        end

        function write(obj, val)
            report = uint8([0 val]);
            calllib('hidapi', 'hid_write', obj.hid, report, length(report));
        end

        function out = query(obj, val)
            obj.write(val);
            out = obj.read();
        end
		
		% Instrument parameter accessors
        % getters
        function val = get.frequency(obj)
            % returns frequency in 10s of Hz
            cmd_id = 4;
            report = [cmd_id zeros(7.1)];
            result = typecast(obj.query(report), 'uint32');
            % return value is in 10's of Hz -> convert to GHz
            val = double(result)/1e8;
        end
        function val = get.power(obj)
            % returns power as attenuation from the max output power, in an integer multiple of 0.25dBm.
            cmd_id = 13;
            report = [cmd_id zeros(7,1)];
%             attenuation = str2double(obj.query(report)) / 4;
%             val = obj.max_power - attenuation;
            val = obj.query(report);
        end

        function val = get.output(obj)
            cmd_id = 10;
            report = [cmd_id zeros(7,1)];
            val = obj.query(report);
        end
        
        function obj = set.frequency(obj, value)
            % value: frequency to set in GHz
            cmd_id = 132;
            cmd_size = 4;
            
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
            value = typecast(uint32(value*1e8), 'uint8'); % pack as 4 bytes
            report = [cmd_id cmd_size value zeros(1,2)];
            obj.write(report);
        end

        function obj = set.power(obj, value)
            cmd_id = 141;
            cmd_size = 1;
            % error check power level within bounds of the device
            if value > obj.max_power
                value = obj.max_power;
                warning('Power out of range');
            elseif value < obj.min_power
                value = obj.min_power;
                warning('Power out of range');
            end
            
            % write power as a multiple of 0.25dBm
            value = uint8(value*4);
            report = [cmd_id cmd_size value zeros(1,5)];
            obj.write(report);
        end

        function obj = set.output(obj, value)
            cmd_id = 138;
            cmd_size = 1;
            
            % Validate input
            if isnumeric(value)
                value = num2str(value);
            end
            valueMap = containers.Map({'on','1','off','0'},...
                {uint8(1), uint8(1), uint8(0), uint8(0)});
            if not (valueMap.isKey( lower(value) ))
                error('Invalid input');
            else
                value = valueMap(lower(value));
            end

            report = [cmd_id cmd_size value zeros(1,5)];
            obj.write(report);
        end
    end
    
    
end
