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
        results = struct('iOffset',0, 'qOffset',0, 'ampFactor', 1, 'phaseSkew', 0)
        prompt %if 1, user input is required to accept the calibration result
    end
    
    methods
        % constructor
        function obj = MixerOptimizer()
        end
        
        %% class methods
        function Init(obj, cfgFile, chan, prompt, overrideSSBFreq)
            
            % pull in channel parameters from requested logical channel in the Qubit2ChannelMap
            %Quiet down warnings from '-''s in fieldnames
            warning('off', 'json:fieldNameConflict');
            channelLib = json.read(getpref('qlab','ChannelParamsFile'));
            warning('on', 'json:fieldNameConflict');
            assert(isfield(channelLib.channelDict, genvarname(chan)), 'Qubit %s not found in channel library', chan);
            obj.chan = chan;
            obj.channelParams = channelLib.channelDict.(genvarname(chan));
            
            % load any optimize mixer specific configurations
            settings = json.read(cfgFile);
            obj.expParams = settings.ExpParams;
            instrSettings = settings.InstrParams;
            
            % ignore SSBFreq value in cfgFile 
            % override with frequency lookup from logical channel
            if overrideSSBFreq
              obj.expParams.SSBFreq = MixerOptimizer.lookup_logical_channel_frequency(obj.channelParams, ...
                obj.expParams.SSBFreq);
            end
            
            %Get references to the AWG, uW source, and spectrum analyzer
            tmpStr = regexp(obj.channelParams.physChan, '-', 'split'); % split on '-'
            awgName = tmpStr{1};
            obj.awg = InstrumentFactory(awgName);
            % would like to use instrument library rather than
            % CurScripterFile, but the struct in the instrument library is
            % not compatible with awg.setAll()
            instrLib = json.read(getpref('qlab', 'CurScripterFile'));
            obj.awg.setAll(instrLib.instruments.(awgName));
            
            %pass physChan through genvarname to get a MATLAB compatible name
            mangledPhysChan = genvarname(obj.channelParams.physChan);
            sourceName = channelLib.channelDict.(mangledPhysChan).generator;
            obj.uwsource = InstrumentFactory(sourceName);
            obj.uwsource.setAll(instrLib.instruments.(sourceName)); %catch any frequency updates from GUI
            obj.sa = InstrumentFactory(obj.expParams.specAnalyzer);
            
            obj.sa.setAll(instrSettings.(obj.expParams.specAnalyzer));
            obj.sa.centerFreq = obj.uwsource.frequency;
            
            %Turn the uwave source on and turn modulation off
            obj.uwsource.mod = 0;
            obj.uwsource.pulse = 0;
            obj.uwsource.output = 1;
            
            obj.prompt = prompt;
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
                    [obj.results.ampFactor, obj.results.phaseSkew] = obj.optimize_mixer_ampPhase_bySweep();
                case 'search'
                    obj.setup_SSB_AWG(0,0);
                    [obj.results.iOffset, obj.results.qOffset] = obj.optimize_mixer_offsets_bySearch();
                    obj.setup_SSB_AWG(obj.results.iOffset, obj.results.qOffset);
                    [obj.results.ampFactor, obj.results.phaseSkew] = obj.optimize_mixer_ampPhase_bySearch();
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
            obj.sa.span = obj.expParams.SSBFreq * 2.2;
            obj.sa.sweep_mode = 'cont';
            obj.sa.resolution_bw = 'auto';
            obj.sa.sweep_points = 800;
            obj.sa.number_averages = 10;
            obj.sa.video_averaging = 1;
            obj.sa.sweep();
            obj.sa.peakAmplitude();
            
            if obj.prompt
            %Ask whether to write to file or not
                happy = questdlg('Are you happy with the result?','Optimize Mixer Wrap-up');
            else
                happy = 'Yes';
            end
                
            switch happy
                case 'Yes'
            
                % update transformation matrix params in channel library
                updateAmpPhase(obj.channelParams.physChan, obj.results.ampFactor, obj.results.phaseSkew);

                % update i and q offsets in the instrument library
                
                instrLib = json.read(getpref('qlab', 'InstrumentLibraryFile'));
                tmpStr = regexp(obj.channelParams.physChan, '-', 'split');
                awgName = tmpStr{1};
                iChan = str2double(obj.channelParams.physChan(end-1));
                qChan = str2double(obj.channelParams.physChan(end));
                instrLib.instrDict.(awgName).channels(iChan).offset = round(1e4*obj.results.iOffset)/1e4;
                instrLib.instrDict.(awgName).channels(qChan).offset = round(1e4*obj.results.qOffset)/1e4;
                json.write(instrLib, getpref('qlab', 'InstrumentLibraryFile'), 'indent', 2);
                
                case {'No','Cancel'}
                    fprintf('Not writing to file...');
            end
            
            %Stop the AWG
            obj.awg.stop()
                    
            %Print out a summary for the notebook
            fprintf('\nSummary:\n');
            fprintf('i_offset = %.4f; q_offset = %.4f; ampFactor = %.4f; phaseSkew = %.1f\n', ...
                obj.results.iOffset, obj.results.qOffset, obj.results.ampFactor, obj.results.phaseSkew)
            
        end
        
        
        function setup_SSB_AWG(obj, i_offset, q_offset)
            %Helper function to setup the SSB waveforms from the AWGs
            awgfile = obj.expParams.SSBAWGFile;
            iChan = str2double(obj.channelParams.physChan(end-1));
            qChan = str2double(obj.channelParams.physChan(end));
            switch class(obj.awg)
                case 'deviceDrivers.Tek5014'
                    %Here we just preload a custom special AWG file
                    awg_amp = obj.awg.getAmplitude(iChan);
                    obj.awg.loadConfig(awgfile);
                    obj.awg.runMode = 'CONT';
                    obj.awg.setAmplitude(iChan, awg_amp);
                    obj.awg.setOffset(iChan, i_offset);
                    obj.awg.setSkew(iChan, 0);
                    obj.awg.setEnabled(iChan, 1);
                    
                    obj.awg.setAmplitude(qChan, awg_amp);
                    obj.awg.setOffset(qChan, q_offset);
                    obj.awg.setSkew(qChan, 0);
                    obj.awg.setEnabled(qChan, 1);
                    obj.awg.run();
                    
                case {'deviceDrivers.APS', 'APS'}
                    %Here we use waveform mode to put out a continuous
                    %sine wave
                    obj.awg.stop();
                    awg_amp = obj.awg.getAmplitude(iChan);
                    %Setup a SSB waveform with a 1200 pt sinusoid for both
                    %channels
                    waveformLength = 1200;
                    tpts = (1/obj.awg.samplingRate)*(0:(waveformLength-1));
                    
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
                    %conflict between the two FPGAs
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
                case 'APS2'
                    obj.awg.stop();
                    awg_amp = obj.awg.get_channel_scale(iChan);
                    
                    %Setup a SSB waveform with a 1200 pt sinusoid for both
                    %channels
                    waveformLength = 1200;
                    tpts = (1/obj.awg.samplingRate)*(0:(waveformLength-1));
                    
                    % i waveform
                    iwf = 0.5 * cos(2*pi*obj.expParams.SSBFreq*tpts);
                    obj.awg.set_channel_scale(iChan, awg_amp);
                    obj.awg.set_channel_offset(iChan, i_offset);
                    % waveforms in the range (-1, 1)
                    obj.awg.load_waveform(iChan, iwf);
                    
                    % q waveform
                    qwf = -0.5 * sin(2*pi*obj.expParams.SSBFreq*tpts);
                    obj.awg.set_channel_scale(qChan, awg_amp);
                    obj.awg.set_channel_offset(qChan, q_offset);
                    obj.awg.load_waveform(qChan, qwf);
                    
                    obj.awg.set_trigger_source('internal');
                    obj.awg.set_run_mode('CW_WAVEFORM');
                    
                    for ct = 1:2
                        obj.awg.set_channel_enabled(ct, true);
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
        
        
        function frequency = lookup_logical_channel_frequency(channel, defaultFrequency)
          % look up logical channel frequency information for optimizing
          % the mixer
          frequency = defaultFrequency;
          switch channel.x__class__
            case 'Qubit'
              frequency = channel.frequency; 
            case 'Measurement'
              if strcmp(channel.measType,'autodyne')
                frequency = channel.autodyneFreq;
              end
          end
        end
    end
end