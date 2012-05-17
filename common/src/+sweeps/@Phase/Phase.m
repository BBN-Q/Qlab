%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Module Name :  Phase.m
 %
 % Author/Date : Blake Johnson / October 15, 2010
 %
 % Description : A phase sweep class.
 %
 % Version: 1.0
 %
 %    Modified    By    Reason
 %    --------    --    ------
 %
 %
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef Phase < sweeps.Sweep
	properties
	end
	
	methods
		% constructor
		function obj = Phase(SweepParams, Instr, params, sweepPtsOnly)
			if nargin < 3
				error('Usage: Power(SweepParams, Instr, ExpParams)');
			end
			obj.name = 'Phase';
			
            if ~sweepPtsOnly
                % look for an instrument with the name 'genID'
                if isfield(Instr, SweepParams.genID)
                    obj.Instr = Instr.(SweepParams.genID);
                else
                    error(['Could not find instrument with name ' SweepParams.genID]);
                end
            end
			
			% generate phase points
			start = SweepParams.start;
			stop = SweepParams.stop;
			step = SweepParams.step;
			if start > stop
				step = -abs(step);
			end
			obj.points = start:step:stop;
			
			obj.plotRange.start = start;
			obj.plotRange.end = stop;
		end
		
		% phase stepper
		function step(obj, index)
			obj.Instr.phase = obj.points(index);
		end
	end
end