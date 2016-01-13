function out = is_scope(instr)
    out = ismember(class(instr), {'deviceDrivers.AgilentAP240', 'deviceDrivers.AlazarATS9870', 'X6'});
    out = out || (isprop(instr, 'is_scope') && instr.is_scope);
end

    