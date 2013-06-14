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
        bandwidth
        samplingRate
        boxCarStart
        boxCarStop
        filter
        phase
        fileHandleReal
        fileHandleImag
        saveRecords
        headerWritten = false;
    end
    
    methods
        function obj = DigitalHomodyne(settings)
            obj = obj@MeasFilters.MeasFilter(settings);
            obj.IFfreq = settings.IFfreq;
            obj.bandwidth = settings.bandwidth;
            obj.samplingRate = settings.samplingRate;
            obj.boxCarStart = settings.boxCarStart;
            obj.boxCarStop = settings.boxCarStop;
            obj.phase = settings.phase;
            
            if isfield(settings, 'filterFilePath') && ~isempty(settings.filterFilePath)
                obj.filter = load(settings.filterFilePath, 'filter', 'bias');
            else
                obj.filter = [];
            end
            
            obj.saveRecords = settings.saveRecords;
            if obj.saveRecords
                obj.fileHandleReal = fopen([settings.recordsFilePath, '.real'], 'wb');
                obj.fileHandleImag = fopen([settings.recordsFilePath, '.imag'], 'wb');
            end
        end
        
        function delete(obj)
            if obj.saveRecords
                fclose(obj.fileHandleReal);
                fclose(obj.fileHandleImag);
            end
        end
        
        function out = apply(obj, data)
            import MeasFilters.*
            data = apply@MeasFilters.MeasFilter(obj, data);
            
            [demodSignal, decimFactor] = digitalDemod(data, obj.IFfreq, obj.bandwidth, obj.samplingRate);
            
            %Box car the demodulated signal
            if ndims(demodSignal) == 2
                demodSignal = demodSignal(max(1,floor(obj.boxCarStart/decimFactor)):floor(obj.boxCarStop/decimFactor),:);
            elseif ndims(demodSignal) == 4
                demodSignal = demodSignal(max(1,floor(obj.boxCarStart/decimFactor)):floor(obj.boxCarStop/decimFactor),:,:,:);
                %If we have a file to save to then do so
                if obj.saveRecords
                    if ~obj.headerWritten
                        %Write the first three dimensions of the demodSignal:
                        %recordLength, numWaveforms, numSegments
                        sizes = size(demodSignal);
                        fwrite(obj.fileHandleReal, sizes(1:3), 'int32');
                        fwrite(obj.fileHandleImag, sizes(1:3), 'int32');
                        obj.headerWritten = true;
                    end
                    
                    fwrite(obj.fileHandleReal, real(demodSignal), 'single');
                    fwrite(obj.fileHandleImag, imag(demodSignal), 'single');
                end
                
            else
                error('Only able to handle 2 and 4 dimensional data.');
            end
            
            %If we have a pre-defined filter use it, otherwise integrate
            %and rotate
            if ~isempty(obj.filter)
                obj.latestData = sum(bsxfun(@times, demodSignal, obj.filter.filter')) + obj.filter.bias;
            else
                %Integrate and rotate
                obj.latestData = exp(1j*obj.phase) * 2 * mean(demodSignal,1);
            end
            
            obj.accumulate();
            out = obj.latestData;
        end
    end
    
    
end