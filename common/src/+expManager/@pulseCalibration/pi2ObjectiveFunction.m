function [cost, J] = pi2ObjectiveFunction(obj, x, direction)
    pi2Amp = real(x(1));
    offset = real(x(2));
    fprintf('pi2Amp: %.1f, offset: %.4f\n', pi2Amp, offset);
    % create sequence
    obj.pulseParams.pi2Amp = pi2Amp;
    [filenames nbrPatterns] = obj.Pi2CalChannelSequence(obj.ExpParams.Qubit, direction, false);
    
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
        obj.pulseParams.(chan) = offset;
        % load sequence
        obj.loadSequence(filenames, 2);
    end
    
    % measure
    if ~obj.testMode
        data = obj.homodyneMeasurement(nbrPatterns);
    else
        data = simulateMeasurement(x);
        plot(data);
        ylim([.49 .81])
        pause(.1);
    end
    
    % evaluate cost
    [cost, J] = obj.RepPulseCostFunction(data, pi/2);
    % scale J rows by amplitude and offset->amplitude conversion factor and
    % turn on/off offset shifting if we are using SSB
    J(:,1) = J(:,1)/pi2Amp;
    offset2amp = obj.ExpParams.offset2amp;
    J(:,2) = (obj.ExpParams.SSBFreq == 0)*obj.ExpParams.OffsetNorm*J(:,2)*offset2amp/pi2Amp; % offset can have a different integral norm
    fprintf('Cost: %.4f (%.4f) \n', sum(cost.^2), sum(cost.^2/length(cost)));
end

function data = simulateMeasurement(x)
    idealAmp = 3400;
    idealOffset = .123;
    
    amp = x(1);
    offset = x(2);
    
    % amp = 8192 <=> offset 2.0
    off2Amp = 8192/2.0;
    offsetError = off2Amp*(offset - idealOffset);
    ampError = (amp + offsetError - idealAmp)/idealAmp;
    ampError2 = (amp - offsetError - idealAmp)/idealAmp;
    angleError = ampError*pi/2;
    angleError2 = ampError2*pi/2;
    
    % data representing amplitude error
    n = 1:9;
    data = 0.65 + 0.15*(-1).^(n+1) .* sin((2*n-1) * angleError);
    data2 = 0.65 + 0.15*(-1).^(n+1) .* sin((2*n-1) * angleError2);
    % double every point
    data = data(floor(1:.5:9.5));
    data2 = data2(floor(1:.5:9.5));
    data = [0.5 0.5 data data2];
end