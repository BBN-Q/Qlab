% A frequency sweep class.

% Author/Date : Blake Johnson and Colm Ryan / February 4, 2013

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
classdef Frequency < sweeps.Sweep
    properties
    end
    
    methods
        % constructor
        function obj = Frequency(sweepParams, Instr)
            obj.label = 'Frequency (GHz)';
            start = sweepParams.start;
            stop = sweepParams.stop;
            step = sweepParams.step;
            if start > stop
                step = -abs(step);
            end
            
            % look for an instrument with the name 'genID'
            obj.Instr = Instr.(sweepParams.genID);
            
            % generate frequency points
            obj.points = start:step:stop;
            obj.numSteps = length(obj.points);
        end
        
        % frequency stepper
        function step(obj, index)
            obj.Instr.frequency = obj.points(index);
        end
    end
end