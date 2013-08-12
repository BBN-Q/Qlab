% CLASS Picosec10070A - Instrument driver for the Picosecond Pulse Lab
% Model 10,070A

% Author: Tom Ohki (tohki@bbn.com)

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
    
    properties 
        amplitude %-7.5 to 7.5 V 
        delay
        disable
        duration
        enable
        offset
        trigger
        period
    end
    
    
    
    
    
    methods
%         %amplitude
%         function val = get.amp(obj)
%             val = strtrim(obj.query('FUNC:MODE ?'));
%             if numericMode == '1'
%                 val = 'current';
%             else
%                 val = 'voltage';
%             end
%         end
%         function obj = set.mode(obj, mode)
%             obj.write(sprintf('FUNC:MODE %s', obj.modeMap(mode)));
%         end
%     
%         
%         %The programmed output value
%         function val = get.value(obj)
%             val = str2double(obj.query(sprintf('%s?', obj.modeMap(obj.mode))));
%         end
%         function obj = set.value(obj, value)
%             assert(isnumeric(value), 'Oops! You need to program a numeric value.');
%             obj.write(sprintf('%s %E', obj.modeMap(obj.mode), value)); 
%         end
%         
%         %Whether output is enabled
%         function val = get.output(obj)
%             val = strtrim(obj.query('OUTP?'));
%         end
%         function obj = set.output(obj, output)
%             obj.write(sprintf('OUTP %d', logical(output)));
%         end
%         
        
        
        
        
    end
    
end