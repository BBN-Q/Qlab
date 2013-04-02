function device = InstrumentFactory(name)
    %load the instrument library
    instrLibrary = jsonlab.loadjson(getpref('qlab', 'instrument_library'));
    instr = instrLibrary.(name);
    deviceClass = instr.type;
    
    device = deviceDrivers.(deviceClass);
    device.connect(instr.address);

end