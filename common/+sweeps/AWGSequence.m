% Sweep for AWG sequence name.

% Author/Date : Blake Johnson and Colm Ryan

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
classdef AWGSequence < sweeps.Sweep
    properties
        sequenceFile
        AWGs
    end
    
    methods
        % constructor
        function obj = AWGSequence(sweepParams, Instr)
            obj.axisLabel = 'AWG Sequence Number';
            
            obj.sequenceFile = sweepParams.sequenceFile;

            %Construct a list of AWGs
            obj.AWGs = struct_filter(@(x) ExpManager.is_AWG(x), Instr);
                        
            % generate sweep points
            start = sweepParams.start;
            stop = sweepParams.stop;
            step = sweepParams.step;
            if start > stop
                step = -abs(step);
            end
            obj.points = start:step:stop;
            obj.numSteps = length(obj.points);
            
        end
        
        % channel stepper
        function step(obj, index)
            
            %Loop over the AWGs
            for tmp = fieldnames(obj.AWGs)'
                curAWGName = tmp{1};
                switch class(obj.AWGs.(curAWGName))
                    case 'deviceDrivers.Tek5014'
                        ext = '.awg';
                        error('Have not written code for TekAWG yet.');
                    case 'deviceDrivers.APS'
                        ext = '.h5';
                end
                fileName = sprintf('%s-%s_%d%s',obj.sequenceFile, curAWGName, obj.points(index), ext);
                assert(logical(exist(fileName, 'file')), 'AWGSequence ERROR: Could not find file %s\n', fileName)
                
                %Load the new file
                wasRunning = false;
                if obj.AWGs.(curAWGName).isRunning
                    wasRunning = true;
                    obj.AWGs.(curAWGName).stop()
                end
                obj.AWGs.(curAWGName).loadConfig(fileName);
                if wasRunning
                    obj.AWGs.(curAWGName).run()
                    pause(0.1);
                end
            end
        end
    end
end