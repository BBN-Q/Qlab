%A simple GUI which loads the digitizer_settings_gui GUI and has buttons to
%take and plot data.  

function test_digitizer_gui()

mainWindow = figure( ...
	'Tag', 'figure1', ...
	'Units', 'characters', ...
	'Position', [25 40 100 50], ...
	'Name', 'Testing Digitizer', ...
	'MenuBar', 'none', ...
	'NumberTitle', 'off', ...
	'Color', get(0,'DefaultUicontrolBackgroundColor'), ...
	'Visible', 'off');

%Add the digitizer settings GUI
get_digitizer_settings = deviceGUIs.digitizer_settings_gui(mainWindow, 10, 10);

%Add the "Take Data" button
runHandle = uicontrol(mainWindow, ...
	'Style', 'pushbutton', ...
	'String', 'Take Data', ...
    'Unit', 'characters',...
	'Position', [70 45, 14, 3], ...
	'Callback', {@take_data_callback});

%Add the "Plot Data" button
runHandle = uicontrol(mainWindow, ...
	'Style', 'pushbutton', ...
	'String', 'Plot Data', ...
    'Unit', 'characters',...
	'Position', [70 40, 14, 3], ...
	'Callback', {@plot_data_callback});


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
        timeStep = curSettings.horizontal.sampleInterval;
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