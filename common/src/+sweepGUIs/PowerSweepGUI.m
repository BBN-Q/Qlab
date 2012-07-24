function settings_fcn = PowerSweepGUI(parent, name)
% POWERSWEEP_BUILD
%-------------------------------------------------------------------------------
% File name   : PowerSweep_build.m            
% Generated on: 15-Oct-2010 15:06:37          
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
			'Name', 'Power Settings', ...
			'MenuBar', 'none', ...
			'NumberTitle', 'off', ...
			'Color', get(0,'DefaultUicontrolBackgroundColor'));
	
	name = ['Power settomgs'];
else
	handles.parent = parent;
	name = ['Power settings ' name];
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
        [~, ~, handles.powerUnits] = uiextras.labeledPopUpMenu(tmpHBox1, 'Units:', 'powerUnits',  {'dBm', 'mW'});
        uiextras.Empty('Parent', tmpHBox1);
        tmpHBox1.Sizes =  [-2, -2, -1];
        tmpHBox2 = uiextras.HButtonBox('Parent', tmpVBox, 'Spacing', 5, 'VerticalAlignment', 'bottom');
        textParams = {'Parent', tmpHBox2, 'Style', 'text', 'FontSize', 10};
        uicontrol(textParams{:}, 'String', 'Start');
        uicontrol(textParams{:}, 'String', 'Stop');
        uicontrol(textParams{:}, 'String', 'Step');
        
        tmpHBox3 = uiextras.HButtonBox('Parent', tmpVBox, 'Spacing', 5, 'VerticalAlignment', 'top');
        editParams = {'Parent', tmpHBox3, 'Style', 'edit', 'BackgroundColor', [1, 1, 1], 'FontSize', 10};
        handles.powStart = uicontrol(editParams{:}, 'String', -50);
        handles.powStop = uicontrol(editParams{:}, 'String', -50);
        handles.powStep = uicontrol(editParams{:}, 'String', 1);
        
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
		
		settings.type = 'sweeps.Power';
		settings.start = get_numeric(handles.powStart);
		settings.stop = get_numeric(handles.powStop);
		settings.step = get_numeric(handles.powStep);
		settings.units = get_selected(handles.powerUnits);
		settings.genID = [get_selected(handles.genID) 'gen'];
	end

end
