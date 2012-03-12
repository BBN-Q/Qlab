function [get_settings_fcn, set_settings_fcn] = AWG5014_settings_GUI(parent, name, settings)
% AWG5014_BUILD
%-------------------------------------------------------------------------------
% File name   : AWG5014_build.m               
% Generated on: 07-Oct-2010 14:35:49          
% Description :
%-------------------------------------------------------------------------------


% Initialize handles structure
handles = struct();

% if there is no parent figure given, generate one
if nargin < 1 
	handles.parent = figure( ...
			'Tag', 'figure1', ...
			'Units', 'characters', ...
			'Position', [103.833333333333 13.8571428571429 90 20], ...
			'Name', 'TekAWG Settings', ...
			'MenuBar', 'none', ...
			'NumberTitle', 'off', ...
			'Color', get(0,'DefaultUicontrolBackgroundColor'));
	name = 'TekAWG settings';
else
	handles.parent = parent;
	name = [name ' settings'];
end

% Create all UI controls
build_gui();

if nargin < 5
	settings = struct();
end
set_GUI_fields(settings);

% Assign function handles output
get_settings_fcn = @get_settings;
set_settings_fcn = @set_GUI_fields;

%% ---------------------------------------------------------------------------
	function build_gui()
% Creation of all uicontrols

        handles.mainPanel = uiextras.Panel('Parent', handles.parent, 'Title', name, 'Padding', 5 , 'FontSize',11);

        editBoxParams = {'style', 'edit', 'BackgroundColor', [1,1,1]};

        tmpVBox_main = uiextras.VBox('Parent', handles.mainPanel, 'Spacing', 5);
        
        handles.enable = uicontrol('Parent', tmpVBox_main, 'Style', 'checkbox', 'FontSize', 10, 'String', 'Enable');

        tmpHBox_top = uiextras.HBox('Parent', tmpVBox_main, 'Spacing', 5); 
        
        tmpVBox1 = uiextras.VBox('Parent', tmpHBox_top, 'Spacing', 5);
        
        tmpHBox1 = uiextras.HButtonBox('Parent', tmpVBox1, 'Spacing', 5, 'ButtonSize', [50,25], 'VerticalAlignment', 'middle');
        uiextras.Empty('Parent', tmpHBox1);
        uicontrol('Parent', tmpHBox1, 'style', 'text', 'String', 'Ch1.');
        uicontrol('Parent', tmpHBox1, 'style', 'text', 'String', 'Ch2.');
        uicontrol('Parent', tmpHBox1, 'style', 'text', 'String', 'Ch3.');
        uicontrol('Parent', tmpHBox1, 'style', 'text', 'String', 'Ch4.');
        
        tmpHBox2 = uiextras.HButtonBox('Parent', tmpVBox1, 'Spacing', 5, 'ButtonSize', [50,25], 'VerticalAlignment', 'middle');
        uicontrol('Parent', tmpHBox2, 'style', 'text', 'String', 'Amp.');
        handles.ch1amp = uicontrol('Parent', tmpHBox2, editBoxParams{:});
        handles.ch2amp = uicontrol('Parent', tmpHBox2, editBoxParams{:});
        handles.ch3amp = uicontrol('Parent', tmpHBox2, editBoxParams{:});
        handles.ch4amp = uicontrol('Parent', tmpHBox2, editBoxParams{:});

        tmpHBox3 = uiextras.HButtonBox('Parent', tmpVBox1, 'Spacing', 5, 'ButtonSize', [50,25], 'VerticalAlignment', 'middle');
        uicontrol('Parent', tmpHBox3, 'style', 'text', 'String', 'Off.');
        handles.ch1off = uicontrol('Parent', tmpHBox3, editBoxParams{:});
        handles.ch2off = uicontrol('Parent', tmpHBox3, editBoxParams{:});
        handles.ch3off = uicontrol('Parent', tmpHBox3, editBoxParams{:});
        handles.ch4off = uicontrol('Parent', tmpHBox3, editBoxParams{:});

        tmpHBox4 = uiextras.HButtonBox('Parent', tmpVBox1, 'Spacing', 5, 'ButtonSize', [50,25]);
        uiextras.Empty('Parent', tmpHBox4);
        radioButtonParams = {'Style', 'radiobutton', 'FontSize', 10, 'Parent', tmpHBox4, 'String', 'On'};
        handles.ch1enable = uicontrol(radioButtonParams{:});
        handles.ch2enable = uicontrol(radioButtonParams{:});
        handles.ch3enable = uicontrol(radioButtonParams{:});
        handles.ch4enable = uicontrol(radioButtonParams{:});
        
        uiextras.Empty('Parent', tmpVBox1);
        
        tmpVBox2 =  uiextras.VBox('Parent', tmpHBox_top, 'Spacing', 5);
        [~, ~, handles.scaleMode] = uiextras.labeledPopUpMenu(tmpVBox2, 'Scale Mode:', 'scaleMode',  {'Amp/Off','Hi/Lo'});
        [~, ~, handles.triggerSource] = uiextras.labeledPopUpMenu(tmpVBox2, 'Scale Mode:', 'triggerSource',  {'External','Internal'});
        [~, ~, handles.samplingRate] = uiextras.labeledEditBox(tmpVBox2, 'Samp. Rate:', 'samplingRate', '1');
        [~, ~, handles.triggerInterval] = uiextras.labeledEditBox(tmpVBox2, 'Trigger Int. (s):', 'triggerInterval', '');
        [~, ~, handles.gpibAddress] = uiextras.labeledEditBox(tmpVBox2, 'GPIB:', 'gpibAddress', '');
        
        tmpHBox5 = uiextras.HBox('Parent', tmpVBox_main, 'Spacing', 5); 
        uicontrol('Parent', tmpHBox5, 'Style', 'text', 'String', 'Sequence File:');
        handles.seqfile = uicontrol('Parent', tmpHBox5, 'Style', 'edit', 'BackgroundColor', [1 1 1]);
        handles.seqforce = uicontrol('Parent', tmpHBox5, 'Style', 'checkbox', 'String', 'Force Reload?');
        
        %Try and size things up
        tmpHBox5.Sizes = [-1, -3.5, -1.25];
        tmpVBox_main.Sizes = [-1, -8, -1];
        tmpVBox1.Sizes = [-0.5, -1, -1, -1, -2];

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
		value = str2num(get(hObject, 'String'));
	end

	function settings = get_settings()
		settings = struct();
		
		settings.enable = get(handles.enable, 'Value');
		settings.deviceName = 'Tek5014';
		settings.Address = get(handles.gpibAddress, 'String');

		settings.scaleMode = get_selected(handles.scaleMode);
		switch settings.scaleMode
			case 'Amp/Off'
				upperField = 'Amplitude';
				lowerField = 'offset';
			case 'Hi/Lo'
				upperField = 'AnalogHigh';
				lowerField = 'AnalogLow';
			otherwise
				error('AWG5014GUI', 'Unknown scale mode');
		end
		settings.chan_1.(upperField) = get_numeric(handles.ch1amp);
		settings.chan_1.(lowerField) = get_numeric(handles.ch1off);
		settings.chan_1.Enabled = get(handles.ch1enable, 'Value');
		settings.chan_2.(upperField) = get_numeric(handles.ch2amp);
		settings.chan_2.(lowerField) = get_numeric(handles.ch2off);
		settings.chan_2.Enabled = get(handles.ch2enable, 'Value');
		settings.chan_3.(upperField) = get_numeric(handles.ch3amp);
		settings.chan_3.(lowerField) = get_numeric(handles.ch3off);
		settings.chan_3.Enabled = get(handles.ch3enable, 'Value');
		settings.chan_4.(upperField) = get_numeric(handles.ch4amp);
		settings.chan_4.(lowerField) = get_numeric(handles.ch4off);
		settings.chan_4.Enabled = get(handles.ch4enable, 'Value');
		settings.seqfile = get(handles.seqfile, 'String');
		settings.seqforce = get(handles.seqforce, 'Value');
		settings.triggerSource = get_selected(handles.triggerSource);
		settings.InternalRate = get_numeric(handles.triggerInterval);
		settings.samplingRate = get_numeric(handles.samplingRate)*10^9;
		
    end

	function set_GUI_fields(settings)
		% define default values for fields. If given a settings structure, grab
		% defaults from it
		defaults = struct();
		defaults.enable = 0;
		defaults.Address = 'GPIB0::2::INSTR';
		defaults.scaleMode = 'Amp/Off';
        for i = 1:4
            channel = ['chan_' num2str(i)];
            defaults.(channel).Amplitude = 1;
            defaults.(channel).offset = 0;
            defaults.(channel).Enabled = 1;
        end
        defaults.seqfile = 'U:\AWG\Trigger\Trigger.awg';
        defaults.seqforce = 0;
        defaults.triggerSource = 'Ext';
        defaults.InternalRate = '';
        defaults.samplingRate = 1e9;

		if ~isempty(fieldnames(settings))
			fields = fieldnames(settings);
			for i = 1:length(fields)
				name = fields{i};
				defaults.(name) = settings.(name);
			end
		end
		
		set(handles.enable, 'Value', defaults.enable);
		set(handles.gpibAddress, 'String', num2str(defaults.Address));
		set_selected(handles.scaleMode, defaults.scaleMode);
        for i = 1:4
            channel = ['chan_' num2str(i)];
            set(handles.(['ch' num2str(i) 'amp']), 'String', defaults.(channel).Amplitude);
            set(handles.(['ch' num2str(i) 'off']), 'String', defaults.(channel).offset);
            set(handles.(['ch' num2str(i) 'enable']), 'Value', defaults.(channel).Enabled);
        end
		set(handles.seqfile, 'String', defaults.seqfile);
		set(handles.seqforce, 'Value', defaults.seqforce);
		set_selected(handles.triggerSource, defaults.triggerSource);
        set(handles.triggerInterval, 'String', num2str(defaults.InternalRate));
        set(handles.samplingRate, 'String', num2str(defaults.samplingRate/1e9));
	end

end
