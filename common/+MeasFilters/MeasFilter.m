classdef MeasFilter < handle
    
    properties
        channel
        accumulatedData
        avgct
        childFilter
    end
    
    methods
        function obj = MeasFilter(settings)
            obj.channel = settings.channel;
        end
        
        function out = apply(obj, data)
            my_data = data.channel;
            if ~isempty(obj.childFilter)
                out = apply(obj.childFilter, my_data);
            else
                out = my_data;
            end
        end
    end
    
    methods (Abstract = true)
        
        %Return averaged data
        function data = get_data(obj)
        end
        
    end
    
    
end