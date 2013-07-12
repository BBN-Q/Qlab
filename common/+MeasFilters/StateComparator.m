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
        function obj = StateComparator(childFilter, settings)
            obj = obj@MeasFilters.MeasFilter(childFilter, struct('plotMode', 'real/imag'));
            obj.integrationTime = settings.integrationTime;
            obj.threshold = settings.threshold;
        end
        
        function out = apply(obj, data)
            % apply child filter
            data = apply@MeasFilters.MeasFilter(obj, data);

            % integrate and threshold
            if obj.integrationTime < 0
                obj.integrationTime = size(data,1);
            end
            sumdata = sum(data(1:obj.integrationTime,:,:,:), 1);
            % better to cast to int32, but need to update the data file handler to support it
            obj.latestData = double(real(sumdata) > obj.threshold) + 1j*double(imag(sumdata) > obj.threshold);
            
            obj.accumulate();
            out = obj.latestData;
        end

        function accumulate(obj)
            % data comes back from the scope as either 2D (time x segment)
            % or 4D (time x waveforms x segment x roundRobinsPerBuffer)
            % in the 4D case, we want to average over waveforms and round
            % robins
            assert(ndims(obj.latestData) == 4, 'State comparator expects single-shot data, so latestData should be 4D');
            numShots = size(obj.latestData,2)*size(obj.latestData,4);
            tmpData = squeeze(sum(sum(obj.latestData, 4), 2));
            tmpVar = struct();
            tmpVar.real = squeeze(sum(sum(real(obj.latestData).^2, 4), 2));
            tmpVar.imag = squeeze(sum(sum(imag(obj.latestData).^2, 4), 2));
            tmpVar.prod = squeeze(sum(sum(real(obj.latestData).*imag(obj.latestData), 4), 2));
            obj.varct = obj.varct + numShots;
            
            if isempty(obj.accumulatedData)
                obj.accumulatedData = tmpData;
                obj.accumulatedVar = tmpVar;
            else
                obj.accumulatedData = obj.accumulatedData + tmpData;
                obj.accumulatedVar.real = obj.accumulatedVar.real + tmpVar.real;
                obj.accumulatedVar.imag = obj.accumulatedVar.imag + tmpVar.imag;
                obj.accumulatedVar.prod = obj.accumulatedVar.prod + tmpVar.prod;
            end
            obj.avgct = obj.avgct + numShots;
        end
        
                
        function out = get_var(obj)
            out = struct();
            if ~isempty(obj.accumulatedVar)
                out.realvar = (1/obj.varct)*obj.accumulatedVar.real - real(get_data(obj)).^2;
                out.imagvar = (1/obj.varct)*obj.accumulatedVar.imag - imag(get_data(obj)).^2;
                out.prodvar = (1/obj.varct)*obj.accumulatedVar.prod - abs(get_data(obj)).^2;
            end
        end
        
    end
end