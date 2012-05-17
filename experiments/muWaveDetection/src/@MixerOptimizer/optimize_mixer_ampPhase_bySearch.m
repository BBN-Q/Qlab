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

function T = optimize_mixer_ampPhase_bySearch(obj, i_offset, q_offset)
    % unpack constants from cfg file
    ExpParams = obj.inputStructure.ExpParams;
    spec_analyzer_span = ExpParams.SpecAnalyzer.span;
    spec_resolution_bw = ExpParams.SpecAnalyzer.resolution_bw;
    spec_sweep_points = ExpParams.SpecAnalyzer.sweep_points;
    awg_I_channel = ExpParams.Mixer.I_channel;
    awg_Q_channel = ExpParams.Mixer.Q_channel;
    fssb = ExpParams.SSBFreq; % SSB modulation frequency (usually 10 MHz)

    simul_amp = 1.0;
    simul_phase = 0.0;

    verbose = obj.inputStructure.verbose;
    simulate = obj.testMode;
    
    % initialize instruments
    if ~simulate
        % grab instrument objects
        sa = obj.sa;
        awg = obj.awg;
        
        sa.center_frequency = obj.specgen.frequency * 1e9 - fssb;
        sa.span = spec_analyzer_span;
        sa.sweep_mode = 'single';
        sa.resolution_bw = spec_resolution_bw;
        sa.sweep_points = spec_sweep_points;
        sa.video_averaging = 0;
        sa.sweep();
        sa.peakAmplitude();

        awgfile = ExpParams.SSBAWGFile;

        switch class(awg)
            case 'deviceDrivers.Tek5014'
                awg_amp = awg.(['chan_' num2str(awg_I_channel)]).Amplitude;
                awg.openConfig(awgfile);
                awg.(['chan_' num2str(awg_I_channel)]).offset = i_offset;
                awg.(['chan_' num2str(awg_Q_channel)]).offset = q_offset;
                awg.runMode = 'CONT';
                awg.(['chan_' num2str(awg_I_channel)]).Amplitude = awg_amp;
                awg.(['chan_' num2str(awg_Q_channel)]).Amplitude = awg_amp;
                awg.(['chan_' num2str(awg_I_channel)]).Skew = 0;
                awg.(['chan_' num2str(awg_Q_channel)]).Skew = 0;
                awg.(['chan_' num2str(awg_I_channel)]).Enabled = 1;
                awg.(['chan_' num2str(awg_Q_channel)]).Enabled = 1;
            case 'deviceDrivers.APS'
                awg_amp = awg.(['chan_' num2str(awg_I_channel)]).amplitude;

                samplingRate = 1.2e9;
                waveform_length = 1200;
                timeStep = 1/samplingRate;
                tpts = timeStep*(0:(waveform_length-1));
                % i waveform
                iwf = awg.(['chan_' num2str(awg_I_channel)]).waveform;
                iwf.dataMode = iwf.REAL_DATA;
                iwf.data = 0.5 * cos(2*pi*fssb.*tpts);
                iwf.set_offset(i_offset);
                awg.loadWaveform(awg_I_channel-1, iwf.prep_vector());
                awg.setOffset(awg_I_channel, i_offset);
                awg.(['chan_' num2str(awg_I_channel)]).waveform = iwf;
                % q waveform
                qwf = awg.(['chan_' num2str(awg_Q_channel)]).waveform;
                qwf.dataMode = qwf.REAL_DATA;
                qwf.data = -0.5 * sin(2*pi*fssb.*tpts);
                qwf.set_offset(q_offset);
                awg.loadWaveform(awg_Q_channel-1, qwf.prep_vector());
                awg.setOffset(awg_Q_channel, q_offset);
                awg.(['chan_' num2str(awg_Q_channel)]).waveform = qwf;
                
                % copy onto outputs 3 and 4 for testing
                awg.loadWaveform(2, iwf.prep_vector());
                awg.loadWaveform(3, qwf.prep_vector());
                awg.setLinkListMode(2, awg.LL_DISABLE, awg.LL_CONTINUOUS);
                awg.setLinkListMode(3, awg.LL_DISABLE, awg.LL_CONTINUOUS);
                awg.chan_3.enabled = 1;
                awg.chan_4.enabled = 1;
            
                awg.triggerSource = 'internal';
                awg.setLinkListMode(awg_I_channel-1, awg.LL_DISABLE, awg.LL_CONTINUOUS);
                awg.setLinkListMode(awg_Q_channel-1, awg.LL_DISABLE, awg.LL_CONTINUOUS);
                awg.(['chan_' num2str(awg_I_channel)]).enabled = 1;
                awg.(['chan_' num2str(awg_Q_channel)]).enabled = 1;
        end
        awg.run();
        awg.waitForAWGtoStartRunning();
    else
        awg_amp = 1.0;
    end
    
    % initial guess has no amplitude or phase correction
    x0 = [awg_amp, 0];
    % options for Levenberg-Marquardt
    if verbose
        displayMode = 'iter';
    else
        displayMode = 'none';
    end
    
    fprintf('\nStarting search for optimal amp/phase\n');

    % Leven-Marquardt search
    options = optimset(...
        'TolX', 2e-3, ... %2e-3
        'TolFun', 2e-4, ...
        'MaxFunEvals', 1000, ...
        'OutputFcn', @obj.LMStoppingCondition, ...
        'DiffMinChange', 1e-3, ... %1e-4 worked well in simulation
        'Jacobian', 'off', ... % use finite-differences to compute Jacobian
        'Algorithm', {'levenberg-marquardt',1e-2}, ... % starting value for lambda = 1e-1
        'ScaleProblem', 'none', ... % 'Jacobian' or 'none'
        'Display', displayMode);
    [x0, optPower] = lsqnonlin(@SSBObjectiveFcn,x0,[],[],options);

    % commented out section for fminunc search
%     options = optimset(...
%         'TolX', 1e-3, ... %2e-3
%         'TolFun', 1e-4, ...
%         'MaxFunEvals', 100, ...
%         'DiffMinChange', 5e-3, ... %1e-4 worked well in simulation
%         'LargeScale', 'off',...
%         'Display', displayMode);
%     [x0, optPower] = fminunc(@SSBObjectiveFcn,x0,options);
%     optPower = optPower^2;

    % Nelder-Meade Simplex search
%     options = optimset(...
%         'TolX', 1e-3, ... %2e-3
%         'TolFun', 1e-4, ...
%         'MaxFunEvals', 100, ...
%         'Display', displayMode);
%     [x0, optPower] = fminsearch(@SSBObjectiveFcn,x0,options);
%     optPower = optPower^2;
    
    ampFactor = x0(1)/awg_amp;
    skew = x0(2);
    fprintf('Optimal amp/phase parameters:\n');
    fprintf('a: %.3g, skew: %.3f (%.3f degrees)\n', [ampFactor, skew, skew*180/pi]);
    fprintf('SSB power: %.2f\n', 10*log10(optPower));
    
    % correction transformation
    T = [ampFactor ampFactor*tan(skew); 0 sec(skew)];
    
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
        
        obj.setInstrument(x0(1), skew);
        %awg.(['chan_' num2str(awg_I_channel)]).offset = i_offset;
        %awg.(['chan_' num2str(awg_Q_channel)]).offset = q_offset;
    end
    
    % local functions
    function cost = SSBObjectiveFcn(x)
        if verbose, fprintf('amp: %.3f, phase: %.3f\n', x(1), x(2)); end
        if ~simulate
            obj.setInstrument(x(1), x(2));
            pause(0.02);
        else
            simul_amp = x(1);
            simul_phase = x(2);
        end
        power = readPower();
        cost = 10^(power/20);
        if verbose, fprintf('Power: %.3f, Cost: %.3f\n', power, cost); end
    end

    function power = readPower()
        if ~simulate
            sa.sweep();
            power = sa.peakAmplitude();
        else
            best_amp = 1.05;
            best_phase = 0.1;
            a = simul_amp/best_amp;
            phi = simul_phase - best_phase;
            errorVec = [a - cos(phi); sin(phi)];
            power = 20*log10(norm(errorVec));
        end
    end
end
