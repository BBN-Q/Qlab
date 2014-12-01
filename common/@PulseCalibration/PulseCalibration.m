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
        numShots % also participates in noise variance estimate
        finished = false
        initialParams
    end
    methods
        % Class constructor
        function obj = PulseCalibration()
        end

        function out = take_data(obj, segmentPoints)
            % runs the pulse sequence and returns the data
            
            % set number of segments in the sweep
            obj.experiment.sweeps{1}.points = segmentPoints;

            % set digitizer with the appropriate number of segments
            switch class(obj.experiment.scopes{1})
                case 'deviceDrivers.AlazarATS9870'
                    averagerSettings = obj.experiment.scopes{1}.averager;
                    averagerSettings.nbrSegments = length(segmentPoints);
                    obj.experiment.scopes{1}.averager = averagerSettings;
                case 'X6'
                    x6 = obj.experiment.scopes{1};
                    set_averager_settings(x6, x6.recordLength, length(segmentPoints), x6.nbrWaveforms, x6.nbrRoundRobins);
                otherwise
                    error('Unknown scope type.');
            end
            
            obj.experiment.run();
            
            % pull out data from the specified
            data = obj.experiment.data.(obj.settings.measurement).mean;
            
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

            warning('off', 'json:fieldNameConflict');
            channelLib = json.read(getpref('qlab','ChannelParamsFile'));
            warning('on', 'json:fieldNameConflict');
            channelLib = channelLib.channelDict;
            assert(isfield(channelLib, settings.Qubit), 'Qubit %s not found in channel library', settings.Qubit);
            obj.channelParams = channelLib.(settings.Qubit).pulseParams;
            
            if isfield(obj.settings, 'SoftwareDevelopmentMode') && obj.settings.SoftwareDevelopmentMode
                obj.testMode = true;
            end
            
            % create an ExpManager object
            obj.experiment = ExpManager();
            
            % load ExpManager settings
            expSettings = json.read(obj.settings.cfgFile);
            instrSettings = expSettings.instruments;
            instrNames = fieldnames(instrSettings);
            ct = 0;
            while (true)
                ct = ct+1;
                if strcmp(instrSettings.(instrNames{ct}).deviceName, 'AlazarATS9870') || strcmp(instrSettings.(instrNames{ct}).deviceName, 'X6')
                    obj.numShots = instrSettings.(instrNames{ct}).averager.nbrRoundRobins * instrSettings.(instrNames{ct}).averager.nbrWaveforms;
                    break;
                end
            end
            
            % add instruments
            for instrument = fieldnames(instrSettings)'
                instr = InstrumentFactory(instrument{1});
                add_instrument(obj.experiment, instrument{1}, instr, instrSettings.(instrument{1}));
            end
            
            % create a generic SegmentNum sweep
            add_sweep(obj.experiment, 1, sweeps.SegmentNum(struct('axisLabel', 'Segment', 'start', 0, 'step', 1, 'numPoints', 2)));
            
            % add the appropriate measurement stack
            measSettings = expSettings.measurements.(obj.settings.measurement);
            curSource = obj.settings.measurement;
            curFilter = MeasFilters.(measSettings.filterType)(measSettings);
            while (true)
               add_measurement(obj.experiment, curSource, curFilter);
               if isa(curFilter, 'MeasFilters.RawStream') || isa(curFilter, 'MeasFilters.StreamSelector')
                   break;
               end
               sourceParams = expSettings.measurements.(curSource);
               curFilter = MeasFilters.(sourceParams.filterType)(sourceParams);
               curSource = sourceParams.dataSource;
            end

            % intialize the ExpManager
            init(obj.experiment);
            
            obj.AWGs = struct_filter(@(x) ExpManager.is_AWG(x), obj.experiment.instruments);
            obj.AWGSettings = cellfun(@(awg) obj.experiment.instrSettings.(awg), fieldnames(obj.AWGs)', 'UniformOutput', false);
            obj.AWGSettings = cell2struct(obj.AWGSettings, fieldnames(obj.AWGs)', 2);

            tmpStr = regexp(channelLib.(settings.Qubit).physChan, '-', 'split');
            obj.controlAWG = tmpStr{1};
            obj.channelParams.physChan = channelLib.(settings.Qubit).physChan;

            if ~obj.testMode
                % pull in physical channel parameters into channelParams
                % Note: need to use genvarname to match the field name in
                % the JSON struct
                physChan = genvarname(channelLib.(settings.Qubit).physChan);
                obj.channelParams.ampFactor = channelLib.(physChan).ampFactor;
                obj.channelParams.phaseSkew = channelLib.(physChan).phaseSkew;
                controlAWGsettings = obj.AWGSettings.(obj.controlAWG);
                obj.channelParams.i_offset = controlAWGsettings.(['chan_' physChan(end-1)]).offset;
                obj.channelParams.q_offset = controlAWGsettings.(['chan_' physChan(end)]).offset;
                obj.channelParams.SSBFreq = channelLib.(physChan).SSBFreq;
            else
                % setup parameters compatible with unit test
                obj.channelParams.piAmp = 0.65;
                obj.channelParams.pi2Amp = 0.32;
                obj.channelParams.dragScaling = -0.50;
                obj.channelParams.ampFactor = 1;
                obj.channelParams.phaseSkew = 0;
                obj.channelParams.i_offset = 0.074;
                obj.channelParams.q_offset = 0.083;
                obj.channelParams.SSBFreq = 0;
            end
            % save a copy of the parameters to restore later if something
            % goes wrong
            obj.initialParams = obj.channelParams;
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
            % restore pulse parameters if we didn't make it to the end
            if ~obj.finished
                updateAmpPhase(obj.channelParams.physChan, obj.initialParams.ampFactor, obj.initialParams.phaseSkew);
                updateQubitPulseParams(obj.settings.Qubit, obj.initialParams);
                
                instrLib = json.read(getpref('qlab', 'InstrumentLibraryFile'));
                tmpStr = regexp(obj.channelParams.physChan, '-', 'split');
                awgName = tmpStr{1};
                iChan = str2double(obj.channelParams.physChan(end-1));
                qChan = str2double(obj.channelParams.physChan(end));
                instrLib.instrDict.(awgName).channels(iChan).offset = round(1e4*obj.initialParams.i_offset)/1e4;
                instrLib.instrDict.(awgName).channels(qChan).offset = round(1e4*obj.initialParams.q_offset)/1e4;
                json.write(instrLib, getpref('qlab', 'InstrumentLibraryFile'), 'indent', 2);
            end
        end
    end
        
    methods (Static)
        
        % externally defined static methods
        [cost, J, noiseVar] = RepPulseCostFunction(data, angle, numPulses);
        [amp, offsetPhase]  = analyzeRabiAmp(data);
        bestParam = analyzeSlopes(data, numPsQIds, paramRange, numShots);
        
        function UnitTest()
            % construct settings struct
            ExpParams = struct();
            ExpParams.Qubit = 'q1';
            ExpParams.measurement = 'M1';
            ExpParams.DoMixerCal = 0;
            ExpParams.DoRabiAmp = 0;
            ExpParams.DoRamsey = 0;
            ExpParams.NumPi2s = 9;
            ExpParams.DoPi2Cal = 1;
            ExpParams.NumPis = 9;
            ExpParams.DoPiCal = 1;
            ExpParams.DoDRAGCal = 0;
            ExpParams.DoSPAMCal = 0;
            ExpParams.OffsetNorm = 2;
            ExpParams.offset2amp = 1;
            ExpParams.dataType = 'real';
            ExpParams.SoftwareDevelopmentMode = 1;
            ExpParams.cfgFile = getpref('qlab', 'CurScripterFile');
            
            % create object instance
            pulseCal = PulseCalibration();
            
            %pulseCal.channelParams = struct('piAmp', 0.6, 'pi2Amp', 0.28, 'dragScaling', -0.5, 'ampFactor', 1, 'phaseSkew', 0, 'shapeFun', 'drag',...
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
