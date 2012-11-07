classdef (Sealed) HP8673B < deviceDrivers.lib.uWSource & deviceDrivers.lib.GPIB
    %HP8673B
    %
    %
    % Author(s): tohki
    % Generated on: Fri Jan 22 15:23:54 2010
    % Modified by Blake Johnson July 2, 2012
    
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
        function obj = HP8673B()
        end

		% Instrument parameter accessors
        function val = get.frequency(obj)
            gpib_string = 'FR';
            temp = obj.query([gpib_string '?']);
			expr = 'FR(\d+)HZ';
            tokens = regexp(temp, expr, 'tokens');
            val = str2double(tokens{1})/1e9;
        end
        function val = get.power(obj)
            gpib_string = 'LEOA';
            temp = obj.query(gpib_string);
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
            obj.write(gpib_string);
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
            obj.write(gpib_string);
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
            obj.write(gpib_string);
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
            obj.write(gpib_string);
        end
    end % end instrument parameter accessors
    
    
end % end class definition
