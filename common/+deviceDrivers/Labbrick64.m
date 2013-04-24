% Labbrick microwave source driver for 64-bit windows
% Vaunix is yet to supply a 64-bit driver, so we make use of some reverse
% engineering done by special-measure (http://code.google.com/p/special-measure)
% to manually maninpulate the device through the USB byte stream. At this
% time only a limited subset of commands are supported (output, power, and
% frequency).

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
        hid
        open = 0;
        serialNum
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
    end

    properties (Constant = true)
        vendor_id = sscanf('0x041f', '%i');
        product_id = sscanf('0x1220', '%i'); %0x1221 for LMS-802 or 0x1209 for LSG-451

        % CMD IDs
        POWER_CMD = sscanf('0x0D', '%i');
        OUTPUT_CMD = sscanf('0x0A', '%i');
        FREQ_CMD = sscanf('0x44', '%i');

        SET_BYTE = 8;

        max_power = 10; % dBm
        min_power = -40; % dBm
        max_freq = 10; % GHz
        min_freq = 5; % GHz
    end
    
    methods
        function obj = Labbrick64()
            % load DLL
            base_path = fileparts(mfilename('fullpath'));
            if ~libisloaded('hidapi')
                loadlibrary(fullfile(base_path, 'hidapi.dll'), fullfile(base_path, 'hidapi.h'));
            end
        end

        function delete(obj)
            if ~isempty(obj.hid)
                obj.disconnect();
            end
            % cleanup the HID driver
            calllib('hidapi', 'hid_exit');
            unloadlibrary('hidapi');
        end
        
        % open the connection to the Labbrick with the given serial number
        function connect(obj, serialNum)
            obj.serialNum = serialNum;
            
            % check that the device exists
            serial_nums = obj.enumerate();
            if ~any(strcmp(serial_nums, serialNum))
                error('Could not find a Labbrick with serial %i', serialNum);
            end
            obj.hid = calllib('hidapi', 'hid_open', obj.vendor_id, obj.product_id, uint16(['SN:0' serialNum 0]));
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
            
            while ~isempty(cur_device) && ~cur_device.isNull
                snum = cur_device.value.serial_number;
                setdatatype(snum, 'uint16Ptr', 8);
                serials = [serials char(snum.value(5:end)')];
                cur_device = cur_device.value.next;
                if ~isempty(cur_device)
                    setdatatype(cur_device, 'hid_device_infoPtr');
                end
            end

            calllib('hidapi', 'hid_free_enumeration', device_info);
        end

        function out = read(obj)
            read_buffer = zeros(1, 256, 'uint8');
            timeout = 100; % timeout in milliseconds
            [bytesread, ~, out] = calllib('hidapi', 'hid_read_timeout', obj.hid, read_buffer, length(read_buffer), timeout);
            out = out(1:bytesread);
        end

        function write(obj, val)
            report = uint8([0 val]);
            calllib('hidapi', 'hid_write', obj.hid, report, length(report));
            pause(0.02);
        end

        function out = query(obj, val)
            obj.write(val);
            cmd_id = val(1);
            out = obj.read();
            ct = 1;
            % keep trying to read until the return block starts with the
            % cmd id
            while (out(1) ~= cmd_id && ct < 128)
                out = obj.read();
                ct = ct + 1;
            end
            if ct == 256
                error('No result found with matching cmd id');
            end
        end
        
        function save_settings(obj)
            % saves current settings
            cmd_id = 140;
            cmd_size = 3;
            report = [cmd_id cmd_size 66 85 49 zeros(1,3)];
            obj.write(report);
        end
		
		% Instrument parameter accessors
        function val = get.frequency(obj)
            cmd_id = obj.FREQ_CMD;
            report = [cmd_id zeros(1,7)];
            result = obj.query(report);
            % return value is in 10's of Hz -> convert to GHz
            val = double(typecast(result(3:6), 'uint32'))*1e-8;
        end
        function val = get.power(obj)
            % returns power as attenuation from the max output power, in integer multiples of 0.25dBm.
            cmd_id = obj.POWER_CMD;
            report = [cmd_id zeros(1,7)];
            result = obj.query(report);
            attenuation = double(result(3)) / 4;
            val = obj.max_power - attenuation;
        end

        function val = get.output(obj)
            cmd_id = obj.OUTPUT_CMD;
            report = [cmd_id zeros(1,7)];
            result = obj.query(report);
            val = result(3);
        end
        
        function obj = set.frequency(obj, value)
            % value: frequency to set in GHz
            cmd_id = bitset(obj.FREQ_CMD, obj.SET_BYTE);
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
            check_value = value;
            
            % write frequency in 10s of Hz
            value = typecast(uint32(value*1e8), 'uint8'); % pack as 4 bytes
            report = [cmd_id cmd_size value zeros(1,2)];
            obj.write(report);
            freq_diff = obj.frequency - check_value;
            assert(freq_diff < 1e-8 + eps, 'Failed to set frequency. Found frequency %f', freq_diff+check_value);
        end

        function obj = set.power(obj, value)
            cmd_id = bitset(obj.POWER_CMD, obj.SET_BYTE);
            cmd_size = 1;
            % error check power level within bounds of the device
            if value > obj.max_power
                value = obj.max_power;
                warning('Power out of range');
            elseif value < obj.min_power
                value = obj.min_power;
                warning('Power out of range');
            end
            check_value = value;
            
            % write power as attenuation from max power in increments of 0.25dBm
            value = uint8(4 * (obj.max_power - value));
            report = [cmd_id cmd_size value zeros(1,5)];
            obj.write(report);
            assert(obj.power == check_value, 'Failed to set power');
        end

        function obj = set.output(obj, value)
            cmd_id = bitset(obj.OUTPUT_CMD, obj.SET_BYTE);
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
            assert(obj.output == value, 'Failed to set output');
        end
    end
    
    
end
