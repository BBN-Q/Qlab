function [get_settings_fcn, set_settings_fcn] = AWGChannelSweepGUI(parent, name)

% Initialize handles structure
handles = struct();

AWGNameList = {'TekAWG','BBNAPS'};
ChannelList = {'1', '2', '3', '4', '1&2', '3&4'};
ModeList = {'Amp', 'Offset'};

% if there is no parent figure given, generate one
if nargin < 1 
	handles.parent = figure( ...
			'Tag', 'figure1', ...
			'Units', 'characters', ...
			'Position', [103.833333333333 13.8571428571429 85 12], ...
			'Name', 'Time settings', ...
			'MenuBar', 'none', ...
			'NumberTitle', 'off', ...
			'Color', get(0,'DefaultUicontrolBackgroundColor'));
	name = ['AWG Channel'];
else
	handles.parent = parent;
	name = ['AWG Channel ' name];
end

% Create all UI controls
build_gui();

settings = struct();
set_GUI_fields(settings);

% Assign function handles output
get_settings_fcn = @get_settings;
set_settings_fcn = @set_GUI_fields;

%% ---------------------------------------------------------------------------
	function build_gui()
% Creation of all uicontrols

	    handles.mainPanel = uiextras.Panel('Parent', handles.parent, 'Title', name, 'Padding', 5 , 'FontSize',11);

        tmpVBox = uiextras.VBox('Parent', handles.mainPanel, 'Spacing', 2);
        
        tmpHBox1 = uiextras.HButtonBox('Parent', tmpVBox, 'Spacing', 5);
        textParams = {'Parent', tmpHBox1, 'Style', 'text', 'FontSize', 10};
        popupParams = {'Parent', tmpHBox1, 'Style', 'popupmenu', 'BackgroundColor', [1, 1, 1], 'FontSize', 10};
        uicontrol(textParams{:}, 'String', 'AWG');
        handles.AWGName = uicontrol(popupParams{:}, 'String', AWGNameList);
        uicontrol(textParams{:}, 'String', 'Channel(s)');
        handles.channels = uicontrol(popupParams{:}, 'String', ChannelList);
        uicontrol(textParams{:}, 'String', 'Mode');
        handles.mode = uicontrol(popupParams{:}, 'String', ModeList);

        tmpHBox2 = uiextras.HButtonBox('Parent', tmpVBox, 'Spacing', 5, 'VerticalAlignment', 'bottom');
        textParams = {'Parent', tmpHBox2, 'Style', 'text', 'FontSize', 10};
        uicontrol(textParams{:}, 'String', 'Start');
        uicontrol(textParams{:}, 'String', 'Stop');
        uicontrol(textParams{:}, 'String', 'Step');
        
        tmpHBox3 = uiextras.HButtonBox('Parent', tmpVBox, 'Spacing', 5, 'VerticalAlignment', 'top');
        editParams = {'Parent', tmpHBox3, 'Style', 'edit', 'BackgroundColor', [1, 1, 1], 'FontSize', 10};
        handles.start = uicontrol(editParams{:}, 'String', 0);
        handles.stop = uicontrol(editParams{:}, 'String', 1);
        handles.step = uicontrol(editParams{:}, 'String', 1);
        
        %Try and patch up the sizing
        tmpVBox.Sizes = [-1.5, -1, -1];


    end

    function value = get_numeric(hObject)
		value = str2double(get(hObject, 'String'));
	end

	function settings = get_settings()
		settings = struct();
		
		settings.type = 'sweeps.AWGChannel';
		settings.start = get_numeric(handles.start);
		settings.stop = get_numeric(handles.stop);
        settings.step = get_numeric(handles.step);
        settings.channel =  ChannelList{get(handles.channels, 'Value')};
        settings.AWGName = AWGNameList{get(handles.AWGName,'Value')};
        settings.mode = ModeList{get(handles.mode, 'Value')};
    end

    function set_selected(hObject, strValue)
        menu = get(hObject, 'String');
        set(hObject, 'Value', find(strcmp(strValue, menu)));
    end

    function set_GUI_fields(settings)
        
        defaults.type = 'sweeps.AWGChannel';
        defaults.start = 0;
        defaults.step = 1;
        defaults.stop = 1;
        defaults.channel = '1';
        defaults.AWGName = 'TekAWG';
        defaults.mode = 'Amp';
        
        if ~isempty(fieldnames(settings))
			fields = fieldnames(settings);
			for i = 1:length(fields)
				name = fields{i};
				defaults.(name) = settings.(name);
			end
        end
        
        set(handles.start,'String',num2str(defaults.start));
        set(handles.stop,'String',num2str(defaults.stop));
        set(handles.step,'String',num2str(defaults.step));
        set_selected(handles.channels, defaults.channel);
        set_selected(handles.AWGName, defaults.AWGName);
        set_selected(handles.mode, defaults.mode);
    end

end
