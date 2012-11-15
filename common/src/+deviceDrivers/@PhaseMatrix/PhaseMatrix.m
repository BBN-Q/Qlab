classdef (Sealed) PhaseMatrix < deviceDrivers.lib.uWSource & deviceDrivers.lib.Serial
    % PhaseMatrix signal generator
    
    properties (Access = public)
        output
        frequency
        power
        phase
        alc
        pulse
        pulseSource
        mod
    end % end device properties
    
    methods
        function obj = PhaseMatrix()
            obj.baudRate = 115200;
        end
		
		% Instrument parameter accessors
        % getters
        function val = get.frequency(obj)
            val = str2double(obj.query('FREQ?'));
            %Convert to GHz units (returns in mHz
            val = 1e-12*val;
        end
        
        function val = get.power(obj)
            val = str2double(obj.query('POW?'));
        end
        
        function val = get.phase(obj)
            %Dummy function
            val = NaN;
        end
        
        function val = get.output(obj)
            val = str2double(obj.query('OUTP:STAT?'));
        end
        
        function val = get.alc(obj)
            %Dummy no alc on PhaseMatrix
            val = NaN;
        end
        
        function val = get.pulse(obj)
            strVal = obj.query('PULM:STAT?');
            if strfind(strVal, 'ON')
                val = 1;
            elseif strfind(strVal, 'OFF')
                val = 0;
            else
                error('Unrecognized return value: %s', strVal);
            end
        end
        
        function val = get.pulseSource(obj)
            %Empty dummy function
            val = NaN;
        end
        
        
        % property setters
        function obj = set.frequency(obj, value)
            % Validate input
            if ~isnumeric(value)
                error('Invalid input');
            end
            %Assume input is in GHz
            obj.write(sprintf('FREQ %fGHz',value));
        end
        
        function obj = set.power(obj, value)
            % Validate input
            if ~isnumeric(value)
                error('Invalid input');
            end
            obj.write(sprintf('POW %f',value));
        end
        
        function obj = set.output(obj, value)
            if isnumeric(value)
                value = num2str(value);
            end
            
            % Validate input
            onOffMap = containers.Map({'on','1','off','0'},...
                {'ON','ON','OFF','OFF'});
            if not (onOffMap.isKey( lower(value) ))
                error('Invalid input');
            end
            obj.write(sprintf('OUTP:STAT %s', onOffMap(value)));
        end
        
        % set phase in degrees
        function obj = set.phase(obj, value)
            %Empty dummy function
        end
        
        function obj = set.alc(obj, value)
            %Empty dummy function
        end
        
        function obj = set.pulse(obj, value)
            if isnumeric(value)
                value = num2str(value);
            end
            % Validate input
            onOffMap = containers.Map({'on','1','off','0'},...
                {'ON','ON','OFF','OFF'});
            if not (onOffMap.isKey( lower(value) ))
                error('Invalid input');
            end
            
            obj.write(sprintf('PULM:STAT %s', onOffMap(value)));
        end
        
        function obj = set.pulseSource(obj, value)
            %Dummy function
        end
        
    end % end instrument parameter accessors
    
    
end % end class definition