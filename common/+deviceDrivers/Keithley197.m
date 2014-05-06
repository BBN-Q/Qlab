%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Keithley Digital Multimeter Device 197
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef Keithley197 < deviceDrivers.lib.GPIB
    
    properties
        autoRange;
        mode;
        value;
    end
    
    methods
        function obj = Keithley197()
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
                obj.write('R0X;');
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
                    obj.write('F3X');
                case {'V','v'}
                    obj.write('F0X');
                case {'R','r'}
                    obj.write('F2X');
                otherwise
                    MException('DMM:BadInput', ...
                        'Value: %i is invalid',value);
                    return
            end
            obj.mode = value;
        end
        
        function [str,rc] = get.value(obj)
            obj.write('READ?');
            pause(.1);
            rc = obj.read();
            str=rc(5:end);
            rc = str2num(rc(5:end));
        end
    end
end