classdef HDF5DataHandler < handle
    properties
        FID
        fileName
        fileOpen
        idx
        rowSize
        dimension
        buffer
        bufferIdx
    end
    methods
        function obj = HDF5DataHandler(dimension, fileName, headerStruct)
            obj.dimension = dimension;
            switch (dimension)
                case 1
                    obj.open1dDataFile(fileName, headerStruct);
                case 2
                    obj.open2dDataFile(fileName, headerStruct);
                otherwise
                    error('HDF5DataHandler does not support dimension = %d', dimension);
            end
        end
        
        function open1dDataFile(obj, fileName, headerStruct)
            %First create it with overwrite if it is there
            obj.FID = H5F.create(fileName,'H5F_ACC_TRUNC', 'H5P_DEFAULT', 'H5P_DEFAULT');
            H5F.close(obj.FID);
            
            obj.fileName = fileName;
            obj.fileOpen = 1;

            %write header info
            obj.writeHeader(headerStruct, headerStruct.xpoints, headerStruct.xlabel);

            %open a data set
            h5create(fileName, '/idata', Inf, 'ChunkSize', 10);
            h5create(fileName, '/qdata', Inf, 'ChunkSize', 10);

            obj.idx = 1;
        end
        
        function open2dDataFile(obj, fileName, headerStruct)
            %First create it with overwrite if it is there
            obj.FID = H5F.create(fileName,'H5F_ACC_TRUNC', 'H5P_DEFAULT', 'H5P_DEFAULT');
            H5F.close(obj.FID);
            
            obj.fileName = fileName;
            obj.fileOpen = 1;

            %write header info
            obj.writeHeader(headerStruct, ...
                headerStruct.xpoints, headerStruct.xlabel, ...
                headerStruct.ypoints, headerStruct.ylabel);
            
            obj.rowSize = length(headerStruct.xpoints);

            %open a data set
            h5create(fileName, '/idata', [Inf obj.rowSize], 'ChunkSize', [10 obj.rowSize]);
            h5create(fileName, '/qdata', [Inf obj.rowSize], 'ChunkSize', [10 obj.rowSize]);

            obj.idx = 1;
            
            %initialize a buffer
            obj.buffer = nan(1, obj.rowSize);
            obj.bufferIdx = 1;
        end
        
        function writeHeader(obj, headerStruct, xpoints, xlabel, ypoints, ylabel, zpoints, zlabel)
            assert(obj.fileOpen == 1, 'File must be open first');
            
            obj.writeString('/header', jsonlab.savejson('', headerStruct));
            if exist('xpoints', 'var') && exist('xlabel', 'var')
                h5create(obj.fileName, '/xpoints', length(xpoints));
                h5write(obj.fileName, '/xpoints', xpoints);
                h5writeatt(obj.fileName, '/xpoints', 'xlabel', xlabel);
            end
            if exist('ypoints', 'var') && exist('ylabel', 'var')
                h5create(obj.fileName, '/ypoints', length(ypoints));
                h5write(obj.fileName, '/ypoints', ypoints);
                h5writeatt(obj.fileName, '/ypoints', 'ylabel', ylabel);
            end
            if exist('zpoints', 'var') && exist('zlabel', 'var')
                h5create(obj.fileName, '/zpoints', length(zpoints));
                h5write(obj.fileName, '/zpoints', zpoints);
                h5writeatt(obj.fileName, '/zpoints', 'zlabel', zlabel);
            end
        end
        
        function out = readHeader(obj)
            out = jsonlab.loadjson(obj.readString('/header'));
        end
        
        function write(obj, val)
            % write data to file or internal buffer, depending on the
            % dimensions of the data set and the passed value
            switch obj.dimension
                case 1
                    if length(val) == 1
                        obj.writePoint(val);
                    else
                        obj.writeRow(val);
                    end
                case 2
                    % TODO: allow writing an entire 2D data set at once (ie. add a
                    % write array method)
                    
                    % if it is a 2D data set and we are passed a single
                    % point, add it to the buffer until we have filled an
                    % entire row, then write the row.
                    % otherwise, we have an entire row, so write it
                    if length(val) == 1
                        obj.buffer(obj.bufferIdx) = val;
                        obj.bufferIdx = obj.bufferIdx + 1;
                        % check if we need to flush the buffer
                        if obj.bufferIdx > obj.rowSize
                            obj.writeRow(obj.buffer);
                            obj.bufferIdx = 1;
                            obj.buffer = nan(1, obj.rowSize);
                        end
                    else
                        obj.writeRow(val);
                    end
                otherwise
                    error('Unallowed dimension %d', obj.dimension);
            end
        end

        function writePoint(obj, val)
            assert(obj.fileOpen == 1, 'writePoint ERROR: file is not open\n');
            h5write(obj.fileName, '/idata', real(val), obj.idx, 1);
            h5write(obj.fileName, '/qdata', imag(val), obj.idx, 1);
            obj.idx = obj.idx + 1;
        end
        
        function writeRow(obj, row)
            assert(obj.fileOpen == 1, 'writeRow ERROR: file is not open\n');
            h5write(obj.fileName, '/idata', real(row), [obj.idx 1], [1 obj.rowSize]);
            h5write(obj.fileName, '/qdata', imag(row), [obj.idx 1], [1 obj.rowSize]);
            obj.idx = obj.idx + 1;
        end
        
        function closeDataFile(obj)
            % all functions should close the FID, so don't need to do
            % anything
            %H5F.close(obj.FID);
            obj.fileOpen = 0;
        end
        
        % helper functions for reading and writing header data
        function writeString(obj, dataSetName, string)
            obj.FID = H5F.open(obj.fileName, 'H5F_ACC_RDWR', 'H5P_DEFAULT');
            
            % create data type
            datatypeID = H5T.copy('H5T_C_S1');
            
            % create the data space
            dataspaceID = H5S.create_simple(1, length(string), []);
            
            % create the data set
            datasetID = H5D.create(obj.FID, dataSetName, datatypeID, dataspaceID, 'H5P_DEFAULT');
            
            H5D.write(datasetID,'H5ML_DEFAULT','H5S_ALL','H5S_ALL', 'H5P_DEFAULT', string);
            
            H5D.close(datasetID);
            H5S.close(dataspaceID);
            H5T.close(datatypeID);
            H5F.close(obj.FID);
        end
        
        function out = readString(obj, dataSpace)
            out = char(h5read(obj.fileName, dataSpace))';
        end
        
        function delete(obj)
            if obj.fileOpen
                %H5F.close(obj.FID);
            end
        end
    end
    methods (Static)
        function out = UnitTest()
            out = HDF5DataHandler.UnitTest1d(0) && HDF5DataHandler.UnitTest2d(0) && HDF5DataHandler.UnitTestBufferd2d(0);
        end
        
        function out = UnitTest1d(verbose)
            data = [1, -1i, 2];
            data = data(:);
            header = struct('xpoints', [5 10 15], 'xlabel', 'Frequency (GHz)');
            dataHandler = HDF5DataHandler(1, 'unit_test.h5', header);
            for ct = 1:3
                dataHandler.write(data(ct));
            end

            disp(dataHandler.readHeader());
            
            readData = h5read('unit_test.h5', '/idata') + 1i * h5read('unit_test.h5', '/qdata');
            if verbose
                disp(readData);
            end
            
            out = all(data == readData);
        end
        
        function out = UnitTest2d(verbose)
            data = [1, 0, 1; 0, 1i, 0; 1, 0, 1];
            header = struct('xpoints', [5 10 15], 'xlabel', 'Frequency (GHz)',...
                'ypoints', [1 2 3], 'ylabel', 'Time (us)');
            dataHandler = HDF5DataHandler(2, 'unit_test.h5', header);
            for ct = 1:3
                dataHandler.write(data(ct,:));
            end
            
            disp(dataHandler.readHeader());
            
            readData = h5read('unit_test.h5', '/idata') + 1i * h5read('unit_test.h5', '/qdata');
            if verbose
                disp(readData);
            end
            
            out = all(all(data == readData),2);
        end
        
        function out = UnitTestBufferd2d(verbose)
            data = [1, 0, 2; 0, 1i, 0; 1, 0, 1];
            header = struct('xpoints', [5 10 15], 'xlabel', 'Frequency (GHz)',...
                'ypoints', [1 2 3], 'ylabel', 'Time (us)');
            dataHandler = HDF5DataHandler(2, 'unit_test.h5', header);
            for rowct = 1:3
                for columnct = 1:3
                    dataHandler.write(data(rowct,columnct));
                end
            end
            
            disp(dataHandler.readHeader());
            
            readData = h5read('unit_test.h5', '/idata') + 1i * h5read('unit_test.h5', '/qdata');
            if verbose
                disp(readData);
            end
            
            out = all(all(data == readData),2);
        end
    end
end