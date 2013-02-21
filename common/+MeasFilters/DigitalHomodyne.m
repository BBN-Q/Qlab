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
            
            [demodSignal, decimFactor] = digitalDemod(data, obj.IFfreq, obj.samplingRate);
            
%             save(['SSRecords_', datestr(now, 'yymmdd-HH-MM-SS'), '.mat'], 'demodSignal');
            
            %Box car the demodulated signal
            if ndims(demodSignal) == 2
                demodSignal = demodSignal(floor(obj.integrationStart/decimFactor):floor((obj.integrationStart+obj.integrationPts-1)/decimFactor),:);
            elseif ndims(demodSignal) == 4
                demodSignal = demodSignal(floor(obj.integrationStart/decimFactor):floor((obj.integrationStart+obj.integrationPts-1)/decimFactor),:,:,:);
            else
                error('Only able to handle 2 and 4 dimensional data.');
            end
            
            
            
            %Integrate
            obj.latestData = 2*mean(demodSignal,1);
                
            obj.accumulate();
            out = obj.latestData;
        end
    end
    
    
end