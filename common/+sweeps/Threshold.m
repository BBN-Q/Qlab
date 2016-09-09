% A threshold sweep class.

% Author/Date : Diego Riste'

% Copyright 2015 Raytheon BBN Technologies
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

classdef Threshold < sweeps.Sweep
    properties
        stream
    end
    methods
		% constructor
		function obj = Threshold(sweepParams, instruments)
			obj.axisLabel = 'Threshold';
            obj.Instr = instruments.X6;
            obj.stream = sweepParams.stream;
			% generate threshold points
			start = sweepParams.start;
			stop = sweepParams.stop;
			step = sweepParams.step;
			if start > stop
				step = -abs(step);
			end
			obj.points = start:step:stop;
            obj.numSteps = length(obj.points);
        end
        
        %threshold stepper
        function step(obj,index)
            obj.Instr.set_threshold(str2double(obj.stream(2)),str2double(obj.stream(4)),obj.points(index));
        end
    end
end