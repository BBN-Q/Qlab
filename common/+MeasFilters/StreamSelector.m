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
        stream=struct()
        saveRecords
        fileHandleReal
        fileHandleImag
        headerWritten = false;
        streamMode
    end

    constants
        DIGITZER_STREAM = 0;
        AVERAGER_STREAM = 1;
    end

    methods
        function obj = StreamSelector(label, settings)
            obj = obj@MeasFilters.MeasFilter(label, settings);

            % stream property is a list of stream tuples of the form: (a,b,c), (u,v,w), ...
            tokens = regexp(settings.stream, '(\([\d\w,]+\))', 'tokens');
            for ct = 1:length(tokens)
                % convert round brackets to square brackets so that it becomes a vector
                streamVec = eval(strrep(strrep(tokens{ct}{1}, '(', '['), ')', ']'));
                if ct==1
                    obj.stream = struct('a', streamVec(1), 'b', streamVec(2), 'c', streamVec(3));
                else
                    obj.stream(ct) = struct('a', streamVec(1), 'b', streamVec(2), 'c', streamVec(3));
                end
            end

            obj.saveRecords = settings.saveRecords;
            if obj.saveRecords
                obj.fileHandleReal = fopen([settings.recordsFilePath, '.real'], 'wb');
                obj.fileHandleImag = fopen([settings.recordsFilePath, '.imag'], 'wb');
            end
            obj.streamMode = obj.DIGITZER_STREAM;
        end

        function delete(obj)
            if obj.saveRecords
                fclose(obj.fileHandleReal);
                fclose(obj.fileHandleImag);
            end
        end

        function apply(obj, src, ~)

            %Pull the raw stream from the digitizer
            obj.latestData = src.transfer_stream(obj.stream);
            if strcmp(src.digitizerMode, 'AVERAGER')
                % in averager mode, the variance is calculated by the driver
                obj.accumulatedVar = src.transfer_stream_variance(obj.stream);
                obj.streamMode = obj.AVERAGER_STREAM;
                obj.avgct = 1;
            end

            %If we have a file to save to then do so
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


            if obj.streamMode == obj.AVERAGER_STREAM
                %Data accumulated in driver
                obj.accumulatedData = obj.latestData;
            else
                accumulate(obj);
            end
            notify(obj, 'DataReady');
        end

        function out = get_var(obj)
            if obj.streamMode == obj.AVERAGER_STREAM
                out = struct();
                out.realvar = obj.accumulatedVar.real;
                out.imagvar = obj.accumulatedVar.imag;
                out.prodvar = obj.accumulatedVar.prod;
            else
                out = get_var@MeasFilters(obj);
        end
    end


end
