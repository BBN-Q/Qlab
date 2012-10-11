%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Module Name :  AWGSequence.m
%
% Author/Date : Blake Johnson / November 9, 2010
%
% Description : A Tek channel sweep class.
%
% Version: 1.0
%
%    Modified    By    Reason
%    --------    --    ------
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef AWGSequence < sweeps.Sweep
    properties
        sequenceFile
        awgs
    end
    
    methods
        % constructor
        function obj = AWGSequence(SweepParams, Instr, params, sweepPtsOnly)
            if nargin < 3
                error('Usage: AWGSequence(SweepParams, Instr, params, sweepPtsOnly)');
            end
            obj.name = 'AWG sequence number';
            
            obj.awgs = struct();
            obj.sequenceFile = SweepParams.sequenceFile;

            if ~sweepPtsOnly
                %Load the enabled AWGs
                %Go through the instrument list and pull out enabled AWG's
                for tmp = fieldnames(Instr)'
                    curName = tmp{1};
                    if isa(Instr.(curName), 'deviceDrivers.Tek5014') || isa(Instr.(curName), 'deviceDrivers.APS')
                        if params.InstrParams.(curName).enable
                            obj.awgs.(curName)= struct();
                            obj.awgs.(curName).driver = Instr.(curName);
                            obj.awgs.(curName).params = params.InstrParams.(curName);
                            obj.awgs.(curName).params.seqforce = 1;
                        end
                    end
                end
            end
                        
            % generate sweep points
            start = SweepParams.start;
            stop = SweepParams.stop;
            step = SweepParams.step;
            if start > stop
                step = -abs(step);
            end
            obj.points = start:step:stop;
            
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