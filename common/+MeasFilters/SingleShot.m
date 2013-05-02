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
        pdfData
        numShots = -1
        analysed = false
    end
    
    methods
        function obj = SingleShot(childFilter, varargin)
            obj = obj@MeasFilters.MeasFilter(childFilter, struct());
            if length(varargin) == 1
                obj.numShots = varargin{1};
            end
        end
        
        function out = apply(obj, data)
            % just grab (and sort) latest data from child filter
            data = apply@MeasFilters.MeasFilter(obj, data);
            %Assume that the data is recordLength x 1 (waveforms) x 2
            %(segments ground/excited) x roundRobinsPerBuffer
            obj.groundData = cat(2, obj.groundData, squeeze(data(:,1,1,:)));
            obj.excitedData = cat(2, obj.excitedData, squeeze(data(:,1,2,:)));
            out = [];
        end
        
        function out = get_data(obj)
            %If we don't have any data yet return empty
            if size(obj.groundData,2) ~= obj.numShots/2
                out = [];
                return
            end
            
            if ~obj.analysed
                % return histogrammed data
                obj.pdfData = struct();
                
                groundMean = mean(obj.groundData, 2);
                excitedMean = mean(obj.excitedData, 2);
                centre = 0.5*(groundMean+excitedMean);
                rotAngle = angle(excitedMean-groundMean);
                
                unwoundGroundData = bsxfun(@times, bsxfun(@minus, obj.groundData, centre), exp(-1j*rotAngle));
                unwoundExcitedData = bsxfun(@times, bsxfun(@minus, obj.excitedData, centre), exp(-1j*rotAngle));
                
                %Use the difference magnitude as a weight function
                diffMag = abs(excitedMean-groundMean);
                weights = diffMag/sum(diffMag);
                groundIData = bsxfun(@times, real(unwoundGroundData), weights);
                excitedIData = bsxfun(@times, real(unwoundExcitedData), weights);
                groundQData = bsxfun(@times, imag(unwoundGroundData), weights);
                excitedQData = bsxfun(@times, imag(unwoundExcitedData), weights);
                
                %Take cummulative sum up to each timestep
                intGroundIData = cumsum(groundIData, 1);
                intExcitedIData = cumsum(excitedIData, 1);
                intGroundQData = cumsum(groundQData, 1);
                intExcitedQData = cumsum(excitedQData, 1);
                
                %Loop through each intergration point; esimtate the CDF and
                %then calculate best measurement fidelity
                numTimePts = size(intGroundIData,1);
                fidelities = zeros(numTimePts,1);
                for intPt = 1:numTimePts
                    %Setup bins from the minimum to maximum measured voltage
                    bins = linspace(min([intGroundIData(intPt,:), intExcitedIData(intPt,:)]), max([intGroundIData(intPt,:), intExcitedIData(intPt,:)]));
                    
                    %Estimate the PDF for the ground and excited states
                    gPDF = ksdensity(intGroundIData(intPt,:), bins);
                    ePDF = ksdensity(intExcitedIData(intPt,:), bins);
                    
                    fidelities(intPt) = 0.5*(bins(2)-bins(1))*sum(abs(gPDF-ePDF));
                end
                
                [maxFidelity_I, intPt] = max(fidelities);
                obj.pdfData.bins_I = linspace(min([intGroundIData(intPt,:), intExcitedIData(intPt,:)]), max([intGroundIData(intPt,:), intExcitedIData(intPt,:)]));
                obj.pdfData.gPDF_I = ksdensity(intGroundIData(intPt,:), obj.pdfData.bins_I);
                obj.pdfData.ePDF_I = ksdensity(intExcitedIData(intPt,:), obj.pdfData.bins_I);
                obj.pdfData.maxFidelity_I = maxFidelity_I;
                
                fidelities = zeros(numTimePts,1);
                for intPt = 1:numTimePts
                    %Setup bins from the minimum to maximum measured voltage
                    bins = linspace(min([intGroundQData(intPt,:), intExcitedQData(intPt,:)]), max([intGroundQData(intPt,:), intExcitedQData(intPt,:)]));
                    
                    %Estimate the PDF for the ground and excited states
                    gPDF = ksdensity(intGroundQData(intPt,:), bins);
                    ePDF = ksdensity(intExcitedQData(intPt,:), bins);
                    
                    fidelities(intPt) = 0.5*(bins(2)-bins(1))*sum(abs(gPDF-ePDF));
                end
                
                [maxFidelity_Q, intPt] = max(fidelities);
                obj.pdfData.bins_Q = linspace(min([intGroundQData(intPt,:), intExcitedQData(intPt,:)]), max([intGroundQData(intPt,:), intExcitedQData(intPt,:)]));
                obj.pdfData.gPDF_Q = ksdensity(intGroundQData(intPt,:), obj.pdfData.bins_Q);
                obj.pdfData.ePDF_Q = ksdensity(intExcitedQData(intPt,:), obj.pdfData.bins_Q);
                obj.pdfData.maxFidelity_Q = maxFidelity_Q;
                
                out = maxFidelity_I + 1j*maxFidelity_Q;
                
                obj.analysed = true;
                
            else
                out = obj.pdfData.maxFidelity_I + 1j*obj.pdfData.maxFidelity_Q;
            end
        end
        
        function reset(obj)
            obj.groundData = [];
            obj.excitedData = [];
            obj.pdfData = struct();
            obj.analysed = false;
        end
        
    end
end