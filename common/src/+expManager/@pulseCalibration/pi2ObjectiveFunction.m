function cost = pi2ObjectiveFunction(obj, x, qubit, direction)
    [pi2Amp, offset] = deal(x);
    % create and load sequence
    obj.pulseParams.pi2Amp = pi2Amp;
    filename = obj.Pi2CalChannelSequence(ExpParams.Qubit, direction);
    obj.loadSequence(filename);
    
    % set channel offset
    IQchannels = obj.channelMap(qubit);
    switch direction
        case 'X'
            chan = num2str(IQchannels(1));
        case 'Y'
            chan = num2str(IQchannels(2));
        otherwise
            error('Unknown direction %s', direction);
    end
    obj.Instr.awg.(['chan_' chan]).offset = offset;
    
    % measure
    data = obj.homodyneDetection2DDo();
    
    % evaluate cost
    cost = obj.Pi2CostFunction(data);
end