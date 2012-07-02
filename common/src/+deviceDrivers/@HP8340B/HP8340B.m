classdef (Sealed) HP8340B < deviceDrivers.lib.uWSource & deviceDrivers.lib.GPIB
    %HP8340B
    %
    %
    % Author(s): tohki
    % Generated on: Fri Jan 22 15:23:54 2010
    % Modifed by Blake Johnson on July 2, 2012
    
    
    % Device properties correspond to instrument parameters
    properties (Access = public)
        output
        frequency
        power
        phase
        mod
        alc
        pulse
        pulseSource
    end % end device properties
    
    
    methods
        function obj = HP8340B()
            %             obj = obj@dev.DAObject.GPIB.GPIBWrapper();
        end
		
		% Instrument parameter accessors
        function val = get.frequency(obj)
            gpib_string = 'OK';
            temp = obj.Query([gpib_string]);
            val = str2double(temp);
        end
        function val = get.power(obj)
            gpib_string = 'OR';
            temp = obj.Query([gpib_string]);
            val = str2double(temp);
        end
        function obj = set.frequency(obj, value)
            gpib_string = 'CW %d GZ';

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
            gpib_string = 'PL %d DB';
            
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
            gpib_string = 'RF%d';
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
    end % end instrument parameter accessors
    
    
end % end class definition
