classdef MeasFilter < handle
    
    properties
        channel
        latestData
        accumulatedData
        avgct = 0
        childFilter
    end
    
    methods
        function obj = MeasFilter(varargin)
            % MeasFilter(filter, settings) or MeasFilter(settings)
            if nargin == 1
                settings = varargin{1};
                filter = [];
            elseif nargin == 2
                [filter, settings] = varargin{:};
            end
            obj.channel = settings.channel;

            if ~isempty(filter)
                obj.childFilter = filter;
            end
        end
        
        function out = apply(obj, data)
            my_data = data.(obj.channel);
            if ~isempty(obj.childFilter)
                out = apply(obj.childFilter, my_data);
            else
                out = my_data;
            end
        end
        
        function reset(obj)
            obj.avgct = 0;
            obj.accumulatedData = [];
        end
        
    end
    
    methods (Abstract = true)
        
        %Return averaged data
        get_data(obj)
    end
    
    
end