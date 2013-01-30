classdef Correlator < MeasFilters.MeasFilter
   
    properties
        filters = {}
    end
    
    methods
        function obj = Correlator(varargin)
            obj = obj@MeasFilters.MeasFilter(struct('channel', []));
            obj.filters = varargin;
        end
        
        function out = apply(obj, ~)
            filterData = cellfun(@(x) x.latestData, obj.filters, 'UniformOutput', false);
            filterData = cell2mat(filterData);
            
            obj.latestData = prod(filterData, ndims(filterData));

            %The first time we just assign
            if isempty(obj.accumulatedData)
                obj.accumulatedData = obj.latestData;
            else
                obj.accumulatedData = obj.accumulatedData + obj.latestData;
            end
            obj.avgct = obj.avgct + 1;
            out = obj.accumulatedData / obj.avgct;
        end
        
        function out = get_data(obj)
            out = obj.accumulatedData / obj.avgct;
        end
    end
    
    
end