%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Module Name :  DC.m
 %
 % Author/Date : Blake Johnson / October 29, 2010
 %
 % Description : A DC sweep class.
 %
 % Version: 1.0
 %
 %    Modified    By    Reason
 %    --------    --    ------
 %
 %
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef DC < sweeps.Sweep
	properties
		channel
	end
	
	methods
		% constructor
		function obj = DC(SweepParams, Instr, params, sweepPtsOnly)
			if nargin < 3
				error('Usage: DC(SweepParams, Instr, ExpParams)');
			end
			obj.name = 'DC';
			
            if ~sweepPtsOnly
                % look for an instrument with the name 'genID'
                if isfield(Instr, SweepParams.sourceID)
                    obj.Instr = Instr.(SweepParams.sourceID);
                else
                    error(['Could not find instrument with name ' SweepParams.sourceID]);
                end
            end
			% grab the instrument channel
			obj.channel = SweepParams.channel;
			
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
		
		% DC stepper
		function step(obj, index)
			% hard coded to set coarse pot on BBN DC source. Make this more
			% flexible in the future.
			% loop through channels in case an array of channels is
			% specified
			for i = obj.channel
				obj.Instr.SetSinglePot(i, 0, obj.points(index));
			end
			pause(0.5); % pause 500 ms for settling
		end
	end
end