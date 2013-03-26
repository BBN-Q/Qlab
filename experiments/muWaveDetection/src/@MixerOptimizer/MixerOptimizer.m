% Corrects for carrier leakage, amplitude imbalance, and phase
% skew of an I/Q mixer.
%

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
%
% Author: Blake Johnson, BBN Technologies
% Updated: Colm Ryan and Blake Johnson to handle sweeping and searching
% optimization
%
%

classdef MixerOptimizer < handle
    properties
        % instruments
        sa % spectrum analyzer
        uwsource % the LO source of the mixer to calibrate
        awg % the AWG driving the I/Q ports of the mixer
        awgAmp % amplitude of I/Q ports coming from the AWG
        chan % the logical channel we are optimizing
        channelParams %the Qubit2Channel params associated with logical channel
        costFunctionGoal = -70;
        expParams
        optimMode = 'sweep' %optimize by naive sweeping ('sweep') or clever searching ('search')
        results = struct('iOffset',0, 'qOffset',0, 'T', eye(2))
    end
    
    methods
        % constructor
        function obj = MixerOptimizer()
        end
        
        %% class methods
        function Init(obj, cfgFile, chan)
            
            % pull in channel parameters from requested logical channel in the Qubit2ChannelMap
            channelMap = jsonlab.loadjson(getpref('qlab','Qubit2ChannelMap'));
            assert(isfield(channelMap, chan), 'Qubit %s not found in channel map', chan);
            obj.chan = chan;
            obj.channelParams = channelMap.(obj.chan);
            
            % load any optimize mixer specific configurations
            settings = jsonlab.loadjson(cfgFile);
            obj.expParams = settings.ExpParams;
            instrSettings = settings.InstrParams;
            
            %Get references to the AWG, uW source, and spectrum analyzer
            obj.awg = InstrumentFactory(obj.channelParams.awg);
            %TODO: Update this to the instrument library instead.
            instrLibParams = jsonlab.loadjson(fullfile(getpref('qlab', 'cfgDir'), 'scripter.json'));
            obj.awg.setAll(instrLibParams.instruments.(obj.channelParams.awg));
            obj.uwsource = InstrumentFactory(obj.channelParams.source);
            obj.sa = InstrumentFactory(obj.expParams.specAnalyzer);
            
            obj.sa.setAll(instrSettings.(obj.expParams.specAnalyzer));
            obj.sa.centerFreq = obj.uwsource.frequency;
            
            %Turn the uwave source on and turn modulation off
            obj.uwsource.mod = 0;
            obj.uwsource.pulse = 0;
            obj.uwsource.output = 1;
        end
        
        function Do(obj)
            
            %Set the cleanup function so that even if we ctrl-c out we
            %correctly cleanup
            c = onCleanup(@() obj.cleanUp());
            
            switch obj.optimMode
                case 'sweep'
                    obj.setup_SSB_AWG(0,0);
                    [obj.results.iOffset, obj.results.qOffset] = obj.optimize_mixer_offsets_bySweep();
                    obj.setup_SSB_AWG(obj.results.iOffset,obj.results.qOffset);
                    obj.results.T = obj.optimize_mixer_ampPhase_bySweep();
                case 'search'
                    obj.setup_SSB_AWG(0,0);
                    [obj.results.iOffset, obj.results.qOffset] = obj.optimize_mixer_offsets_bySearch();
                    obj.setup_SSB_AWG(obj.results.iOffset, obj.results.qOffset);
                    obj.results.T = obj.optimize_mixer_ampPhase_bySearch();
                otherwise
                    error('Unknown optimMode');
            end
            
            
        end
        
        function stop = LMStoppingCondition(obj, ~, optimValues, ~)
            if 10*log10(optimValues.resnorm) < obj.costFunctionGoal
                stop = true;
            else
                stop = false;
            end
        end
        
        function cleanUp(obj)
            
            % restore instruments to a normal state
            obj.sa.centerFreq = obj.uwsource.frequency;
            obj.sa.span = obj.expParams.SSBFreq * 2.1;
            obj.sa.sweep_mode = 'cont';
            obj.sa.resolution_bw = 'auto';
            obj.sa.sweep_points = 800;
            obj.sa.number_averages = 10;
            obj.sa.video_averaging = 1;
            obj.sa.sweep();
            obj.sa.peakAmplitude();
            
            %Ask whether to write to file or not
            happy = questdlg('Are you happy with the result?','Optimize Mixer Wrap-up');
            switch happy
                case 'Yes'
            
                % update transformation matrix T in pulse param file
                params = jsonlab.loadjson(getpref('qlab', 'pulseParamsBundleFile'));
                params.(obj.channelParams.IQkey).T = obj.results.T;
                FID = fopen(getpref('qlab', 'pulseParamsBundleFile'),'w');
                fprintf(FID, '%s', jsonlab.savejson('',params));
                fclose(FID);

                % update i and q offsets in ExpScripter cfg
                %TODO: Update this to the instrument library instead.
                params = jsonlab.loadjson(fullfile(getpref('qlab', 'cfgDir'), 'scripter.json'));
                iChan = obj.channelParams.IQkey(end-1);
                qChan = obj.channelParams.IQkey(end);
                params.instruments.(obj.channelParams.awg).(['chan_' iChan]).offset = obj.results.iOffset;
                params.instruments.(obj.channelParams.awg).(['chan_' qChan]).offset = obj.results.qOffset;
                FID = fopen(fullfile(getpref('qlab', 'cfgDir'), 'scripter.json'),'wt'); %open in text mode
                fprintf(FID, '%s', jsonlab.savejson('',params));
                fclose(FID);
                
                case {'No','Cancel'}
                    fprintf('Not writing to file...');
            end
            
            %Stop the AWG
            obj.awg.stop()
                    
            %Print out a summary for the notebook
            fprintf('\nSummary:\n');
            fprintf('i_offset = %.4f; q_offset = %.4f; ampFactor = %.4f; phaseSkew = %.1f\n', ...
                obj.results.iOffset, obj.results.qOffset, obj.results.T(1,1), atand(obj.results.T(1,2)/obj.results.T(1,1)))
            
        end
        
        
        function setup_SSB_AWG(obj, i_offset, q_offset)
            %Helper function to setup the SSB waveforms from the AWGs
            awgfile = obj.expParams.SSBAWGFile;
            iChan = obj.channelParams.IQkey(end-1);
            qChan = obj.channelParams.IQkey(end);
            
            switch class(obj.awg)
                case 'deviceDrivers.Tek5014'
                    %Here we just preload a custom special AWG file
                    awg_amp = obj.awg.(['chan_' iChan]).amplitude;
                    obj.awg.openConfig(awgfile);
                    obj.awg.(['chan_' iChan]).offset = i_offset;
                    obj.awg.(['chan_' qChan]).offset = q_offset;
                    obj.awg.runMode = 'CONT';
                    obj.awg.(['chan_' iChan]).amplitude = awg_amp;
                    obj.awg.(['chan_' qChan]).amplitude = awg_amp;
                    obj.awg.(['chan_' iChan]).skew = 0;
                    obj.awg.(['chan_' qChan]).skew = 0;
                    obj.awg.(['chan_' iChan]).enabled = 1;
                    obj.awg.(['chan_' qChan]).enabled = 1;
                    obj.awg.run();
                    
                case 'deviceDrivers.APS'
                    % convert iChan and qChan
                    iChan = str2double(iChan);
                    qChan = str2double(qChan);
                    
                    awg_amp = obj.awg.getAmplitude(iChan);
                    %Here we use waveform mode to put out a continuous
                    %sine wave
                    obj.awg.stop();
                    %Setup a SSB waveform with a 1200 pt sinusoid for both
                    %channels
                    waveformLength = 1200;
                    % APS returns sampling rate in MHz, so convert to Hz
                    tpts = (1e-6/obj.awg.samplingRate)*(0:(waveformLength-1));
                    
                    % i waveform
                    iwf = 0.5 * cos(2*pi*obj.expParams.SSBFreq*tpts);
                    obj.awg.setAmplitude(iChan, awg_amp);
                    obj.awg.setOffset(iChan, i_offset);
                    % waveforms in the range (-1, 1)
                    obj.awg.loadWaveform(iChan, iwf);
                    
                    % q waveform
                    qwf = -0.5 * sin(2*pi*obj.expParams.SSBFreq*tpts);
                    obj.awg.setAmplitude(qChan, awg_amp);
                    obj.awg.setOffset(qChan, q_offset);
                    obj.awg.loadWaveform(qChan, qwf);
                    
                    obj.awg.triggerSource = 'internal';
                    
                    %Set all channels to continuous waveform to avoid a
                    %conflict betweent the two FPGAs
                    for ct = 1:4
                        obj.awg.setRepeatMode(ct, obj.awg.CONTINUOUS);
                        obj.awg.setRunMode(ct, obj.awg.RUN_WAVEFORM);
                    end
                    
                    %Turn off the unused channels
                    channelsOn = false(1,4);
                    channelsOn([iChan, qChan]) = true;
                    for ct = 1:4
                        obj.awg.setEnabled(ct, channelsOn(ct));
                    end
                    
                    %Get the AWG going
                    obj.awg.run();
            end
            obj.awgAmp = awg_amp;
        end
        
        
    end
    
    methods(Static)
        %Forward reference a static helper that fits the typical sweep
        %curves
        [bestOffset, goodOffsetPts, measPowers] = find_null_offset(measPowers, xPts)
    end
end