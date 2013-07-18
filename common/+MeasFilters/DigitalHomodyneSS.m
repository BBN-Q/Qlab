% A single-channel digital homodyne measurement filter without a boxcar filter.

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
classdef DigitalHomodyneSS < MeasFilters.MeasFilter
   
    properties
        IFfreq
        bandwidth
        samplingRate
        boxCarStart
        boxCarStop
        filter
        phase
    end
    
    methods
        function obj = DigitalHomodyneSS(settings)
            obj = obj@MeasFilters.MeasFilter(settings);
            obj.IFfreq = settings.IFfreq;
            obj.bandwidth = settings.bandwidth;
            obj.samplingRate = settings.samplingRate;
            obj.boxCarStart = settings.boxCarStart;
            obj.boxCarStop = settings.boxCarStop;
            obj.phase = settings.phase;
            
            if isfield(settings, 'filterFilePath') && ~isempty(settings.filterFilePath)
                obj.filter = load(settings.filterFilePath, 'filterCoeffs', 'bias');
            else
                obj.filter = [];
            end
        end
        
        function out = apply(obj, data)
            import MeasFilters.*
            data = apply@MeasFilters.MeasFilter(obj, data);
            
            [demodSignal, decimFactor] = digitalDemod(data, obj.IFfreq, obj.bandwidth, obj.samplingRate);
            
            % Use box car start/stop just to select a time span
            if ndims(demodSignal) == 2
                demodSignal = demodSignal(max(1,floor(obj.boxCarStart/decimFactor)):floor(obj.boxCarStop/decimFactor),:);
            elseif ndims(demodSignal) == 4
                demodSignal = demodSignal(max(1,floor(obj.boxCarStart/decimFactor)):floor(obj.boxCarStop/decimFactor),:,:,:);
            else
                error('Only able to handle 2 and 4 dimensional data.');
            end
            
            %If we have a pre-defined filter use it, otherwise just update
            %latestData
            if ~isempty(obj.filter)
                obj.latestData = bsxfun(@times, demodSignal, obj.filter.filterCoeffs') + obj.filter.bias;
            else
                %Integrate and rotate
                obj.latestData = demodSignal;
            end

            out = obj.latestData;
        end
    end
    
    
end