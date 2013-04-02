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
classdef HeterodyneFrequency < sweeps.Sweep
    properties
        Instr1
        Instr2
        diffFreq
    end
    
    methods
        % constructor
        function obj = HeterodyneFrequency(sweepParams, Instrs)
            obj.label = 'Frequency (GHz)';
            start = sweepParams.start;
            stop = sweepParams.stop;
            step = sweepParams.step;
            if start > stop
                step = -abs(step);
            end
            obj.diffFreq = sweepParams.diffFreq;
            
            % look for an instrument with the name 'genID'
            obj.Instr1 = Instrs.(sweepParams.genID1);
            obj.Instr2 = Instrs.(sweepParams.genID2);
            
            % generate frequency points
            obj.points = start:step:stop;
            obj.numSteps = length(obj.points);
        end
        
        % frequency stepper
        function step(obj, index)
            obj.Instr1.frequency = obj.points(index);
            obj.Instr2.frequency = obj.points(index) + obj.diffFreq;
        end
    end
end