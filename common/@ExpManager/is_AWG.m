function out = is_AWG(instr)
    out = ismember(class(instr), {'deviceDrivers.Tek5014', 'deviceDrivers.APS', 'APS', 'APS2'});
end

    