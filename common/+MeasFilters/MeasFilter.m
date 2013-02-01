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
        
        function accumulate(obj)
            % data comes back from the scope as either 2D (time x segment)
            % or 4D (time x waveforms x segment x roundRobinsPerBuffer)
            % in the 4D case, we want to average over waveforms and round
            % robins
            if ndims(obj.latestData) > 2
                tmpData = squeeze(mean(mean(obj.latestData, 4), 2));
            else
                tmpData = obj.latestData;
            end
            if isempty(obj.accumulatedData)
                obj.accumulatedData = tmpData;
            else
                obj.accumulatedData = obj.accumulatedData + tmpData;
            end
            obj.avgct = obj.avgct + 1;
        end
        
        function out = get_data(obj)
            out = obj.accumulatedData / obj.avgct;
        end
    end
    
end