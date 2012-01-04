function loadSequence(obj, paths)
    % loadSequence(paths)
    % Load a set of pattern files onto one or more AWGs
    
    if length(paths) > length(obj.awg)
        error('Must provide a sequence path for each AWG');
    end
    
    IQchannels = obj.channelMap(obj.ExpParams.Qubit);
    
    for i = 1:length(paths)
        % load sequence
        params = obj.awgParams{i};
        awg = obj.awg{i};
        params.seqfile = paths{i};
        params.seqforce = 1;
        params.(['chan_' num2str(IQchannels{1})]).offset = obj.pulseParams.i_offset;
        params.(['chan_' num2str(IQchannels{2})]).offset = obj.pulseParams.q_offset;
        awg.setAll(params);
        obj.awgParams{i} = params;
    end
end