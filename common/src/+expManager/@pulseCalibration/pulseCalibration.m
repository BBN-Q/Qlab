%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Module Name :  pulseCalibration.m
%
% Author/Date : Blake Johnson / Aug 24, 2011
%
% Description : Loops over a set of homodyneDetection2D experiments to
% optimize qubit operations
%
% Restrictions/Limitations : UNRESTRICTED
%
% Change Descriptions :
%
% Classification : Unclassified
%
% References :
%
%
%    Modified    By    Reason
%    --------    --    ------
%
%
% Copyright 2010 Raytheon BBN Technologies
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

classdef pulseCalibration < expManager.homodyneDetection2D
    properties
        pulseParams
        pulseParamPath
        mixerCalPath
        channelMap
        ExpParams
        awgParams
        targetAWGIdx = 1
        scope
        scopeParams
        testMode = false;
        costFunctionGoal = 0.075; % tweak experimentally
    end
    methods (Static)
        %% Class constructor
        function obj = pulseCalibration(data_path, cfgFileName, basename, filenumber)
            if ~exist('filenumber', 'var')
                filenumber = 1;
            end
            if ~exist('basename', 'var')
                basename = 'pulseCalibration';
            end
			% superclass constructor
            obj = obj@expManager.homodyneDetection2D(data_path, cfgFileName, basename, filenumber);
            
            script = mfilename('fullpath');
            sindex = strfind(script, 'common');
            script = [script(1:sindex-1) 'experiments/muWaveDetection/'];
            
            obj.mixerCalPath = [script 'cfg/mixercal.mat'];
            obj.pulseParamPath = getpref('qlab', 'pulseParamsBundleFile');
            
            % to do: load channel mapping from file
            obj.channelMap = jsonlab.loadjson(getpref('qlab','PulseCalibrationMap'));
        end
        
        % externally defined static methods
        [cost, J] = RepPulseCostFunction(data, angle);
        [amp, offsetPhase]  = analyzeRabiAmp(data);
        
        function UnitTest()
            script = java.io.File(mfilename('fullpath'));
            path = char(script.getParent());
            
            % construct minimal cfg file
            ExpParams = struct();
            ExpParams.Qubit = 'q1';
            ExpParams.DoMixerCal = 0;
            ExpParams.DoRabiAmp = 1;
            ExpParams.DoRamsey = 0;
            ExpParams.DoPi2Cal = 1;
            ExpParams.DoPiCal = 1;
            ExpParams.DoDRAGCal = 0;
            ExpParams.OffsetNorm = 1;
            
            cfg = struct('ExpParams', ExpParams, 'SoftwareDevelopmentMode', 1, 'InstrParams', struct());
            cfg_path = [path '/unit_test.cfg'];
            writeCfgFromStruct(cfg_path, cfg);
            
            % create object instance
            pulseCal = expManager.pulseCalibration(path, cfg_path, 'unit_test', 1);
            
            %pulseCal.pulseParams = struct('piAmp', 6000, 'pi2Amp', 2800, 'delta', -0.5, 'T', eye(2,2), 'pulseType', 'drag',...
            %                         'i_offset', 0.110, 'q_offset', 0.138);
            %pulseCal.rabiAmpChannelSequence('q1q2', true);
            %pulseCal.rabiAmpChannelSequence('q2', false);
            %pulseCal.Pi2CalChannelSequence('q1q2', 'X', true);
            %pulseCal.Pi2CalChannelSequence('q2', 'Y', false);
            %pulseCal.PiCalChannelSequence('q1q2', 'Y', true);
            %pulseCal.PiCalChannelSequence('q2', 'X', false);
            
            % rabi Amp data
            %xpts = 0:100:80*100;
            %piAmp = 6200;
            %data = 0.5 - 0.1 * cos(2*pi*xpts/(2*piAmp));
            %piAmpGuess = pulseCal.analyzeRabiAmp(data);
            %fprintf('Initial guess for piAmp: %.1f\n', piAmpGuess);
            
            % perfect Pi2Cal data
            %data = [0 0 .5*ones(1,36)];
            %[cost, J] = pulseCal.Pi2CostFunction(data);
            %fprintf('Pi2Cost for ''perfect'' data. Cost: %.4f, Jacobian: (%.4f, %.4f)\n', sum(cost.^2/length(cost)), sum(J(:,1)), sum(J(:,2)));
            
            % data representing amplitude error
            %n = 1:9;
            %data = 0.65 + 0.1*(-1).^n .* n./10;
            %data = data(floor(1:.5:9.5));
            %data = [0.5 0.5 data data];
            %[cost, J] = pulseCal.Pi2CostFunction(data);
            %fprintf('Pi2Cost for more realistic data. Cost: %.4f, Jacobian: (%.4f, %.4f)\n', sum(cost.^2/length(cost)), sum(J(:,1)), sum(J(:,2)));
            %cost = pulseCal.PiCostFunction(data);
            %fprintf('PiCost for more realistic data: %f\n', cost);
            
            pulseCal.Init();
            %pulseCal.Do();
            %pulseCal.CleanUp();
        end
    end
    methods
        function out = homodyneMeasurement(obj, nbrSegments)
            % homodyneMeasurement calls homodyneDetection2DDo and returns
            % the amplitude data
            
            % set digitizer with the appropriate number of segments
            obj.scopeParams.averager.nbrSegments = nbrSegments;
            obj.scope.averager = obj.scopeParams.averager;
            
            % create tmp file
            fclose('all'); % make sure dangling file handles are closed
            obj.openDataFile();
            fprintf(obj.DataFileHandle,'$$$ Beginning of Data\n');
            obj.homodyneDetection2DDo();
            % finish and close file
            fprintf(obj.DataFileHandle,'\n$$$ End of Data\n');
            fclose(obj.DataFileHandle);
            data = obj.parseDataFile(false);
            
            % delete the file
            filename = [obj.DataPath '\' obj.DataFileName];
            delete(filename);
            
            % return the amplitude data
            out = data.abs_Data;
        end

        function [cost, J] = Xpi2ObjectiveFnc(obj, x0)
            [cost, Jtmp] = obj.pi2ObjectiveFunction(x0, obj.ExpParams.Qubit, 'X');
            if nargout > 1
                J = Jtmp;
            end
        end
        function [cost, J] = Ypi2ObjectiveFnc(obj, x0)
            [cost, Jtmp] = obj.pi2ObjectiveFunction(x0, obj.ExpParams.Qubit, 'Y');
            if nargout > 1
                J = Jtmp;
            end
        end
        function [cost, J] = XpiObjectiveFnc(obj, x0)
            [cost, Jtmp] = obj.piObjectiveFunction(x0, obj.ExpParams.Qubit, 'X');
            if nargout > 1
                J = Jtmp;
            end
        end
        function [cost, J] = YpiObjectiveFnc(obj, x0)
            [cost, Jtmp] = obj.piObjectiveFunction(x0, obj.ExpParams.Qubit, 'Y');
            if nargout > 1
                J = Jtmp;
            end
        end

        function stop = LMStoppingCondition(obj, x, optimValues, state)
            if optimValues.resnorm < obj.costFunctionGoal
                stop = true;
            else
                stop = false;
            end
        end
        
        function Init(obj)
            obj.parseExpcfgFile();
            obj.ExpParams = obj.inputStructure.ExpParams;
            if isfield(obj.inputStructure, 'SoftwareDevelopmentMode') && obj.inputStructure.SoftwareDevelopmentMode
                obj.testMode = true;
            end
            Init@expManager.homodyneDetection2D(obj);
            
            IQchannels = obj.channelMap.(obj.ExpParams.Qubit);
            IQkey = [IQchannels.instr num2str(IQchannels.i) num2str(IQchannels.q)];
            
            % find AWG instrument parameters(s) - traverse in the same way
            % used to find the awg objects, to try to preserve the ordering
            % at the same time, grab the digitizer object and parameters
            numAWGs = 0;
            InstrumentNames = fieldnames(obj.Instr);
            for Instr_index = 1:numel(InstrumentNames)
                InstrName = InstrumentNames{Instr_index};
                DriverName = class(obj.Instr.(InstrName));
                switch DriverName
                    case {'deviceDrivers.Tek5014', 'deviceDrivers.APS'}
                        numAWGs = numAWGs + 1;
                        obj.awgParams{numAWGs} = obj.inputStructure.InstrParams.(InstrName);
                        if strcmp(InstrName, IQchannels.instr)
                            obj.targetAWGIdx = numAWGs;
                        end
                    case 'deviceDrivers.AgilentAP120'
                        obj.scope = obj.Instr.(InstrName);
                        obj.scopeParams = obj.inputStructure.InstrParams.(InstrName);
                end
            end

            if ~obj.testMode
                % load pulse parameters for the relevant qubit
                params = jsonlab.loadjson(obj.pulseParamPath);
                obj.pulseParams = params.(obj.ExpParams.Qubit);
                obj.pulseParams.T = params.(IQkey).T;
                channelParams = obj.inputStructure.InstrParams.(IQchannels.instr);
                obj.pulseParams.i_offset = channelParams.(['chan_' num2str(IQchannels.i)]).offset;
                obj.pulseParams.q_offset = channelParams.(['chan_' num2str(IQchannels.q)]).offset;
            else
                obj.pulseParams = struct('piAmp', 6560, 'pi2Amp', 3280, 'delta', -0.5, 'T', eye(2,2),...
                    'pulseType', 'drag', 'i_offset', 0.119, 'q_offset', 0.130);
            end
            
            % create a generic 'time' sweep
            timeSweep = struct('type', 'sweeps.Time', 'number', 1, 'start', 0, 'step', 1);
            obj.inputStructure.SweepParams = struct('time', timeSweep);
        end
        
        function Do(obj)
            obj.pulseCalibrationDo();
        end
        
        function errorCheckExpParams(obj)
            % call super class method
            errorCheckExpParams@expManager.homodyneDetection2D(obj);

            ExpParams = obj.inputStructure.ExpParams;
            if ~isfield(ExpParams, 'OffsetNorm')
                ExpParams.OffsetNorm = 2;
            end
        end
    end
end
