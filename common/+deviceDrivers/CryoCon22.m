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
% File: CryoCon22.m
% Author: Jesse Crossno (Crossno@seas.harvard.edu)
%
% Description: Instrument driver for the CryoCon 22 Temperature Controller.

classdef CryoCon22 < deviceDrivers.lib.GPIB
    
   properties
       temperatureA
       temperatureB
       loopTemperature
       overTemp
       pGain
       iGain
       dGain
       range
   end
   
   methods
       function obj = CryoCon22()
       end
       
       % clear error status
       function clear(obj)
           obj.write('CLS;');
       end
       
       % reset instrument hardware
       function reset(obj)
           obj.write('RST;');
       end
       
       % stop all heaters and loops
       function loopStop(obj)
           obj.write('STOP;');
       end
       
       % start control loop
       function loopStart(obj)
           obj.write('CONT;');
       end
       
       % set temperature units to Kelvin
       function setUnitsKelvin(obj)
           obj.write('INPUT A:UNITS K;');
       end
       
       % read out channel A temperature
       function val = get.temperatureA(obj)
           tmp = obj.query('INPUT? A;');
           val = str2double(tmp);
       end
       
       % read out channel B temperature
       function val = get.temperatureB(obj)
           tmp = obj.query('INPUT? B;');
           val = str2double(tmp);
       end
       
       % set channel A set point
       function set.loopTemperature(obj, value)
           % Validate input
           assert(isnumeric(value), 'Invalid input');
           obj.write(sprintf('LOOP 1:SETPT %G;',value));
       end

       function loopInitialize(obj)
           obj.write('LOOP 1:SOURCE A;LOOP 1:TYPE PID;OVERTEMP:SOURCE A');
       end
       
       function set.overTemp(obj,value)
           % Validate input
           assert(isnumeric(value), 'Invalid input');
           obj.write(sprintf('OVERTEMP:TEMP %G',value));
       end
       
       function calibrateD6004541(obj,file)
           obj.write('CALCUR 1;');
           obj.write('D6004541;');
           obj.write('Diode;');
           obj.write('-1.0;');
           obj.write('volts;');
           calibration= readtable(file);
           s=size(calibration);
           for i=1:s(1)
               t = calibration.Temperature(i);
               v = calibration.Voltage(i);
               obj.write(sprintf('%G %G;',v,t));
           end
           obj.write(';');
       end
       
       function set.range(obj,value)
           %validate input
           assert(sum(strcmpi(value,{'HI','MID','LOW'}))==1,'Invalid range input: must be HI MID or LOW');
           obj.write(strjoin({'LOOP 1:RANGE ',value,';'},''));
       end
       
       function set.pGain(obj,value)
           % Validate input
           assert(isnumeric(value), 'Invalid input');
           obj.write(sprintf('LOOP 1:PGAIN %G',value));
       end
       
       function set.iGain(obj,value)
           % Validate input
           assert(isnumeric(value), 'Invalid input');
           obj.write(sprintf('LOOP 1:IGAIN %G',value));
       end
       
       function set.dGain(obj,value)
           % Validate input
           assert(isnumeric(value), 'Invalid input');
           obj.write(sprintf('LOOP 1:DGAIN %G',value));
       end
       
   end
end