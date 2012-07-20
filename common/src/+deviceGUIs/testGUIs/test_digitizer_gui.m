%A simple GUI which loads the digitizer_settings_gui GUI and has buttons to
%take and plot data.  

function test_digitizer_gui()

mainWindow = figure( ...
	'Tag', 'figure1', ...
	'Units', 'characters', ...
	'Position', [25 20 110 50], ...
	'Name', 'Testing Digitizer', ...
	'MenuBar', 'none', ...
	'NumberTitle', 'off', ...
	'Color', get(0,'DefaultUicontrolBackgroundColor'), ...
	'Visible', 'off');

%Add the digitizer settings GUI
%Create some layout
mainHBox = uiextras.HBox('Parent', mainWindow, 'Spacing', 10);
get_digitizer_settings = deviceGUIs.digitizer_settings_gui(mainHBox);

tmpVBox = uiextras.VBox('Parent', mainHBox, 'Spacing', 10);
tmpButtonBox = uiextras.VButtonBox('Parent', tmpVBox);

%Add the "Take Data" button
uicontrol('Parent', tmpButtonBox , 'Style', 'pushbutton', 'String', 'Take Data', 'Callback', {@take_data_callback});

%Add the "Plot Data" button
uicontrol('Parent', tmpButtonBox , 'Style', 'pushbutton', 'String', 'Plot Data', 'Callback', {@plot_data_callback});
uiextras.Empty('Parent',tmpVBox);
mainHBox.Sizes = [-4, -1];

channelAData = [];
channelBData = [];

% show mainWindow
drawnow;
set(mainWindow, 'Visible', 'on');


    function take_data_callback(~, ~)
        %Load the current digitizer settings
        curSettings = get_digitizer_settings();
        curSettings = rmfield(curSettings, {'deviceName' 'Address'});
        
        %Create an instrument
        digitizer = deviceDrivers.AlazarATS9870();
        
        %Call connect (doesn't actually do anything but consistent with
        %expBase
        digitizer.connect('')
        
        %Load all the settings
        digitizer.setAll(curSettings);
        
        %Start the acquisition
        fprintf('Starting acquisition...\n');
        digitizer.acquire()
        
        %Wait for the acquisition to finish
        fprintf('Waiting for data.... ');
        digitizer.wait_for_acquisition()
        
        %"Transfer" the waveforms
        channelAData = digitizer.transfer_waveform(1);
        channelBData = digitizer.transfer_waveform(2);

        %Release the memory
        delete(digitizer);
        fprintf('Done!\n');
        
    end

    function plot_data_callback(~, ~)
        figure()
        %Load the current digitizer settings
        curSettings = get_digitizer_settings();
        timeStep = (1/curSettings.horizontal.samplingRate);
        numPoints = curSettings.averager.recordLength;
        timeData = timeStep*(1:numPoints);
        if(~isempty(channelAData))
            plot(timeData, channelAData);
        end
        hold on
        if(~isempty(channelBData))
            plot(timeData, channelBData,'r');
        end
        hold off
        
    end


end