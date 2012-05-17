function settings_fcn = digitalHomodyne_GUI(parent, settings)
% DIGITALHOMODYNE_BUILD
%-------------------------------------------------------------------------------
% File name   : digitalHomodyne_build.m       
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
			'Name', 'Digital Homodyne', ...
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

	    handles.mainPanel = uiextras.Panel('Parent', handles.parent, 'Title', 'Digital Homodyne', 'Padding', 5 , 'FontSize',11);

        tmpVBox = uiextras.VBox('Parent', handles.mainPanel, 'Spacing', 2);

        tmpHBox1 = uiextras.HButtonBox('Parent', tmpVBox, 'Spacing', 5, 'VerticalAlignment', 'bottom');
        textParams = {'Parent', tmpHBox1, 'Style', 'text', 'FontSize', 10};
        uicontrol(textParams{:}, 'String', 'Mode');
        uicontrol(textParams{:}, 'String', 'IF Freq (MHz)');
        uicontrol(textParams{:}, 'String', 'Phase');
        
        tmpHBox2 = uiextras.HButtonBox('Parent', tmpVBox, 'Spacing', 5, 'VerticalAlignment', 'top');
        editParams = {'Parent', tmpHBox2, 'Style', 'edit', 'BackgroundColor', [1, 1, 1], 'FontSize', 10};
        handles.DHmode = uicontrol('Parent', tmpHBox2, 'Style', 'popupmenu', 'BackgroundColor', [1,1,1], 'FontSize', 10, 'String',  {'OFF', 'DH1', 'DIQ'});
        handles.IFfreq = uicontrol(editParams{:}, 'String', 10);
        handles.phase = uicontrol(editParams{:}, 'String', 0.001);
        
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
		
		settings.DHmode = get_selected(handles.DHmode);
		settings.IFfreq = get_numeric(handles.IFfreq);
		settings.phase = get_numeric(handles.phase);
    end

    function set_defaults(settings)
		% define default values for fields. If given a settings structure, grab
		% defaults from it
		defaults.DHmode = 'DH1';
        defaults.IFfreq = 1;
        defaults.phase = 0;

		if ~isempty(fieldnames(settings))
			fields = fieldnames(settings);
			for i = 1:length(fields)
				name = fields{i};
				defaults.(name) = settings.(name);
			end
		end
		
		set_selected(handles.DHmode, defaults.DHmode);
		set(handles.IFfreq, 'String', num2str(defaults.IFfreq));
        set(handles.phase, 'String', num2str(defaults.phase));

	end

end
