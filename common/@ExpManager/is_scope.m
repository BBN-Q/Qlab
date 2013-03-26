function out = is_scope(instr)
    out = ismember(class(instr), {'deviceDrivers.AgilentAP240', 'deviceDrivers.AlazarATS9870'});
end

    