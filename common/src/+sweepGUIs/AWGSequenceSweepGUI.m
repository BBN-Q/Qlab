function [get_settings_fcn, set_settings_fcn] = AWGSequenceSweepGUI(parent, name)

% Initialize handles structure
handles = struct();

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
	name = ['AWG Sequence'];
else
	handles.parent = parent;
	name = ['AWG Sequence ' name];
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

        tmpHBox1 = uiextras.HButtonBox('Parent', tmpVBox, 'Spacing', 5, 'VerticalAlignment', 'bottom');
        textParams = {'Parent', tmpHBox1, 'Style', 'text', 'FontSize', 10};
        uicontrol(textParams{:}, 'String', 'Start');
        uicontrol(textParams{:}, 'String', 'Stop');
        uicontrol(textParams{:}, 'String', 'File Name');
        
        tmpHBox2 = uiextras.HButtonBox('Parent', tmpVBox, 'Spacing', 5, 'VerticalAlignment', 'top');
        editParams = {'Parent', tmpHBox2, 'Style', 'edit', 'BackgroundColor', [1, 1, 1], 'FontSize', 10};
        handles.start = uicontrol(editParams{:}, 'String', 1);
        handles.stop = uicontrol(editParams{:}, 'String', 1);
        handles.sequenceFile = uicontrol(editParams{:}, 'String', '\RB\RBTekAWG12_');
        
        %Try and patch up the sizing
        tmpVBox.Sizes = [-1, -1];


    end

    function value = get_numeric(hObject)
		value = str2double(get(hObject, 'String'));
	end

	function settings = get_settings()
		settings = struct();
		
		settings.type = 'sweeps.AWGSequence';
		settings.start = get_numeric(handles.start);
		settings.stop = get_numeric(handles.stop);
        settings.step = 1;
        settings.sequenceFile =  get(handles.sequenceFile, 'String');
    end

    function set_GUI_fields(settings)
        
        defaults.type = 'sweeps.AWGSequence';
        defaults.start = 1;
        defaults.step = 1;
        defaults.stop = 1;
        defaults.sequenceFile = '\';
        
        if ~isempty(fieldnames(settings))
			fields = fieldnames(settings);
			for i = 1:length(fields)
				name = fields{i};
				defaults.(name) = settings.(name);
			end
        end
        
        set(handles.start,'String',num2str(defaults.start));
        set(handles.stop,'String',num2str(defaults.stop));
        set(handles.sequenceFile, 'String', defaults.sequenceFile);
    end

end
