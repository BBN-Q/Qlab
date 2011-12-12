function loadSequence(obj, paths)
    % loadSequence(paths)
    % Load a set of pattern files onto one or more AWGs
    
    if length(paths) ~= length(obj.awg)
        error('Must provide a sequence path for each AWG');
    end
    
    for i = 1:length(paths)
        % load sequence
        obj.awg(i).seqfile = paths(i);
        % set the awg running
        obj.awg(i).run();
    end
    for i = 1:length(obj.awg)
        % wait for each AWG to start
        [success_flag_AWG] = obj.awg(i).waitForAWGtoStartRunning();
        if success_flag_AWG ~= 1, error('AWG timed out'), end

        obj.awg(i).stop(); % stop AWGs to sync them with digitizer
    end
    % start slave AWGs
    for i = 2:length(obj.awg)
        obj.awg(i).run();
        [success_flag_AWG] = obj.awg(i).waitForAWGtoStartRunning();
        if success_flag_AWG ~= 1, error('AWG timed out'), end
    end
    
    pause(0.5);
end