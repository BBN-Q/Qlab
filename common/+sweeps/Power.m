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
classdef Power < sweeps.Sweep
	properties
		units
	end
	
	methods
		% constructor
		function obj = Power(sweepParams, Instr)
			obj.label = 'Power';
			
            % look for an instrument with the name 'genID'
            obj.Instr = Instr.(sweepParams.genID);
			
			obj.units = sweepParams.units;
			
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