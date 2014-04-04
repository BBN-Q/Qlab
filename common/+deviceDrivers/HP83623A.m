classdef (Sealed) HP83623A < deviceDrivers.lib.uWSource & deviceDrivers.lib.GPIBorEthernet
    % Agilent N5183A microwave signal generator
    %
    %
    % Author(s): Blake Johnson/Regina Hain
    % Generated on: Tues Nov 1 20107
    
    % Device properties correspond to instrument parameters
    properties (Access = public)
        output
        frequency % This is in GHz as of some crazy change.
        power     % dB
        phase    
        mod
        alc
        pulse
        pulseSource
    end % end device properties
    
    methods
        function obj = HP83623A()
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
        function val = get.output(obj)
            val = obj.query(':POW:STAT?;');
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
        
        % property setters
        function obj = set.frequency(obj, value)
            assert(isnumeric(value), 'Requires numeric input');

            %mode_string = ':freq:mode fixed'; %set to fixed
            %obj.write(mode_string);
            obj.write(sprintf(':freq:fixed %dGHz;', value));
            obj.query('*OPC?');
            %Wait for frequency to settle
            pause(0.005);
        end
        function obj = set.power(obj, value)
            assert(isnumeric(value), 'Requires numeric input');
            obj.write(sprintf(':power %ddbm;', value));
        end
        function obj = set.output(obj, value)
            obj.write([':POW:STAT ' obj.cast_boolean(value) ';']);
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
