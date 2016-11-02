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
        sweep
        sweepTrig
        pointTrig
        alc
        pulse
        pulseSource
        pulseWidth
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
        function val = get.pulseWidth(obj)
            val = str2double(obj.query(':PULM:INTernal:PWIDth?'));
        end
        
        % property setters
        function armsweep(obj)
            obj.write('INIT;');
        end
        function obj = set.sweep(obj, value)
            value=def(value,'dwell',0.001);
            obj.write(sprintf(':freq:start %f GHz;', value.start));
            obj.write(sprintf(':freq:stop %f GHz;', value.stop));
            obj.write(sprintf(':swe:poin %i;',value.points));
            obj.write(sprintf(':swe:dwel %g;', value.dwell));
            obj.write(':FREQ:MODE LIST;');
            obj.write(':INIT:CONT 1;');
            obj.check_errors();
        end
        function obj = set.pointTrig(obj, value)
            % Good choices are BUS, IMM, EXT, INT, KEY, TIM
            obj.write(sprintf(':list:trig:sour %s;', value));
        end
        function obj = set.sweepTrig(obj, value)
            % Good choices are BUS, IMM, EXT, INT, KEY, TIM
            obj.write(sprintf(':trig:sour %s;', value));
        end
        
        function obj = set.frequency(obj, value)
            assert(isnumeric(value), 'Requires numeric input');

            %mode_string = ':freq:mode fixed'; %set to fixed
            %obj.write(mode_string);
            obj.write(sprintf(':freq:fixed %20.10f Hz;', value*1e9));
            obj.query('*OPC?');
            %Wait for frequency to settle
            pause(0.005);
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
        function obj = set.pulseWidth(obj, value)
            assert(isnumeric(value), 'Requires numeric input');
            obj.write(sprintf(':PULM:INTernal:PWIDth %1.3e', value));
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
        function s=def(s,opt,def)
            % function s=def(s,opt,def)
            %% Utility functions
            if ~isfield(s,opt)
                s.(opt)=def;
            end
        end
    end
end % end class definition
