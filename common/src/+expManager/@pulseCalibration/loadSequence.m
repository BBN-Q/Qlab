function loadSequence(obj, paths, qubit)
    % loadSequence(paths)
    % Load a set of pattern files onto one or more AWGs
    
    if length(paths) > length(obj.awg)
        error('Must provide a sequence path for each AWG');
    end
    
    IQchannels = obj.channelMap(obj.ExpParams.Qubit);
    
    % update offsets on target AWG
    obj.awgParams{obj.targetAWGIdx}.(['chan_' num2str(IQchannels.i)]).offset = obj.pulseParams.i_offset;
    obj.awgParams{obj.targetAWGIdx}.(['chan_' num2str(IQchannels.q)]).offset = obj.pulseParams.q_offset;
    
    for i = 1:length(paths)
        % load sequence
        params = obj.awgParams{i};
        awg = obj.awg{i};
        params.seqfile = paths{i};
        params.seqforce = 1;
        awg.setAll(params);
        obj.awgParams{i} = params;
    end
end