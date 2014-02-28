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
        frequency % This is in GHz as of some crazy change.
        power     % dB
        phase    
        mod
        alc
        pulse
        pulseSource
    end % end device properties
    
    methods
        function obj = uWSource()
        end
        
    end
    
    
end % end class definition
