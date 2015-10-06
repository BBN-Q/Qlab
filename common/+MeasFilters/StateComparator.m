% A measurement filter to convert a demodulated signal into a vector of
% hard decisions on qubit state outcomes.

% Author/Date : Blake Johnson and Colm Ryan / July 12, 2013

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
classdef StateComparator < MeasFilters.MeasFilter

    properties
        integrationTime = -1
        threshold = 0
    end

    methods
        function obj = StateComparator(label, settings)
            obj = obj@MeasFilters.MeasFilter(label,settings);
            obj.integrationTime = settings.integrationTime;
            obj.threshold = settings.threshold;
            obj.saved = false;
        end

        function apply(obj, src, ~)
            data = src.latestData;
            
            % integrate and threshold
            if obj.integrationTime < 0
                obj.integrationTime = size(data,1);
            end
            sumdata = sum(data(1:obj.integrationTime,:,:,:), 1);
            % better to cast to int32, but need to update the data file handler to support it
            obj.latestData = double(real(sumdata) > obj.threshold) + 1j*double(imag(sumdata) > obj.threshold);
            
            accumulate(obj);
            notify(obj, 'DataReady');

        end

    end
end
