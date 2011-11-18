%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Module Name :  TekChannel.m
 %
 % Author/Date : Blake Johnson / November 9, 2010
 %
 % Description : A Tek channel sweep class.
 %
 % Version: 1.0
 %
 %    Modified    By    Reason
 %    --------    --    ------
 %
 %
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef CrossDriveTuneUp < sweeps.Sweep
	properties
        aps
        sequencePath = 'U:\APS\Rabi\CrossDriveTuneUp.mat';
	end
	
	methods
		% constructor
		function obj = CrossDriveTuneUp(SweepParams, Instr, ExpParams, sweepPtsOnly)
			if nargin < 3
				error('Usage: CrossDriveTuneUp(SweepParams, Instr, ExpParams)');
			end
			obj.name = 'Sequence number';
			
            if ~sweepPtsOnly
                obj.aps = Instr.BBNAPS;
            end
			
			% generate channel points
			%start = SweepParams.start;
			%stop = SweepParams.stop;
			%step = SweepParams.step;
            start = -8000;
            stop = 8000;
            step = 250;
			if start > stop
				step = -abs(step);
			end
			obj.points = start:step:stop;
			
			obj.plotRange.start = start;
			obj.plotRange.end = stop;
		end
		
		% channel stepper
		function step(obj, index)
            crossDriveTuneUpSequence(obj.points(index), false);
            obj.aps.stop();
            obj.aps.loadConfig(obj.sequencePath);
            obj.aps.run();
		end
	end
end