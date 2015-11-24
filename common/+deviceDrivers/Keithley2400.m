% Copyright 2015 Raytheon BBN Technologies
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
% File: Kiethley2400.m
% Author: Jesse Crossno (crossno@seas.harvard.edu)
%
% Description: Instrument driver for the Kiethley 2400 sourcemeter.
% 
classdef Keithley2400 < deviceDrivers.lib.GPIB
    
    properties
        CurrentLimit
        VoltageLimit
        Voltage
        Current
        CurrentRange
        VoltageRange
    end
    
    methods
        function obj = Keithley2400()
        end        

        % place in current source mode
        function CurrentMode(obj)
            obj.write('SOURce:FUNC:MODE CURR;');
        end
        
        % set current range
        function set.CurrentRange(obj, value)
            % Validate input
            assert(isnumeric(value), 'Invalid input');
            obj.write(sprintf('SOURce:CURR:RANGE %G;',value));
        end
        
        % set current
        function set.Current(obj, value)
            % Validate input
            assert(isnumeric(value), 'Invalid input');
            obj.write(sprintf('SOURce:CURR:LEV:IMM:AMP %G;',value));
        end
        
        % set current protection
        function set.CurrentLimit(obj, value)
            % Validate input
            assert(isnumeric(value), 'Invalid input');
            obj.write(sprintf('SOURce:CURR:PROT:LEV %G;',value));
        end
        
        %place in voltage source mode
        function VoltageMode(obj)
            obj.write('SOURce:FUNC:MODE VOLT;');
        end
        
        %Set voltage range
        function set.VoltageRange(obj, value)
            % Validate input
            assert(isnumeric(value), 'Invalid input');
            obj.write(sprintf('SOURce:VOLT:RANGE %G;',value));
        end
        
        % set voltage
        function set.Voltage(obj, value)
            % Validate input
            assert(isnumeric(value), 'Invalid input');
            obj.write(sprintf('SOURce:VOLT:LEV:IMM:AMP %G;',value));
        end
        
        % set voltage protection
        function set.VoltageLimit(obj, value)
            % Validate input
            assert(isnumeric(value), 'Invalid input');
            obj.write(sprintf('SOURce:VOLT:PROT:LEV %G;',value));
        end
        
        % Measure Current, Voltage, and Resistance
        function EnableAllMeasure(obj)
            obj.write('SENS:FUNC:CONC ON;');
            obj.write('SENS:ON;ALL;');
        end
        
        % Turn current measurement on
        function EnableCurrentMeasure(obj)
            obj.write('SENS:ON; CURR;');
        end
        
        % Turn voltage measurement on
        function EnableVoltageMeasure(obj)
            obj.write('SENS:ON; VOLT;');
        end
        
        % Turn resistance measurement on
        function EnableResistanceMeasure(obj)
            obj.write('SENS:ON; RES;');
        end
        
        %Turn all measurements OFF
        function DisableAllMeasure(obj)
            obj.write('SENS:OFF:ALL;');
        end
        
        % read out channel B temperature
        function val = get.Measure(obj)
            tmp = obj.query('SENS:DATA:LAT?;');
            val = str2double(tmp);
        end
    end
end
