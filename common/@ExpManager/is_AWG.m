function out = is_AWG(instr)
    out = ismember(class(instr), {'deviceDrivers.Tek5014', 'deviceDrivers.APS', 'APS', 'APS2'});
    out = out || (isprop(instr, 'is_AWG') && instr.is_AWG);
end
