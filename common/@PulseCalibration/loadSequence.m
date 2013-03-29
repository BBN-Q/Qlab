function loadSequence(obj, paths, numRepeats)
    % loadSequence(paths)
    % Load a set of pattern files onto one or more AWGs
    
    if length(paths) < length(fieldnames(obj.AWGs))
        error('Must provide a sequence path for each AWG');
    end
    
    IQchannels = obj.channelMap.(obj.settings.Qubit);
    
    % update offsets on control AWG
    params = obj.AWGSettings.(obj.controlAWG);
    iChan = IQchannels.IQkey(end-1);
    qChan = IQchannels.IQkey(end);
    params.(['chan_' iChan]).offset = obj.pulseParams.i_offset;
    params.(['chan_' qChan]).offset = obj.pulseParams.q_offset;
    obj.AWGSettings.(obj.controlAWG) = params;
    
    % load sequence on all AWGs
    awgNames = fieldnames(obj.AWGs)';
    for ct = 1:length(awgNames)
        params = obj.AWGSettings.(awgNames{ct});
        params.seqfile = paths{ct};
        params.seqforce = 1;
        params.miniLLRepeat = numRepeats-1;
        obj.AWGs.(awgNames{ct}).setAll(params);
    end
end