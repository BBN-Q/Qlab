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
classdef AWGChannel < sweeps.Sweep
    properties
        AWGType
        mode
        channelList
    end
    
    methods
        % constructor
        function obj = AWGChannel(SweepParams, Instr, ~, sweepPtsOnly)
            if nargin < 3
                error('Usage: AWGChannel(SweepParams, Instr, ExpParams)');
            end
            obj.name = ['AWG Channel(s) ' SweepParams.channel ' ' SweepParams.mode ' (V)'];
            
            if ~sweepPtsOnly
                % look for the AWG instrument object
                assert(isfield(Instr, SweepParams.AWGName), 'Could not find AWG instrument');
                %obj.Instr = Instr.TekAWG.(channel_str);
                obj.Instr = Instr.(SweepParams.AWGName);
            end
            
            switch SweepParams.AWGName(1:6)
                case 'TekAWG'
                    obj.AWGType = 'Tek';
                case 'BBNAPS'
                    obj.AWGType = 'APS';
                otherwise
                    error('Unrecognized AWG type');
            end
            
            obj.mode = SweepParams.mode;
            
            % construct channel list
            switch SweepParams.channel
                case {'1', '2', '3', '4'}
                    obj.channelList = str2double(SweepParams.channel);
                case '1&2'
                    obj.channelList = [1, 2];
                case '3&4'
                    obj.channelList = [3, 4];
                otherwise
                    error('Unrecognized channel parameter');
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
        
        function stepAmplitude(obj, index)
            for ch = obj.channelList
                switch (obj.AWGType)
                    case 'Tek'
                        channel_str = sprintf('chan_%d', ch);
                        obj.Instr.(channel_str).amplitude = obj.points(index);
                    case 'APS'
                        obj.Instr.setAmplitude(ch, obj.points(index));
                end
            end
        end
        
        function stepOffset(obj, index)
            for ch = obj.channelList
                switch (obj.AWGType)
                    case 'Tek'
                        channel_str = sprintf('chan_%d', ch);
                        obj.Instr.(channel_str).offset = obj.points(index);
                    case 'APS'
                        obj.Instr.setOffset(ch, obj.points(index));
                end
            end
        end
        
        function step(obj, index)
            switch lower(obj.mode)
                case 'amp'
                    obj.stepAmplitude(index);
                case 'offset'
                    obj.stepOffset(index);
            end
        end
    end
end
