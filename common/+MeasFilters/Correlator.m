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
            % stack latestData's and convert to array
            filterData = cat(ndims(filterData{1})+1, filterData{:});
            % take the product along the stacked dimension
            obj.latestData = prod(filterData, ndims(filterData));

            obj.accumulate();
            out = obj.get_data();
        end
    end
end