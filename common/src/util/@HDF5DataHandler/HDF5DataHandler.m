classdef HDF5DataHandler < handle
    properties
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
            tmpFID = H5F.create(fileName,'H5F_ACC_TRUNC', H5P.create('H5P_FILE_CREATE'),H5P.create('H5P_FILE_ACCESS'));
            H5F.close(tmpFID);

            %write header info
            %h5write(fileName,'/header', headerStruct);
            h5writeatt(fileName,'/', 'xpoints', headerStruct.xpoints);

            %open a data set
            h5create(fileName, '/idata', Inf, 'ChunkSize', 10);
            h5create(fileName, '/qdata', Inf, 'ChunkSize', 10);

            obj.fileName = fileName;
            obj.fileOpen = 1;
            obj.idx = 1;
        end
        
        function open2dDataFile(obj, fileName, headerStruct)
            %First create it with overwrite if it is there
            tmpFID = H5F.create(fileName,'H5F_ACC_TRUNC', H5P.create('H5P_FILE_CREATE'),H5P.create('H5P_FILE_ACCESS'));
            H5F.close(tmpFID);

            %write header info
            %h5write(fileName,'/header', headerStruct);
            h5writeatt(fileName,'/', 'xpoints', headerStruct.xpoints);
            h5writeatt(fileName,'/', 'ypoints', headerStruct.ypoints);
            
            obj.rowSize = length(headerStruct.xpoints);

            %open a data set
            h5create(fileName, '/idata', [Inf obj.rowSize], 'ChunkSize', [10 obj.rowSize]);
            h5create(fileName, '/qdata', [Inf obj.rowSize], 'ChunkSize', [10 obj.rowSize]);

            obj.fileName = fileName;
            obj.fileOpen = 1;
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
            
            readData = h5read('unit_test.h5', '/idata') + 1i * h5read('unit_test.h5', '/qdata');
            if verbose
                disp(readData);
            end
            
            out = all(all(data == readData),2);
        end
    end
end