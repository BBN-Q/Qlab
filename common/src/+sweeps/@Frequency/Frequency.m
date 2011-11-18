%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Module Name :  Frequency.m
 %
 % Author/Date : Blake Johnson / October 15, 2010
 %
 % Description : A frequency sweep class.
 %
 % Version: 1.0
 %
 %    Modified    By    Reason
 %    --------    --    ------
 %
 %
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef Frequency < sweeps.Sweep
	properties
		LOInstr
		IFfreq
		lockLO = false
        longSettle = 0
	end
	
	methods
		% constructor
		function obj = Frequency(SweepParams, Instr, ExpParams, sweepPtsOnly)
			if nargin < 3
				error('Usage: Frequency(SweepParams, Instr, ExpParams)');
			end
			obj.name = 'Frequency (GHz)';
			start = SweepParams.start;
			stop = SweepParams.stop;
			step = SweepParams.step;
			if start > stop
				step = -abs(step);
            end
			
            if ~sweepPtsOnly
                % look for an instrument with the name 'genID'
                if isfield(Instr, SweepParams.genID)
                    obj.Instr = Instr.(SweepParams.genID);
                else
                    error(['Could not find instrument with name ' SweepParams.genID]);
                end

                % if we are sweeping RFgen, find LOgen and the IF frequency
                if strcmp(SweepParams.genID, 'RFgen')
                    if isfield(Instr, 'LOgen') && isfield(ExpParams, 'digitalHomodyne') && ~strcmp(ExpParams.digitalHomodyne.DHmode, 'OFF')
                        obj.LOInstr = Instr.LOgen;
                        % IF frequency is in MHz: convert to GHz
                        obj.IFfreq = ExpParams.digitalHomodyne.IFfreq/(1e3);
                        obj.lockLO = true;
                    else
                        warning('Could not find Instr.LOgen and IF frequency. Just sweeping RF.');
                    end
                end
                
                % if pulse mode is enabled, wait longer to settle
                if obj.Instr.pulse
                    obj.longSettle = 1;
                end
            end
			
			% generate frequency points
			obj.points = start:step:stop;
			
			obj.plotRange.start = start;
			obj.plotRange.end = stop;
		end
		
		% frequency stepper
		function step(obj, index)
			obj.Instr.frequency = obj.points(index);
			if obj.lockLO
				obj.LOInstr.frequency = obj.points(index) + obj.IFfreq;
			end
			% wait for the instrument to settle
            if obj.longSettle
                pause(0.2)
            else
                pause(.05);
            end
		end
	end
end