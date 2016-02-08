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
% File: AgilentE3631A.m
% Author: Evan Walsh (evanwalsh@seas.harvard.edu)
%
% Description: Instrument driver for the Agilent E3631A Triple Output DC
% Power Supply
% 
classdef AgilentE3631A < deviceDrivers.lib.GPIB
    
    properties
        P6V_Voltage
        P6V_Current
        P25V_Voltage
        P25V_Current
        N25V_Voltage
        N25V_Current
        output
    end
    
    methods
        function obj = AgilentE3631A()
        end        

        %Get voltage from +6V source
        function val = get.P6V_Voltage(obj)
            obj.write('INST P6V')
            val=str2double(obj.query('MEAS?'));
        end
        
        %Get voltage from +25V source
        function val = get.P25V_Voltage(obj)
            obj.write('INST P25V')
            val=str2double(obj.query('MEAS?'));
        end
        
        %Get voltage from -25V source
        function val = get.N25V_Voltage(obj)
            obj.write('INST N25V')
            val=str2double(obj.query('MEAS?'));
        end
        
        %Get current from +6V source
        function val = get.P6V_Current(obj)
            obj.write('INST P6V')
            val=str2double(obj.query('MEAS:CURR?'));
        end
        
        %Get voltage from +25V source
        function val = get.P25V_Current(obj)
            obj.write('INST P25V')
            val=str2double(obj.query('MEAS:CURR?'));
        end
        
        %Get voltage from -25V source
        function val = get.N25V_Current(obj)
            obj.write('INST N25V')
            val=str2double(obj.query('MEAS:CURR?'));
        end
        
        %Get output state (0 (off) or 1 (on))
        function val = get.output(obj)
            val = str2double(obj.query('OUTP?'));
        end
        
        %Set voltage for +6V source
        function set.P6V_Voltage(obj,value)
            obj.write('INST P6V')
            obj.write('VOLT %G',value)
        end
        
        %Set voltage for +25V source
        function set.P25V_Voltage(obj,value)
            obj.write('INST P25V')
            obj.write('VOLT %G',value)
        end
        
        %Set voltage for -25V source
        function set.N25V_Voltage(obj,value)
            obj.write('INST N25V')
            obj.write('VOLT %G',value)
        end
        
        %Set current for +6V source
        function set.P6V_Current(obj,value)
            obj.write('INST P6V')
            obj.write('CURR %G',value)
        end
        
        %Set current for +25V source
        function set.P25V_Current(obj,value)
            obj.write('INST P25V')
            obj.write('CURR %G',value)
        end
        
        %Set current for -25V source
        function set.N25V_Current(obj,value)
            obj.write('INST N25V')
            obj.write('CURR %G',value)
        end
        
        %Set output state (0 (off) or 1 (on))
        function set.output(obj,value)
            obj.write('OUTP %G',value);
        end
        

        end
end
