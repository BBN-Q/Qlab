% A dummy class for repeating.

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
classdef Repeat < sweeps.Sweep
	properties

	delay = 0;

	end

	methods
		% constructor
		function obj = Repeat(sweepParams, ~)
			obj.axisLabel = 'Repeat';

			% generate sweep points
            obj.numSteps = sweepParams.numRepeats;
			obj.points = 1:obj.numSteps;
			obj.delay = sweepParams.delay;

		end

		% repeat stepper
		function step(obj, ~)
            % do nothing
			pause(obj.delay);
		end
	end
end
