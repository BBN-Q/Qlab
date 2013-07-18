% CLASS YokoGS200 - Instrument driver for the Yokogawa GS200 DC source

% Author: Blake Johnson (bjohnson@bbn.com)

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

classdef (Sealed) YokoGS200 < deviceDrivers.lib.deviceDriverBase & deviceDrivers.lib.GPIBorVISA
    properties (Access = public)
        output
        range
        mode % 'current', or 'voltage'
        value
    end
    
    methods
        function obj = YokoGS200()
        end

        % getters
        function val = get.value(obj)
            val = str2double(obj.query(':SOURCE:LEVEL?'));
        end
        function val = get.mode(obj)
            val = strtrim(obj.query(':SOURCE:FUNCTION?'));
        end
        function val = get.output(obj)
            val = str2double(obj.query(':OUTPUT?'));
        end
        function val = get.range(obj)
            val = str2double(obj.query(':SOURCE:RANGE?'));
        end
        
        % setters
        function obj = set.value(obj, value)
            obj.write([':SOURCE:LEVEL ' num2str(value)]);
        end
        function obj = set.mode(obj, mode)
            valid_modes = {'current', 'curr', 'voltage', 'volt'};
            if ~ismember(mode, valid_modes)
                error('Invalid mode');
            end
            obj.write([':SOURCE:FUNCTION ' mode]);
        end
        function obj = set.output(obj, value)
            if isnumeric(value) || islogical(value)
                value = num2str(value);
            end
            valid_inputs = ['on', '1', 'off', '0'];
            if ~ismember(value, valid_inputs)
                error('Invalid input');
            end
            
            obj.write([':OUTPUT ' value]);
        end
        function obj = set.range(obj, range)
            valid_ranges = [1e-3, 10e-3, 100e-3, 200e-3, 1, 10, 30];
            if ~isnumeric(range)
                range = str2double(range);
            end
            if ~ismember(range, valid_ranges)
                error('Invalid range: %f', range);
            end
            
            obj.write([':SOURCE:RANGE ' num2str(range)]);
        end
    end
end