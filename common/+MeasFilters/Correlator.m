% An N-channel product measurement filter. To create this filter you need
% to pass in the set of measurement filters to take the product of. For
% example:
% dh1 = DigitalHomodyne(...);
% dh2 = DigitalHomodyne(...);
% corrMeas = Correlator(dh1, dh2);

% Author/Date : Blake Johnson and Colm Ryan / February 4, 2013

% Copyright 2013 Raytheon BBN Technologies
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
%
%     http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.
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