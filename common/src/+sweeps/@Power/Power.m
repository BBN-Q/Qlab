%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Module Name :  Power.m
 %
 % Author/Date : Blake Johnson / October 15, 2010
 %
 % Description : A power sweep class.
 %
 % Version: 1.0
 %
 %    Modified    By    Reason
 %    --------    --    ------
 %
 %
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef Power < sweeps.Sweep
	properties
		units
	end
	
	methods
		% constructor
		function obj = Power(SweepParams, Instr, ExpParams, sweepPtsOnly)
			if nargin < 3
				error('Usage: Power(SweepParams, Instr, ExpParams)');
			end
			obj.name = 'Power';
			
            if ~sweepPtsOnly
                % look for an instrument with the name 'genID'
                if isfield(Instr, SweepParams.genID)
                    obj.Instr = Instr.(SweepParams.genID);
                else
                    error(['Could not find instrument with name ' SweepParams.genID]);
                end
            end
			
			obj.units = SweepParams.units;
			
			% generate power points
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
		
		% power stepper
		function step(obj, index)
			switch obj.units
				case 'dBm'
					obj.Instr.power = obj.points(index);
				case 'mW'
					% convert mWatts to dBm
					obj.Instr.power = 10*log10( obj.points(index) );
				otherwise
					error('Unknown power units');
			end
		end
	end
end