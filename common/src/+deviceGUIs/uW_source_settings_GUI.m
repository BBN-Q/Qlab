function setting_fcn = uW_source_settings_GUI(parent, name, settings)
% UW_SOURCE_SETTINGS_GUI_BUILD
%-------------------------------------------------------------------------------
% File name   : uW_source_settings_GUI_build.m
% Generated on: 06-Oct-2010 14:36:30          
% Description :
%-------------------------------------------------------------------------------


% Initialize handles structure
handles = struct();

% if there is no parent figure given, generate one
if nargin < 1 
	handles.parent = figure( ...
			'Tag', 'figure1', ...
			'Units', 'characters', ...
			'Position', [103.833333333333 13.8571428571429 90 22], ...
			'Name', 'uW_settings', ...
			'MenuBar', 'none', ...
			'NumberTitle', 'off', ...
			'Color', get(0,'DefaultUicontrolBackgroundColor'));
	name = ['uW' ' source settings'];
else
	%handles.figure1 = figure(parent);
	handles.parent = parent;
	name = [name ' source settings'];
end

% Create all UI controls
build_gui();

%If no settings were passed in create an empty structure
if nargin < 3
	settings = struct();
end
set_defaults(settings);

% Assign function output
setting_fcn = @get_settings;

%% ---------------------------------------------------------------------------
	function build_gui()
% Creation of all uicontrols

    handles.mainPanel = uiextras.Panel('Parent', handles.parent, 'Title', name, 'Padding', 5 , 'FontSize',11);
    tmpHBox1 = uiextras.HBox('Parent', handles.mainPanel, 'Spacing', 10);

    tmpVBox1 = uiextras.VBox('Parent', tmpHBox1, 'Spacing', 5);
	handles.enable = uicontrol('Parent', tmpVBox1, 'Style', 'checkbox', 'FontSize', 10, 'String', 'Enable');
    
    [~, ~, handles.gen_model] = uiextras.labeledPopUpMenu(tmpVBox1, 'Model:', 'gen_model', {'AgilentN5183A','AgilentE8267D','AnritsuMG3692B','HP8673B','HP8340B','Labbrick','BNC845'}, [120, 25]);
    [~, ~, handles.freq] = uiextras.labeledEditBox(tmpVBox1, 'Freq. (GHz):', 'freq', '5');
    [~, ~, handles.power] = uiextras.labeledEditBox(tmpVBox1, 'Power (dBm):', 'power', '-110');
    [~, ~, handles.phase] = uiextras.labeledEditBox(tmpVBox1, 'Phase (deg.):', 'phase', '0');
    [~, ~, handles.gpib_address ] = uiextras.labeledEditBox(tmpVBox1, 'GPIB Address:', 'gpib_address', '0');
    
    tmpVBox2 = uiextras.VBox('Parent', tmpHBox1, 'Spacing', 5);
    
    radioButtonsBox = uiextras.HButtonBox('Parent', tmpVBox2, 'Spacing', 5);
    radioButtonDefaults = {'Style', 'radiobutton', 'FontSize', 10};
    handles.rf = uicontrol(radioButtonDefaults{:}, 'Parent', radioButtonsBox, 'String', 'RF');
    handles.mod = uicontrol(radioButtonDefaults{:}, 'Parent', radioButtonsBox, 'String', 'Mod.');
    handles.alc = uicontrol(radioButtonDefaults{:}, 'Parent', radioButtonsBox, 'String', 'ALC');
    
    tmpHBox2 = uiextras.HButtonBox('Parent', tmpVBox2, 'Spacing', 5);
    handles.pulse = uicontrol(radioButtonDefaults{:}, 'Parent', tmpHBox2, 'String', 'Pulse');
    handles.pulsetype = uicontrol('Parent', tmpHBox2, 'Style', 'popupmenu', 'FontSize', 10, 'BackgroundColor', [1,1,1], 'String', {'External','Internal'});
    
    IQAdjustPanel = uiextras.Panel('Parent', tmpVBox2, 'Title', 'IQ Adjust', 'FontSize',10, 'Padding', 5);
    tmpVBox3 = uiextras.VBox('Parent', IQAdjustPanel, 'Spacing', 5);
    handles.iqadjust =  uicontrol('Parent', tmpVBox3, 'Style', 'checkbox', 'String', 'On/Off', 'FontSize', 10);
    [~, ~, handles.ioffset] = uiextras.labeledEditBox(tmpVBox3, 'I Offset:', 'ioffset', '0');
    [~, ~, handles.qoffset] = uiextras.labeledEditBox(tmpVBox3, 'Q Offset:', 'qoffset', '0');
    [~, ~, handles.skew] = uiextras.labeledEditBox(tmpVBox3, 'Skew:', 'skew', '0');
    
    %Try to size things up a bit nicer
    tmpVBox1.Sizes = [-0.5, -1, -1, -1, -1, -1];
    tmpVBox2.Sizes = [-0.5,-1,-4];
    
    end

	function selected = get_selected(hObject)
		menu = get(hObject,'String');
		selected = menu{get(hObject,'Value')};
	end

	function set_selected(hObject, val)
		menu = get(hObject, 'String');
		index = find(strcmp(val, menu));
		if ~isempty(index)
			set(hObject, 'Value', index);
		end
	end

	function value = get_numeric(hObject)
		value = str2double(get(hObject, 'String'));
	end

	function settings = get_settings()
		settings = struct();
		
		settings.enable = get(handles.enable, 'Value');
		settings.deviceName = get_selected(handles.gen_model);
		settings.Address = get(handles.gpib_address, 'String');
		settings.frequency = get_numeric(handles.freq);
		settings.power = get_numeric(handles.power);
		settings.phase = get_numeric(handles.phase);
		settings.output = get(handles.rf, 'Value');
		settings.mod = get(handles.mod, 'Value');
		settings.alc = get(handles.alc, 'Value');
		settings.pulse = get(handles.pulse, 'Value');
		settings.pulseSource = get_selected(handles.pulsetype);
		settings.iqadjust = get(handles.iqadjust, 'Value');
		settings.ioffset = get_numeric(handles.ioffset);
		settings.qoffset = get_numeric(handles.qoffset);
		settings.iqskew = get_numeric(handles.skew);
		
	end

	function set_defaults(settings)
		% define default values for fields. If given a settings structure, grab
		% defaults from it
		defaults = struct();
		defaults.frequency = 10.0;
		defaults.power = -110;
		defaults.phase = 0;
		defaults.Address = '';
		defaults.deviceName = 'AgilentN5183A';
		defaults.enable = 0;
		defaults.output = 0;
		defaults.mod = 0;
		defaults.alc = 0;
		defaults.pulse = 0;
		defaults.pulseSource = 'External';
		defaults.iqadjust = 0;
		defaults.ioffset = 0;
		defaults.qoffset = 0;
		defaults.iqskew = 0;

		if ~isempty(fieldnames(settings))
			fields = fieldnames(settings);
			for i = 1:length(fields)
				name = fields{i};
				defaults.(name) = settings.(name);
			end
		end
		
		set(handles.enable, 'Value', defaults.enable);
		set(handles.gpib_address, 'String', num2str(defaults.Address));
		set_selected(handles.gen_model, defaults.deviceName);
		set(handles.freq, 'String', num2str(defaults.frequency));
		set(handles.power, 'String', num2str(defaults.power));
		set(handles.phase, 'String', num2str(defaults.phase));
		set(handles.rf, 'Value', defaults.output);
		set(handles.mod, 'Value', defaults.mod);
		set(handles.alc, 'Value', defaults.alc);
		set(handles.pulse, 'Value', defaults.pulse);
		set_selected(handles.pulsetype, defaults.pulseSource);
		set(handles.iqadjust, 'Value', defaults.iqadjust);
		set(handles.ioffset, 'String', num2str(defaults.ioffset));
		set(handles.qoffset, 'String', num2str(defaults.qoffset));
		set(handles.skew, 'String', num2str(defaults.iqskew));
	end

end
