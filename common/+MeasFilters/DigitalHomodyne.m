% A single-channel digital homodyne measurement filter.

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
classdef DigitalHomodyne < MeasFilters.MeasFilter
   
    properties
        IFfreq
        samplingRate
        integrationStart
        integrationPts
    end
    
    methods
        function obj = DigitalHomodyne(settings)
            obj = obj@MeasFilters.MeasFilter(settings);
            obj.IFfreq = settings.IFfreq;
            obj.samplingRate = settings.samplingRate;
            obj.integrationStart = settings.integrationStart;
            obj.integrationPts = settings.integrationPts;
        end
        
        function out = apply(obj, data)
            import MeasFilters.*
            data = apply@MeasFilters.MeasFilter(obj, data);
            
            demodSignal = digitalDemod(data, obj.IFfreq, obj.samplingRate);
            
            %Box car filter the demodulated signal
            if ndims(demodSignal) == 2
                obj.latestData = 2*mean(demodSignal(obj.integrationStart:obj.integrationStart+obj.integrationPts-1,:));
            elseif ndims(demodSignal) == 4
                obj.latestData = 2*mean(demodSignal(obj.integrationStart:obj.integrationStart+obj.integrationPts-1,:,:,:));
            else
                error('Only able to handle 2 and 4 dimensional data.');
            end
                
            obj.accumulate();
            out = obj.get_data();
        end
    end
    
    
end