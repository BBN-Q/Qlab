% CLASS Picosec10070A - Instrument driver for the Picosecond Pulse Lab
% Model 10,070A

% Author: Tom Ohki (tohki@bbn.com) and Colm Ryan (cryan@bbn.com)

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

classdef (Sealed) Picosec10070A < deviceDrivers.lib.GPIB
    
    properties (Access = public)
        amplitude % pulse amplitude in volts (-7.5 to 7.5 V) 
        duration % pulse duration in seconds(0-10.2ns; resolution 2.5ps)
        delay % pulse delay in seconds (0-63ns; resolution 1ns)
        offset % dc offset to pulse (-5 to 5V; resolution 1.25mV)
        enable % whether output is enabled (boolean)
        frequency % pulse repetition frequency (1Hz-100kHz)
        period % pulse repitition period (10us to 1s; resolution 0.1us)
    end
    

    properties (Constant)
        enableMap = containers.Map({false, true}, {'NO', 'YES'})

    end
    
    methods
        %pulse amplitude
        function val = get.amplitude(obj)
            val = str2double(obj.query('amplitude?'));
        end
        function obj = set.amplitude(obj, amp)
            assert(amp > -7.5 && amp < 7.5, 'Oops! The pulse amplitude must be between -7.5V and +7.5V.');
            obj.write(sprintf('amplitude %E', amp));
        end
        
        %pulse duration
        function val = get.duration(obj)
            val = str2double(obj.query('duration?'));
        end
        function obj = set.duration(obj, duration)
            assert(duration > 0 && duration <= 10.2e-9, 'Oops! The pulse duration must be between 0 and 10.2ns.');
            obj.write('duration %E', duration);
        end
        
        %pulse delay
        function val = get.delay(obj)
            val = str2double(obj.query('delay?'));
        end
        function obj = set.delay(obj, delay)
            assert(delay > 0 && delay <= 63e-9, 'Oops! The pulse delay must be between 0 and 63ns.');
            obj.write('delay %E', delay);
        end

        %dc offset
        function val = get.offset(obj)
            val = str2double(obj.query('offset?'));
        end
        function obj = set.offset(obj, offset)
            assert(offset > -5 && offset < 5, 'Oops! The dc offset must be between -5V and +5V.');
            obj.write('offset %E', offset);
        end
        
        %output enabled
        function val = get.enable(obj)
            inverseMap = invertMap(obj.enableMap)
            val = inverseMap(strtrim(obj.query('enable?')));
        end
        function obj = set.enable(obj, enable)
            obj.write('enable %s', obj.enableMap(logical(enable)));
        end
        
        %repetition frequency
        function val = get.frequency(obj)
            val = str2double(obj.query('frequency?'));
        end
        function obj = set.frequency(obj, frequency)
            assert(frequency > 1 && frequency <= 100e3, 'Oops! The pulse frequency must be between 1Hz-100kHz.');
            obj.write('frequency %E', frequency);
        end

        %repetition period
        function val = get.period(obj)
            val = str2double(obj.query('period?'));
        end
        function obj = set.period(obj, period)
            assert(period > 10e-6 && period <= 1, 'Oops! The pulse period must be between 10us and 1s.');
            obj.write('period %E', period);
        end


        function trigger(obj)
            %Sends a software trigger
            obj.write('*TRG')
        end

    end
    
end