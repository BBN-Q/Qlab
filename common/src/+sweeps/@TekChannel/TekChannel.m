%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Module Name :  TekChannel.m
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
classdef TekChannel < sweeps.Sweep
	properties
        ampOffset = 'offset'
	end
	
	methods
		% constructor
		function obj = TekChannel(SweepParams, Instr, params, sweepPtsOnly)
			if nargin < 3
				error('Usage: TekChannel(SweepParams, Instr, ExpParams)');
			end
			obj.name = ['TekAWG Channel ' num2str(SweepParams.channel) ' ' SweepParams.ampOffset ' (V)'];
            
            if (SweepParams.channel < 1 || SweepParams.channel > 4)
                error('Specified channel is invalid');
            end
            channel_str = sprintf('chan_%d', SweepParams.channel);
			
            if ~sweepPtsOnly
                % look for an instrument with the name 'TekAWG'
                if isfield(Instr, 'TekAWG')
                    obj.Instr = Instr.TekAWG.(channel_str);
                    obj.ampOffset = SweepParams.ampOffset;
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
            switch lower(obj.ampOffset)
                case 'amp'
                    obj.Instr.Amplitude = obj.points(index);
                case 'offset'
                    obj.Instr.offset = obj.points(index);
                otherwise
                    error('Unrecognized ampOffset value');
            end
		end
	end
end