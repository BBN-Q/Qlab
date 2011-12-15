function cost = piObjectiveFunction(obj, x, qubit, direction)
    [piAmp, offset] = deal(x);
    % create and load sequence
    obj.pulseParams.piAmp = piAmp;
    filename = obj.PiCalChannelSequence(ExpParams.Qubit, direction);
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
    data = obj.homodyneMeasurement();
    
    % evaluate cost
    cost = obj.PiCostFunction(data);
end