% A DC source sweep class.

% Author/Date : Blake Johnson

% Copyright 2013 Raytheon BBN Technologies
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
%
%     http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.
classdef DC < sweeps.Sweep
	properties
		channel
	end
	
	methods
		% constructor
		function obj = DC(sweepParams, Instr)
			obj.label = 'DC';
			
            % look for an instrument with the name 'sourceID'
            obj.Instr = Instr.(sweepParams.sourceID);
			% grab the instrument channel
			obj.channel = sweepParams.channel;
			
			% generate power points
			start = sweepParams.start;
			stop = sweepParams.stop;
			step = sweepParams.step;
			if start > stop
				step = -abs(step);
			end
			obj.points = start:step:stop;
            obj.numSteps = length(obj.points);
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