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
% File: optimize_mixer_ampPhase.m
%
% Description: Searches for optimal amplitude and phase correction on an
% I/Q mixer.

function T = optimize_mixer_ampPhase(obj, i_offset, q_offset)
    % unpack constants from cfg file
    ExpParams = obj.inputStructure.ExpParams;
    spec_analyzer_span = ExpParams.SpecAnalyzer.span;
    spec_resolution_bw = ExpParams.SpecAnalyzer.resolution_bw;
    spec_sweep_points = ExpParams.SpecAnalyzer.sweep_points;
    awg_I_channel = ExpParams.Mixer.I_channel;
    awg_Q_channel = ExpParams.Mixer.Q_channel;
    search_iterations = 2;
    fssb = 10e6; % SSB modulation frequency

    simul_amp = 1.0;
    simul_phase = 0.0;

    verbose = obj.inputStructure.verbose;
    simulate = obj.inputStructure.SoftwareDevelopmentMode;
    
    % initialize instruments
    if ~simulate
        % grab instrument objects
        sa = obj.sa;
        awg = obj.awg;
        
        awg_amp = awg.(['chan_' num2str(awg_I_channel)]).Amplitude;

        sa.center_frequency = obj.specgen.frequency * 1e9 + fssb;
        sa.span = spec_analyzer_span;
        sa.sweep_mode = 'single';
        sa.resolution_bw = spec_resolution_bw;
        sa.sweep_points = spec_sweep_points;
        sa.video_averaging = 0;
        sa.sweep();
        sa.peakAmplitude();

        awgfile = 'U:\AWG\MixerCal\MixerCal.awg';
        awg.openConfig(awgfile);
        awg.runMode = 'CONT';
        awg.(['chan_' num2str(awg_I_channel)]).Amplitude = awg_amp;
        awg.(['chan_' num2str(awg_I_channel)]).offset = i_offset;
        awg.(['chan_' num2str(awg_Q_channel)]).Amplitude = awg_amp;
        awg.(['chan_' num2str(awg_Q_channel)]).offset = q_offset;
        awg.(['chan_' num2str(awg_I_channel)]).Skew = 0.0;
        awg.(['chan_' num2str(awg_Q_channel)]).Skew = 0.0;
        awg.(['chan_' num2str(awg_I_channel)]).Enabled = 1;
        awg.(['chan_' num2str(awg_Q_channel)]).Enabled = 1;
        awg.run();
        awg.waitForAWGtoStartRunning();
    end
    
    % search for best I and Q values to minimize the peak amplitude
    for i = 1:search_iterations
        fprintf('Iteration %d\n', i);
        ampFactor = optimizeAmp()/awg_amp;
        skew = optimizePhase(); % in ns
    end
    
    % convert skew to radians
    skew = -skew * fssb/1e9 * 2*pi;
    fprintf('a: %.3g, skew: %.3g degrees\n', [ampFactor, skew*180/pi]);
    
    % correction transformation
    T = [ampFactor -tan(skew); 0 sec(skew)];
    
    % restore instruments to a normal state
    if ~simulate
        sa.center_frequency = obj.specgen.frequency * 1e9;
        sa.span = 25e6;
        sa.sweep_mode = 'cont';
        sa.resolution_bw = 'auto';
        sa.sweep_points = 800;
        sa.video_averaging = 1;
        sa.sweep();
        sa.peakAmplitude();
        
        %awg.openConfig(awgfile);
        %awg.runMode = 'CONT';
        awg.(['chan_' num2str(awg_I_channel)]).Amplitude = awg_amp;
        awg.(['chan_' num2str(awg_I_channel)]).offset = i_offset;
        awg.(['chan_' num2str(awg_Q_channel)]).Amplitude = awg_amp;
        awg.(['chan_' num2str(awg_Q_channel)]).offset = q_offset;
        awg.(['chan_' num2str(awg_I_channel)]).Skew = 0.0;
        awg.(['chan_' num2str(awg_Q_channel)]).Skew = 0.0;
        %awg.run();
    end
    
    % local functions
    
    %% Modify amplitude imbalance factor in transformation matrix to minimize
     % amplitude in the undesired sideband.
    %%
    function a = optimizeAmp()
        [a, minPower, success] = fminbnd(@amplitude_objective_fcn, 0.9*awg_amp, 1.1*awg_amp,...
            optimset('TolX', 0.001));
        if ~success
            error('optimizeAmp() did not converge.');
        end
        fprintf('Amplitude scale: %.3f, Power: %.1f dBm\n', [a, minPower]);
    end

    function out = amplitude_objective_fcn(amp)
        awg.(['chan_' num2str(awg_I_channel)]).Amplitude = amp;
        pause(0.01);
        out = readPower();
    end

    function skew = optimizePhase()
        [skew, minPower, success] = fminbnd(@phase_objective_fcn, -2, 2,...
            optimset('TolX', 0.005));
        if ~success
            error('optimizePhase() did not converge.');
        end
        fprintf('Phase skew: %.3f, Power: %.1f dBm\n', [skew, minPower]);
    end

    function out = phase_objective_fcn(skew)
        awg.(['chan_' num2str(awg_Q_channel)]).Skew = skew * 1e-9;
        pause(0.01);
        out = readPower();
    end

    function power = readPower()
        if ~simulate
            sa.sweep();
            power = sa.peakAmplitude();
        else
            best_amp = 1.05;
            best_phase = 11.0;
            distance = sqrt((simul_amp - best_amp)^2 + (simul_phase - best_phase)^2);
            power = 20*log10(distance);
        end
    end
end