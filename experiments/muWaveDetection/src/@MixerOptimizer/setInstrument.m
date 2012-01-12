function setInstrument(obj, amp, phase)
    ExpParams = obj.inputStructure.ExpParams;
    fssb = 2*pi*ExpParams.SSBFreq;
    samplingRate = obj.awg.samplingRate;
    I_channel = ExpParams.Mixer.I_channel;
    Q_channel = ExpParams.Mixer.Q_channel;
    % convert phase to radians and restrict to range [-pi, pi]
    phase = mod(phase*pi/180, 2*pi);
    if phase > pi, phase = phase - 2*pi; end
    
    switch class(obj.awg)
        case 'deviceDrivers.Tek5014'
            obj.awg.(['chan_' num2str(ExpParams.Mixer.I_channel)]).Amplitude = amp;
            % on the Tek5014 we just update the channel skew to change the
            % phase
            skew = phase/fssb;
            if obj.inputStructure.verbose
                fprintf('Skew: %.3f ns\n', skew*1e9);
            end
            obj.awg.(['chan_' num2str(Q_channel)]).Skew = skew;
        case 'deviceDrivers.APS'
            samplingRate = samplingRate*1e6; % APS gives sampling rate in MHz
            % on the APS we generate a new waveform and upload it
            waveform_length = 1200;
            timeStep = 1/samplingRate;
            tpts = timeStep*(0:(waveform_length-1));

            obj.awg.stop();

            % scale I waveform
            wf = obj.awg.(['chan_' num2str(I_channel)]).waveform;
            wf.set_scale_factor(amp);
            obj.awg.loadWaveform(I_channel-1, wf.prep_vector());
            obj.awg.loadWaveform(2, wf.prep_vector());
            
            % generate new Q waveform with phase shift
            wf = obj.awg.(['chan_' num2str(Q_channel)]).waveform;
            wf.dataMode = wf.REAL_DATA;
            wf.data = -0.5 * sin(fssb.*tpts + phase);
            
            wf.set_offset(obj.awg.(['chan_' num2str(Q_channel)]).offset);
            wf.set_scale_factor(obj.awg.(['chan_' num2str(Q_channel)]).amplitude);
            obj.awg.loadWaveform(Q_channel-1, wf.prep_vector());
            obj.awg.loadWaveform(3, wf.prep_vector());
            obj.awg.(['chan_' num2str(Q_channel)]).waveform = wf;
            obj.awg.run();
    end
end