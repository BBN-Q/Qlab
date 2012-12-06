function [outx, outy] = arbitrary(params)
    persistent arbPulses;
    if isempty(arbPulses)
        arbPulses = containers.Map();
    end
    amp = params.amp;
    fname = params.arbfname;
    delta = params.delta;

    if ~arbPulse.isKey(fname)
        % need to load the pulse from file
        % TODO check for existence of file before loading it
        arbPulses(fname) = load(fname);
    end
    pulseData = arbPulses(fname);
    outx = round(amp*pulseData(:,1));
    outy = round(delta*amp*pulseData(:,2));
end
