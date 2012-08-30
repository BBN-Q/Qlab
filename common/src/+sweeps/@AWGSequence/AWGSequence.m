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
        AWGName
        TekAWG
        TekParams
        BBNAPS
        BBNParams
	end
	
	methods
		% constructor
		function obj = AWGSequence(SweepParams, Instr, params, sweepPtsOnly)
			if nargin < 3
				error('Usage: AWGSequence(SweepParams, Instr, params, sweepPtsOnly)');
			end
			obj.name = 'AWG sequence number';
			
            if ~sweepPtsOnly
                %Switch on which AWG we are looping through
                obj.AWGName = SweepParams.AWGName;
                obj.sequenceFile = SweepParams.sequenceFile;
                switch obj.AWGName
                    case 'TekAWG'
                        obj.TekAWG = Instr.TekAWG;
                        obj.TekParams = params.InstrParams.TekAWG;
                        obj.TekParams.seqforce = 1;
                    case 'BBNAPS'
                        obj.BBNAPS = Instr.BBNAPS;
                        obj.BBNParams = params.InstrParams.BBNAPS;
                        obj.BBNParams.seqforce = 1;
                    case 'Both'
                        obj.TekAWG = Instr.TekAWG;
                        obj.TekParams = params.InstrParams.TekAWG;
                        obj.TekParams.seqforce = 1;
                        obj.BBNAPS = Instr.BBNAPS;
                        obj.BBNParams = params.InstrParams.BBNAPS;
                        obj.BBNParams.seqforce = 1;
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
            
            %This assumes the TekAWG is the Master and the slave APS needs
            %to be restarted. 
            
            switch obj.AWGName
                case 'TekAWG'
                    step_TekAWG()
                case 'BBNAPS'
                    step_BBNAPS()
                case 'Both'
                    step_TekAWG()
                    step_BBNAPS()
            end
            
            function step_TekAWG()
                obj.TekAWG.stop()
                TekFile = fullfile('U:\AWG', [obj.sequenceFile, '-TekAWG', num2str(obj.points(index)), '.awg']);
                assert(logical(exist(TekFile, 'file')), 'AWGSequence ERROR: Could not find file %s\n', TekFile)
                obj.TekParams.seqfile = TekFile;
                obj.TekAWG.setAll(obj.TekParams);
            end
            
            function step_BBNAPS()
                obj.BBNAPS.stop()
                APSFile = fullfile('U:\AWG', [obj.sequenceFile, '-BBNAPS', num2str(obj.points(index)), '.h5']);
                assert(logical(exist(APSFile, 'file')), 'AWGSequence ERROR: Could not find file %s\n', APSFile)
                obj.BBNParams.seqfile = APSFile;
                obj.BBNAPS.setAll(obj.BBNParams);
                obj.BBNAPS.run()
                isRunning = obj.BBNAPS.waitForAWGtoStartRunning();
                assert(isRunning, 'Oops! Could not get the APS running.') 
            end
            
		end
	end
end