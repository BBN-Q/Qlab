classdef HP8153A < deviceDrivers.lib.GPIB
    
    properties
        SourceWavelength
    end
    
       methods
        function obj = HP8153A()
        end
        
        %Get Source Wavelength
        function val = get.SourceWavelength(obj)
            val = str2double(obj.query('SOUR:POW:WAVE?'));
        end
        
        %Set Source Wavelength
        function obj = set.SourceWavelength(obj,value)
            if value==1300
                obj.write('SOUR:POW:WAVE LOW');
            elseif value==1550
                obj.write('SOUR:POW:WAVE UPP');
            else
                error('Valid inputs are 1300 or 1550');
            end
        end
            
        
        
        
       end
end