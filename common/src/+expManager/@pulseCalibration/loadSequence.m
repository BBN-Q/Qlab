function loadSequence(obj, paths)
    % loadSequence(paths)
    % Load a set of pattern files onto one or more AWGs
    
    if length(paths) ~= length(obj.awg)
        error('Must provide a sequence path for each AWG');
    end
    
    for i = 1:length(paths)
        % load sequence
        obj.awg(i).seqfile = paths{i};
        % TODO: update other config data
    end
end