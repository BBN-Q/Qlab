classdef HDF5DataHandler < handle
    properties
        FID
        fileName
        fileOpen
        idx
        rowSize
    end
    methods
        function obj = HDF5DataHandler(dimension, fileName, headerStruct)
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
            obj.FID = H5F.create(fileName,'H5F_ACC_TRUNC', H5P.create('H5P_FILE_CREATE'),H5P.create('H5P_FILE_ACCESS'));
            
            obj.fileName = fileName;
            obj.fileOpen = 1;

            %write header info
            obj.writeString('/header', jsonlab.savejson('', headerStruct));
            h5writeatt(fileName,'/', 'xpoints', headerStruct.xpoints);

            %open a data set
            h5create(fileName, '/idata', Inf, 'ChunkSize', 10);
            h5create(fileName, '/qdata', Inf, 'ChunkSize', 10);

            obj.idx = 1;
        end
        
        function open2dDataFile(obj, fileName, headerStruct)
            %First create it with overwrite if it is there
            obj.FID = H5F.create(fileName,'H5F_ACC_TRUNC', H5P.create('H5P_FILE_CREATE'),H5P.create('H5P_FILE_ACCESS'));
            
            obj.fileName = fileName;
            obj.fileOpen = 1;

            %write header info
            obj.writeString('/header', jsonlab.savejson('', headerStruct));
            h5writeatt(fileName,'/', 'xpoints', headerStruct.xpoints);
            h5writeatt(fileName,'/', 'ypoints', headerStruct.ypoints);
            
            obj.rowSize = length(headerStruct.xpoints);

            %open a data set
            h5create(fileName, '/idata', [Inf obj.rowSize], 'ChunkSize', [10 obj.rowSize]);
            h5create(fileName, '/qdata', [Inf obj.rowSize], 'ChunkSize', [10 obj.rowSize]);

            obj.idx = 1;
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
            % don't need to do anything
            obj.fileOpen = 0;
        end
        
        % helper functions for reading and writing header data
        function writeString(obj, dataSetName, string)
            % create data type
            datatypeID = H5T.copy('H5T_C_S1');
            %H5T.set_size(datatypeID, 'H5T_VARIABLE');
            
            % create the data space
            dataspaceID = H5S.create_simple(1, length(string), []);
            
            % create the data set
            datasetID = H5D.create(obj.FID, dataSetName, datatypeID, dataspaceID, 'H5P_DEFAULT');
            
            H5D.write(datasetID,'H5ML_DEFAULT','H5S_ALL','H5S_ALL', 'H5P_DEFAULT', string);
            
            H5D.close(datasetID);
            H5S.close(dataspaceID);
            H5T.close(datatypeID);
        end
        
        function out = readString(obj, dataSpace)
            out = char(h5read(obj.fileName, dataSpace))';
        end
        
        function delete(obj)
            H5F.close(obj.FID);
        end
    end
    methods (Static)
        function out = UnitTest()
            out = HDF5DataHandler.UnitTest1d(0) && HDF5DataHandler.UnitTest2d(0);
        end
        
        function out = UnitTest1d(verbose)
            data = [1, -1i, 2];
            data = data(:);
            header = struct('xpoints', [5 10 15]);
            dataHandler = HDF5DataHandler(1, 'unit_test.h5', header);
            for ct = 1:3
                dataHandler.writePoint(data(ct));
            end

            readHeader = jsonlab.loadjson(dataHandler.readString('/header'));
            disp(readHeader);
            
            readData = h5read('unit_test.h5', '/idata') + 1i * h5read('unit_test.h5', '/qdata');
            if verbose
                disp(readData);
            end
            
            out = all(data == readData);
        end
        
        function out = UnitTest2d(verbose)
            data = [1, 0, 1; 0, 1i, 0; 1, 0, 1];
            header = struct('xpoints', [5 10 15], 'ypoints', [1 2 3]);
            dataHandler = HDF5DataHandler(2, 'unit_test.h5', header);
            for ct = 1:3
                dataHandler.writeRow(data(ct,:));
            end
            
            readHeader = jsonlab.loadjson(dataHandler.readString('/header'));
            disp(readHeader);
            
            readData = h5read('unit_test.h5', '/idata') + 1i * h5read('unit_test.h5', '/qdata');
            if verbose
                disp(readData);
            end
            
            out = all(all(data == readData),2);
        end
    end
end