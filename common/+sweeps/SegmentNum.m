% A segment number virtual-sweep.

% Author/Date : Colm Ryan / February 4, 2013

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
 classdef SegmentNum < sweeps.Sweep
	properties
	end
	
	methods
		% constructor
		function obj = SegmentNum(sweepParams, ~)
			obj.label = sweepParams.label;
			start = sweepParams.start;
			step = sweepParams.step;
            stop = start+step*(sweepParams.numPoints-1);
			
			% Generate inferred sweep points
			obj.points = start:step:stop;
            
            %Since this is done on the AWG the number of steps is actually
            %1
            obj.numSteps = 1;
			obj.plotRange.start = start;
			obj.plotRange.end = stop;
		end
		
		% frequency stepper
		function step(obj, ~)
		end
	end
end