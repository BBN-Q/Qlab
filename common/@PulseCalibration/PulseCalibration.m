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
        channelParams
        controlAWG % name of control AWG
        AWGs
        AWGSettings
        testMode = false;
        noiseVar % estimated variance of the noise from repeats
    end
    methods
        % Class constructor
        function obj = PulseCalibration()
        end

        function out = homodyneMeasurement(obj, segmentPoints)
            % runs the pulse sequence and returns the data
            
            % set number of segments in the sweep
            obj.experiment.sweeps{1}.points = segmentPoints;

            % set digitizer with the appropriate number of segments
            averagerSettings = obj.experiment.scopes{1}.averager;
            averagerSettings.nbrSegments = length(segmentPoints);
            obj.experiment.scopes{1}.averager = averagerSettings;
            
            obj.experiment.run();
            
            % pull out data from the first measurement
            measNames = fieldnames(obj.experiment.measurements);
            data = obj.experiment.data.(measNames{1}).mean;
            
            % return amplitude or phase data
            switch obj.settings.dataType
                case 'amp'
                    out = abs(data);
                case 'phase'
                    % unwrap phase jumps
                    out = 180/pi * unwrap(angle(data));
                case 'real'
                    out = real(data);
                case 'imag'
                    out = imag(data);
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

        function stop = LMStoppingCondition(obj, ~, optimValues, ~)
            %Assume that if the variance of the residuals is less than some 
            %multiple of the variance of the noise then we are as good as it gets
            %Anecdotally 2-3 seems to be reasonable 
            if var(optimValues.residual) < 3*obj.noiseVar
                stop = true;
            else
                stop = false;
            end
        end
        
        function Init(obj, settings)
            obj.settings = settings;

            channelLib = jsonlab.loadjson(getpref('qlab','ChannelParams'));
            assert(isfield(channelLib, settings.Qubit), 'Qubit %s not found in channel library', settings.Qubit);
            obj.channelParams = channelLib.(settings.Qubit);
            
            if isfield(obj.settings, 'SoftwareDevelopmentMode') && obj.settings.SoftwareDevelopmentMode
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
            add_sweep(obj.experiment, 1, sweeps.SegmentNum(struct('label', 'Segment', 'start', 0, 'step', 1, 'numPoints', 2)));
            
            % add measurement M1
            import MeasFilters.*
            measSettings = expSettings.measurements;
            dh = DigitalHomodyne(measSettings.(obj.settings.measurement));
            add_measurement(obj.experiment, obj.settings.measurement, dh);
            
            % intialize the ExpManager
            init(obj.experiment);
            
            obj.AWGs = struct_filter(@(x) ExpManager.is_AWG(x), obj.experiment.instruments);
            obj.AWGSettings = cellfun(@(awg) obj.experiment.instrSettings.(awg), fieldnames(obj.AWGs)', 'UniformOutput', false);
            obj.AWGSettings = cell2struct(obj.AWGSettings, fieldnames(obj.AWGs)', 2);

            tmpStr = strsplit(obj.channelParams.physChan);
            obj.controlAWG = tmpStr{1};

            if ~obj.testMode
                % pull in physical channel parameters into channelParams
                physChan = obj.channelParams.physChan;
                obj.channelParams.ampFactor = channelLib.(physChan).ampFactor;
                obj.channelParams.phaseSkew = channelLib.(physChan).phaseSkew;
                controlAWGsettings = obj.AWGSettings.(obj.controlAWG);
                obj.channelParams.i_offset = controlAWGsettings.(['chan_' physChan(end-1)]).offset;
                obj.channelParams.q_offset = controlAWGsettings.(['chan_' physChan(end)]).offset;
                obj.channelParams.SSBFreq = channelLib.(physChan).SSBFreq;
            else
                obj.channelParams = struct('piAmp', 0.6, 'pi2Amp', 0.3, 'dragScaling', -0.5, 'ampFactor', 1,...
                    'phaseSkew', 0, 'shapeFun', 'drag', 'i_offset', 0.019, 'q_offset', 0.013);
            end
        end
        
        function Do(obj)
            obj.PulseCalibrationDo();
        end
        
        function filenames = getAWGFileNames(obj, basename)
            pathAWG = fullfile(getpref('qlab', 'awgDir'), basename);
            awgNames = fieldnames(obj.AWGs)';
            for awgct = 1:length(awgNames)
                switch class(obj.AWGs.(awgNames{awgct}))
                    case 'deviceDrivers.Tek5014'
                        filenames{awgct} = fullfile(pathAWG, [basename '-' awgNames{awgct}, '.awg']);
                    case 'deviceDrivers.APS'
                        filenames{awgct} = fullfile(pathAWG, [basename '-' awgNames{awgct}, '.h5']);
                    otherwise
                        error('Unknown AWG type.');
                end
            end
        end

        function cleanup(obj)
            error('Not implemented')
        end
    end
        
    methods (Static)
        
        % externally defined static methods
        [cost, J, noiseVar] = RepPulseCostFunction(data, angle, numPulses);
        [amp, offsetPhase]  = analyzeRabiAmp(data);
        bestParam = analyzeSlopes(data, numPsQIds, paramRange);
        
        function UnitTest()
            % construct settings struct
            ExpParams = struct();
            ExpParams.Qubit = 'q1';
            ExpParams.DoMixerCal = 0;
            ExpParams.DoRabiAmp = 1;
            ExpParams.DoRamsey = 0;
            ExpParams.DoPi2Cal = 1;
            ExpParams.DoPiCal = 1;
            ExpParams.DoDRAGCal = 0;
            ExpParams.OffsetNorm = 1;
            ExpParams.offset2amp = 1/2;
            ExpParams.dataType = 'amp';
            ExpParams.SoftwareDevelopmentMode = 1;
            ExpParams.cfgFile = getpref('qlab', 'CurScripterFile');
            
            % create object instance
            pulseCal = PulseCalibration();
            
            %pulseCal.channelParams = struct('piAmp', 0.6, 'pi2Amp', 0.28, 'dragScaling', -0.5, 'ampFactor', 1, 'phaseSkew', 0, 'pulseType', 'drag',...
            %                        'i_offset', 0.110, 'q_offset', 0.138, 'SSBFreq', 0);
            %pulseCal.rabiAmpChannelSequence('q2', false);
            %pulseCal.Pi2CalChannelSequence('q2', 'Y', false);
            %pulseCal.PiCalChannelSequence('q2', 'X', false);
            
            % rabi Amp data
            %xpts = linspace(0, 1, 81);
            %piAmp = 0.6;
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
            
            pulseCal.Init(ExpParams);
            pulseCal.Do();
        end
    end
end
