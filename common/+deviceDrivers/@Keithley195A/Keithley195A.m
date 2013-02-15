%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Keithley Digital Multimeter Device
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef (Sealed) Keithley195A < deviceDrivers.lib.GPIB
    properties
        autoRange;
        mode;
        value;
    end
    methods
        function obj = Keithley195A(vendor,id)
            if ~exist('vendor','var')
                vendor = 'ni';
            end
            if ~exist('id','var')
                id = 0;
            end
            % Initialize Super class
            obj = obj@deviceDrivers.lib.GPIB(vendor,id);
            obj.autoRange = 0;
            obj.mode = 'none';
            obj.Name = 'Keithley195A';
        end
        
        function setAll(obj,init_params)
            fs = fields(init_params);
            for i = 1:length(fs)
                initStr = sprintf('obj.%s = init_params.%s;',fs{i},fs{i});
                eval(initStr);
            end
        end
        
        function set.autoRange(obj,value)
            if value ~= 0 && value ~= 1
                MException('DMM:set.autoRange:BadInput', ...
                    'Value: %i is invalid',value);
            end
            
            obj.autoRange = value;
            if value
                obj.Write('R0X');
            end
        end
        
        function measureVoltage(obj)
            obj.mode = 'V';
        end
        
        function measureCurrent(obj)
            obj.mode = 'I';
        end
        
        function measureOhms(obj)
            obj.mode = 'R';
        end
        
        function set.mode(obj,value)
            switch value
                case {'I','i'}
                    obj.Write('F3X');
                case {'V','v'}
                    obj.Write('F0X');
                case {'R','r'}
                    obj.Write('F2X');
                otherwise
                    MException('DMM:BadInput', ...
                        'Value: %i is invalid',value);
                    return
            end
            obj.mode = value;
        end
        
        function rc = get.value(obj)
            obj.Write('READ?');
            pause(.1);
            rc = obj.Read();
            rc = str2num(rc(5:end));
        end
    end
end