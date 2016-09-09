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
% File: HP8153A.m
% Authors: Evan Walsh (evanwalsh@seas.harvard.edu)
% February 2016
%
% Description: Instrument driver for the HP 8153A Lightwave Multimeter.

classdef HP8153A < deviceDrivers.lib.GPIB
    
    
    properties
       wavelength %detection wavelength in nanometers
       avg_time %averaging time
    end
    
    methods
        function obj = HP8153A()
        end        

        %get averaging time
        function val = get.avg_time(obj)
            val=str2num(obj.query(':SENS2:POW:ATIME?'));
        end
        
        function val = get.wavelength(obj)
            val=str2num(obj.query(':SENS2:POW:WAVE?'))/10^-9;
        end
        
        function val=value(obj)
            val=str2num(obj.query(':READ2:POW?'));
        end
        
         %set averaging time
        function obj = set.avg_time(obj, value)
            obj.write([':SENS2:POW:ATIME ' num2str(value) 'S']);
        end
        
        function obj = set.wavelength(obj, value)
            obj.write([':SENS2:POW:WAVE ' num2str(value) 'NM']);
        end
        
    end
    
end