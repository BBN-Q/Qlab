function cost = piObjectiveFunction(obj, x, qubit, direction)
    piAmp = x(1);
    offset = x(2);
    % create and load sequence
    obj.pulseParams.piAmp = piAmp;
    [filenames nbrPatterns] = obj.PiCalChannelSequence(obj.ExpParams.Qubit, direction);
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
        pause(.1);
    end
    
    % evaluate cost
    cost = obj.PiCostFunction(data);
end

function data = simulateMeasurement(x)
    idealAmp = 5000;
    idealOffset = .124;
    
    amp = x(1);
    offset = x(2);
    
    % amp = 8192 <=> offset .5
    off2Amp = 16000;
    offsetError = off2Amp*(offset - idealOffset)/idealAmp;
    ampError = (amp - idealAmp)/idealAmp + offsetError;
    ampError2 = (amp - idealAmp)/idealAmp - offsetError;
    
    % data representing amplitude error
    n = 1:9;
    data = 0.65 + 0.15*(-1).^n .* sin(n * ampError);
    data2 = 0.65 + 0.15*(-1).^n .* sin(n * ampError2);
    data = data(floor(1:.5:9.5));
    data2 = data2(floor(1:.5:9.5));
    data = [0.5 0.5 data data2];
end