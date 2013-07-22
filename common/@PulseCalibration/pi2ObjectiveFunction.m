function [cost, J] = pi2ObjectiveFunction(obj, x, direction)
    pi2Amp = real(x(1));
    offset = real(x(2));
    fprintf('pi2Amp: %.4f, offset: %.4f\n', pi2Amp, offset);
    % create sequence
    obj.channelParams.pi2Amp = pi2Amp;
    [filenames segmentPoints] = obj.Pi2CalChannelSequence(obj.settings.Qubit, direction, obj.settings.NumPi2s, false);
    
    % set channel offset
    switch direction
        case 'X'
            chan = 'i_offset';
        case 'Y'
            chan = 'q_offset';
        otherwise
            error('Unknown direction %s', direction);
    end
    if ~obj.testMode
        obj.channelParams.(chan) = offset;
        % load sequence
        obj.loadSequence(filenames, 2);
    end
    
    % measure
    if ~obj.testMode
        data = obj.homodyneMeasurement(segmentPoints);
    else
        data = simulateMeasurement(x, obj.settings.offset2amp, obj.settings.OffsetNorm);
        plot(data);
        ylim([-.21 .21])
        pause(.1);
    end
    
    % evaluate cost
    [cost, J, obj.noiseVar] = obj.RepPulseCostFunction(data, pi/2, obj.settings.NumPi2s);
    % scale J rows by amplitude and offset->amplitude conversion factor and
    % turn on/off offset shifting if we are using SSB
    J(:,1) = J(:,1)/pi2Amp;
    offset2amp = obj.settings.offset2amp;
    J(:,2) = (obj.channelParams.SSBFreq == 0)*obj.settings.OffsetNorm*J(:,2)*offset2amp/pi2Amp; % offset can have a different integral norm
    fprintf('Cost: %.4f (%.4f) \n', sum(cost.^2), sum(cost.^2/length(cost)));
    fprintf('Noise var: %.4f\n', obj.noiseVar);
end

function data = simulateMeasurement(x, offset2amp, offsetNorm)
    idealAmp = 0.34;
    idealOffset = .081;
    
    amp = x(1);
    offset = x(2);

    offsetError = offsetNorm*offset2amp*(offset - idealOffset);
    ampError = (amp + offsetError - idealAmp)/idealAmp;
    ampError2 = (amp - offsetError - idealAmp)/idealAmp;
    angleError = ampError*pi/2;
    angleError2 = ampError2*pi/2;
    
    % data representing amplitude error
    n = 1:9;
    scale = 0.2;
    data = scale*(-1).^(n+1) .* sin((2*n-1) * angleError);
    data2 = scale*(-1).^(n+1) .* sin((2*n-1) * angleError2);
    % double every point
    data = data(floor(1:.5:9.5));
    data2 = data2(floor(1:.5:9.5));
    data = [-scale -scale data data2];
    % add noise
    data = data + 0.005*scale*randn(1,length(data));
end