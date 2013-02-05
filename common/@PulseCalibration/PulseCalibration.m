% The PulseCalibration class uses repeated pulse experiments to optimize
% qubit control parameters, including: amplitude, phase, and DRAG
% parameter. It does this using an efficient Levenberg-Marquardt search.

% Author/Date : Blake Johnson / Aug 24, 2011
% Copyright 2010-13 Raytheon BBN Technologies
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

classdef PulseCalibration < handle
    properties
        experiment % an instance of the ExpManager class
        settings
        pulseParams
        channelMap
        awgParams
        targetAWGIdx = 1
        testMode = false;
        costFunctionGoal = 0.075; % tweak experimentally
    end
    methods
        % Class constructor
        function obj = PulseCalibration()
        end

        function out = homodyneMeasurement(obj, nbrSegments)
            % run the pulse sequence and return the data
            
            % set digitizer with the appropriate number of segments
            averagerSettings = obj.experiment.scopes{1}.averager;
            averagerSettings.nbrSegments = nbrSegments;
            obj.experiment.scopes{1}.averager = averagerSettings;
            
            obj.experiment.run();
            
            % pull out data from the first measurement
            % TODO: allow specifying which measurement to use in the
            % settings struct
            measNames = fieldnames(obj.experiment.measurements);
            data = obj.experiment.data.(measNames{1});
            abs_Data = abs(data);
            phase_Data = 180/pi * unwrap(angle(data));
            
            % return amplitude or phase data
            switch obj.settings.dataType
                case 'amp'
                    out = abs_Data;
                case 'phase'
                    % unwrap assume phase data in radians
                    out = phase_Data;
                otherwise
                    error('Unknown dataType can only be "amp" or "phase"');
            end
        end

        function [cost, J] = Xpi2ObjectiveFnc(obj, x0)
            [cost, Jtmp] = obj.pi2ObjectiveFunction(x0, 'X');
            if nargout > 1
                J = Jtmp;
            end
        end
        function [cost, J] = Ypi2ObjectiveFnc(obj, x0)
            [cost, Jtmp] = obj.pi2ObjectiveFunction(x0, 'Y');
            if nargout > 1
                J = Jtmp;
            end
        end
        function [cost, J] = XpiObjectiveFnc(obj, x0)
            [cost, Jtmp] = obj.piObjectiveFunction(x0, 'X');
            if nargout > 1
                J = Jtmp;
            end
        end
        function [cost, J] = YpiObjectiveFnc(obj, x0)
            [cost, Jtmp] = obj.piObjectiveFunction(x0, 'Y');
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
        
        function Init(obj, settings)
            obj.settings = settings;
            obj.channelMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));
            
            if isfield(obj.settings, 'SoftwareDevelopmentMode') && obj.settomgs.SoftwareDevelopmentMode
                obj.testMode = true;
            end
            
            % create an ExpManager object
            obj.experiment = ExpManager();
            
            % load ExpManager settings
            expSettings = jsonlab.loadjson(obj.settings.cfgFile);
            instrSettings = expSettings.instruments;
            
            % add instruments
            for instrument = fieldnames(instrSettings)'
                instr = InstrumentFactory(instrument{1});
                add_instrument(obj.experiment, instrument{1}, instr, instrSettings.(instrument{1}));
            end
            
            % create a generic SegmentNum sweep
            add_sweep(obj.experiment, sweeps.SegmentNum(struct('label', 'Segment', 'start', 0, 'step', 1, 'numPoints', 2)));
            
            % add measurement M1
            measSettings = expSettings.measurements;
            dh1 = DigitalHomodyne(measSettings.meas1);
            add_measurement(obj.experiment, 'M1', dh1);
            
            % intialize the ExpManager
            init(obj.experiment);
            
            IQchannels = obj.channelMap.(obj.ExpParams.Qubit);
            IQkey = IQchannels.IQkey;
            
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
                        %% FIX ME
                        obj.awgParams{numAWGs} = obj.inputStructure.InstrParams.(InstrName);
                        obj.awgParams{numAWGs}.InstrName = InstrName;
                        if strcmp(InstrName, IQchannels.awg)
                            obj.targetAWGIdx = numAWGs;
                        end
                    case {'deviceDrivers.AgilentAP240', 'deviceDrivers.AlazarATS9870'}
                        %% FIX ME
                        obj.scopeParams = obj.inputStructure.InstrParams.(InstrName);
                end
            end

            if ~obj.testMode
                % load pulse parameters for the relevant qubit
                params = jsonlab.loadjson(getpref('qlab', 'pulseParamsBundleFile'));
                obj.pulseParams = params.(obj.settings.Qubit);
                obj.pulseParams.T = params.(IQkey).T;
                %% FIX ME
                channelParams = obj.inputStructure.InstrParams.(IQchannels.awg);
                obj.pulseParams.i_offset = channelParams.(['chan_' num2str(IQchannels.i)]).offset;
                obj.pulseParams.q_offset = channelParams.(['chan_' num2str(IQchannels.q)]).offset;
            else
                obj.pulseParams = struct('piAmp', 6560, 'pi2Amp', 3280, 'delta', -0.5, 'T', eye(2,2),...
                    'pulseType', 'drag', 'i_offset', 0.119, 'q_offset', 0.130);
            end
        end
        
        function Do(obj)
            obj.PulseCalibrationDo();
        end
        
        function filenames = getAWGFileNames(obj, basename)
            pathAWG = fullfile(getpref('qlab', 'awgDir'), basename);
            awgs = cellfun(@(x) x.InstrName, obj.awgParams, 'UniformOutput',false);
            for awgct = 1:length(awgs)
                switch awgs{awgct}(1:6)
                    case 'TekAWG'
                        filenames{awgct} = fullfile(pathAWG, [basename '-' awgs{awgct}, '.awg']);
                    case 'BBNAPS'
                        filenames{awgct} = fullfile(pathAWG, [basename '-' awgs{awgct}, '.h5']);
                    otherwise
                        error('Unknown AWG type.');
                end
            end
        end
    end
        
    methods (Static)
        
        % externally defined static methods
        [cost, J] = RepPulseCostFunction(data, angle);
        [amp, offsetPhase]  = analyzeRabiAmp(data);
        bestParam = analyzeSlopes(data, numPsQIds, paramRange);
        
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
            cfg_path = [path '/unit_test.json'];
            writeCfgFromStruct(cfg_path, cfg);
            
            % create object instance
            pulseCal = expManager.pulseCalibration(path, cfg_path, 'unit_test', 1);
            
            %pulseCal.pulseParams = struct('piAmp', 6000, 'pi2Amp', 2800, 'delta', -0.5, 'T', eye(2,2), 'pulseType', 'drag',...
            %                        'i_offset', 0.110, 'q_offset', 0.138, 'SSBFreq', 0);
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
            pulseCal.Do();
        end
    end
end
