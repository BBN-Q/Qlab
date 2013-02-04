%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Module Name :  Frequency.m
%
% Original author : Blake Johnson / October 15, 2010
%
% Description : A frequency sweep class.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

classdef Frequency < sweeps.Sweep
    properties
    end
    
    methods
        % constructor
        function obj = Frequency(sweepParams, Instr)
            obj.label = 'Frequency (GHz)';
            start = sweepParams.start;
            stop = sweepParams.stop;
            step = sweepParams.step;
            if start > stop
                step = -abs(step);
            end
            
            % look for an instrument with the name 'genID'
            obj.Instr = Instr.(sweepParams.genID);
            
            % generate frequency points
            obj.points = start:step:stop;
            obj.numSteps = length(obj.points);
            obj.plotRange.start = start;
            obj.plotRange.end = stop;
        end
        
        % frequency stepper
        function step(obj, index)
            obj.Instr.frequency = obj.points(index);
        end
    end
end