% A single-shot fidelity estimator

% Author/Date : Blake Johnson and Colm Ryan / February 12, 2013

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
classdef SingleShot < MeasFilters.MeasFilter
   
    properties
        groundData
        excitedData
        histData
    end
    
    methods
        function obj = SingleShot(childFilter)
            obj = obj@MeasFilters.MeasFilter(childFilter, struct());
        end
        
        function out = apply(obj, data)
            % just grab (and sort) latest data from child filter
            data = apply@MeasFilters.MeasFilter(obj, data);
            %Assume that the data is recordLength x 1 (waveforms) x 2
            %(segments ground/excited) x roundRobinsPerBuffer
            obj.groundData = [obj.groundData; squeeze(data(1,1,1,:))];
            obj.excitedData = [obj.excitedData; squeeze(data(1,1,2,:))];
            out = [];
        end
        
        function out = get_data(obj)
            %If we don't have any data yet return empty
            if isempty(obj.groundData)
                out = [];
                return
            end
            
            % return histogrammed data
            obj.histData = struct();
            
            groundAmpData = real(obj.groundData);
            excitedAmpData = real(obj.excitedData);
            
            groundPhaseData = imag(obj.groundData);
            excitedPhaseData = imag(obj.excitedData);
            
            %Setup bins from the minimum to maximum measured voltage
            bins = linspace(min([groundAmpData; excitedAmpData]), max([groundAmpData; excitedAmpData]));
            
            groundCounts = histc(groundAmpData, bins);
            excitedCounts = histc(excitedAmpData, bins);
            
            maxAmpFidelity = (1/2/length(obj.groundData))*sum(abs(groundCounts-excitedCounts));
            
            obj.histData.bins_amp = bins;
            obj.histData.groundCounts_amp = groundCounts;
            obj.histData.excitedCounts_amp = excitedCounts;
            obj.histData.maxFidelity_amp = maxAmpFidelity;
            
            % recalculate bins for phase data
            bins = linspace(min([groundPhaseData; excitedPhaseData]), max([groundPhaseData; excitedPhaseData]));
            
            groundCounts = histc(groundPhaseData, bins);
            excitedCounts = histc(excitedPhaseData, bins);
            
            maxPhaseFidelity = (1/2/length(obj.groundData))*sum(abs(groundCounts-excitedCounts));
            
            obj.histData.bins_phase = bins;
            obj.histData.groundCounts_phase = groundCounts;
            obj.histData.excitedCounts_phase = excitedCounts;
            obj.histData.maxFidelity_phase = maxPhaseFidelity;

            out = maxAmpFidelity + 1j*maxPhaseFidelity;
        end
        
        function reset(obj)
            obj.groundData = [];
            obj.excitedData = [];
            obj.histData = struct();
        end
            
    end
end