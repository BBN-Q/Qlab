function device = InstrumentFactory(name, instrSettings)
    
    %If we weren't passed settings then load from library
    if ~exist('instrSettings', 'var')
        %load the instrument library
        %turn off annoying warnings about illegal Matlab structure field
        %names
        warning('off', 'json:fieldNameConflict');
        instrLibrary = json.read(getpref('qlab', 'InstrumentLibraryFile'));
        warning('on', 'json:fieldNameConflict');

        %Pull out the instrument settings dictionary
        instrSettings = instrLibrary.instrDict.(name);
        deviceClass = instrSettings.x__class__;
    else
        deviceClass = instrSettings.deviceName;
    end

    import deviceDrivers.*
    device = eval(deviceClass);
    device.connect(instrSettings.address);

end