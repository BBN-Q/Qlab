% Holzworth multi-channel source driver
%
% Author: Blake Johnson

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

classdef HolzworthHS9000 < deviceDrivers.lib.deviceDriverBase & deviceDrivers.lib.uWSource
    properties (Access = public)
        serial % device serial number
        channel % channel (1-8)
        output
        frequency
        power
        phase
        mod = 0
        alc = -1
        pulse = -1
        pulseSource = -1
        ref = 'int' % (internal 100MHz) 'int', (external) '10MHz', or (external) '100MHz'
    end
    
    methods
        function obj = HolzworthHS9000()
            % if necessary, load the library
            if ~libisloaded('HolzworthMulti')
                libpath = fileparts(mfilename('fullpath'));
                
                switch computer()
                    case 'PCWIN64'
                        libfname = 'HolzworthMulti64.dll';
                        protoFile = @obj.HolzworthProto64;
                    case 'PCWIN'
                        libfname = 'HolzworthMulti.dll';
                        protoFile = @obj.HolzworthProto32;
                    otherwise
                        error('Your platform is not supported')
                end
                loadlibrary([libpath filesep libfname], protoFile, 'alias', 'HolzworthMulti');
            end
            
        end
        
        function delete(obj)
            obj.disconnect();
        end
        
        function connect(obj, address)
            % connect to an individual channel of a Holzworth9000
            % synthesizer
            % address strings are of the form:
            % <device name>-<serial>-<channel num>
            % e.g. HS9004A-009-1
            if ~isa(address, 'char')
                error('Device address must be a string')
            end
            [obj.serial, obj.channel] = obj.parseAddress(address);
            % check that the device is available
            if ~ismember(obj.serial, obj.unique_serials())
                error('Cannot find device with serial: %s')
            end
            success = calllib('HolzworthMulti', 'openDevice', obj.serial);
            if success ~= 0
                % Driver indicates trouble, but it is possible we have
                % another channel open. So, ignore it.
            end
        end
        
        function disconnect(obj)
            calllib('HolzworthMulti', 'close_all');
        end
        
        function devices = enumerate(obj)
            % this method is non-static because it depends on the DLL being
            % loaded
            deviceStr = calllib('HolzworthMulti', 'getAttachedDevices');
            % split result on commas
            devices = textscan(deviceStr, '%s', 'Delimiter', ',');
            devices = devices{1};
        end
        
        function out = unique_serials(obj)
            out = unique(cellfun(@obj.parseAddress, obj.enumerate(), 'UniformOutput', false));
        end
        
        function write(obj, varargin)
            % WRITE(channel, command) or WRITE(command)
            obj.query(varargin{:});
        end
        
        function out = query(obj, varargin)
            % QUERY(channel, command) or QUERY(command)
            if nargin == 3
                [ch, command] = varargin{:};
                if ~isa(ch, 'char')
                    ch = num2str(ch);
                    chString = [':CH' ch];
                else
                    chString = [':' ch];
                end
                out = calllib('HolzworthMulti', 'usbCommWrite', [obj.serial '-' ch], [chString command]);
            else
                command = varargin{1};
                out = calllib('HolzworthMulti', 'usbCommWrite', obj.serial, command);
            end
        end

        % property getters/setters
        function set.output(obj, output)
            if output == 1 || strcmpi(output, 'on')
                obj.write(obj.channel, ':PWR:RF:ON');
                obj.output = 1;
            elseif output == 0 || strcmpi(output, 'off')
                obj.write(obj.channel, ':PWR:RF:OFF');
                obj.output = 0;
            end
        end
        
        function out = get.output(obj)
            out = obj.query(obj.channel, ':PWR:RF?');
        end
        
        function set.frequency(obj, freq)
            obj.write(obj.channel, [':FREQ:' num2str(freq) 'Hz']);
            obj.frequency = freq;
        end
        
        function out = get.frequency(obj)
            % :FREQ? returns a string of the form XX.X MHz
            % so, we convert it to a numeric value in Hz
            freq = strtok(obj.query(obj.channel, ':FREQ?'));
            out = str2double(freq)*1e6;
        end
        
        function set.power(obj, power)
            obj.write(obj.channel, [':PWR:' num2str(power) 'dBm']);
            obj.power = power;
        end
        
        function out = get.power(obj)
            out = str2double(obj.query(obj.channel, ':PWR?'));
        end
        
        function set.phase(obj, phase)
            obj.write(obj.channel, [':PHASE:' num2str(freq) 'deg']);
            obj.phase = phase;
        end
        
        function out = get.phase(obj)
            out = str2double(obj.query(obj.channel, ':PHASE?'));
        end
        
        function set.mod(obj, mod)
            if mod == 1 || strcmpi(mod, 'on')
                obj.write(obj.channel, ':MOD:MODE:PULSE');
                obj.mod = 1;
            elseif mod == 0 || strcmpi(mod, 'off')
                obj.write(obj.channel, ':MOD:MODE:OFF');
                obj.mod = 0;
            end
        end
        
        function out = get.mod(obj)
            out = obj.query(obj.channel, ':MOD:MODE?');
        end
        
        function set.alc(obj, alc)
            % not supported by hardware
            obj.alc = alc;
        end
        
        function set.pulse(obj, pulse)
            % ignored, control with mod
            obj.pulse = pulse;
        end
    
        function set.pulseSource(obj, source)
            % always external, so ignored
            obj.pulseSource = source;
        end
        
        function set.ref(obj, ref)
            % allowed values for ref = (internal 100MHz) 'int', (external) '10MHz', or (external) '100MHz'
            switch upper(ref)
                case 'INT'
                    obj.write('REF', ':INT:100MHz');
                case '10MHZ'
                    obj.write('REF', ':EXT:10MHz');
                case '100MHZ'
                    obj.write('REF', ':EXT:100MHz');
                otherwise
                    error('Unrecognized reference: %s', ref);
            end
            obj.ref = ref;
        end

        function out = get.ref(obj)
            out = obj.query('REF', ':STATUS?');
        end
    end
    
    methods (Static)        
        %Reference prototype file for fast loading of shared library
        [methodinfo,structs,enuminfo,ThunkLibName]=HolzworthProto64
        [methodinfo,structs,enuminfo,ThunkLibName]=HolzworthProto32
        
        function [serial, channel] = parseAddress(str)
            [model, str] = strtok(str, '-');
            [serial, str] = strtok(str, '-');
            channel = str2double(strtok(str, '-'));
            % put model and serial number back together
            serial = [model '-' serial];
        end
    end
end