%Instrument Driver for the NI USB-6341 (NIDAQ)
%Written by Evan Walsh (evanwalsh@seas.harvard.edu) Sept. 2016

classdef NIDAQ < handle

    properties
        samplingRate %NIDAQ sampling rate
        taskHandle %Handle for when a new task is created
        points % Number of data points taken in a given task
    end
    
   
    methods
               
        function obj = NIDAQ()
        end
        
        
        function trigDataCollectAI0(obj,time)
            if isempty(obj.samplingRate)
                error('Oops! You forgot to set the sampling rate.')
            end
            numPoints = round(time*obj.samplingRate);
            obj.points = py.int(numPoints);
            rate = py.int(obj.samplingRate);
            obj.taskHandle = py.NIDAQai0.NIDAQai0(obj.points,rate);
        end
        
        function val = getDataAI0(obj)
            pydata = py.NIDAQai0.getData(obj.taskHandle,obj.points);
            val = double(py.array.array('d',py.numpy.nditer(pydata)));
            py.NIDAQai0.killTask(obj.taskHandle);
        end
        
        function trigDataCollectAI0AI1(obj,time)
            if isempty(obj.samplingRate)
                error('Oops! You forgot to set the sampling rate.')
            end
            numPoints = round(time*obj.samplingRate);
            obj.points = py.int(numPoints);
            rate = py.int(obj.samplingRate);
            obj.taskHandle = py.NIDAQai0ai1.NIDAQai0ai1(obj.points,rate);
        end
        
        function val = getDataAI0AI1(obj)
            pydata = py.NIDAQai0ai1.getData(obj.taskHandle,obj.points);
            matdata = double(py.array.array('d',py.numpy.nditer(pydata)));
            val(1,:) = matdata(1:double(obj.points));
            val(2,:) = matdata(double(obj.points)+1:end);
            py.NIDAQai0ai1.killTask(obj.taskHandle);
        end
        
        function killTask(obj)
            py.NIDAQai0.killTask(obj.taskHandle);
        end
        

    end





end