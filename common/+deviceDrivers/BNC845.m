classdef (Sealed) BNC845 < deviceDrivers.lib.uWSource & deviceDrivers.lib.GPIBorEthernet
    % BNC845 signal generator
    %
    
    % Device properties correspond to instrument parameters
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
        function obj = BNC845()
            obj.DEFAULT_PORT = 18;
        end
        
        function connect(obj, address)
            %Call the superclass connector
            connect@deviceDrivers.lib.GPIBorEthernet(obj, address);
            
            %Setup the reference every time
            %Output 10MHz for daisy-chaining and lock to 10MHz external
            %reference
            write(obj, 'SOURCE:ROSC:OUTPUT:STATE ON');
            write(obj, 'SOURCE:ROSC:EXT:FREQ 10E6');
            write(obj, 'SOUR:ROSC:SOUR EXT');
            
            %Check that it locked
            ct = 0;
            while ct < 10
                locked = query(obj, 'SOURCE:ROSC:LOCKED?');
                if strcmp(locked, '1')
                    break;
                end
                pause(0.5);
                ct = ct + 1;
            end
            if ~strcmp(locked, '1')
                warning('BNC %s unlocked.', address);
            end

        end
        
        %Override setAll to workaround a BNC issue
        %Below 10GHz the BNC's put out broadband noise the first time the
        %RF is turned on after toggling modulation.
        function setAll(obj, settings)
            setAll@deviceDrivers.lib.deviceDriverBase(obj, settings);
            %Toggle output
            obj.output = false;
            obj.output = settings.output;
        end
            
        % Instrument parameter accessors
        % getters
        function val = get.frequency(obj)
            val = str2double(obj.query('SOURCE:FREQUENCY?'));
            %Convert to GHz units
            val = 1e-9*val;
        end
        
        function val = get.power(obj)
            val = str2double(obj.query('SOURCE:POWER?'));
        end
        
        function val = get.phase(obj)
            val = str2double(obj.query('SOURCE:PHASE:ADJUST?'));
        end
        
        function val = get.output(obj)
            val = str2double(obj.query('OUTPUT:STATE?'));
        end
        
        function val = get.alc(obj)
            val = str2double(obj.query('SOURCE:POWER:ALC?'));
        end
        
        function val = get.pulse(obj)
            val = str2double(obj.query('SOURCE:PULM:STATE?'));
        end
        
        function val = get.pulseSource(obj)
            val = obj.query('SOURCE:PULM:SOURCE?');
        end
        
        
        % property setters
        function obj = set.frequency(obj, value)
            % Validate input
            if ~isnumeric(value)
                error('Invalid input');
            end
            obj.write(sprintf('SOURCE:FREQUENCY:FIXED %E',value*1e9));
        end
        
        function obj = set.power(obj, value)
            % Validate input
            if ~isnumeric(value)
                error('Invalid input');
            end
            obj.write(sprintf('SOURCE:POWER:LEVEL:IMMEDIATE:AMPLITUDE %E',value));
        end
        
        function obj = set.output(obj, value)
            % test if value is a logical
            if islogical(value)
                if value
                    value = '1';
                else
                    value = '0';
                end
            end
            if isnumeric(value)
                value = num2str(value);
            end
            
            % Validate input
            onOffMap = containers.Map({'on','1','off','0'},...
                {'1','1','0','0'});
            if not (onOffMap.isKey( lower(value) ))
                error('Invalid input');
            end
            obj.write(sprintf('OUTPUT:STATE %c', onOffMap(value)));
        end
        % set phase in degrees
        function obj = set.phase(obj, value)
            obj.write(sprintf('SOURCE:PHASE:ADJUST %f', value));
        end
        
        function obj = set.alc(obj, value)
            % test if value is a logical
            if islogical(value)
                if value
                    value = '1';
                else
                    value = '0';
                end
            end
            if isnumeric(value)
                value = num2str(value);
            end
            % Validate input
            onOffMap = containers.Map({'on','1','off','0'},...
                {'ON','ON','OFF','OFF'});
            if not (onOffMap.isKey( lower(value) ))
                error('Invalid input');
            end
            obj.write(sprintf('SOURCE:POWER:ALC %s',onOffMap(value)));
        end
        
        function obj = set.pulse(obj, value)
            % test if value is a logical
            if islogical(value)
                if value
                    value = '1';
                else
                    value = '0';
                end
            end
            if isnumeric(value)
                value = num2str(value);
            end
            % Validate input
            onOffMap = containers.Map({'on','1','off','0'},...
                {'ON','ON','OFF','OFF'});
            holdMap = containers.Map({'on','1','off','0'},{'ON','ON','OFF','OFF'});
            if not (onOffMap.isKey( lower(value) ))
                error('Invalid input');
            end
            
            obj.write(sprintf('SOURCE:PULM:STATE %s', onOffMap(value)));
            obj.write(sprintf('SOURCE:POWER:ALC:HOLD %s',holdMap(value)));

        end
        
        function obj = set.pulseSource(obj, value)
            % Validate input
            onOffMap = containers.Map({'int','internal','ext','external'},...
                {'INT','INT','EXT','EXT'});
            if not (onOffMap.isKey( lower(value) ))
                error('Invalid input');
            end
            
            obj.write(sprintf('SOURCE:PULM:SOURCE %s', onOffMap(lower(value))));
        end
        
    end % end instrument parameter accessors
    
    
end % end class definition