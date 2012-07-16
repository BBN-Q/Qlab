classdef uWSource < deviceDrivers.lib.deviceDriverBase
    % Microwave Source Base Class
    %
    %
    % Author(s): Regina Hain, Colm Ryan, and Blake Johnson
    % Generated on: Tues Oct 29 2010
    % Modified July 2, 2012
    
    % Device properties correspond to instrument parameters
    properties (Access = public, Abstract = true)
        output
        frequency
        power
        phase
        mod
        alc
        pulse
        pulseSource
    end % end device properties
    
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
        
    end % end instrument parameter accessors
    
    
end % end class definition
