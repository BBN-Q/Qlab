%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Module Name :  Time.m
 %
 % Author/Date : Blake Johnson / October 15, 2010
 %
 % Description : A time sweep class. Dummy class for recording points
 %
 % Version: 1.0
 %
 %    Modified    By    Reason
 %    --------    --    ------
 %
 %
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef Repeat < sweeps.Sweep
	properties
        numSegments
	end
	
	methods
		% constructor
		function obj = Repeat(SweepParams, Instr, ExpParams, sweepPtsOnly)
			if nargin < 3
				error('Usage: Repeat(SweepParams, Instr, ExpParams)');
			end
			obj.name = 'Repeat';
			
			% generate time points
			start = 1;
			step = 1;
            stop = SweepParams.stop;

			obj.points = start:step:stop;
			
			obj.plotRange.start = start;
			obj.plotRange.end = stop;
		end
		
		% repeat stepper
		function step(obj, index)
            % do nothing
		end
	end
end