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
    
    methods
        function obj = AgilentN5183A()
            %obj = obj@deviceDrivers.lib.uWSource();
        end
        
		% Instrument parameter accessors
        % getters
        function val = get.frequency(obj)
            val = str2double(obj.query(':freq?;'))*1e-9; % convert to GHz
        end
        function val = get.power(obj)
            val = str2double(obj.query(':power?;'));
        end
        function val = get.phase(obj)
            val = str2double(obj.query(':phase?;'));
        end
        function val = get.output(obj)
            val = obj.query(':output?;');
        end
        function val = get.mod(obj)
            val = obj.query(':output:mod?;');
        end
        function val = get.alc(obj)
            val = obj.query(':power:alc?;');
        end
        function val = get.pulse(obj)
            val = obj.query(':pulm:state?;');
        end
        function val = get.pulseSource(obj)
            val = obj.query(':pulm:source?;');
        end
        function val = get.IQ(obj)
            val = obj.query(':dm:state?;');
        end
        function val = get.IQ_Adjust(obj)
            val = obj.query(':dm:IQAD?;');
        end
        function val = get.IQ_IOffset(obj)
            val = str2double(obj.query(':dm:iqad:ioff?;'));
        end
        function val = get.IQ_QOffset(obj)
            val = str2double(obj.query(':dm:iqad:qoff?;'));
        end
        function val = get.IQ_Skew(obj)
            val = str2double(obj.query(':dm:iqad:qskew?;'));
        end
        
        % property setters
        function obj = set.frequency(obj, value)
            assert(isnumeric(value), 'Requires numeric input');

            %mode_string = ':freq:mode fixed'; %set to fixed
            %obj.write(mode_string);
            obj.write(sprintf(':freq:fixed %d GHz;', value));

            %Wait for frequency to settle
            pause(0.02);
        end
        function obj = set.power(obj, value)
            assert(isnumeric(value), 'Requires numeric input');
            obj.write(sprintf(':power %ddbm;', value));
        end
        function obj = set.output(obj, value)
            obj.write([':output ' obj.cast_boolean(value) ';']);
        end
        % set phase in degrees
        function obj = set.phase(obj, value)
            assert(isnumeric(value), 'Requires numeric input');
            obj.write(sprintf(':phase %dDEG;', value));
        end
        function obj = set.mod(obj, value)
            obj.write([':output:mod ' obj.cast_boolean(value) ';']);
        end
        function obj = set.alc(obj, value)
            obj.write([':power:alc ' obj.cast_boolean(value) ';']);
        end
        function obj = set.pulse(obj, value)
            obj.write([':pulm:state ' obj.cast_boolean(value) ';']);
        end
        function obj = set.pulseSource(obj, value)
            value = lower(value);
            % Validate input
            checkMapObj = containers.Map({'int','internal','ext','external'},...
                {'int','int','ext','ext'});
            if not (checkMapObj.isKey(value))
                error('Invalid input');
            end
            obj.write([':pulm:source ' checkMapObj(value) ';']);
        end
        function obj = set.IQ(obj, value)
            obj.write([':dm:state ' obj.cast_boolean(value) ';']);
        end
        function obj = set.IQ_Adjust(obj, value)
            obj.write([':dm:IQAD ' obj.cast_boolean(value) ';']);
        end
        function obj = set.IQ_IOffset(obj, value)
            assert(isnumeric(value), 'Requires numeric input');
            obj.write(sprintf(':dm:iqad:ioff %d;', value));
        end
        function obj = set.IQ_QOffset(obj, value)
            assert(isnumeric(value), 'Requires numeric input');
            obj.write(sprintf(':dm:iqad:qoff %d;', value));
        end
        function obj = set.IQ_Skew(obj, value)
            assert(isnumeric(value), 'Requires numeric input');
            obj.write(sprintf(':dm:iqad:qskew %d;', value));
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
                  fprintf('Error occured on N5183\n')
                  first=0;
                end
                fprintf('  -> "%s"\n',a);
            end
        end
    end % end instrument parameter accessors
    
    methods (Static)
       
        %Helper function to cast boolean inputs to 'on'/'off' strings
        function out = cast_boolean(in)
            if isnumeric(in)
                in = logical(in);
            end
            if islogical(in)
                if in
                    in = 'on';
                else 
                    in = 'off';
                end
            end
            
            checkMapObj = containers.Map({'on','1','off','0'},...
                {'on','on','off','off'});
            assert(checkMapObj.isKey(lower(in)), 'Invalid input');
            out = checkMapObj(lower(in));
        end
        
    end
end % end class definition
