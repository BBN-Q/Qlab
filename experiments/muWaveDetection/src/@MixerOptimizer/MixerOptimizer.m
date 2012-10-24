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
%
% File: MixerOptimizer.m
%
% Author: Blake Johnson, BBN Technologies
% Updated: Colm Ryan and Blake Johnson to handle sweeping and searching
% optimization
%
% Description: Corrects for carrier leakage, amplitude imbalance, and phase
% skew of an I/Q mixer.
%

classdef MixerOptimizer < expManager.expBase
    properties
        % instruments
        sa % spectrum analyzer
        specgen % the LO source of the mixer to calibrate
        awg % the AWG driving the I/Q ports of the mixer
        channelParams
        qubit
        costFunctionGoal = -70;
        testMode = false
        optimMode = 'sweep' %optimize by naive sweeping ('sweep') or clever searching ('search')
    end
    
    methods
        % constructor
        function obj = MixerOptimizer(cfg_file_path, qubit)
            if ~exist('cfg_file_path', 'var')
                cfg_file_path = fullfile(getpref('qlab', 'cfgDir'),'optimize_mixer.json');
            end
            % call super class
            obj = obj@expManager.expBase('optimize_mixer', '', cfg_file_path, 1);
            obj.qubit = qubit;
        end
        
        %% class methods
        function Init(obj)
            % load config
            obj.parseExpcfgFile();
            timeDomainCfg = jsonlab.loadjson(fullfile(getpref('qlab', 'cfgDir'),'TimeDomain.json'));
            
            % pull in more configuration data from TimeDomain.json based
            % upon the requested logical channel in the Qubit2ChannelMap
            channelMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));
            assert(isfield(channelMap, obj.qubit), 'Qubit %s not found in channel map', obj.qubit);
            obj.channelParams = channelMap.(obj.qubit);
            % grab the AWG
            obj.inputStructure.InstrParams.AWG = timeDomainCfg.InstrParams.(obj.channelParams.awg);
            % grab the uW source
            obj.inputStructure.InstrParams.Specgen = timeDomainCfg.InstrParams.(obj.channelParams.source);
            % grab AWG channels for mixer I and Q
            obj.inputStructure.ExpParams.Mixer.I_channel = obj.channelParams.i;
            obj.inputStructure.ExpParams.Mixer.Q_channel = obj.channelParams.q;
            
            obj.errorCheckExpParams();
            obj.openInstruments();
            obj.initializeInstruments();
            
            if isfield(obj.inputStructure, 'SoftwareDevelopmentMode') && obj.inputStructure.SoftwareDevelopmentMode
                obj.testMode = true;
            end
            
            if ~obj.testMode
                obj.sa = obj.Instr.spectrum_analyzer;
                obj.specgen = obj.Instr.Specgen;
                obj.awg = obj.Instr.AWG;
                
                % turn modulation off on Specgen
                obj.specgen.mod = 0;
                obj.specgen.pulse = 0;
            end
        end
        function Do(obj)
            switch obj.optimMode
                case 'sweep'
                    obj.setup_SSB_AWG(0,0);
                     [i_offset, q_offset] = obj.optimize_mixer_offsets_bySweep();
                     obj.setup_SSB_AWG(i_offset,q_offset);
                     T = obj.optimize_mixer_ampPhase_bySweep(i_offset, q_offset);
                case 'search'
                    [i_offset, q_offset] = obj.optimize_mixer_offsets_bySearch();
                    T = obj.optimize_mixer_ampPhase_bySearch(i_offset, q_offset);
                otherwise
                    error('Unknown optimMode');
            end

            % restore instruments to a normal state
            obj.sa.center_frequency = obj.specgen.frequency * 1e9;
            obj.sa.span = 25e6;
            obj.sa.sweep_mode = 'cont';
            obj.sa.resolution_bw = 'auto';
            obj.sa.sweep_points = 800;
            obj.sa.number_averages = 10;
            obj.sa.video_averaging = 1;
            obj.sa.sweep();
            obj.sa.peakAmplitude();

            % update transformation matrix T in pulse param file
            params = jsonlab.loadjson(getpref('qlab', 'pulseParamsBundleFile'));
            params.(obj.channelParams.IQkey).T = T;
            FID = fopen(getpref('qlab', 'pulseParamsBundleFile'),'w'); 
            fprintf(FID, '%s', jsonlab.savejson('',params));
            fclose(FID);
            
            % update i and q offsets in TimeDomain
            params = jsonlab.loadjson(fullfile(getpref('qlab', 'cfgDir'), 'TimeDomain.json'));
            params.InstrParams.(obj.channelParams.awg).(sprintf('chan_%d', obj.channelParams.i)).offset = i_offset;
            params.InstrParams.(obj.channelParams.awg).(sprintf('chan_%d', obj.channelParams.q)).offset = q_offset;
            FID = fopen(fullfile(getpref('qlab', 'cfgDir'), 'TimeDomain.json'),'wt'); %open in text mode
            fprintf(FID, '%s', jsonlab.savejson('',params));
            fclose(FID);
            
            %Print out a summary for the notebook
            fprintf('\nSummary:\n');
            fprintf('i_offset = %.4f; q_offset = %.4f; ampFactor = %.4f; phaseSkew = %.1f\n', i_offset, q_offset, T(1,1), atand(T(1,2)/T(1,1)))
        end
        function CleanUp(obj)
            %Close all instruments
            obj.closeInstruments();
        end
        
        function errorCheckExpParams(obj)
            ExpParams = obj.inputStructure.ExpParams;
            if ~isfield(ExpParams, 'SpecAnalyzer')
                error('Must provide ExpParams.SpecAnalyzer struct');
            end
            if ~isfield(ExpParams, 'Mixer')
                error('Must provide ExpParams.Mixer struct');
            end
            if ~isfield(ExpParams, 'SSBFreq')
                error('Must specify ExpParams.SSBFreq');
            end
        end
        
        function Run(obj)
            obj.Init();
            obj.Do();
            obj.CleanUp();
        end
        
        function stop = LMStoppingCondition(obj, x, optimValues, state)
            if 10*log10(optimValues.resnorm) < obj.costFunctionGoal
                stop = true;
            else
                stop = false;
            end
        end
        
        function setup_SSB_AWG(obj, i_offset, q_offset)
            %Setup the SSB waveforms from the AWGs
            ExpParams = obj.inputStructure.ExpParams;
            awg_I_channel = ExpParams.Mixer.I_channel;
            awg_Q_channel = ExpParams.Mixer.Q_channel;
            fssb = ExpParams.SSBFreq; % SSB modulation frequency (usually 10 MHz)
            awgfile = ExpParams.SSBAWGFile;
            
            switch class(obj.awg)
                case 'deviceDrivers.Tek5014'
                    awg_amp = obj.awg.(['chan_' num2str(awg_I_channel)]).amplitude;
                    obj.awg.openConfig(awgfile);
                    obj.awg.(['chan_' num2str(awg_I_channel)]).offset = i_offset;
                    obj.awg.(['chan_' num2str(awg_Q_channel)]).offset = q_offset;
                    obj.awg.runMode = 'CONT';
                    obj.awg.(['chan_' num2str(awg_I_channel)]).amplitude = awg_amp;
                    obj.awg.(['chan_' num2str(awg_Q_channel)]).amplitude = awg_amp;
                    obj.awg.(['chan_' num2str(awg_I_channel)]).skew = 0;
                    obj.awg.(['chan_' num2str(awg_Q_channel)]).skew = 0;
                    obj.awg.(['chan_' num2str(awg_I_channel)]).enabled = 1;
                    obj.awg.(['chan_' num2str(awg_Q_channel)]).enabled = 1;
                    
                    obj.awg.run();
                    obj.awg.operationComplete();
                case 'deviceDrivers.APS'

                    obj.awg.stop();
                    %Setup a SSB waveform with a 1200 pt sinusoid for both
                    %channels
                    samplingRate = 1.2e9;
                    waveformLength = 1200;
                    timeStep = 1/samplingRate;
                    tpts = timeStep*(0:(waveformLength-1));
                    
                    % i waveform
                    iwf = 0.5 * cos(2*pi*fssb.*tpts);
                    obj.awg.setOffset(awg_I_channel, i_offset);
                    % TODO: update APS driver to accept normalized
                    % waveforms in the range (-1, 1)
                    obj.awg.loadWaveform(awg_I_channel, iwf);
 
                    % q waveform
                    qwf = -0.5 * sin(2*pi*fssb.*tpts);
                    obj.awg.setOffset(awg_Q_channel, q_offset);
                    % same TODO item here as above
                    obj.awg.loadWaveform(awg_Q_channel, qwf);
                    
                    obj.awg.triggerSource = 'internal';
                    
                    %Set all channels to continuous waveform to avoid a
                    %conflict betweent the two FPGAs
                    for ct = 1:4
                       obj.awg.setRepeatMode(ct, obj.awg.CONTINUOUS);
                       obj.awg.setRunMode(ct, obj.awg.RUN_WAVEFORM);
                    end
                    
                    unusedChannels = setdiff(1:4, [awg_I_channel, awg_Q_channel]);
                    obj.awg.setEnabled(unusedChannels(1), 0);
                    obj.awg.setEnabled(unusedChannels(2), 0);
                    
                    obj.awg.run();
            end
            
        end
        
        
    end
    
    methods(Static)
       [bestOffset, goodOffsetPts, measPowers] = find_null_offset(measPowers, xPts)
    end
end