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
        awgs
    end
    
    methods
        % constructor
        function obj = AWGSequence(sweepParams, Instr)
            obj.label = 'AWG sequence number';
            
            obj.awgs = struct();
            obj.sequenceFile = sweepParams.sequenceFile;

            %Construct a list of AWGs
            for tmp = fieldnames(Instr)'
                curName = tmp{1};
                if isa(Instr.(curName), 'deviceDrivers.Tek5014') || isa(Instr.(curName), 'deviceDrivers.APS')
                    if params.InstrParams.(curName).enable
                        obj.awgs.(curName)= struct();
                        obj.awgs.(curName).driver = Instr.(curName);
                        % TODO: fix me (following two lines do not work)
                        obj.awgs.(curName).params = params.InstrParams.(curName);
                        obj.awgs.(curName).params.seqforce = 1;
                    end
                end
            end
                        
            % generate sweep points
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
        
        % channel stepper
        function step(obj, index)
            
            %Loop over the AWGs
            for tmp = fieldnames(obj.awgs)'
                curAWGName = tmp{1};
                switch class(obj.awgs.(curAWGName).driver)
                    case 'deviceDrivers.Tek5014'
                        ext = '.awg';
                    case 'deviceDrivers.APS'
                        ext = '.h5';
                end
                fileName = sprintf('%s-%s_%d%s',obj.sequenceFile, curAWGName, obj.points(index), ext);
                assert(logical(exist(fileName, 'file')), 'AWGSequence ERROR: Could not find file %s\n', fileName)
                
                %Stop the AWG
                obj.awgs.(curAWGName).driver.stop()
                
                %Load the new file
                obj.awgs.(curAWGName).params.seqfile = fileName;
                obj.awgs.(curAWGName).driver.setAll(obj.awgs.(curAWGName).params);
                
                %If it is not a master then start it up
                if ~obj.awgs.(curAWGName).params.isMaster
                    obj.awgs.(curAWGName).driver.run();
                    assert(obj.awgs.(curAWGName).driver.waitForAWGtoStartRunning(), 'Oops! Could not get the APS running.')
                end
            end
        end
    end
end