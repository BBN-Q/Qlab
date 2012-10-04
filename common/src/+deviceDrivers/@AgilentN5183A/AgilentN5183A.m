classdef (Sealed) AgilentN5183A < deviceDrivers.lib.uWSource & deviceDrivers.lib.GPIBorEthernet
    % Agilent N5183A microwave signal generator
    %
    %
    % Author(s): Blake Johnson/Regina Hain
    % Generated on: Tues Nov 1 2010
    
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
        IQ
        IQ_Adjust
        IQ_IOffset
        IQ_QOffset
        IQ_Skew
    end % end device properties
    
    % Class-specific private methods
    methods (Access = private)
        
    end % end private methods
    
    methods
        function obj = AgilentN5183A()
            %obj = obj@deviceDrivers.lib.uWSource();
        end
		
		% Instrument parameter accessors
        % getters
        function val = get.frequency(obj)
            gpib_string = ':freq?;';
            temp = obj.Query([gpib_string]);
            val = str2double(temp)*1e-9; % convert to GHz
        end
        function val = get.power(obj)
            gpib_string = ':power?;';
            temp = obj.Query([gpib_string]);
            val = str2double(temp);
        end
        function val = get.phase(obj)
            gpib_string = ':phase?;';
            temp = obj.Query([gpib_string]);
            val = str2double(temp);
        end
        function val = get.output(obj)
            gpib_string = ':output?;';
            temp = obj.Query([gpib_string]);
            val = temp;
        end
        function val = get.mod(obj)
            gpib_string = ':output:mod?;';
            temp = obj.Query([gpib_string]);
            val = temp;
        end
        function val = get.alc(obj)
            gpib_string = ':power:alc?;';
            temp = obj.Query([gpib_string]);
            val = temp;
        end
        function val = get.pulse(obj)
            gpib_string = ':pulm:state?;';
            temp = obj.Query([gpib_string]);
            val = temp;
        end
        function val = get.pulseSource(obj)
            gpib_string = ':pulm:source?;';
            temp = obj.Query([gpib_string]);
            val = temp;
        end
        function val = get.IQ(obj)
            gpib_string = ':dm:state?;';
            temp = obj.Query([gpib_string]);
            val = temp;
        end
        function val = get.IQ_Adjust(obj)
            gpib_string = ':dm:IQAD?;';
            temp = obj.Query([gpib_string]);
            val = temp;
        end
        function val = get.IQ_IOffset(obj)
            gpib_string = ':dm:iqad:ioff?;';
            temp = obj.Query([gpib_string]);
            val = str2double(temp);
        end
        function val = get.IQ_QOffset(obj)
            gpib_string = ':dm:iqad:qoff?;';
            temp = obj.Query([gpib_string]);
            val = str2double(temp);
        end
        function val = get.IQ_Skew(obj)
            gpib_string = ':dm:iqad:qskew?;';
            temp = obj.Query([gpib_string]);
            val = str2double(temp);
        end
        
        % property setters
        function obj = set.frequency(obj, value)
            gpib_string = ':freq:fixed %dGHz;';

            % Validate input
            if ~isnumeric(value)
                error('Invalid input');
            end
            
            gpib_string = sprintf(gpib_string, value);

            %mode_string = ':freq:mode fixed'; %set to fixed
            %obj.Write(mode_string);
            obj.Write(gpib_string);
        end
        function obj = set.power(obj, value)
            gpib_string = ':power %ddbm;';

            % Validate input
            if ~isnumeric(value)
                error('Invalid input');
            end
            
            gpib_string = sprintf(gpib_string, value);
            obj.Write(gpib_string);
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
            
            gpib_string =[gpib_string checkMapObj(value) ';'];
            obj.Write(gpib_string);
        end
        % set phase in degrees
        function obj = set.phase(obj, value)
            gpib_string = ':phase %dDEG;';
            
            % Validate input
            if ~isnumeric(value)
                error('Invalid input');
            end
            
            gpib_string = sprintf(gpib_string, value);
            obj.Write(gpib_string);
        end
        function obj = set.mod(obj, value)
            gpib_string = ':output:mod ';
            if isnumeric(value)
                value = num2str(value);
            end
            
            % Validate input
            checkMapObj = containers.Map({'on','1','off','0'},...
                {'on','on','off','off'});
            if not (checkMapObj.isKey( lower(value) ))
                error('Invalid input');
            end
            
            gpib_string =[gpib_string checkMapObj(value) ';'];
            obj.Write(gpib_string);
        end
        function obj = set.alc(obj, value)
            gpib_string = ':power:alc ';
            if isnumeric(value)
                value = num2str(value);
            end
            
            % Validate input
            checkMapObj = containers.Map({'on','1','off','0'},...
                {'on','on','off','off'});
            if not (checkMapObj.isKey( lower(value) ))
                error('Invalid input');
            end
            
            gpib_string =[gpib_string checkMapObj(value) ';'];
            obj.Write(gpib_string);
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
            
            gpib_string = [gpib_string checkMapObj(value) ';'];
            obj.Write(gpib_string);
        end
        function obj = set.pulseSource(obj, value)
            gpib_string = ':pulm:source ';
            value = lower(value);
            
            % Validate input
            checkMapObj = containers.Map({'int','internal','ext','external'},...
                {'int','int','ext','ext'});
            if not (checkMapObj.isKey(value))
                error('Invalid input');
            end
            
            gpib_string = [gpib_string checkMapObj(value) ';'];
            obj.Write(gpib_string);
        end
        function obj = set.IQ(obj, value)
            gpib_string = ':dm:state ';
            if isnumeric(value)
                value = num2str(value);
            end
            
            % Validate input
            checkMapObj = containers.Map({'on','1','off','0'},...
                {'on','on','off','off'});
            if not (checkMapObj.isKey( lower(value) ))
                error('Invalid input');
            end
            
            gpib_string = [gpib_string checkMapObj(value) ';'];
            obj.Write(gpib_string);
        end
        function obj = set.IQ_Adjust(obj, value)
            gpib_string = ':dm:IQAD ';
            if isnumeric(value)
                value = num2str(value);
            end
            
            % Validate input
            checkMapObj = containers.Map({'on','1','off','0'},...
                {'on','on','off','off'});
            if not (checkMapObj.isKey( lower(value) ))
                error('Invalid input');
            end
            
            gpib_string = [gpib_string checkMapObj(value) ';'];
            obj.Write(gpib_string);
        end
        function obj = set.IQ_IOffset(obj, value)
            gpib_string = ':dm:iqad:ioff %d;';
            
            % Validate input
            if ~isnumeric(value)
                error('Invalid input');
            end
            
            gpib_string = sprintf(gpib_string, value);
            obj.Write(gpib_string);
        end
        function obj = set.IQ_QOffset(obj, value)
            gpib_string = ':dm:iqad:qoff %d;';
            
            % Validate input
            if ~isnumeric(value)
                error('Invalid input');
            end
            
            gpib_string = sprintf(gpib_string, value);
            obj.Write(gpib_string);
        end
        function obj = set.IQ_Skew(obj, value)
            gpib_string = ':dm:iqad:qskew %d;';
            
            % Validate input
            if ~isnumeric(value)
                error('Invalid input');
            end
            
            gpib_string = sprintf(gpib_string, value);
            obj.Write(gpib_string);
        end
    end % end instrument parameter accessors
    
    
end % end class definition
