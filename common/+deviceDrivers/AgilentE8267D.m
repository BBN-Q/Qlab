classdef (Sealed) AgilentE8267D < deviceDrivers.lib.uWSource & deviceDrivers.lib.GPIBorEthernet
    % Agilent E8267D vector signal generator
    %
    %
    % Author(s): Blake Johnson
    % Generated on: Tues Oct 19 2010
    
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
    
    methods
        function obj = AgilentE8267D()
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
            gpib_string = ':output:mod?';
            temp = obj.query([gpib_string]);
            val = temp;
        end
        function val = get.alc(obj)
            gpib_string = ':power:alc?';
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
        function val = get.WBIQ(obj)
            gpib_string = ':wdm:state?';
            temp = obj.query([gpib_string]);
            val = temp;
        end
        function val = get.WBIQ_Adjust(obj)
            gpib_string = ':wdm:IQAD?';
            temp = obj.query([gpib_string]);
            val = temp;
        end
        function val = get.WBIQ_IOffset(obj)
            gpib_string = ':wdm:iqad:ioff?';
            temp = obj.query([gpib_string]);
            val = str2double(temp);
        end
        function val = get.WBIQ_QOffset(obj)
            gpib_string = ':wdm:iqad:qoff?';
            temp = obj.query([gpib_string]);
            val = str2double(temp);
        end
        function val = get.WBIQ_Skew(obj)
            gpib_string = ':wdm:iqad:qskew?';
            temp = obj.query([gpib_string]);
            val = str2double(temp);
        end
        
        % property setters
        function obj = set.frequency(obj, value)
            gpib_string = ':freq:fixed %d GHz';

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
            obj.write(gpib_string);
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
            obj.write(gpib_string);
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
            obj.write(gpib_string);
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
            obj.write(gpib_string);
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
            obj.write(gpib_string);
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
            obj.write(gpib_string);
        end
        function obj = set.WBIQ_IOffset(obj, value)
            gpib_string = ':wdm:iqad:ioff %d';
            
            % Validate input
            if ~isnumeric(value)
                error('Invalid input');
            end
            
            gpib_string = sprintf(gpib_string, value);
            obj.write(gpib_string);
        end
        function obj = set.WBIQ_QOffset(obj, value)
            gpib_string = ':wdm:iqad:qoff %d';
            
            % Validate input
            if ~isnumeric(value)
                error('Invalid input');
            end
            
            gpib_string = sprintf(gpib_string, value);
            obj.write(gpib_string);
        end
        function obj = set.WBIQ_Skew(obj, value)
            gpib_string = ':wdm:iqad:qskew %d';
            
            % Validate input
            if ~isnumeric(value)
                error('Invalid input');
            end
            
            gpib_string = sprintf(gpib_string, value);
            obj.write(gpib_string);
        end
        function errs=check_errors(obj)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Check for errors
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%            
            first=1;
            errs=[];
            while 1
                a=query(obj,'SYST:ERR?');
                loc=find(a==',');
                errflag=str2num(a(1:(loc-1)));
                if errflag == 0
                    break;
                end
                errs=[errs errflag];
                if first
                  fprintf('Error occured on E8267D\n')
                  first=0;
                end
                fprintf('  -> "%s"\n',a);
            end
        end
        
    end % end instrument parameter accessors
    
    
end % end class definition