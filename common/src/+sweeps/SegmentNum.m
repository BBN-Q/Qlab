%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Module Name :  Frequency.m
 %
 % Original author : Blake Johnson / October 15, 2010
 %
 % Description : A frequency sweep class.
 %
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

 classdef SegmentNum < sweeps.Sweep
	properties
	end
	
	methods
		% constructor
		function obj = SegmentNum(sweepParams, ~)
			obj.label = sweepParams.label;
			start = sweepParams.start;
			step = sweepParams.step;
            stop = start+step*(sweepParams.numPoints-1);
			
			% Generate inferred sweep points
			obj.points = start:step:stop;
            
            %Since this is done on the AWG the number of steps is actually
            %1
            obj.numSteps = 1;
			obj.plotRange.start = start;
			obj.plotRange.end = stop;
		end
		
		% frequency stepper
		function step(~, ~)
		end
	end
end