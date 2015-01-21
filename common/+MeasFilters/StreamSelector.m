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
        channel
        stream
        saveRecords
        fileHandleReal
        fileHandleImag
        headerWritten = false;
    end
    
    methods
        function obj = StreamSelector(settings)
            obj = obj@MeasFilters.MeasFilter(settings);
            % convert round brackets to square brackets
            streamVec = eval(strrep(strrep(settings.stream, '(', '['), ')', ']'));
            % first index is the physical channel
            obj.channel = streamVec(1);
            obj.stream = streamVec;
            obj.saveRecords = settings.saveRecords;
            if obj.saveRecords
                obj.fileHandleReal = fopen([settings.recordsFilePath, '.real'], 'wb');
                obj.fileHandleImag = fopen([settings.recordsFilePath, '.imag'], 'wb');
            end
        end
        
        function apply(obj, src, ~)
            
            %Pull the raw stream from the digitizer
            obj.latestData = src.transfer_stream(obj.stream(1), obj.stream(2), obj.stream(3));
            
%           %If we have a file to save to then do so
            if obj.saveRecords
                if ~obj.headerWritten
                    %Write the first three dimensions of the signal:
                    %recordLength, numWaveforms, numSegments
                    sizes = size(obj.latestData);
                    if length(sizes) == 2
                        sizes = [sizes(1), 1, sizes(2)];
                    end
                    fwrite(obj.fileHandleReal, sizes(1:3), 'int32');
                    fwrite(obj.fileHandleImag, sizes(1:3), 'int32');
                    obj.headerWritten = true;
                end
                
                fwrite(obj.fileHandleReal, real(obj.latestData), 'single');
                fwrite(obj.fileHandleImag, imag(obj.latestData), 'single');
            end
            

            %Data accumulated in driver
            obj.accumulatedData = obj.latestData;
            notify(obj, 'DataReady');
        end
        
        function out = get_data(obj)
            out = obj.accumulatedData;
        end
    end
    
    
end