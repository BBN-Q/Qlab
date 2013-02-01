%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Module Name :  Frequency.m
 %
 % Author/Date : Blake Johnson / October 15, 2010
 %
 % Description : A frequency sweep class.
 %
 % Version: 1.0
 %
 %    Modified    By    Reason
 %    --------    --    ------
 %
 %
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef Frequency < sweeps.Sweep
	properties
	end
	
	methods
		% constructor
		function obj = Frequency(SweepParams, Instr)
			if nargin < 2
				error('Usage: Frequency(SweepParams, Instr)');
			end
			obj.name = 'Frequency (GHz)';
			start = SweepParams.start;
			stop = SweepParams.stop;
			step = SweepParams.step;
			if start > stop
				step = -abs(step);
            end
			
            % look for an instrument with the name 'genID'
            if isfield(Instr, SweepParams.genID)
                obj.Instr = Instr.(SweepParams.genID);
            else
                error(['Could not find instrument with name ' SweepParams.genID]);
            end
			
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