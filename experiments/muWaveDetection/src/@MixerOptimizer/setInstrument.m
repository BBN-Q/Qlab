function setInstrument(obj, amp, phase)
    %Helper function to set the amplitude and phase for IQ calibration
    
    fssb = 2*pi*obj.expParams.SSBFreq;
    samplingRate = obj.awg.samplingRate;
    I_channel = str2double(obj.channelParams.IQkey(end-1));
    Q_channel = str2double(obj.channelParams.IQkey(end));
    % restrict phase to range [-pi, pi]
    phase = mod(phase, 2*pi);
    if phase > pi, phase = phase - 2*pi; end
    
    switch class(obj.awg)
        case 'deviceDrivers.Tek5014'
            obj.awg.(['chan_' num2str(I_channel)]).amplitude = amp;
            % on the Tek5014 we just update the channel skew to change the
            % phase
            skew = phase/fssb;
            if obj.expParams.verbose
                fprintf('Skew: %.3f ns\n', skew*1e9);
            end
            obj.awg.(['chan_' num2str(Q_channel)]).skew = skew;
            obj.awg.operationComplete()
        case 'deviceDrivers.APS'
            samplingRate = samplingRate*1e6; % APS gives sampling rate in MHz
            % on the APS we generate a new waveform and upload it
            waveform_length = 1200;
            timeStep = 1/samplingRate;
            tpts = timeStep*(0:(waveform_length-1));

            % scale I waveform
            obj.awg.setAmplitude(I_channel, amp);
            
            % generate new Q waveform with phase shift
            qwf = -0.5 * sin(fssb.*tpts + phase);

            obj.awg.loadWaveform(Q_channel, qwf);

            pause(0.1);
    end
end