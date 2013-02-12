% Module Name : DigitalAttenuator
%
% Author/Date : Blake R. Johnson
%
% Description : Object to manage access to the BBN simple spectrum
% analyzer. Borrows most of its code from the DigitalAttenuator driver.

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

classdef (Sealed) SpectrumAnalyzer < deviceDrivers.lib.Serial
    properties
        serial = 0; % ID of the device to distinguish multiple instances
    end
    
    methods
        
        function obj = SpectrumAnalyzer()
            % Initialize Super class
            obj = obj@deviceDrivers.lib.Serial();
            obj.baudRate = 9600;
        end
        
        function out = readUntilEND(obj)
            %readUntilEND - Reads from the Arduino until it receives 'END'
            out = '';
            val = obj.read();
            while (strcmp(val, 'END') == 0)
                out = [out val];
                val = obj.read();
            end
        end
        
        function val = get.serial(obj)
            % poll device for its serial number
            obj.write('ID?');
            val = obj.readUntilEND();
            val = str2double(val);
            obj.serial = val;
        end

        function out = getVoltage(obj)
            % error check inputs
            obj.write('READ');
            out = obj.readUntilEND();
        end

    end % Methods
    
end % Class