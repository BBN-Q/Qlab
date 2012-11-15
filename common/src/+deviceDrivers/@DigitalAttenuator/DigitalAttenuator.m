%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Class DIGITALATTENUATOR manages access to the BBN digital attenuator.

% Author/Date : Blake R. Johnson 6/10/2011

% Copyright 2012 Raytheon BBN Technologies
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

classdef (Sealed) DigitalAttenuator < deviceDrivers.lib.Serial
    properties
        ComPortName = '';
        serial = 0; % ID of the device to distinguish multiple instances
    end
    properties (Constant = true)
        MAX_CHANNELS  =  3;
        MAX_VALUE = 31.5;  % maximum attenuation value
        MIN_VALUE = 0; % minimum attenuation value
    end
    methods
        function obj = DigitalAttenuator()
            % Initialize Super class
            obj = obj@deviceDrivers.lib.Serial();
            obj.baudRate = 9600;
        end
        
        function setAll(obj,init_params)
            % setAll is called as part of the Experiment initialize instruments
        end
        
        function out = readUntilEND(obj)
            % readUntilEND
            % Reads from the Arduino until it receives 'END'
            out = '';
            val = obj.read();
            while (strcmp(val, 'END') == 0)
                out = [out val];
                val = obj.read();
            end
        end
        
        function val = get.serial(obj)
            % poll device for its serial number
            obj.write('ID?;');
            val = obj.readUntilEND();
            val = str2double(val);
            obj.serial = val;
        end
        
        function setAttenuation(obj, channel, value)
            % error check inputs
            if (channel < 1 || channel > obj.MAX_CHANNELS)
                error('DigitalAttenuator:setAttenuation:channel', 'Invalid channel number %d', channel);
            end
            if (value < obj.MIN_VALUE)
                value = obj.MIN_VALUE;
            end
            if (value > obj.MAX_VALUE)
                value = obj.MAX_VALUE;
            end
            
            cmd = sprintf('SET %d %.1f', [channel value]);
            obj.write(cmd);
            obj.readUntilEND();
        end
        
        function out = getAttenuation(obj, channel)
            % error check inputs
            if (channel < 1 || channel > obj.MAX_CHANNELS)
                error('DigitalAttenuator:getAttenuation:channel', 'Invalid channel number %d', channel);
            end
            cmd = sprintf('GET %d', channel);
            obj.write(cmd);
            out = obj.readUntilEND();
        end

        function zeroAll(obj)
            % zeroAll sets all channels to zero attenuation
            for channel=1:obj.MAX_CHANNEL
                obj.setAttenuation(channel, 0);
            end
        end
        
        function pendingArduino(obj)
            % pendingArduino - clear the serial interface
            if ( obj.interface.BytesAvailable > 0)
                rv = obj.read();
                if (~isempty(rv))
                    warning('DigitalAttenuator:pendingArduino:Data','%s\n', rv);
                end
            end
        end
        

    end % Methods
    
end % Class