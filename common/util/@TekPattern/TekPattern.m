% File: TekPattern.m
%
% Description: class wrapper for functions that generate Tek AWG 5000 pattern files
%

% Copyright 2010 Raytheon BBN Technologies
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

classdef TekPattern < handle
    methods (Static)
        function exportTekSequence(path, basename, seqData, options)
            
            %Check that all channels have the same dimension
            dims = structfun(@size, seqData, 'UniformOutput', false);
            assert(all(TekPattern.range(cell2mat(struct2cell(dims))) == 0), 'All channels must have same dimensions');
            
            %Default options structure
            if ~exist('options', 'var')
                options = struct();
            end
            if ~isfield(options, 'verbose')
                options.verbose = true;
            end
            
            self = TekPattern;
            
            % pack patterns and markers into 16-bit binary format
            if options.verbose
                disp('Packing patterns');
            end
            packedCh1 = self.packPattern(seqData.ch1, seqData.ch1m1, seqData.ch1m2);
            packedCh2 = self.packPattern(seqData.ch2, seqData.ch2m1, seqData.ch2m2);
            packedCh3 = self.packPattern(seqData.ch3, seqData.ch3m1, seqData.ch3m2);
            packedCh4 = self.packPattern(seqData.ch4, seqData.ch4m1, seqData.ch4m2);
            
            if options.verbose
                disp('Done packing');
            end
            
            % open file
            if options.verbose
                disp('Writing AWG file');
            end
            fullpath = strcat(path, basename, '.awg');
            if ~exist(path, 'dir')
                mkdir(path);
            end
            
            fid = fopen(fullpath, 'w');
            
            % write header information
            numsteps = dims.ch1(1);
            self.writeTekHeader(fid, numsteps, basename, options);
            
            % write patterns
            for i = 1:numsteps
                % by some weird Tektronix convention, waveform numbering
                % starts at 21
                self.writeTekPattern(fid, sprintf('%sCh1%03d', basename, i), 20 + 4*(i - 1) + 1, packedCh1(i,:));
                self.writeTekPattern(fid, sprintf('%sCh2%03d', basename, i), 20 + 4*(i - 1) + 2, packedCh2(i,:));
                self.writeTekPattern(fid, sprintf('%sCh3%03d', basename, i), 20 + 4*(i - 1) + 3, packedCh3(i,:));
                self.writeTekPattern(fid, sprintf('%sCh4%03d', basename, i), 20 + 4*(i - 1) + 4, packedCh4(i,:));
            end
            
            % write sequence table
            self.writeTekSeqTable(fid, basename, numsteps, options);
            
            % close file
            fclose(fid);
        end
        
        function status = exportTek7Sequence(path, basename, patCh1, m11, m12, patCh2, m21, m22,options)
            % error check
            dims = size(patCh1);
            if (~isequal(size(m11), dims) || ~isequal(size(m12), dims) || ~isequal(size(patCh2), dims) || ~isequal(size(m21), dims) || ~isequal(size(m22), dims) )
                error('inputs must all have the same dimensions');
            end
            if ~exist('options', 'var')
                options = struct();
            end
            if ~isfield(options, 'verbose')
                options.verbose = true;
            end
            
            self = TekPattern;
            
            % pack patterns and markers into 16-bit binary format
            if options.verbose
                disp('Packing patterns');
            end
            packedCh1 = self.pack7Pattern(patCh1, m11, m12);
            packedCh2 = self.pack7Pattern(patCh2, m21, m22);
            if options.verbose
                disp('Done packing');
            end
            
            % open file
            if options.verbose
                disp('Writing AWG file');
            end
            fullpath = strcat(path, basename, '.awg');
            if ~exist(path, 'dir')
                mkdir(path);
            end
            fid = fopen(fullpath, 'w');
            
            % write header information
            numsteps = size(patCh1,1);
            self.writeTek7Header(fid, numsteps, basename, options);
            
            % write patterns
            for i = 1:numsteps
                % by some weird Tektronix convention, waveform numbering
                % starts at 21
                self.writeTekPattern(fid, sprintf('%sCh1%03d', basename, i), 20 + 4*(i - 1) + 1, packedCh1(i,:));
                self.writeTekPattern(fid, sprintf('%sCh2%03d', basename, i), 20 + 4*(i - 1) + 2, packedCh2(i,:));
            end
            
            % write sequence table
            self.writeTek7SeqTable(fid, basename, numsteps, options);
            
            % close file
            fclose(fid);
        end
        
        function pattern = packPattern(pattern, marker1, marker2)
            % AWG 5000 series binary data format
            % m2 m1 d14 d13 d12 d11 d10 d9 d8 d7 d6 d5 d4 d3 d2 d1
            % 16-bit format with markers occupying left 2 bits followed by the 14 bit
            % analog channel value
            
            % clip patterns to 14-bits
            pattern = uint16(pattern);
            pattern( pattern > 2^14 - 1 ) = 2^14 - 1;
            
            % integrate marker bits
            pattern = bitset(pattern,15, logical(marker1));
            pattern = bitset(pattern,16, logical(marker2));
        end
        
        function pattern = pack7Pattern(pattern, marker1, marker2)
            % AWG 7000 series binary data format
            % m2 m1 d8 d7 d6 d5 d4 d3 d2 d1
            % 8-bit format with markers occupying left 2 bits followed by the 8 bit
            % analog channel value
            % clip patterns to 8-bits
            pattern = uint16(pattern);
            pattern( pattern > 2^8 - 1 ) = 2^8 - 1;
            
            % force markers to binary
            marker1 = uint16(marker1);
            marker2 = uint16(marker2);
            
            pattern = bitor(bitshift(pattern,6), bitor(bitshift(marker1, 14), bitshift(marker2, 15)));
        end
        
        function writeTekHeader(fid, numsteps, basename, options)
            % writes the file header for the binary AWG format of the Tek AWG5000 series
            % magic number to determine endian-ness
            self = TekPattern;
            self.writeField(fid, 'MAGIC', 5000, 'int16');
            
            % version 1
            self.writeField(fid, 'VERSION', 1, 'int16');
            
            % sampling rate
            self.writeField(fid, 'SAMPLING_RATE', 1e9, 'double');
            
            % run mode: 1 = continuous, 2 = triggered, 3 = gated, 4 = sequence
            if numsteps == 1
                runMode = 2; % use triggered mode if only one step
            else
                runMode = 4;
            end
            self.writeField(fid, 'RUN_MODE', runMode, 'int16');
            
            % run state: 1 = on, 0 = off
            self.writeField(fid, 'RUN_STATE', 0, 'int16');
            
            % reference source: 1 = internal, 2 = external
            self.writeField(fid, 'REFERENCE_SOURCE', 2, 'int16');
            
            % trigger treshold
            self.writeField(fid, 'TRIGGER_INPUT_THRESHOLD', 1.0, 'double');
            
            % channel output
            for i = 1:4
                % channel state: 1 = on, 0 = off
                self.writeField(fid, strcat('CHANNEL_STATE_', num2str(i)), 1, 'int16');
                
                % marker level input format: 1 = amp/offset, 2 = high/low
                self.writeField(fid, strcat('MARKER1_METHOD_', num2str(i)), 2, 'int16');
                self.writeField(fid, strcat('MARKER2_METHOD_', num2str(i)), 2, 'int16');
                
                % marker high/low
                marker_name = ['m' num2str(i) '1'];
                if ismember([marker_name '_high'], fieldnames(options))
                    marker_high = options.([marker_name '_high']);
                else
                    marker_high = 1.0;
                end
                if ismember([marker_name '_low'], fieldnames(options))
                    marker_low = options.([marker_name '_low']);
                else
                    marker_low = 0.0;
                end
                self.writeField(fid, strcat('MARKER1_HIGH_', num2str(i)), marker_high, 'double');
                self.writeField(fid, strcat('MARKER1_LOW_', num2str(i)), marker_low, 'double');
                
                marker_name = ['m' num2str(i) '2'];
                if ismember([marker_name '_high'], fieldnames(options))
                    marker_high = options.([marker_name '_high']);
                else
                    marker_high = 1.0;
                end
                if ismember([marker_name '_low'], fieldnames(options))
                    marker_low = options.([marker_name '_low']);
                else
                    marker_low = 0.0;
                end
                self.writeField(fid, strcat('MARKER2_HIGH_', num2str(i)), marker_high, 'double');
                self.writeField(fid, strcat('MARKER2_LOW_', num2str(i)), marker_low, 'double');
                
                % channel skew
                %self.writeField(fid, strcat('CHANNEL_SKEW_', num2str(i)), 0.0, 'double');
            end
            
            % if only one step, need to specify waveform names for each
            % channel
            if numsteps == 1
                for i = 1:4
                    namestring = strcat(basename, 'Ch', num2str(i), '001');
                    self.writeField(fid, strcat('OUTPUT_WAVEFORM_NAME_', num2str(i)), namestring, 'char');
                end
            end
        end
        
        function writeTek7Header(fid, numsteps, basename, options)
            % writes the file header for the binary AWG format of the Tek AWG5000 series
            % magic number to determine endian-ness
            self = TekPattern;
            self.writeField(fid, 'MAGIC', 5000, 'int16');
            
            % version 1
            self.writeField(fid, 'VERSION', 1, 'int16');
            
            % sampling rate
            self.writeField(fid, 'SAMPLING_RATE', 1e9, 'double');
            
            % run mode: 1 = continuous, 2 = triggered, 3 = gated, 4 = sequence
            if numsteps == 1
                runMode = 2; % use triggered mode if only one step
            else
                runMode = 4;
            end
            self.writeField(fid, 'RUN_MODE', runMode, 'int16');
            
            % run state: 1 = on, 0 = off
            self.writeField(fid, 'RUN_STATE', 0, 'int16');
            
            % reference source: 1 = internal, 2 = external
            self.writeField(fid, 'REFERENCE_SOURCE', 2, 'int16');
            
            % trigger treshold
            self.writeField(fid, 'TRIGGER_INPUT_THRESHOLD', 1.0, 'double');
            
            % channel output
            for i = 1:2
                % channel state: 1 = on, 0 = off
                self.writeField(fid, strcat('CHANNEL_STATE_', num2str(i)), 1, 'int16');
                
                % marker level input format: 1 = amp/offset, 2 = high/low
                self.writeField(fid, strcat('MARKER1_METHOD_', num2str(i)), 2, 'int16');
                self.writeField(fid, strcat('MARKER2_METHOD_', num2str(i)), 2, 'int16');
                
                % marker high/low
                marker_name = ['m' num2str(i) '1'];
                if ismember([marker_name '_high'], fieldnames(options))
                    marker_high = options.([marker_name '_high']);
                else
                    marker_high = 1.0;
                end
                if ismember([marker_name '_low'], fieldnames(options))
                    marker_low = options.([marker_name '_low']);
                else
                    marker_low = 0.0;
                end
                self.writeField(fid, strcat('MARKER1_HIGH_', num2str(i)), marker_high, 'double');
                self.writeField(fid, strcat('MARKER1_LOW_', num2str(i)), marker_low, 'double');
                
                marker_name = ['m' num2str(i) '2'];
                if ismember([marker_name '_high'], fieldnames(options))
                    marker_high = options.([marker_name '_high']);
                else
                    marker_high = 1.0;
                end
                if ismember([marker_name '_low'], fieldnames(options))
                    marker_low = options.([marker_name '_low']);
                else
                    marker_low = 0.0;
                end
                self.writeField(fid, strcat('MARKER2_HIGH_', num2str(i)), marker_high, 'double');
                self.writeField(fid, strcat('MARKER2_LOW_', num2str(i)), marker_low, 'double');
                
                % channel skew
                %self.writeField(fid, strcat('CHANNEL_SKEW_', num2str(i)), 0.0, 'double');
            end
            
            % if only one step, need to specify waveform names for each
            % channel
            if numsteps == 1
                for i = 1:2
                    namestring = strcat(basename, 'Ch', num2str(i), '001');
                    self.writeField(fid, strcat('OUTPUT_WAVEFORM_NAME_', num2str(i)), namestring, 'char');
                end
            end
        end
        
        
        
        
        function writeTekPattern(fid, filename, number, packedPattern)
            self = TekPattern;
            numstring = num2str(number);
            
            self.writeField(fid, ['WAVEFORM_NAME_', numstring], filename, 'char');
            
            % waveform type = 1 for integer format data
            self.writeField(fid, ['WAVEFORM_TYPE_', numstring], 1, 'int16');
            
            self.writeField(fid, ['WAVEFORM_LENGTH_', numstring], length(packedPattern), 'int32');
            
            self.writeField(fid, ['WAVEFORM_TIMESTAMP_', numstring], 0, 'uint128');
            
            fieldName = ['WAVEFORM_DATA_', numstring, 0];
            dataSize = 2*length(packedPattern);
            fwrite(fid, length(fieldName), 'uint32');
            fwrite(fid, dataSize, 'uint32');
            fwrite(fid, fieldName, 'char');
            fwrite(fid, packedPattern, 'uint16');
        end
        
        function writeTekSeqTable(fid, basename, numsteps, options)
            self = TekPattern;
            nbrRepeats = 1;
            if isfield(options, 'nbrRepeats')
                nbrRepeats = options.nbrRepeats;
            end
            
            for stepct = 1:numsteps
                for repeatct = 1:nbrRepeats
                    i_str = num2str((stepct-1)*nbrRepeats + repeatct);
                    % sequence wait: 1 = on, 0 = off
                    self.writeField(fid, ['SEQUENCE_WAIT_', i_str], 1, 'int16');
                    
                    % sequence loop: 0 = infinite (default = 1)
                    num_loops = 1;
                    if ismember('num_repeats', fieldnames(options)) && isnumeric(options.num_repeats) && options.num_repeats >= 0
                        num_loops = options.num_repeats;
                    end
                    self.writeField(fid, ['SEQUENCE_LOOP_', i_str], num_loops, 'int32');
                    
                    % sequence jump: 0 = off, -1 = next, n = element #
                    self.writeField(fid, ['SEQUENCE_JUMP_', i_str], 0, 'int16');
                    
                    % sequence goto: 0 = off, n = element #
                    if stepct == numsteps && repeatct == nbrRepeats
                        goto = 1;
                    else
                        goto = 0;
                    end
                    self.writeField(fid, ['SEQUENCE_GOTO_', i_str], goto, 'int16');
                    
                    namestring = sprintf('%sCh1%03d', basename, stepct);
                    self.writeField(fid, ['SEQUENCE_WAVEFORM_NAME_CH_1_', i_str], namestring, 'char');
                    
                    namestring = sprintf('%sCh2%03d', basename, stepct);
                    self.writeField(fid, ['SEQUENCE_WAVEFORM_NAME_CH_2_', i_str], namestring, 'char');
                    
                    namestring = sprintf('%sCh3%03d', basename, stepct);
                    self.writeField(fid, ['SEQUENCE_WAVEFORM_NAME_CH_3_', i_str], namestring, 'char');
                    
                    namestring = sprintf('%sCh4%03d', basename, stepct);
                    self.writeField(fid, ['SEQUENCE_WAVEFORM_NAME_CH_4_', i_str], namestring, 'char');
                end
            end
        end
        
        function writeField(fid, name, data, type)
            nameSize = length(name) + 1;
            typeSizes = struct(...
                'int16', 2, ...
                'int32', 4, ...
                'uint128', 16, ...
                'double', 8 ...
                );
            
            if strcmp(type,'char')
                dataSize = length(data) + 1;
                % add null termination to string
                data = [data 0];
            else
                try
                    dataSize = typeSizes.(type);
                catch
                    error('Unknown data type');
                end
            end
            
            fwrite(fid, nameSize, 'uint32');
            fwrite(fid, dataSize, 'uint32');
            fwrite(fid, [name 0], 'char');
            % deal with the absence of 128 bit int in MATLAB
            if strcmp(type, 'uint128')
                fwrite(fid, 0, 'uint64');
                fwrite(fid, data, 'uint64');
            else
                fwrite(fid, data, type);
            end
            
        end
        
        function writeTek7SeqTable(fid, basename, numsteps,options)
            self = TekPattern;
            for i = 1:numsteps
                i_str = num2str(i);
                % sequence wait: 1 = on, 0 = off
                self.writeField(fid, ['SEQUENCE_WAIT_', i_str], 1, 'int16');
                
                % sequence loop: 0 = infinite
                num_repeats = 1;
                if ismember('num_repeats', fieldnames(options)) && isnumeric(options.num_repeats) && options.num_repeats >= 0
                    num_repeats = options.num_repeats;
                end
                self.writeField(fid, ['SEQUENCE_LOOP_', i_str], num_repeats, 'int32');
                
                % sequence jump: 0 = off, -1 = next, n = element #
                self.writeField(fid, ['SEQUENCE_JUMP_', i_str], 0, 'int16');
                
                % sequence goto: 0 = off, n = element #
                if i == numsteps
                    goto = 1;
                else
                    goto = 0;
                end
                self.writeField(fid, ['SEQUENCE_GOTO_', i_str], goto, 'int16');
                
                namestring = sprintf('%sCh1%03d', basename, i);
                self.writeField(fid, ['SEQUENCE_WAVEFORM_NAME_CH_1_', i_str], namestring, 'char');
                
                namestring = sprintf('%sCh2%03d', basename, i);
                self.writeField(fid, ['SEQUENCE_WAVEFORM_NAME_CH_2_', i_str], namestring, 'char');
                
            end
        end
        
        % utility to replace range() in statistics toolbox
        function out = range(in)
            out = max(in) - min(in);
        end
        
        %Helper function to dump waveforms to h5 file for plotting
        %Helper function to dump a set of TekAWG sequences to a H5 file
        function waveforms2h5(fileName, tekChannelData)
            %Create and overwrite the file
            tmpFID = H5F.create(fileName,'H5F_ACC_TRUNC', H5P.create('H5P_FILE_CREATE'),H5P.create('H5P_FILE_ACCESS'));
            H5F.close(tmpFID);
            
            %Now loop over the channels and write/pack the data
            %We'll efficiently pack the data in like is done on the Tek itself
            %using the upper 2 bits for the marker data
            for chanct = 1:4
                chanStr = sprintf('ch%d',chanct);
                marker1Str = sprintf('ch%dm1', chanct);
                marker2Str = sprintf('ch%dm2', chanct);

                tmpData = uint16(tekChannelData.(chanStr));
                tmpData = bitset(tmpData, 15, tekChannelData.(marker1Str));
                tmpData = bitset(tmpData, 16, tekChannelData.(marker2Str));
                
                h5create(fileName, ['/' chanStr], fliplr(size(tmpData)), 'DataType', 'uint16');
                h5write(fileName, ['/' chanStr], tmpData');
            end
        end
    end
end