% A wrapper around MATLAB's HDF5 reading/writing methods to support the
% Qlab framework file format.

% Authors : Blake Johnson and Colm Ryan

% Copyright 2012-13 Raytheon BBN Technologies
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
classdef HDF5DataHandler < handle
    properties
        FID
        fileName
        fileOpen = 0
        idx % index into file
        rowSizes
        columnSizes
        dimensions
        nbrDataSets
        buffers
        bufferIdx % index into buffer
    end
    properties (Constant = true)
        version = 2
    end
    methods
        function obj = HDF5DataHandler(fileName)
            obj.fileName = fileName;
        end
        
        function open(obj, headerStruct, dataSetInfo)
            % OPEN(headerStruct, dataSetInfo)
            % headerStruct - global header information
            % dataSetInfo - cell array (length = number of data sets) with
            % (name, dimension, xpoints, xlabel, ypoints...) for each data set
            
            % do generic file opening stuff here (e.g. write headerStruct)
            %First create the file with overwrite if it is there
            obj.FID = H5F.create(obj.fileName,'H5F_ACC_TRUNC', 'H5P_DEFAULT', 'H5P_DEFAULT');
            H5F.close(obj.FID);
            obj.fileOpen = 1;
            
            %initialize data set dimensions
            obj.dimensions = cellfun(@(x) x.dimension, dataSetInfo);
            
            %initialize index array
            obj.nbrDataSets = length(dataSetInfo);
            obj.idx = ones(obj.nbrDataSets, 1);
            
            %initialize buffer row sizes
            obj.rowSizes = cellfun(@(s) length(s.xpoints), dataSetInfo);
            %initialize buffer column sizes
            obj.columnSizes = ones(1, length(dataSetInfo));
            for ct = 1:length(dataSetInfo)
                if dataSetInfo{ct}.dimension > 2
                    obj.columnSizes(ct) = length(dataSetInfo{ct}.ypoints);
                end
            end
            
            %initilize buffers
            obj.buffers = arrayfun(@(x,y) nan(x,y), obj.columnSizes, obj.rowSizes, 'UniformOutput', false);
            obj.bufferIdx = ones(obj.nbrDataSets, 1);
            
            %write header info
            obj.writeHeader(headerStruct);
            
            for ct = 1:length(dataSetInfo)
                if dataSetInfo{ct}.dimension == 1
                    obj.open1dDataSet(ct, dataSetInfo{ct});
                elseif dataSetInfo{ct}.dimension == 2
                    obj.open2dDataSet(ct, dataSetInfo{ct});
                elseif dataSetInfo{ct}.dimension == 3
                    obj.open3dDataSet(ct, dataSetInfo{ct});
                else
                    error('HDF5DataHandler does not support data sets of dimension %d', dataSetInfo{ct}.dimension);
                end
            end
        end
        
        function open1dDataSet(obj, setNumber, info)
            %write xpoints info
            h5create(obj.fileName, ['/DataSet' num2str(setNumber) '/xpoints'], length(info.xpoints));
            h5write(obj.fileName, ['/DataSet' num2str(setNumber) '/xpoints'], info.xpoints);
            h5writeatt(obj.fileName, ['/DataSet' num2str(setNumber) '/xpoints'], 'label', info.xlabel);
            % write dimension
            h5writeatt(obj.fileName, ['/DataSet' num2str(setNumber)], 'dimension', uint16(1));
            % write data set name
            h5writeatt(obj.fileName, ['/DataSet' num2str(setNumber)], 'name', info.name);

            %open data set
            h5create(obj.fileName, ['/DataSet' num2str(setNumber) '/real'], Inf, 'ChunkSize', 10);
            h5create(obj.fileName, ['/DataSet' num2str(setNumber) '/imag'], Inf, 'ChunkSize', 10);
        end
        
        function open2dDataSet(obj, setNumber, info)
            %write xpoints and ypoints info
            h5create(obj.fileName, ['/DataSet' num2str(setNumber) '/xpoints'], length(info.xpoints));
            h5write(obj.fileName, ['/DataSet' num2str(setNumber) '/xpoints'], info.xpoints);
            h5writeatt(obj.fileName, ['/DataSet' num2str(setNumber) '/xpoints'], 'label', info.xlabel);
            
            h5create(obj.fileName, ['/DataSet' num2str(setNumber) '/ypoints'], length(info.ypoints));
            h5write(obj.fileName, ['/DataSet' num2str(setNumber) '/ypoints'], info.ypoints);
            h5writeatt(obj.fileName, ['/DataSet' num2str(setNumber) '/ypoints'], 'label', info.ylabel);
            
            h5writeatt(obj.fileName, ['/DataSet' num2str(setNumber)], 'dimension', uint16(2));
            % write data set name
            h5writeatt(obj.fileName, ['/DataSet' num2str(setNumber)], 'name', info.name);
            
            %open data set
            h5create(obj.fileName, ['/DataSet' num2str(setNumber) '/real'], [Inf obj.rowSizes(setNumber)], 'ChunkSize', [10 obj.rowSizes(setNumber)]);
            h5create(obj.fileName, ['/DataSet' num2str(setNumber) '/imag'], [Inf obj.rowSizes(setNumber)], 'ChunkSize', [10 obj.rowSizes(setNumber)]);
        end
        
        function open3dDataSet(obj, setNumber, info)
            %write xpoints and ypoints info
            h5create(obj.fileName, ['/DataSet' num2str(setNumber) '/xpoints'], length(info.xpoints));
            h5write(obj.fileName, ['/DataSet' num2str(setNumber) '/xpoints'], info.xpoints);
            h5writeatt(obj.fileName, ['/DataSet' num2str(setNumber) '/xpoints'], 'label', info.xlabel);
            
            h5create(obj.fileName, ['/DataSet' num2str(setNumber) '/ypoints'], length(info.ypoints));
            h5write(obj.fileName, ['/DataSet' num2str(setNumber) '/ypoints'], info.ypoints);
            h5writeatt(obj.fileName, ['/DataSet' num2str(setNumber) '/ypoints'], 'label', info.ylabel);
            
            h5create(obj.fileName, ['/DataSet' num2str(setNumber) '/zpoints'], length(info.zpoints));
            h5write(obj.fileName, ['/DataSet' num2str(setNumber) '/zpoints'], info.zpoints);
            h5writeatt(obj.fileName, ['/DataSet' num2str(setNumber) '/zpoints'], 'label', info.zlabel);
            
            h5writeatt(obj.fileName, ['/DataSet' num2str(setNumber)], 'dimension', uint16(3));
            % write data set name
            h5writeatt(obj.fileName, ['/DataSet' num2str(setNumber)], 'name', info.name);
            
            %open data set with expandable dimension along the first axis
            h5create(obj.fileName, ['/DataSet' num2str(setNumber) '/real'], [Inf obj.columnSizes(setNumber) obj.rowSizes(setNumber)], 'ChunkSize', [10 obj.columnSizes(setNumber) obj.rowSizes(setNumber)]);
            h5create(obj.fileName, ['/DataSet' num2str(setNumber) '/imag'], [Inf obj.columnSizes(setNumber) obj.rowSizes(setNumber)], 'ChunkSize', [10 obj.columnSizes(setNumber) obj.rowSizes(setNumber)]);
        end
        
        function writeHeader(obj, headerStruct)
            assert(obj.fileOpen == 1, 'File must be open first');
            
            h5writeatt(obj.fileName, '/', 'version', obj.version);
            obj.writeString('/header', jsonlab.savejson('', headerStruct));
            h5writeatt(obj.fileName, '/', 'nbrDataSets', uint16(obj.nbrDataSets));
        end
        
        function out = readHeader(obj)
            out = jsonlab.loadjson(obj.readString('/header'));
        end
        
        function write(obj, val, dataSet)
            % write data to file or internal buffer, depending on the
            % dimensions of the data set and the passed value
            if ~exist('dataSet', 'var')
                dataSet = 1;
            end
            
            switch obj.dimensions(dataSet)
                case 1
                    if length(val) == 1
                        obj.writePoint(val, dataSet);
                    else
                        obj.writeRow(val, dataSet);
                    end
                case 2
                    % if it is a 2D data set and we are passed a single
                    % point, add it to the buffer until we have filled an
                    % entire row, then write the row.
                    % otherwise, we have an entire row, so write it
                    if length(val) == 1
                        obj.buffers{dataSet}(obj.bufferIdx(dataSet)) = val;
                        obj.bufferIdx(dataSet) = obj.bufferIdx(dataSet) + 1;
                        % check if we need to flush the buffer
                        if obj.bufferIdx(dataSet) > obj.rowSizes(dataSet)
                            obj.writeRow(obj.buffers{dataSet}, dataSet);
                            obj.bufferIdx(dataSet) = 1;
                        end
                    elseif length(setdiff(size(val), 1)) == 1 % 1D row/column
                        obj.writeRow(val, dataSet);
                    else  % otherwise, we have a 2D page
                        obj.writePage(val, dataSet);
                    end
                case 3
                    % TODO: accept single points in a 3D data set
                    if length(setdiff(size(val), 1)) == 1 % 1D row/column
                        % put it in a buffer until we have an entire page
                        obj.buffers{dataSet}(obj.bufferIdx(dataSet), :) = val;
                        obj.bufferIdx(dataSet) = obj.bufferIdx(dataSet) + 1;
                        % check if we need to flush the buffer
                        if obj.bufferIdx(dataSet) > obj.columnSizes(dataSet)
                            obj.writePage(obj.buffers{dataSet}, dataSet);
                            obj.bufferIdx(dataSet) = 1;
                        end
                    elseif ndims == 2 % a 2D page
                        obj.writePage(val, dataSet);
                    else
                        error('Writing 3D data sets at once not yet implemented\n');
                    end
                otherwise
                    error('Unsupported dimension %d', obj.dimensions(dataSet));
            end
        end

        function writePoint(obj, val, dataSet)
            assert(obj.fileOpen == 1, 'writePoint ERROR: file is not open\n');
            
            h5write(obj.fileName, ['/DataSet' num2str(dataSet) '/real'], real(val), obj.idx(dataSet), 1);
            h5write(obj.fileName, ['/DataSet' num2str(dataSet) '/imag'], imag(val), obj.idx(dataSet), 1);
            obj.idx(dataSet) = obj.idx(dataSet) + 1;
        end
        
        function writeRow(obj, row, dataSet)
            assert(obj.fileOpen == 1, 'writeRow ERROR: file is not open\n');
            row = reshape(row, 1, obj.rowSizes(dataSet));
            switch obj.dimensions(dataSet)
                case 1
                    h5write(obj.fileName, ['/DataSet' num2str(dataSet) '/real'], real(row), 1, length(row));
                    h5write(obj.fileName, ['/DataSet' num2str(dataSet) '/imag'], imag(row), 1, length(row));
                case 2
                    h5write(obj.fileName, ['/DataSet' num2str(dataSet) '/real'], real(row), [obj.idx(dataSet) 1], [1 obj.rowSizes(dataSet)]);
                    h5write(obj.fileName, ['/DataSet' num2str(dataSet) '/imag'], imag(row), [obj.idx(dataSet) 1], [1 obj.rowSizes(dataSet)]);
                case 3
                    error('Unsupported dimension %d\n', obj.dimensions(dataSet));
            end
            obj.idx(dataSet) = obj.idx(dataSet) + 1;
        end
        
        function writePage(obj, page, dataSet)
            assert(obj.fileOpen == 1, 'writePage ERROR: file is not open\n');
            page = reshape(page, 1, obj.columnSizes(dataSet), obj.rowSizes(dataSet));
            switch obj.dimensions(dataSet)
                case 1
                    error('Whoops, cannot write a page to a 1D data set.\n')
                case 2
                    h5write(obj.fileName, ['/DataSet' num2str(dataSet) '/real'], real(page), [1 1], size(page));
                    h5write(obj.fileName, ['/DataSet' num2str(dataSet) '/imag'], imag(page), [1 1], size(page));
                case 3
                    h5write(obj.fileName, ['/DataSet' num2str(dataSet) '/real'], real(page), [obj.idx(dataSet) 1 1], [1 obj.columnSizes(dataSet) obj.rowSizes(dataSet)]);
                    h5write(obj.fileName, ['/DataSet' num2str(dataSet) '/imag'], imag(page), [obj.idx(dataSet) 1 1], [1 obj.columnSizes(dataSet) obj.rowSizes(dataSet)]);
            end
            obj.idx(dataSet) = obj.idx(dataSet) + 1;
        end
        
        function close(obj)
            % all functions should close the FID, so don't need to do
            % anything
            obj.fileOpen = 0;
        end
        
        function markAsIncomplete(obj)
            [path, name, ~] = fileparts(obj.fileName);
            movefile(obj.fileName, fullfile(path, [name '.incomplete']));
        end
        
        % helper functions for reading and writing header data
        function writeString(obj, dataSetName, string)
            obj.FID = H5F.open(obj.fileName, 'H5F_ACC_RDWR', 'H5P_DEFAULT');
            
            % create data type
            datatypeID = H5T.copy('H5T_C_S1');
            H5T.set_size(datatypeID, length(string));
            
            % create the data space
            dataspaceID = H5S.create_simple(1, 1, []);
            
            % create the data set
            datasetID = H5D.create(obj.FID, dataSetName, datatypeID, dataspaceID, 'H5P_DEFAULT');
            
            H5D.write(datasetID, 'H5ML_DEFAULT', 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT', string);
            
            H5D.close(datasetID);
            H5S.close(dataspaceID);
            H5T.close(datatypeID);
            H5F.close(obj.FID);
        end
        
        function out = readString(obj, dataSpace)
            out = char(h5read(obj.fileName, dataSpace));
        end
        
        function delete(obj)
            if obj.fileOpen
                %H5F.close(obj.FID);
            end
        end
    end
    methods (Static)
        function out = UnitTest()
            out = HDF5DataHandler.UnitTest1d(0) && HDF5DataHandler.UnitTest2d(0) && HDF5DataHandler.UnitTestBufferd2d(0) && HDF5DataHandler.UnitTestMultiBufferd2d(0) && HDF5DataHandler.UnitTest3d(0);
        end
        
        function out = UnitTest1d(verbose)
            data = [1, -1i, 2];
            data = data(:);
            header = struct();
            dataInfo = struct('name', '1dtest', 'dimension', 1, 'xpoints', [5 10 15], 'xlabel', 'Frequency (GHz)');
            dataHandler = HDF5DataHandler('unit_test.h5');
            dataHandler.open(header, {dataInfo});
            for ct = 1:3
                dataHandler.write(data(ct));
            end

            disp(dataHandler.readHeader());
            
            readData = h5read('unit_test.h5', '/DataSet1/real') + 1i * h5read('unit_test.h5', '/DataSet1/imag');
            if verbose
                disp(readData);
            end
            
            out = all(data == readData);
        end
        
        function out = UnitTest2d(verbose)
            data = [1, 0, -1; 0, 1i, 0; 21, 0, 1; 2, 3, 5];
            header = struct('foo', 1, 'bar', 2);
            dataInfo = struct('name', '2dtest', 'dimension', 2, 'xpoints', [5 10 15], 'xlabel', 'Frequency (GHz)',...
                'ypoints', [1 2 3 4], 'ylabel', 'Time (us)');
            dataHandler = HDF5DataHandler('unit_test.h5');
            dataHandler.open(header, {dataInfo});
            for ct = 1:size(data,1)
                dataHandler.write(data(ct,:));
            end
            
            disp(dataHandler.readHeader());
            
            readData = h5read('unit_test.h5', '/DataSet1/real') + 1i * h5read('unit_test.h5', '/DataSet1/imag');
            if verbose
                disp(readData);
            end
            
            out = all(all(data == readData),2);
        end
        
        function out = UnitTestBufferd2d(verbose)
            data = [1, 0, 2; 0, 1i, 0; 1, 0, 1];
            header = struct('foo', 1, 'bar', 2);
            dataInfo = struct('name', 'buffered2d', 'dimension', 2, 'xpoints', [5 10 15], 'xlabel', 'Frequency (GHz)',...
                'ypoints', [1 2 3], 'ylabel', 'Time (us)');
            dataHandler = HDF5DataHandler('unit_test.h5');
            dataHandler.open(header, {dataInfo});
            for rowct = 1:size(data,1)
                for columnct = 1:size(data,2)
                    dataHandler.write(data(rowct,columnct));
                end
            end
            
            disp(dataHandler.readHeader());
            
            readData = h5read('unit_test.h5', '/DataSet1/real') + 1i * h5read('unit_test.h5', '/DataSet1/imag');
            if verbose
                disp(readData);
            end
            
            out = all(all(data == readData),2);
        end
        
        function out = UnitTestMultiBufferd2d(verbose)
            data1 = [1, 0, 2; 0, 1i, 0; 1, 0, 1];
            data2 = magic(3);
            header = struct('foo', 1, 'bar', 2);
            dataInfo = struct('name', 'set1', 'dimension', 2, 'xpoints', [5 10 15], 'xlabel', 'Frequency (GHz)',...
                'ypoints', [1 2 3], 'ylabel', 'Time (us)');
            dataInfo2 = struct('name', 'set2', 'dimension', 2, 'xpoints', [1 2 3], 'xlabel', 'Frequency2 (GHz)',...
                'ypoints', [4 5 6], 'ylabel', 'Time (us)');
            dataHandler = HDF5DataHandler('unit_test.h5');
            dataHandler.open(header, {dataInfo, dataInfo2});
            for rowct = 1:size(data1,1)
                for columnct = 1:size(data1,2)
                    dataHandler.write(data1(rowct,columnct), 1);
                end
                dataHandler.write(data2(rowct, :), 2);
            end
            
            disp(dataHandler.readHeader());
            
            readData = h5read('unit_test.h5', '/DataSet1/real') + 1i * h5read('unit_test.h5', '/DataSet1/imag');
            readData2 = h5read('unit_test.h5', '/DataSet2/real') + 1i * h5read('unit_test.h5', '/DataSet2/imag');
            if verbose
                disp(readData);
            end
            
            out = all(all(data1 == readData),2) && all(all(data2 == readData2),2);
        end
        
        function out = UnitTest3d(verbose)
            data = zeros(2,4,3);
            data(1,:,:) = [1, 0, 2; 0, 1i, 0; 1, 0, 1; -1 -2 -3];
            data(2,:,:) = [magic(3); -3 -2 -1];
            header = struct('foo', 1, 'bar', 2);
            dataInfo = struct('name', 'buffered3d', 'dimension', 3, 'xpoints', [5 10 15], 'xlabel', 'Frequency (GHz)',...
                'ypoints', [1 2 3 4], 'ylabel', 'Time (us)', 'zpoints', [1 2], 'zlabel', 'Repeat');
            dataHandler = HDF5DataHandler('unit_test.h5');
            dataHandler.open(header, {dataInfo});
            for pagect = 1:size(data,1)
                for rowct = 1:size(data,2)
                    dataHandler.write(data(pagect, rowct, :));
                end
            end
            
            disp(dataHandler.readHeader());
            
            readData = h5read('unit_test.h5', '/DataSet1/real') + 1i * h5read('unit_test.h5', '/DataSet1/imag');
            if verbose
                disp(readData);
            end
            
            out = all(all(all(data == readData),3),2);
        end
    end
end