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
        cfg_path;
        costFunctionGoal = -70;
        testMode = false
        optimMode = 'sweep' %optimize by naive sweeping ('sweep') or clever searching ('search')
    end
    
    methods
        % constructor
        function obj = MixerOptimizer(cfg_file_path)
            if ~exist('cfg_file_path', 'var')
                cfg_file_path = '../../cfg/optimize_mixer.cfg';
            end
            % call super class
            obj = obj@expManager.expBase('optimize_mixer', '', cfg_file_path, 1);
            obj.cfg_path = fileparts(cfg_file_path);
            
            % load config
            obj.parseExpcfgFile();
        end
        
        %% class methods
        function Init(obj)
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
            end
        end
        function Do(obj)
            switch obj.optimMode
                case 'sweep'
                    obj.setup_SSB_AWG(0,0);
%                     [i_offset, q_offset] = obj.optimize_mixer_offsets_bySweep();
                    i_offset = 0;
                    q_offset = 0;
                    T = obj.optimize_mixer_ampPhase_bySweep(i_offset, q_offset);
                case 'search'
                    [i_offset, q_offset] = obj.optimize_mixer_offsets_bySearch();
                    T = obj.optimize_mixer_ampPhase_bySearch(i_offset, q_offset);
                otherwise
                    error('Unknown optimMode');
            end

            % save transformation and offsets to file
            save([obj.cfg_path '/mixercal.mat'], 'i_offset', 'q_offset', 'T', '-v7.3');
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
                    awg_amp = obj.awg.(['chan_' num2str(awg_I_channel)]).Amplitude;
                    obj.awg.openConfig(awgfile);
                    obj.awg.(['chan_' num2str(awg_I_channel)]).offset = i_offset;
                    obj.awg.(['chan_' num2str(awg_Q_channel)]).offset = q_offset;
                    obj.awg.runMode = 'CONT';
                    obj.awg.(['chan_' num2str(awg_I_channel)]).Amplitude = awg_amp;
                    obj.awg.(['chan_' num2str(awg_Q_channel)]).Amplitude = awg_amp;
                    obj.awg.(['chan_' num2str(awg_I_channel)]).Skew = 0;
                    obj.awg.(['chan_' num2str(awg_Q_channel)]).Skew = 0;
                    obj.awg.(['chan_' num2str(awg_I_channel)]).Enabled = 1;
                    obj.awg.(['chan_' num2str(awg_Q_channel)]).Enabled = 1;
                case 'deviceDrivers.APS'
                    awg_amp = obj.awg.(['chan_' num2str(awg_I_channel)]).amplitude;
                    
                    samplingRate = 1.2e9;
                    waveform_length = 1200;
                    timeStep = 1/samplingRate;
                    tpts = timeStep*(0:(waveform_length-1));
                    % i waveform
                    iwf = obj.awg.(['chan_' num2str(awg_I_channel)]).waveform;
                    iwf.dataMode = iwf.REAL_DATA;
                    iwf.data = 0.5 * cos(2*pi*fssb.*tpts);
                    iwf.set_offset(i_offset);
                    obj.awg.loadWaveform(awg_I_channel-1, iwf.prep_vector());
                    obj.awg.setOffset(awg_I_channel, i_offset);
                    obj.awg.(['chan_' num2str(awg_I_channel)]).waveform = iwf;
                    % q waveform
                    qwf = obj.awg.(['chan_' num2str(awg_Q_channel)]).waveform;
                    qwf.dataMode = qwf.REAL_DATA;
                    qwf.data = -0.5 * sin(2*pi*fssb.*tpts);
                    qwf.set_offset(q_offset);
                    obj.awg.loadWaveform(awg_Q_channel-1, qwf.prep_vector());
                    obj.awg.setOffset(awg_Q_channel, q_offset);
                    obj.awg.(['chan_' num2str(awg_Q_channel)]).waveform = qwf;
                    
                    obj.awg.triggerSource = 'internal';
                    obj.awg.setLinkListMode(awg_I_channel-1, obj.awg.LL_DISABLE, obj.awg.LL_CONTINUOUS);
                    obj.awg.setLinkListMode(awg_Q_channel-1, obj.awg.LL_DISABLE, obj.awg.LL_CONTINUOUS);
                    obj.awg.(['chan_' num2str(awg_I_channel)]).enabled = 1;
                    obj.awg.(['chan_' num2str(awg_Q_channel)]).enabled = 1;
            end
            
        end
        
        
    end
end