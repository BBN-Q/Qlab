function fftScopeGUI()

mainWindow = figure( ...
	'Tag', 'figure1', ...
	'Units', 'pixels', ...
	'Position', [50 50 1000 700], ...
	'Name', 'Scope', ...
	'MenuBar', 'none', ...
	'NumberTitle', 'off', ...
	'Color', get(0,'DefaultUicontrolBackgroundColor'), ...
	'Visible', 'off', 'HandleVisibility', 'callback');

% add a layout
mainGrid = uiextras.HBox('Parent', mainWindow, 'Spacing', 20, 'Padding', 10);
leftColumn = uiextras.VBox('Parent', mainGrid, 'Spacing', 20);
rightColumn = uiextras.VBox('Parent', mainGrid, 'Spacing', 20);

% add digitizer settings GUI
[get_digitizer_settings, ~] = deviceGUIs.digitizer_settings_gui(leftColumn);

%Add the Run/Stop buttons
tmpHBox = uiextras.HButtonBox('Parent', leftColumn, 'ButtonSize', [120, 40]);
runButton = uicontrol('Parent', tmpHBox, 'Style', 'pushbutton', 'String', 'Run', 'FontSize', 10, 'Callback', @run_callback);
uicontrol('Parent', tmpHBox, 'Style', 'pushbutton', 'String', 'Stop', 'FontSize', 10, 'Callback', @stop_callback );

% add mode dropdown
[~, ~, mode] = uiextras.labeledPopUpMenu(rightColumn, 'Scope mode:', 'mode',  { 'FFT', 'Waveform'});

% add scope display
plotHandle = axes('Parent', rightColumn);

running = false;

% weight the element sizes
mainGrid.Sizes = [-2, -3];
leftColumn.Sizes = [-3, -1];
rightColumn.Sizes = [-1, -10];

% Now that everything is setup draw the window
drawnow;
set(mainWindow, 'Visible', 'on');

    function stop_callback(~, ~)
        running = false;
    end

    function run_callback(~, ~)
        % get digitizer settings
        settings = get_digitizer_settings();
        % create scope object
        scope = deviceDrivers.(settings.cardType);
        scope.connect(0);
        scope.setAll(settings);
        
        % set up plot
        samplingRate = settings.horizontal.samplingRate;
        recordLength = settings.averager.recordLength;
        xpts = linspace(0, samplingRate/2, recordLength/2+1);
        % skip DC term
        plot(plotHandle, xpts(2:end), nan(1, recordLength/2));
        set(gca(), 'YLimMode', 'manual');
        set(gca(), 'YLim', [0, 35]);
        h = get(gca(), 'Children');
        
        running = true;
        while (running)
            scope.acquire();
            scope.wait_for_acquisition(1);
            [wfm, ~] = scope.transfer_waveform(1);
            y = fft(wfm);
            
            % skip DC term
            set(h, 'YData', abs(y(2:recordLength/2+1)));
            pause(.1);
        end
        
        % cleanup
        scope.disconnect();
    end

end