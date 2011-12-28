function [cost, J] = pi2ObjectiveFunction(obj, x, qubit, direction)
    pi2Amp = x(1);
    offset = x(2);
    fprintf('pi2Amp: %.0f, offset: %.3f\n', pi2Amp, offset);
    % create and load sequence
    obj.pulseParams.pi2Amp = pi2Amp;
    [filenames nbrPatterns] = obj.Pi2CalChannelSequence(obj.ExpParams.Qubit, direction);
    if ~obj.testMode
        obj.loadSequence(filenames);
    end
    
    % set channel offset
    IQchannels = obj.channelMap(qubit);
    switch direction
        case 'X'
            chan = num2str(IQchannels{1});
        case 'Y'
            chan = num2str(IQchannels{2});
        otherwise
            error('Unknown direction %s', direction);
    end
    if ~obj.testMode
        awg = obj.awg{1};
        awg.(['chan_' chan]).offset = offset;
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
    % scale J rows by amplitude and offset->amplitude conversion factor
    J(:,1) = J(:,1)/pi2Amp;
    offset2amp = 8192/2.0; % replace 2.0 by the max output voltage of the AWG
    J(:,2) = J(:,2)*offset2amp/pi2Amp;
    fprintf('Cost: %.4f\n', sum(cost.^2/length(cost)));
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