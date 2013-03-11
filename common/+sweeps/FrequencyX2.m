% A frequency sweep class for two simultaneous frequency sweeps. 
% Mainly used for heterodyne measurment frequency sweeps

% Author/Date : Colm Ryan / March 11, 2013

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
classdef HetrodyneFrequency < sweeps.Sweep
    properties
        Instr1
        Instr2
        points2
        
    end
    
    methods
        % constructor
        function obj = FrequencyX2(sweepParams, Instrs)
            obj.label = 'Frequency (GHz)';
            start1 = sweepParams.start1;
            stop1 = sweepParams.stop1;
            step1 = sweepParams.step1;
            if start1 > stop1
                step1 = -abs(step1);
            end
            
            % look for an instrument with the name 'genID'
            obj.Instr1 = Instrs.(sweepParams.genID1);
            
            % generate frequency points
            obj.points = start1:step1:stop1;
            obj.numSteps = length(obj.points);
            
            %Also sweep the second source
            obj.Instr2 = Instrs.(sweepParams.genID2);
            obj.points2 = sweepParams.start2:sweepParams.step2:sweepParams.stop2;
            assert(length(obj.points2) == obj.numSteps, 'Oops! The two frequency sweeps must have the same number of points.')
            
        end
        
        % frequency stepper
        function step(obj, index)
            obj.Instr1.frequency = obj.points(index);
            obj.Instr2.frequency = obj.points2(index);
        end
    end
end