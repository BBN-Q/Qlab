classdef uWSource < deviceDrivers.lib.GPIB
    % Microwave Src Base Class
    %
    %
    % Author(s): Regina Hain
    % Generated on: Tues Oct 29 2010
    
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
%         output
%         frequency
%         power
%         phase
%         mod
%         alc
%         pulse
%         pulseSource
    end % end device properties
    
    % Class-specific private methods
    methods (Access = private)
        
    end % end private methods
    
    methods
        function obj = uWSource()
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
%         function val = get.frequency(obj)
%         end
%         
%         function val = get.power(obj)
%         end
%         
%         function val = get.phase(obj)
%         end
%         
%         function val = get.output(obj)
%         end
%         
%         function val = get.mod(obj)
%         end
%         
%         function val = get.alc(obj)
%         end
%         
%         function val = get.pulse(obj)
%         end
%         
%         function val = get.pulseSource(obj)
%         end
%         
%         % property setters
%         function obj = set.frequency(obj, value)
%         end
%         
%         function obj = set.power(obj, value)
%         end
%         
%         function obj = set.output(obj, value)
%         end
%         
%         % set phase in degrees
%         function obj = set.phase(obj, value)
%         end
%         
%         function obj = set.mod(obj, value)
%         end
%         
%         function obj = set.alc(obj, value)
%         end
%         
%         function obj = set.pulse(obj, value)
%         end
%         
%         function obj = set.pulseSource(obj, value)
%         end
        
    end % end instrument parameter accessors
    
    
end % end class definition
