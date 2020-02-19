% Copyright 2016 Raytheon BBN Technologies
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
%
% File: Keysight34410A.m
% Authors: Evan Walsh (evanwalsh@seas.harvard.edu)
%
% Description: Instrument driver for the Keysight 34410A DMM.
% 
classdef Keysight34410A < deviceDrivers.lib.GPIB
    
    properties
        CurrentRange
        VoltageRange
        mode
        NPLC
        value
    end
    
    methods
        function obj = Keysight34410A()
        end
        
        function Trigger(obj)
            obj.write(':TRIGger:COUNt 1');
        end
        
        function Initiate(obj)
            obj.write(':INITiate');
        end

        %get value (voltage or current) regardless of mode
        function val = get.value(obj)
            val=str2num(obj.query(':READ?'));            
        end
        
        %get mode
        function val = get.mode(obj)
            val = strtrim(obj.query(':SENS:FUNCTION?'));
        end
                
        %get NPLC
        function val = get.NPLC(obj)
            modestr = strtrim(obj.query(':SENS:FUNCTION?'));
            if strcmp(modestr,'"VOLT"') || strcmp(modestr,'"VOLT:AC"')
                val = str2double(obj.query('SENS:VOLT:NPLC?'));
            elseif strcmp(modestr,'"CURR"') || strcmp(modestr,'"CURR:AC"')
                val = str2double(obj.query('SENS:CURR:NPLC?'));
            end
        end
        
        % get current range
        function val = get.CurrentRange(obj)
            val = str2num(obj.query('SENSE:CURR:RANGE?'));
        end
        
        % get voltage range
        function val = get.VoltageRange(obj)
            val = str2num(obj.query('SENSE:VOLT:RANGE?'));
        end
        
        %set mode
        function obj = set.mode(obj, mode)
            valid_modes = {'CURRENT', 'CURR', 'CURRENT:AC', 'CURR:AC', 'VOLTAGE', 'VOLT','VOLTAGE:AC','VOLT:AC'};
            if ~ismember(mode, valid_modes)
                error('Invalid mode');
            end
            obj.write(['SENSE:FUNCTION "' mode '"']);
        end
                    
        % place in DC current source mode
        function DCCurrentMode(obj)
            obj.write('SENSE:FUNCTION "CURR"');
        end
        
        % place in AC current source mode
        function ACCurrentMode(obj)
            obj.write('SENSE:FUNCTION "CURR:AC"');
        end
        
        % set current range
        function set.CurrentRange(obj, value)
            % Validate input
            assert(isnumeric(value), 'Invalid input');
            obj.write(sprintf('SENSE:CURR:RANGE %G;',value));
        end
                
        %place in AC voltage source mode
        function DCVoltageMode(obj)
            obj.write('SENSE:FUNCTION "VOLT"');
        end
        
        %place in AC voltage source mode
        function ACVoltageMode(obj)
            obj.write('SENSE:FUNCTION "VOLT:AC"');
        end
        
        %Set voltage range
        function set.VoltageRange(obj, value)
            % Validate input
            assert(isnumeric(value), 'Invalid input');
            obj.write(sprintf('SENSE:VOLT:RANGE %G;',value));
        end
                
        function set.NPLC(obj,value)
            if ~isnumeric(value) || value<.006 || value>100
                error('Invalid input')
            end
            
            modestr = strtrim(obj.query(':SENS:FUNCTION?'));
            if strcmp(modestr,'"VOLT"') || strcmp(modestr,'"VOLT:AC"')
                obj.write('SENS:VOLT:NPLC %G',value);
            elseif strcmp(modestr,'"CURR"') || strcmp(modestr,'"CURR:AC"')
                obj.write('SENS:CURR:NPLC %G',value);
            end
        end
        
    end
end