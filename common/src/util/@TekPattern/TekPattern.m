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
		function status = exportTekSequence(path, basename, patCh1, m11, m12, patCh2, m21, m22, patCh3, m31, m32, patCh4, m41, m42, options)
			% error check
			dims = size(patCh1);
			if (~isequal(size(m11), dims) || ~isequal(size(m12), dims) || ~isequal(size(patCh2), dims) || ~isequal(size(m21), dims) || ~isequal(size(m22), dims) || ~isequal(size(patCh3), dims) || ~isequal(size(m31), dims) || ~isequal(size(m32), dims) || ~isequal(size(patCh4), dims) || ~isequal(size(m41), dims) || ~isequal(size(m42), dims))
				error('inputs must all have the same dimensions');
            end
            if ~exist('options', 'var')
                options = struct();
            end
			
			self = TekPattern;

			% pack patterns and markers into 16-bit binary format
			disp('Packing patterns');
			packedCh1 = self.packPattern(patCh1, m11, m12);
			packedCh2 = self.packPattern(patCh2, m21, m22);
			packedCh3 = self.packPattern(patCh3, m31, m32);
			packedCh4 = self.packPattern(patCh4, m41, m42);
			disp('Done packing');

			% open file
			disp('Writing AWG file');
			fullpath = strcat(path, basename, '.awg');
            if ~exist(path, 'dir')
                mkdir(path);
            end
			fid = fopen(fullpath, 'w');

			% write header information
            numsteps = size(patCh1,1);
			self.writeTekHeader(fid, numsteps, basename, options);

			% write patterns
			for i = 1:numsteps
                % by some weird Tektronix convention, waveform numbering
                % starts at 21
				self.writeTekPattern(fid, strcat(basename, 'Ch1', sprintf('%03d', i)), 20 + 4*(i - 1) + 1, packedCh1(i,:));
				self.writeTekPattern(fid, strcat(basename, 'Ch2', sprintf('%03d', i)), 20 + 4*(i - 1) + 2, packedCh2(i,:));
				self.writeTekPattern(fid, strcat(basename, 'Ch3', sprintf('%03d', i)), 20 + 4*(i - 1) + 3, packedCh3(i,:));
				self.writeTekPattern(fid, strcat(basename, 'Ch4', sprintf('%03d', i)), 20 + 4*(i - 1) + 4, packedCh4(i,:));
			end

			% write sequence table
			self.writeTekSeqTable(fid, basename, numsteps, options);

			% close file
			fclose(fid);
		end
		
		function out = packPattern(pattern, marker1, marker2)
			% AWG 5000 series binary data format
			% m2 m1 d14 d13 d12 d11 d10 d9 d8 d7 d6 d5 d4 d3 d2 d1
			% 16-bit format with markers occupying left 2 bits followed by the 14 bit
			% analog channel value
			
			% clip patterns to 14-bits
            pattern = uint16(pattern);
			pattern( pattern > 2^14 - 1 ) = 2^14 - 1;

			% force markers to binary
			marker1 = uint16(bitand(1, marker1));
			marker2 = uint16(bitand(1, marker2));

			out = bitor(pattern, bitor(bitshift(marker1, 14), bitshift(marker2, 15)));
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
		
		function writeTekPattern(fid, filename, number, packedPattern)
			self = TekPattern;
			numstring = num2str(number);
			
			self.writeField(fid, strcat('WAVEFORM_NAME_', numstring), filename, 'char');
			
			% waveform type = 1 for integer format data
			self.writeField(fid, strcat('WAVEFORM_TYPE_', numstring), 1, 'int16');
			
			self.writeField(fid, strcat('WAVEFORM_LENGTH_', numstring), length(packedPattern), 'int32');
			
			self.writeField(fid, strcat('WAVEFORM_TIMESTAMP_', numstring), 0, 'uint128');
			
			fieldName = [strcat('WAVEFORM_DATA_', numstring) 0];
			dataSize = 2*length(packedPattern);
			fwrite(fid, length(fieldName), 'uint32');
			fwrite(fid, dataSize, 'uint32');
			fwrite(fid, fieldName, 'char');
			fwrite(fid, packedPattern, 'uint16');
		end
		
		function writeTekSeqTable(fid, basename, numsteps, options)
			self = TekPattern;
			for i = 1:numsteps
				% sequence wait: 1 = on, 0 = off
				self.writeField(fid, strcat('SEQUENCE_WAIT_', num2str(i)), 1, 'int16');
				
				% sequence loop: 0 = infinite (default = 1)
                num_repeats = 1;
                if ismember('num_repeats', fieldnames(options)) && isnumeric(options.num_repeats) && option.num_repeats >= 0
                    num_repeats = options.num_repeats;
                end
				self.writeField(fid, strcat('SEQUENCE_LOOP_', num2str(i)), num_repeats+1, 'int32');
				
				% sequence jump: 0 = off, -1 = next, n = element #
				self.writeField(fid, strcat('SEQUENCE_JUMP_', num2str(i)), 0, 'int16');
				
				% sequence goto: 0 = off, n = element #
				if i == numsteps
					goto = 1;
				else
					goto = 0;
				end
				self.writeField(fid, strcat('SEQUENCE_GOTO_', num2str(i)), goto, 'int16');
				
				for j = 1:4
					namestring = strcat(basename, 'Ch', num2str(j), sprintf('%03d', i));
					self.writeField(fid, strcat('SEQUENCE_WAVEFORM_NAME_CH_', num2str(j), '_', num2str(i)), namestring, 'char');
				end
			end
		end

		function writeField(fid, name, data, type)
			nameSize = length(name) + 1;
			typeSizes = containers.Map({'int16', 'int32', 'uint128', 'double'}, {2, 4, 16, 8});

			if strcmp(type,'char')
				dataSize = length(data) + 1;
				% add null termination to string
				data = [data 0];
			elseif isKey(typeSizes, type)
				dataSize = typeSizes(type);
			else
				error('Unknown data type');
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
			
% 			fprintf(fid, '%d', nameSize);
% 			fprintf(fid, '%d', dataSize);
% 			fprintf(fid, '%s', [name 0]);
% 			fprintf(fid, '%s', num2str(data));
		end
		
	end
end