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
        data
    end
    
    methods
        function obj = Correlator(label, settings, varargin)
            obj = obj@MeasFilters.MeasFilter(label, settings);
            obj.filters = varargin;
            obj.data = cell2struct(cell(length(obj.filters),1), cellfun(@(x) x.label, obj.filters, 'UniformOutput', false));
        end
        
        function apply(obj, src, ~)
            %queue up latest src data
            % stack latestData's and convert to array
            obj.data.(src.label) = cat(4, obj.data.(src.label), src.latestData);
            
            minSize = min(structfun(@(x) (ndims(x) > 2)*size(x,4), obj.data));
            
            if minSize > 0
                % take the product along the stacked dimension
                sizes = size(obj.data.(obj.filters{1}.label));
                sizes(4) = minSize;
                sizes = [sizes, length(obj.filters)];
                filterData = zeros(sizes);
                for ct = 1:length(obj.filters)
                    filterData(:,:,:,:,ct) = obj.data.(obj.filters{ct}.label)(:,:,:,1:minSize);
                    obj.data.(obj.filters{ct}.label)(:,:,:,1:minSize) = [];
                end
                obj.latestData = prod(filterData, ndims(filterData));
                obj.accumulate();
                notify(obj, 'DataReady');
            end
        end
    end
end