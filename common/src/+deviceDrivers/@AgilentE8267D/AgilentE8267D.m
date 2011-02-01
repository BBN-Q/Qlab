classdef (Sealed) AgilentE8267D < deviceDrivers.lib.GPIB
    % Agilent E8267D vector signal generator
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
        WBIQ
        WBIQ_Adjust
        WBIQ_IOffset
        WBIQ_QOffset
        WBIQ_Skew
    end % end device properties
    
    % Class-specific private methods
    methods (Access = private)
        
    end % end private methods
    
    methods
        function obj = AgilentE8267D()
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
        function val = get.frequency(obj)
            gpib_string = ':freq:fixed?';
            temp = obj.Query([gpib_string]);
            val = str2double(temp);
        end
        function val = get.power(obj)
            gpib_string = ':power?';
            temp = obj.Query([gpib_string]);
            val = str2double(temp);
        end
        function val = get.phase(obj)
            gpib_string = ':phase?';
            temp = obj.Query([gpib_string]);
            val = str2double(temp);
        end
        function val = get.output(obj)
            gpib_string = ':output?';
            temp = obj.Query([gpib_string]);
            val = temp;
        end
        function val = get.mod(obj)
            gpib_string = ':output:mod?';
            temp = obj.Query([gpib_string]);
            val = temp;
        end
        function val = get.alc(obj)
            gpib_string = ':power:alc?';
            temp = obj.Query([gpib_string]);
            val = temp;
        end
        function val = get.pulse(obj)
            gpib_string = ':pulm:state?';
            temp = obj.Query([gpib_string]);
            val = temp;
        end
        function val = get.pulseSource(obj)
            gpib_string = ':pulm:source?';
            temp = obj.Query([gpib_string]);
            val = temp;
        end
        function val = get.WBIQ(obj)
            gpib_string = ':wdm:state?';
            temp = obj.Query([gpib_string]);
            val = temp;
        end
        function val = get.WBIQ_Adjust(obj)
            gpib_string = ':wdm:IQAD?';
            temp = obj.Query([gpib_string]);
            val = temp;
        end
        function val = get.WBIQ_IOffset(obj)
            gpib_string = ':wdm:iqad:ioff?';
            temp = obj.Query([gpib_string]);
            val = str2double(temp);
        end
        function val = get.WBIQ_QOffset(obj)
            gpib_string = ':wdm:iqad:qoff?';
            temp = obj.Query([gpib_string]);
            val = str2double(temp);
        end
        function val = get.WBIQ_Skew(obj)
            gpib_string = ':wdm:iqad:qskew?';
            temp = obj.Query([gpib_string]);
            val = str2double(temp);
        end
        
        % property setters
        function obj = set.frequency(obj, value)
            gpib_string = ':freq:fixed %d';

            % Validate input
            if ~isnumeric(value)
                error('Invalid input');
            end
            
            gpib_string = sprintf(gpib_string, value);
            obj.Write(gpib_string);
        end
        function obj = set.power(obj, value)
            gpib_string = ':power %ddbm';

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
            
            gpib_string =[gpib_string checkMapObj(value)];
            obj.Write(gpib_string);
        end
        % set phase in degrees
        function obj = set.phase(obj, value)
            gpib_string = ':phase %dDEG';
            
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
            
            gpib_string =[gpib_string checkMapObj(value)];
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
            
            gpib_string =[gpib_string checkMapObj(value)];
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
            
            gpib_string = [gpib_string checkMapObj(value)];
            obj.Write(gpib_string);
        end
        function obj = set.pulseSource(obj, value)
            gpib_string = ':pulm:source ';
            
            % Validate input
            checkMapObj = containers.Map({'int','internal','ext','external'},...
                {'int','int','ext','ext'});
            if not (checkMapObj.isKey( lower(value) ))
                error('Invalid input');
            end
            
            gpib_string = [gpib_string checkMapObj(value)];
            obj.Write(gpib_string);
        end
        function obj = set.WBIQ(obj, value)
            gpib_string = ':wdm:state ';
            if isnumeric(value)
                value = num2str(value);
            end
            
            % Validate input
            checkMapObj = containers.Map({'on','1','off','0'},...
                {'on','on','off','off'});
            if not (checkMapObj.isKey( lower(value) ))
                error('Invalid input');
            end
            
            gpib_string = [gpib_string checkMapObj(value)];
            obj.Write(gpib_string);
        end
        function obj = set.WBIQ_Adjust(obj, value)
            gpib_string = ':wdm:IQAD ';
            if isnumeric(value)
                value = num2str(value);
            end
            
            % Validate input
            checkMapObj = containers.Map({'on','1','off','0'},...
                {'on','on','off','off'});
            if not (checkMapObj.isKey( lower(value) ))
                error('Invalid input');
            end
            
            gpib_string = [gpib_string checkMapObj(value)];
            obj.Write(gpib_string);
        end
        function obj = set.WBIQ_IOffset(obj, value)
            gpib_string = ':wdm:iqad:ioff %d';
            
            % Validate input
            if ~isnumeric(value)
                error('Invalid input');
            end
            
            gpib_string = sprintf(gpib_string, value);
            obj.Write(gpib_string);
        end
        function obj = set.WBIQ_QOffset(obj, value)
            gpib_string = ':wdm:iqad:qoff %d';
            
            % Validate input
            if ~isnumeric(value)
                error('Invalid input');
            end
            
            gpib_string = sprintf(gpib_string, value);
            obj.Write(gpib_string);
        end
        function obj = set.WBIQ_Skew(obj, value)
            gpib_string = ':wdm:iqad:qskew %d';
            
            % Validate input
            if ~isnumeric(value)
                error('Invalid input');
            end
            
            gpib_string = sprintf(gpib_string, value);
            obj.Write(gpib_string);
        end
    end % end instrument parameter accessors
    
    
end % end class definition