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
% File: optimize_mixer_offsets.m
%
% Description: Searches for optimal amplitude and phase correction on an
% I/Q mixer.

function optimize_mixer_ampPhase()
    % load constants here (TO DO: load from cfg file)
    spec_analyzer_address = 17;
    spec_generator_address = 19;
    awg_address = 2;
    spec_analyzer_span = 100e3;
    spec_resolution_bw = 10e3;
    spec_sweep_points = 20;
    awg_I_channel = 3;
    awg_Q_channel = 4;
    waveform_length = 1000;
    fssb = 10e6; % SSB modulation frequency
    assb = 6500;
    simul_amp = 1.0;
    simul_phase = 0.0;

    verbose = true;
    simulate = true;
    
    % correction transformation
    T = diag([1 1]);
    
    % initialize instruments
    if ~simulate
        specgen = deviceDrivers.HP8673B();
        specgen.connect(spec_generator_address);

        sa = deviceDrivers.HP71000();
        sa.connect(spec_analyzer_address);
        sa.center_frequency = specgen.frequency * 1e9 + modulation_frequency;
        sa.span = spec_analyzer_span;
        sa.sweep_mode = 'single';
        sa.resolution_bw = spec_resolution_bw;
        sa.sweep_points = spec_sweep_points;
        sa.video_averaging = 0;
        sa.sweep();
        sa.peakAmplitude();

        awg = deviceDrivers.Tek5014();
        awg.connect(awg_address);
        
        % generate initial SSB modulation signal
        [ipattern, qpattern] = ssbWaveform(1.0, 0);
        awgfile = saveAWGFile(ipattern, qpattern);
        awg.openConfig(awgfile);
        awg.runMode = 'CONT';
        awg.(['chan_' awg_I_channel]).Amplitude = 0.5;
        awg.(['chan_' awg_Q_channel]).Amplitude = 0.5;
        awg.(['chan_' awg_I_channel]).Skew = 0.0;
        awg.(['chan_' awg_Q_channel]).Skew = 0.0;
        awg.run();
    end
    
    
    % search for best I and Q values to minimize the peak amplitude
    optimizeAmp();
    optimizePhase();
    
    % restore spectrum analyzer to a normal state
    if ~simulate
        sa.center_frequency = specgen.frequency * 1e9;
        sa.span = 25e6;
        sa.sweep_mode = 'cont';
        sa.resolution_bw = 'auto';
        sa.sweep_points = 800;
        sa.sweep();
        sa.peakAmplitude();
    end
    
    % local functions
    
    %% Modify amplitude imbalance factor in transformation matrix to minimize
     % amplitude in the undesired sideband.
    %%
    function optimizeAmp()

    end

    function optimizePhase()
        
    end

    function power = readPower()
        if ~simulate
            power = sa.peakAmplitude();
        else
            best_amp = 1.05;
            best_phase = 11.0;
            distance = sqrt((simul_amp - best_amp)^2 + (simul_phase - best_phase)^2);
            power = 20*log10(distance);
        end
        fevals = fevals + 1;
    end

    function setOffsets(vertex)
        if ~simulate
            awg.(['chan_' num2str(awg_I_channel)]).offset = vertex.a;
            awg.(['chan_' num2str(awg_Q_channel)]).offset = vertex.b;
            pause(0.02);
            sa.sweep();
        else
            simul_amp = vertex.a;
            simul_phase = vertex.b;
        end
    end

    function [ipat, qpat] = ssbWaveform(amp, phase)
        % generate SSB modulation signals
        t = 0:(waveform_length-1);
        ipat = assb * cos(2*pi*fssb.*t);
        qpat = -assb * amp * sin(2*pi*fssb.*t + pi/180.0*phase);
    end

    function fname = saveAWGFile(ipattern, qpattern)
        %path = 'U:\AWG\MixerCal\';
        path = '/Volumes/mqco/AWG/MixerCal/';
        basename = 'MixerCal';
        fname = [path basename '.awg'];
        len = length(ipattern);
        % initialize everything to zeroes
        ch1 = zeroes(1, len);
        ch1m1 = zeroes(1, len);
        ch1m2 = zeroes(1, len);
        ch2 = zeroes(1, len);
        ch2m1 = zeroes(1, len);
        ch2m2 = zeroes(1, len);
        ch3 = zeroes(1, len);
        ch3m1 = zeroes(1, len);
        ch3m2 = zeroes(1, len);
        ch4 = zeroes(1, len);
        ch4m1 = zeroes(1, len);
        ch4m2 = zeroes(1, len);
        
        % put the pattern on the appropriate channels
        eval(sprintf('ch%d = ipattern;', awg_I_channel));
        eval(sprintf('ch%d = qpattern;', awg_Q_channel));

        TekPattern.exportTekSequence(path, basename, ch1, ch1m1, ch1m2, ch2, ch2m1, ch2m2, ch3, ch3m1, ch3m2, ch4, ch4m1, ch4m2);
    end
end