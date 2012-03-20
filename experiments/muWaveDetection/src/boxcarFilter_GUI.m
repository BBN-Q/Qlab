function settings_fcn = boxcarFilter_GUI(parent, settings)
%-------------------------------------------------------------------------------
% File name   : boxcarFilter_GUI.m       
% Generated on: 07-Oct-2010 16:13:57          
% Description :
%-------------------------------------------------------------------------------


% Initialize handles structure
handles = struct();

% if there is no parent figure given, generate one
if nargin < 1
	handles.parent = figure( ...
			'Tag', 'figure1', ...
			'Units', 'characters', ...
			'Position', [103.833333333333 13.8571428571429 64 12], ...
			'Name', 'Boxcar Filter', ...
			'MenuBar', 'none', ...
			'NumberTitle', 'off', ...
			'Color', get(0,'DefaultUicontrolBackgroundColor'));
	
else
	handles.parent = parent;
end

% Create all UI controls
build_gui();

if nargin < 2
	settings = struct();
end
set_defaults(settings);

% Assign function output
settings_fcn = @get_settings;

%% ---------------------------------------------------------------------------
	function build_gui()
% Creation of all uicontrols

        handles.mainPanel = uiextras.Panel('Parent', handles.parent, 'Title', 'Boxcar Filter', 'Padding', 5 , 'FontSize',11);

        tmpVBox = uiextras.VBox('Parent', handles.mainPanel, 'Spacing', 2);

        tmpHBox1 = uiextras.HButtonBox('Parent', tmpVBox, 'Spacing', 5, 'VerticalAlignment', 'bottom');
        textParams = {'Parent', tmpHBox1, 'Style', 'text', 'FontSize', 10};
        uicontrol(textParams{:}, 'String', '# of Pulses');
        uicontrol(textParams{:}, 'String', 'Start');
        uicontrol(textParams{:}, 'String', 'Length');
        
        tmpHBox2 = uiextras.HButtonBox('Parent', tmpVBox, 'Spacing', 5, 'VerticalAlignment', 'top');
        editParams = {'Parent', tmpHBox2, 'Style', 'edit', 'BackgroundColor', [1, 1, 1], 'FontSize', 10};
        handles.number = uicontrol(editParams{:}, 'String', 1);
        handles.start = uicontrol(editParams{:});
        handles.length = uicontrol(editParams{:});
        
        %Try and patch up the sizing
        tmpVBox.Sizes = [-1, -1];

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
		
		settings.number = get_numeric(handles.number);
		settings.start = get_numeric(handles.start);
		settings.length = get_numeric(handles.length);
    end

    function set_defaults(settings)
		% define default values for fields. If given a settings structure, grab
		% defaults from it
		defaults.number = 1;
        defaults.start = '';
        defaults.length = '';

		if ~isempty(fieldnames(settings))
			fields = fieldnames(settings);
			for i = 1:length(fields)
				name = fields{i};
				defaults.(name) = settings.(name);
			end
		end
		
		set(handles.number, 'String', num2str(defaults.number));
		set(handles.start, 'String', num2str(defaults.start));
        set(handles.length, 'String', num2str(defaults.length));

	end

end
