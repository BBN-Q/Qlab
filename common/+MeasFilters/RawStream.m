% A single-channel of raw data from a digitizer

% Author/Date : Colm Ryan / 22 November 2014

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

classdef RawStream < MeasFilters.MeasFilter
    
    properties
        fileName
        saveRecords
        channel
    end
    
    methods
        function obj = RawStream(settings)
            obj = obj@MeasFilters.MeasFilter(settings);
            obj.kernel = settings.kernel;
        end
        
        function apply(obj, src, ~)
            
            %Pull the raw stream from the digitizer
            obj.latestData = src.(channel);
            
            accumulate(obj);
            notify(obj, 'DataReady');
        end
    end
end
