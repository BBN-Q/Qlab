% A filter to select a virtual channel from a DSP scope

% Author/Date : Blake Johnson and Colm Ryan / August 29, 2014

% Copyright 2014 Raytheon BBN Technologies
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
classdef StreamSelector < MeasFilters.MeasFilter
    
    properties
        stream
    end
    
    methods
        function obj = StreamSelector(settings)
            obj = obj@MeasFilters.MeasFilter(settings);
            % convert round brackets to square brackets
            streamVec = eval(strrep(strrep(settings.stream, '(', '['), ')', ']'));
            % first index is the physical channel
            obj.channel = sprintf('ch%d', streamVec(1));
            obj.stream = ['s' sprintf('%d',streamVec)];
        end
        
        function out = apply(obj, data)
            import MeasFilters.*
            data = apply@MeasFilters.MeasFilter(obj, data);
            obj.accumulatedData = data.(obj.stream);
            out = obj.accumulatedData;
        end
        
        function out = get_data(obj)
            out = obj.accumulatedData;
        end
    end
    
    
end