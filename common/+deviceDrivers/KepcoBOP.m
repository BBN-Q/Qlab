% CLASS KepcoBOP - Instrument driver for the Kepco BOP DC source

% Author: Colm Ryan (colm.ryan@bbn.com)

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

classdef (Sealed) KepcoBOP < deviceDrivers.lib.GPIB
    properties (Access = public)
        output %boolean whether output is on or not
        mode % 'current', or 'voltage'
        value %output value in V or A
        range = 'full' % 'full' or 'quarter' 
        limit %voltage or current limit
    end
    
    properties (SetAccess=private)
        current % read the actual current
        voltage % read the actual voltage
    end
    
    properties (Constant)
        modeMap = containers.Map({'voltage', 'current'}, {'VOLT', 'CURR'});
        limitModeMap = containers.Map({'voltage', 'current'}, {'CURR', 'VOLT'}) %limit sets the complement
        rangeMap = containers.Map({'full','quarter'}, {1, 4});
    end
    
    methods
        %Current or voltage source mode
        function val = get.mode(obj)
            numericMode = strtrim(obj.query('FUNC:MODE?'));
            if numericMode == '1'
                val = 'current';
            else
                val = 'voltage';
            end
        end
        function obj = set.mode(obj, mode)
            assert(isKey(obj.modeMap,mode), 'Oops! Mode must be "voltage" or "current".');
            obj.write(sprintf('FUNC:MODE %s', obj.modeMap(mode)));
        end
        
        %The complement limit value
        function obj = set.limit(obj, limit)
            %In voltage mode, set the current; in current mode, the voltage
            %"MAX" is also a valid option
            if ischar(limit)
                assert(strcmp(limit, 'MAX'), 'Oops! Only non-numeric value allowed is "MAX".');
            else
                limit = num2str(limit, '%E');
            end
            obj.write(sprintf('%s %s', obj.limitModeMap(obj.mode), limit));
        end
        function val = get.limit(obj)
            val = str2double(obj.query(sprintf('%s?', obj.limitModeMap(obj.mode))));
        end
                
        
        %The programmed output value
        function val = get.value(obj)
            val = str2double(obj.query(sprintf('%s?', obj.modeMap(obj.mode))));
        end
        function obj = set.value(obj, value)
            assert(isnumeric(value), 'Oops! You need to program a numeric value.');
            obj.write(sprintf('%s %E', obj.modeMap(obj.mode), value)); 
        end
        
        %Whether output is enabled
        function val = get.output(obj)
            val = logical(str2double(obj.query('OUTP?')));
        end
        function obj = set.output(obj, output)
            obj.write(sprintf('OUTP %d', logical(output)));
        end
        
        %The output range: full or quarter. 
        function val = get.range(obj)
            inverseMap = invertMap(obj.rangeMap);
            val = inverseMap(str2double(obj.query(sprintf('%s:RANG?', obj.modeMap(obj.mode)))));
        end
        function obj = set.range(obj, range)
            assert(isKey(obj.rangeMap, range), 'Oops! The range must be set to "full" or "quarter".');
            obj.write(sprintf('%s:RANG %d',obj.modeMap(obj.mode), obj.rangeMap(range)));
        end
        
        %The actual current or voltage
        function val = get.current(obj)
            val = str2double(obj.query('MEAS:CURR?'));
        end
        function val = get.voltage(obj)
            val = str2double(obj.query('MEAS:VOLT?'));
        end
        
        %Helper function to ramp the current "slowly" (not well-defined what slowly means)
        function ramp(obj, startPt, endPt, numPoints)
            for cur = linspace(startPt, endPt, numPoints)
                obj.value = cur;
                pause(0.05);
            end;
            %Wait until we're really there
            while (abs(obj.current - endPt) > 0.1)
                pause(0.05);
            end
            
        end
    end
end