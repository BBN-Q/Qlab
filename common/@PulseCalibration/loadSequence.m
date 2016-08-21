function loadSequence(obj, metainfo)
    % loadSequence(paths)
    % Load a set of pattern files onto one or more AWGs

    % update offsets on control AWG
    params = obj.AWGSettings.(obj.controlAWG);
    iChan = obj.channelParams.physChan(end-1);
    qChan = obj.channelParams.physChan(end);
    params.(['chan_' iChan]).offset = obj.channelParams.i_offset;
    params.(['chan_' qChan]).offset = obj.channelParams.q_offset;
    obj.AWGSettings.(obj.controlAWG) = params;

    % load sequence on all AWGs
    awgNames = fieldnames(obj.AWGs)';
    for ct = 1:length(awgNames)
        params = obj.AWGSettings.(awgNames{ct});
        if isfield(metainfo.instruments, awgNames{ct})
            params.seqFile = metainfo.instruments.(awgNames{ct});
            params.seqForce = 1;
            obj.AWGs.(awgNames{ct}).setAll(params);
        else
            error('Sequence file not specified in meta info for AWG %s', awgNames{ct});
        end
    end
end
