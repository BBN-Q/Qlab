function settings_fcn = FrequencySweepGUI(parent, name, prevSettings)
% FREQUENCYSWEEP_BUILD
%-------------------------------------------------------------------------------
% File name   : FrequencySweep_build.m        
% Generated on: 15-Oct-2010 15:05:05          
% Description :
%-------------------------------------------------------------------------------


% Initialize handles structure
handles = struct();


% if there is no parent figure given, generate one
if nargin < 1 
	handles.parent = figure( ...
			'Tag', 'figure1', ...
			'Units', 'characters', ...
			'Position', [103.833333333333 13.8571428571429 78 12], ...
			'Name', 'Frequency Settings', ...
			'MenuBar', 'none', ...
			'NumberTitle', 'off', ...
			'Color', get(0,'DefaultUicontrolBackgroundColor'));

	name = ['Frequency settings'];
else
	handles.parent = parent;
	name = ['Frequency settings ' name];
end

if nargin < 3
    prevSettings = struct();
    prevSettings.start = 0;
    prevSettings.stop = 0;
    prevSettings.step = 0;
    prevSettings.genID = 'RFgen';
end
    

% Create all UI controls
build_gui();

% Assign function output
settings_fcn = @get_settings;

%% ---------------------------------------------------------------------------
	function build_gui()
        % Creation of all uicontrols

        handles.mainPanel = uiextras.Panel('Parent', handles.parent, 'Title', name, 'Padding', 5 , 'FontSize',11);

        tmpVBox = uiextras.VBox('Parent', handles.mainPanel, 'Spacing', 2);
        tmpHBox1 =  uiextras.HBox('Parent', tmpVBox, 'Spacing', 5);
        [~, ~, handles.genID] = uiextras.labeledPopUpMenu(tmpHBox1, 'Generator:', 'genID',  {'RF','LO','Spec','Spec2'});
        set(handles.genID, 'Value', find(strcmp(prevSettings.genID(1:end-3), get(handles.genID,'String'))));
        uiextras.Empty('Parent', tmpHBox1);
        tmpHBox2 = uiextras.HButtonBox('Parent', tmpVBox, 'Spacing', 5, 'VerticalAlignment', 'bottom');
        textParams = {'Parent', tmpHBox2, 'Style', 'text', 'FontSize', 10};
        uicontrol(textParams{:}, 'String', 'Start');
        uicontrol(textParams{:}, 'String', 'Stop');
        uicontrol(textParams{:}, 'String', 'Step');
        
        tmpHBox3 = uiextras.HButtonBox('Parent', tmpVBox, 'Spacing', 5, 'VerticalAlignment', 'top');
        editParams = {'Parent', tmpHBox3, 'Style', 'edit', 'BackgroundColor', [1, 1, 1], 'FontSize', 10};
        handles.startFreq = uicontrol(editParams{:}, 'String', prevSettings.start);
        handles.stopFreq = uicontrol(editParams{:}, 'String', prevSettings.stop);
        handles.stepFreq = uicontrol(editParams{:}, 'String', prevSettings.step);
        
        %Try and patch up the sizing
        tmpVBox.Sizes = [-1.5, -1, -1];

	end

	function selected = get_selected(hObject)
		menu = get(hObject,'String');
		selected = menu{get(hObject,'Value')};
	end

	function value = get_numeric(hObject)
		value = str2num(get(hObject, 'String'));
	end

	function settings = get_settings()
		settings = struct();
		
		settings.type = 'sweeps.Frequency';
		settings.start = get_numeric(handles.startFreq);
		settings.stop = get_numeric(handles.stopFreq);
		settings.step = get_numeric(handles.stepFreq);
		settings.genID = [get_selected(handles.genID) 'gen'];
	end

end
