function device = InstrumentFactory(name)
    %load the instrument library
    instrLibrary = jsonlab.loadjson(getpref('qlab', 'InstrumentLibraryFile'));

    %Pull out the instrument settings dictionary
    instrSettings = instrLibrary.instrDict.(name);
    deviceClass = instrSettings.x__class__;
    
    device = deviceDrivers.(deviceClass);
    device.connect(instrSettings.address);

end