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
%
% File: Kiethly2400.m
% Author: Jesse Crossno (Crossno@seas.harvard.edu)
%
% Description: Instrument driver for the Kiethly 2400 sourcemeter.
% 
classdef Keithley2400 < deviceDrivers.lib.GPIB
    
    properties
        CurrentLimit
        VoltageLimit
        Voltage
        Current
        CurrentRange
        VoltageRange
        Measure
    end
    
    methods
        function obj = Keithley2400()
        end        

        % place in current source mode
        function CurrentMode(obj)
            obj.write(':SOUR:FUNC CURR;');
            obj.write(':SOUR:CURR:MODE FIX;');
        end
        
        % set current range
        function set.CurrentRange(obj, value)
            % Validate input
            assert(isnumeric(value), 'Invalid input');
            obj.write(sprintf(':SOUR:CURR:RANGE %G;',value));
        end
        
        % set current
        function set.Current(obj, value)
            % Validate input
            assert(isnumeric(value), 'Invalid input');
            obj.write(sprintf(':SOUR:CURR:LEV:IMM:AMPL %G;',value));
            obj.write(':OUTP ON');
        end
        
        % set current protection
        function set.CurrentLimit(obj, value)
            % Validate input
            assert(isnumeric(value), 'Invalid input');
            obj.write(sprintf(':SENS:CURR:PROT: %G;',value));
        end
        
        %place in voltage source mode
        function VoltageMode(obj)
            obj.write(':SOUR:FUNC VOLT;');
            obj.write(':SOUR:VOLT:MODE FIX;');
        end
        
        %Set voltage range
        function set.VoltageRange(obj, value)
            % Validate input
            assert(isnumeric(value), 'Invalid input');
            obj.write(sprintf(':SOUR:VOLT:RANGE %G;',value));
        end
        
        % set voltage
        function set.Voltage(obj, value)
            % Validate input
            assert(isnumeric(value), 'Invalid input');
            obj.write(sprintf(':SOUR:VOLT:LEV:IMM:AMPL %G;',value));
            obj.write(':OUTP ON');
        end
        
        % set voltage protection
        function set.VoltageLimit(obj, value)
            % Validate input
            assert(isnumeric(value), 'Invalid input');
            obj.write(sprintf(':SENS:VOLT:PROT %G;',value));
        end
        
        % Measure Current, Voltage, and Resistance
        function EnableAllMeasure(obj)
            obj.write(':SENS:FUNC:CONC ON;');
            obj.write(':SENS:FUNC:ON:ALL;');
        end
        
        % Turn current measurement on
        function EnableCurrentMeasure(obj)
            obj.write(':SENS:FUNC:CONC OFF;');
            obj.write(':SENS:FUNC "CURR:DC";');
        end
        
        % Turn voltage measurement on
        function EnableVoltageMeasure(obj)
            obj.write(':SENS:FUNC:CONC OFF;');
            obj.write(':SENS:FUNC "VOLT:DC";');
        end
        
        % Turn resistance measurement on
        function EnableResistanceMeasure(obj)
            obj.write(':SENS:FUNC:CONC OFF;');
            obj.write(':SENS:FUNC "RES:DC";');
        end
        
        %Turn all measurements OFF
        function DisableAllMeasure(obj)
            obj.write(':SENS:FUNC:OFF:ALL;');
        end
        
        % read out channel B temperature
        function val = get.Measure(obj)
            tmp = obj.query(':READ?;');
            val = tmp(1:2);
        end
    end
end
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    