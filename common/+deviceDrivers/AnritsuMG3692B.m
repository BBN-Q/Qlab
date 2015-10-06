classdef (Sealed) AnritsuMG3692B < deviceDrivers.lib.uWSource & deviceDrivers.lib.GPIB
    % Anritsu MG3692B signal generator
    %
    %
    % Author(s): Blake Johnson
    % Generated on: Tues Oct 19 2010
    
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
        phase
        mod
        alc
        pulse
        pulseSource
    end % end device properties
    
    % Class-specific private methods
    methods (Access = private)
        
    end % end private methods
    
    methods
        function obj = AnritsuMG3692B()
        end
		
		% Instrument parameter accessors
        % getters
        function val = get.frequency(obj)
            gpib_string = ':freq:fixed?';
            temp = obj.query([gpib_string]);
            val = str2double(temp) * 1e-9;
        end
        function val = get.power(obj)
            gpib_string = ':power?';
            temp = obj.query([gpib_string]);
            val = str2double(temp);
        end
        function val = get.phase(obj)
            gpib_string = ':phase?';
            temp = obj.query([gpib_string]);
            val = str2double(temp);
        end
        function val = get.output(obj)
            gpib_string = ':output?';
            temp = obj.query([gpib_string]);
            val = temp;
        end
        function val = get.mod(obj)
            gpib_string = ':pulm:state?';
            temp = obj.query([gpib_string]);
            val = temp;
        end
        function val = get.alc(obj)
            gpib_string = ':power:alc:source?';
            temp = obj.query([gpib_string]);
            val = temp;
        end
        function val = get.pulse(obj)
            gpib_string = ':pulm:state?';
            temp = obj.query([gpib_string]);
            val = temp;
        end
        function val = get.pulseSource(obj)
            gpib_string = ':pulm:source?';
            temp = obj.query([gpib_string]);
            val = temp;
        end
        
        % property setters
        function obj = set.frequency(obj, value)
            gpib_string = ':freq:fixed %dGHz';

            % Validate input
            if ~isnumeric(value)
                error('Invalid input');
            end
            
            gpib_string = sprintf(gpib_string, value);
            obj.write(gpib_string);
        end
        function obj = set.power(obj, value)
            gpib_string = ':power %ddbm';

            % Validate input
            if ~isnumeric(value)
                error('Invalid input');
            end
            
            gpib_string = sprintf(gpib_string, value);
            obj.write(gpib_string);
        end
        function obj = set.output(obj, value)
            gpib_string = ':output ';
            if isnumeric(value)
                value = num2str(value);
            end
            
            % Validate input
            checkMapObj = containers.Map({'on','1','off','0'},...
                {'on','on','off','off'});
            if not (checkMapObj.isKey( lower(value) ))
                error('Invalid input');
            end
            
            gpib_string =[gpib_string checkMapObj(value)];
            obj.write(gpib_string);
        end
        % set phase in degrees
        function obj = set.phase(obj, value)
            gpib_string = ':phase %dDEG';
            
            % Validate input
            if ~isnumeric(value)
                error('Invalid input');
            end
            
            gpib_string = sprintf(gpib_string, value);
            obj.write(gpib_string);
        end
        function obj = set.mod(obj, value)
            gpib_string = ':pulm:state ';
            if isnumeric(value)
                value = num2str(value);
            end
            
            % Validate input
            checkMapObj = containers.Map({'on','1','off','0'},...
                {'on','on','off','off'});
            if not (checkMapObj.isKey( lower(value) ))
                error('Invalid input');
            end
            
            gpib_string =[gpib_string checkMapObj(value)];
            obj.write(gpib_string);
        end
        function obj = set.alc(obj, value)
            gpib_string = ':power:alc ';
            if isnumeric(value)
                value = num2str(value);
            end
            
            % Validate input
            checkMapObj = containers.Map({'on','1','off','0'},...
                {'int','int','off','off'});
            if not (checkMapObj.isKey( lower(value) ))
                error('Invalid input');
            end
            
            gpib_string =[gpib_string checkMapObj(value)];
%             obj.write(gpib_string);
        end
        function obj = set.pulse(obj, value)
            gpib_string = ':pulm:state ';
            if isnumeric(value)
                value = num2str(value);
            end
            
            % Validate input
            checkMapObj = containers.Map({'on','1','off','0'},...
                {'on','on','off','off'});
            if not (checkMapObj.isKey( lower(value) ))
                error('Invalid input');
            end
            
            gpib_string =[gpib_string checkMapObj(value)];
            obj.write(gpib_string);
        end
        function obj = set.pulseSource(obj, value)
            gpib_string = ':pulm:source ';
            
            % Validate input
            checkMapObj = containers.Map({'int','internal','ext','external'},...
                {'int','int','ext2','ext2'});
            if not (checkMapObj.isKey( lower(value) ))
                error('Invalid input');
            end
            
            gpib_string = [gpib_string checkMapObj(value)];
            obj.write(gpib_string);
        end
        function check_errors(obj)
        end
    end % end instrument parameter accessors
    
    
end % end class definition