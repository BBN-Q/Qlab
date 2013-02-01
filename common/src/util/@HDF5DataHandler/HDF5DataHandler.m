classdef HDF5DataHandler < handle
    properties
        FID
        fileName
        fileOpen = 0
        idx
        rowSize
        dimension
        nbrDataSets
        buffer
        bufferIdx
    end
    methods
        function obj = HDF5DataHandler(fileName)
            obj.fileName = fileName;
        end
        
        function open(obj, headerStruct, dimension, nbrDataSets)
            obj.dimension = dimension;
            obj.nbrDataSets = nbrDataSets;
            switch (obj.dimension)
                case 1
                    obj.open1dDataFile(obj.fileName, headerStruct);
                case 2
                    obj.open2dDataFile(obj.fileName, headerStruct);
                otherwise
                    error('HDF5DataHandler does not support dimension = %d', obj.dimension);
            end
        end
        
        function open1dDataFile(obj, fileName, headerStruct)
            %First create it with overwrite if it is there
            obj.FID = H5F.create(fileName,'H5F_ACC_TRUNC', 'H5P_DEFAULT', 'H5P_DEFAULT');
            H5F.close(obj.FID);
            
            obj.fileName = fileName;
            obj.fileOpen = 1;

            %write header info
            obj.writeHeader(headerStruct, 1, headerStruct.xpoints, headerStruct.xlabel);
            
            obj.rowSize = length(headerStruct.xpoints);

            %open data set(s)
            for ii = 1:obj.nbrDataSets
                h5create(fileName, ['/DataSet' num2str(ii) '/real'], Inf, 'ChunkSize', 10);
                h5create(fileName, ['/DataSet' num2str(ii) '/imag'], Inf, 'ChunkSize', 10);
            end

            obj.idx = 1;
        end
        
        function open2dDataFile(obj, fileName, headerStruct)
            %First create it with overwrite if it is there
            obj.FID = H5F.create(fileName,'H5F_ACC_TRUNC', 'H5P_DEFAULT', 'H5P_DEFAULT');
            H5F.close(obj.FID);
            
            obj.fileName = fileName;
            obj.fileOpen = 1;

            %write header info
            obj.writeHeader(headerStruct, 2, ...
                headerStruct.xpoints, headerStruct.xlabel, ...
                headerStruct.ypoints, headerStruct.ylabel);
            
            obj.rowSize = length(headerStruct.xpoints);

            %open data set(s)
            for ii = 1:obj.nbrDataSets
                h5create(fileName, ['/DataSet' num2str(ii) '/real'], [Inf obj.rowSize], 'ChunkSize', [10 obj.rowSize]);
                h5create(fileName, ['/DataSet' num2str(ii) '/imag'], [Inf obj.rowSize], 'ChunkSize', [10 obj.rowSize]);
            end

            obj.idx = 1;
            
            %initialize buffer(s)
            obj.buffer = cell(obj.nbrDataSets, 1);
            obj.buffer(:) = {nan(1,obj.rowSize)};
            obj.bufferIdx = 1;
        end
        
        function writeHeader(obj, headerStruct, dimension, xpoints, xlabel, ypoints, ylabel, zpoints, zlabel)
            assert(obj.fileOpen == 1, 'File must be open first');
            
            h5writeatt(obj.fileName, '/', 'dimension', uint8(dimension));
            obj.writeString('/header', jsonlab.savejson('', headerStruct));
            if exist('xpoints', 'var') && exist('xlabel', 'var')
                h5create(obj.fileName, '/xpoints', length(xpoints));
                h5write(obj.fileName, '/xpoints', xpoints);
                h5writeatt(obj.fileName, '/xpoints', 'label', xlabel);
            end
            if exist('ypoints', 'var') && exist('ylabel', 'var')
                h5create(obj.fileName, '/ypoints', length(ypoints));
                h5write(obj.fileName, '/ypoints', ypoints);
                h5writeatt(obj.fileName, '/ypoints', 'label', ylabel);
            end
            if exist('zpoints', 'var') && exist('zlabel', 'var')
                h5create(obj.fileName, '/zpoints', length(zpoints));
                h5write(obj.fileName, '/zpoints', zpoints);
                h5writeatt(obj.fileName, '/zpoints', 'label', zlabel);
            end
            h5writeatt(obj.fileName, '/', 'nbrDataSets', uint16(obj.nbrDataSets));
        end
        
        function out = readHeader(obj)
            out = jsonlab.loadjson(obj.readString('/header'));
        end
        
        function write(obj, val)
            % write data to file or internal buffer, depending on the
            % dimensions of the data set and the passed value
            switch obj.dimension
                case 1
                    if length(val{1}) == 1
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
                    if length(val{1}) == 1
                        for ii=1:obj.nbrDataSets
                            obj.buffer{ii}(obj.bufferIdx) = val{ii};
                        end
                        obj.bufferIdx = obj.bufferIdx + 1;
                        % check if we need to flush the buffer
                        if obj.bufferIdx > obj.rowSize
                            obj.writeRow(obj.buffer);
                            obj.bufferIdx = 1;
                            obj.buffer(:) = {nan(1,obj.rowSize)};
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
            
            for ii=1:obj.nbrDataSets
                h5write(obj.fileName, ['/DataSet' num2str(ii) '/real'], real(val{ii}), obj.idx, 1);
                h5write(obj.fileName, ['/DataSet' num2str(ii) '/imag'], imag(val{ii}), obj.idx, 1);
            end
            obj.idx = obj.idx + 1;
        end
        
        function writeRow(obj, row)
            assert(obj.fileOpen == 1, 'writeRow ERROR: file is not open\n');
            for ii = 1:obj.nbrDataSets
                row = reshape(row{ii}, 1, obj.rowSize);
                switch obj.dimension
                    case 1
                        h5write(obj.fileName, ['/DataSet' num2str(ii) '/real'], real(row), 1, length(row));
                        h5write(obj.fileName, ['/DataSet' num2str(ii) '/imag'], imag(row), 1, length(row));
                    case 2
                        h5write(obj.fileName, ['/DataSet' num2str(ii) '/real'], real(row), [obj.idx 1], [1 obj.rowSize]);
                        h5write(obj.fileName, ['/DataSet' num2str(ii) '/imag'], imag(row), [obj.idx 1], [1 obj.rowSize]);
                    case 3
                        error('Unallowed dimension %d\n', obj.dimension);
                end
            end
            obj.idx = obj.idx + 1;
        end
        
        function close(obj)
            % all functions should close the FID, so don't need to do
            % anything
            %H5F.close(obj.FID);
            obj.fileOpen = 0;
        end
        
        function markAsIncomplete(obj)
            [path, name, ~] = fileparts(obj.fileName);
            movefile(fullname, fullfile(path, [name '.incomplete']));
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
            out = HDF5DataHandler.UnitTest1d(0) && HDF5DataHandler.UnitTest2d(0) && HDF5DataHandler.UnitTestBufferd2d(0);
        end
        
        function out = UnitTest1d(verbose)
            data = [1, -1i, 2];
            data = data(:);
            header = struct('xpoints', [5 10 15], 'xlabel', 'Frequency (GHz)');
            dataHandler = HDF5DataHandler('unit_test.h5', 1);
            dataHandler.open(header);
            for ct = 1:3
                dataHandler.write({data(ct)});
            end

            disp(dataHandler.readHeader());
            
            readData = h5read('unit_test.h5', '/DataSet1/real') + 1i * h5read('unit_test.h5', '/DataSet1/imag');
            if verbose
                disp(readData);
            end
            
            out = all(data == readData);
        end
        
        function out = UnitTest2d(verbose)
            data = [1, 0, 1; 0, 1i, 0; 1, 0, 1];
            header = struct('xpoints', [5 10 15], 'xlabel', 'Frequency (GHz)',...
                'ypoints', [1 2 3], 'ylabel', 'Time (us)');
            dataHandler = HDF5DataHandler('unit_test.h5', 2);
            dataHandler.open(header);
            for ct = 1:3
                dataHandler.write({data(ct,:)});
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
            header = struct('xpoints', [5 10 15], 'xlabel', 'Frequency (GHz)',...
                'ypoints', [1 2 3], 'ylabel', 'Time (us)');
            dataHandler = HDF5DataHandler('unit_test.h5', 2);
            dataHandler.open(header);
            for rowct = 1:3
                for columnct = 1:3
                    dataHandler.write({data(rowct,columnct)});
                end
            end
            
            disp(dataHandler.readHeader());
            
            readData = h5read('unit_test.h5', '/DataSet1/real') + 1i * h5read('unit_test.h5', '/DataSet1/imag');
            if verbose
                disp(readData);
            end
            
            out = all(all(data == readData),2);
        end
    end
end