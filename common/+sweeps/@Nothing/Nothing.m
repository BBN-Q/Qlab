%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Module Name :  Nothing.m
 %
 % Author/Date : Blake Johnson / October 18, 2010
 %
 % Description : A 'nothing' sweep class
 %
 % Version: 1.0
 %
 %    Modified    By    Reason
 %    --------    --    ------
 %
 %
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef Nothing < sweeps.Sweep
	properties
	end
	
	methods
		% constructor
		function obj = Nothing(SweepParams, Instr, ExpParams, sweepPtsOnly)
			if nargin < 3
				error('Usage: Nothing(SweepParams, Instr, ExpParams)');
			end
			obj.name = 'Nothing';
			
			% generate empty list of points
			obj.points = [0];
			
			obj.plotRange.start = 1;
			obj.plotRange.end = 1;
		end
		
		% nothing stepper
		function step(obj, index)
			% do nothing
		end
	end
end