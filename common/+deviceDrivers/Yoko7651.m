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
% File: Yoko7651.m
% Author: Blake Johnson (bjohnson@bbn.com)
% Generated on: Tues Oct 19 2010
%
% Description: Instrument driver for the Yokogawa 7651 DC source

classdef (Sealed) Yoko7651 < deviceDrivers.lib.GPIB
    
    % Class-specific constant properties
    properties (Constant = true)
        
    end % end constant properties
    
    
    % Class-specific private properties
    properties (Access = private)
        
    end % end private properties
    
    
    % Class-specific public properties
    properties (Access = public)
        
    end % end public properties
    
    
    % Device properties correspond to instrument parameters
    properties (Access = public)
        output
        range
        value
    end % end device properties
    
    % Class-specific private methods
    methods (Access = private)
        
    end % end private methods
    
    methods
        function obj = Yoko7651()
        end

		% instrument meta-setter
		function setAll(obj, settings)
			fields = fieldnames(settings);
			for j = 1:length(fields);
				name = fields{j};
				if ismember(name, methods(obj))
					feval(['obj.' name], settings.(name));
				elseif ismember(name, properties(obj))
					obj.(name) = settings.(name);
				end
			end
		end
		
		% Instrument parameter accessors
        % getters
        function val = get.value(obj)
            gpib_string = 'OD';
            temp = obj.query(gpib_string);
            val = str2double(temp(5:end));
        end
        function val = get.output(obj)
            gpib_string = 'OC';
            result = obj.query(gpib_string);
            expr = 'STS1=(\d*)';
            tokens = regexp(result, expr, 'tokens');
            temp = uint16(str2double(tokens{1}));
            % on/off state is in bit 5 of the status code
            val = any(bitand(temp, bitset(0, 5)));
        end
        function val = get.range(obj)
            % read in panel information
            % range is given in line 2
            % the foo's are to take up useless buffer for the reading of
            % the output range.
            gpib_string = 'OS';
            foo = obj.query(gpib_string);
            result = obj.read;
            foo = obj.read;
            foo = obj.read;
            foo = obj.read;
            expr = 'F(\d)R(\d)';
            tokens = regexp(result, expr, 'tokens');
            %val = temp;
            temp = str2double(tokens{1}{2});
            rangeMap = containers.Map({2, 3, 4, 5, 6}, ...
                {'10mV','100mV','1V','10V','30V'});
            val = rangeMap(temp);
        end
        
        % property setters
        function obj = set.value(obj, value)
            gpib_string = 'S%e;E;';

            % Validate input
            if ~isnumeric(value)
                error('Invalid input');
            end
            
            gpib_string = sprintf(gpib_string, value);
            obj.write(gpib_string);
        end
        function obj = set.output(obj, value)
            gpib_string = 'O%d;E;';
            
            % Validate input
            if isnumeric(value)
                value = num2str(value);
            end
            checkMapObj = containers.Map({'on','1','off','0'},...
                {1, 1, 0, 0});
            if not (checkMapObj.isKey( lower(value) ))
                error('Invalid input');
            end
            
            gpib_string = sprintf(gpib_string, checkMapObj(lower(value)));
            obj.write(gpib_string);
        end
        % valid ranges: 2 = 10 mV, 3 = 100 mV, 4 = 1V, 5 = 10V,6 = 30V
        function obj = set.range(obj, value)
            gpib_string = 'R%d;E;';
            
            % Validate input
            checkMapObj = containers.Map({'10mv','100mv','1v','10v','30v'},...
                {2, 3, 4, 5, 6});
            if not (checkMapObj.isKey( lower(value) ))
                error('Invalid input');
            end
            
            gpib_string = sprintf(gpib_string, checkMapObj(lower(value)));
            obj.write(gpib_string);
        end

    end % end instrument parameter accessors
    
    
end % end class definition