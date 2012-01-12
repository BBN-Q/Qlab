function setInstrument(obj, amp, phase)
    ExpParams = obj.inputStructure.ExpParams;
    fssb = 2*pi*ExpParams.SSBFreq;
    samplingRate = obj.awg.samplingRate;
    channel = ExpParams.Mixer.Q_channel;
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
            obj.awg.(['chan_' num2str(channel)]).Skew = skew;
        case 'deviceDrivers.APS'
            % on the APS we generate a new waveform and upload it
            waveform_length = 1000;
            timeStep = 1/samplingRate;
            tpts = timeStep*(0:(waveform_length-1));

            wf = APSWaveform();
            wf.dataMode = wf.REAL_DATA;
            wf.data = -0.5 * amp * sin(fssb.*tpts + phase);
            
            wf.set_offset(obj.awg.(['chan_' num2str(channel)]).offset);
            wf.set_scale_factor(obj.awg.(['chan_' num2str(channel)]).amplitude);
            obj.awg.stop();
            obj.awg.loadWaveform(channel-1, wf.prep_vector());
            obj.awg.(['chan_' num2str(channel)]).waveform = wf;
            obj.awg.run();
    end
end