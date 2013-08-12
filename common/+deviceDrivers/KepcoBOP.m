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
    end
    
    properties (SetAccess=private)
        current % read the actual current
        voltage % read the actual voltage
    end
    
    properties (Constant)
        modeMap = containers.Map({'voltage', 'current'}, {'VOLT', 'CURR'});
    end
    
    methods
        %Current of voltage source mode
        function val = get.mode(obj)
            numericMode = strtrim(obj.query('FUNC:MODE ?'));
            if numericMode == '1'
                val = 'current';
            else
                val = 'voltage';
            end
        end
        function obj = set.mode(obj, mode)
            obj.write(sprintf('FUNC:MODE %s', obj.modeMap(mode)));
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
            val = strtrim(obj.query('OUTP?'));
        end
        function obj = set.output(obj, output)
            obj.write(sprintf('OUTP %d', logical(output)));
        end
        
% 
%         %The output range: full or quarter. 
%         function val = get.range(obj)
%             val = str2double(obj.query(':SOURCE:RANGE?'));
%         end
%         
%         function obj = set.output(obj, value)
%             if isnumeric(value) || islogical(value)
%                 value = num2str(value);
%             end
%             valid_inputs = ['on', '1', 'off', '0'];
%             if ~ismember(value, valid_inputs)
%                 error('Invalid input');
%             end
%             
%             obj.write([':OUTPUT ' value]);
%         end
%         function obj = set.range(obj, range)
%             valid_ranges = [1e-3, 10e-3, 100e-3, 200e-3, 1, 10, 30];
%             if ~isnumeric(range)
%                 range = str2double(range);
%             end
%             if ~ismember(range, valid_ranges)
%                 error('Invalid range: %f', range);
%             end
%             
%             obj.write([':SOURCE:RANGE ' num2str(range)]);
%         end
    end
end