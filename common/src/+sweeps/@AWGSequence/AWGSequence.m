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
        sequencePrefix
        sequencePostfix
        awgParams
	end
	
	methods
		% constructor
		function obj = AWGSequence(SweepParams, Instr, params, sweepPtsOnly)
			if nargin < 3
				error('Usage: AWGSequence(SweepParams, Instr, params, sweepPtsOnly)');
			end
			obj.name = 'AWG sequence number';
			
            if ~sweepPtsOnly
                % look for an instrument with the name 'TekAWG'
                if isfield(Instr, SweepParams.AWGName) && isfield(params.InstrParams, SweepParams.AWGName)
                    obj.Instr = Instr.(SweepParams.AWGName);
                    obj.sequencePrefix = SweepParams.prefix;
                    obj.sequencePostfix = SweepParams.postfix;
                    obj.awgParams = params.InstrParams.(SweepParams.AWGName);
                    obj.awgParams.seqforce = 1;
                else
                    error('Could not find instrument with name: TekAWG');
                end
            end
			
			% generate channel points
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
            sequenceName = [obj.sequencePrefix num2str(obj.points(index)) obj.sequencePostfix];
            % verify that the file exists
            if ~exist(sequenceName, 'file')
                error('AWGSequence ERROR: Could not find file %s\n', sequenceName);
            end
            
            obj.Instr.stop();
            obj.awgParams.seqfile = sequenceName;
            obj.Instr.setAll(obj.awgParams);
		end
	end
end