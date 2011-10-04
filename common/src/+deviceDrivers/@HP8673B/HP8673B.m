classdef (Sealed) HP8673B < deviceDrivers.lib.GPIB
    %HP8673B
    %
    %
    % Author(s): tohki
    % Generated on: Fri Jan 22 15:23:54 2010
    
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
        frequency
        power
        pulse
    end % end device properties
    
    
    
    % Class-specific private methods
    methods (Access = private)
        
    end % end private methods
    
    methods (Access = public)
        function obj = HP8673B()
            %             obj = obj@dev.DAObject.GPIB.GPIBWrapper();
        end
        
        %         % Instrument-specific methods
        %         function outputon(obj)
        %         %OUTPUT ON
        %             gpib_string = 'OUTPUT ON';
        %             obj.Write(gpib_string);
        %         end
        %
        %         function outputoff(obj)
        %         %OUTPUT OFF
        %             gpib_string = 'OUTPUT OFF';
        %             obj.Write(gpib_string);
        %         end
	end
    
    methods % Class-specific public methods
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
        function val = get.frequency(obj)
            gpib_string = 'FR';
            temp = obj.Query([gpib_string '?']);
			expr = 'FR(\d+)HZ';
            tokens = regexp(temp, expr, 'tokens');
            val = str2double(tokens{1})/1e9;
        end
        function val = get.power(obj)
            gpib_string = 'LEOA';
            temp = obj.Query(gpib_string);
			expr = 'LE(.+)DM';
            tokens = regexp(temp, expr, 'tokens');
            val = str2double(tokens{1});
        end
        function obj = set.frequency(obj, value)
            gpib_string = 'FR %.6f GZ';

            % Validate input
            check_val = class(value);
            checkMapObj = containers.Map({'numeric','integer','float','single','double'},{1,1,1,1,1});
            if not (checkMapObj.isKey(check_val))
                error('Invalid input');
            end
            gpib_string = sprintf(gpib_string,value);
            obj.Write(gpib_string);
        end
        function obj = set.power(obj, value)
            gpib_string = 'AP %.6f dB';
            
            % Validate input
            check_val = class(value);
            checkMapObj = containers.Map({'numeric','integer','float','single','double'},{1,1,1,1,1});
            if not (checkMapObj.isKey(check_val))
                error('Invalid input');
            end
            
            gpib_string = sprintf(gpib_string,value);
            obj.Write(gpib_string);
        end
        function obj = set.output(obj, value)
            gpib_string = 'OUTPUT RF%d';
            if isnumeric(value)
                value = num2str(value);
            end
            
            % Validate input
            checkMapObj = containers.Map({'on','1','off','0'},...
                {1, 1, 0, 0});
            if not (checkMapObj.isKey( lower(value) ))
                error('Invalid input');
            end
            
            gpib_string = sprintf(gpib_string, checkMapObj(value));
            obj.Write(gpib_string);
        end
        function obj = set.pulse(obj, value)
            gpib_string = 'P';
            if isnumeric(value)
                value = num2str(value);
            end
            
            % Validate input
            checkMapObj = containers.Map({'on','1','off','0'},...
                {'2','2','0','0'});
            if not (checkMapObj.isKey( lower(value) ))
                error('Invalid input');
            end
            
            gpib_string = [gpib_string checkMapObj(value) ';'];
            obj.Write(gpib_string);
        end
    end % end instrument parameter accessors
    
    
end % end class definition
