function device = InstrumentFactory(name, instrSettings)
    
    %If we weren't passed settings then load from library
    if ~exist('instrSettings', 'var')
        %load the instrument library
        instrLibrary = json.read(getpref('qlab', 'InstrumentLibraryFile'));

        %Pull out the instrument settings dictionary
        instrSettings = instrLibrary.instrDict.(name);
        deviceClass = instrSettings.x__class__;
    else
        deviceClass = instrSettings.deviceName;
    end
        
    device = deviceDrivers.(deviceClass);
    device.connect(instrSettings.address);

end