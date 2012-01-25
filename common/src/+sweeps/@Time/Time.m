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
classdef Time < sweeps.Sweep
	properties
        numSegments
	end
	
	methods
		% constructor
		function obj = Time(SweepParams, Instr, ExpParams, sweepPtsOnly)
			if nargin < 3
				error('Usage: Time(SweepParams, Instr, ExpParams)');
			end
			obj.name = 'Time';
            
            %if ~sweepPtsOnly
                % look for an instrument with the name 'scope'
                if isfield(Instr, 'scope')
                    settings = Instr.scope.averager;
                    obj.numSegments = settings.nbrSegments;
                else
                    error('Could not infer number of segments');
                end
            %end
			
			% generate time points
			start = SweepParams.start;
			step = SweepParams.step;
            stop = start + (obj.numSegments - 1) * step;

            %obj.numSegments is an integer so we have to cast to double or
            %else linspace fails 
			obj.points = linspace(start,double(stop),obj.numSegments);
			
			obj.plotRange.start = start;
			obj.plotRange.end = stop;
		end
		
		% time stepper
		function step(obj, index)
            % do nothing
		end
	end
end