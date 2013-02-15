% A phase sweep class.

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
classdef Phase < sweeps.Sweep
	properties
	end
	
	methods
		% constructor
		function obj = Phase(sweepParams, Instr)
			obj.label = 'Phase';
			
            % look for an instrument with the name 'genID'
            if isfield(Instr, sweepParams.genID)
                obj.Instr = Instr.(sweepParams.genID);
            else
                error(['Could not find instrument with name ' sweepParams.genID]);
            end
			
			% generate phase points
			start = sweepParams.start;
			stop = sweepParams.stop;
			step = sweepParams.step;
			if start > stop
				step = -abs(step);
			end
			obj.points = start:step:stop;
            obj.numSteps = length(obj.points);
			
			obj.plotRange.start = start;
			obj.plotRange.end = stop;
		end
		
		% phase stepper
		function step(obj, index)
			obj.Instr.phase = obj.points(index);
		end
	end
end