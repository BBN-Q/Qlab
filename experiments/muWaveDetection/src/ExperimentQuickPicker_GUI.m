function ExperimentQuickPicker_GUI(parent, GUIgetters, GUIsetters)

% Initialize handles structure
handles = struct();

% if there is no parent figure given, generate one
if nargin < 1 
	handles.parent = figure( ...
			'Tag', 'figure1', ...
			'Units', 'characters', ...
			'Position', [103.833333333333 13.8571428571429 64 12], ...
			'Name', 'Experiment QuickPick', ...
			'MenuBar', 'none', ...
			'NumberTitle', 'off', ...
			'Color', get(0,'DefaultUicontrolBackgroundColor'));
else
	handles.parent = parent;
end

%Load the experiments from the json cfg file
expParams = struct();

% Create all UI controls
build_gui();

loadJSON();


%% ---------------------------------------------------------------------------
	function build_gui()
% Creation of all uicontrols

	    handles.mainPanel = uiextras.Panel('Parent', handles.parent, 'Title', 'Experiment Quick Picker', 'Padding', 5 , 'FontSize',11);

        tmpVBox = uiextras.VBox('Parent', handles.mainPanel, 'Spacing', 2);

        tmpHBox1 = uiextras.HButtonBox('Parent', tmpVBox, 'Spacing', 5, 'VerticalAlignment', 'bottom');
        textParams = {'Parent', tmpHBox1, 'Style', 'text', 'FontSize', 10};
        uicontrol(textParams{:}, 'String', 'Experiment');
        uiextras.Empty('Parent', tmpHBox1);
        
        tmpHBox2 = uiextras.HButtonBox('Parent', tmpVBox, 'Spacing', 5, 'VerticalAlignment', 'top');
        popUpParams = {'Parent', tmpHBox2, 'Style', 'popupmenu', 'BackgroundColor', [1, 1, 1], 'FontSize', 10, 'Callback', @updateFields, 'String', {''}};
        handles.expDropDown = uicontrol(popUpParams{:});
        uicontrol('Parent', tmpHBox2, 'Style', 'pushbutton','String', 'Reload', 'Callback', @loadJSON);
                
        %Try and patch up the sizing
        tmpVBox.Sizes = [-1, -1];

        
           
    end

    function loadJSON(~,~)
        try
            expParams = jsonlab.loadjson(getpref('qlab', 'ExpQuickPickFile'));
            set(handles.expDropDown, 'String', fieldnames(expParams));
        catch me
            warning('Could not find expQuickPick preference');
        end
    end
    
    function updateFields(~,~)
        %Get the current values
        expNames = get(handles.expDropDown,'String');
        expName = expNames{get(handles.expDropDown,'Value')};
 
        %Update the sequence files for the Tek and APS's
        %Get the current Tek5104 settings
        TekSettings_fcn = GUIgetters('TekAWG');
        TekSettings = TekSettings_fcn();
        TekSettings.seqfile = fullfile(expParams.networkDrive, 'AWG', expParams.(expName).baseName, [expParams.(expName).baseName '-TekAWG.awg']);
        tmpSettings_fcn = GUIsetters('TekAWG');
        tmpSettings_fcn(TekSettings)
        
        %Get the current APS settings
        numAPSs = sum(strncmp('BBNAPS', GUIgetters.keys(), 6));
        for APSct = 1:numAPSs
            devName = sprintf('BBNAPS%d',APSct);
            APSSettings_fcn = GUIgetters(devName);
            APSSettings = APSSettings_fcn();
            APSSettings.seqfile = fullfile(expParams.networkDrive, 'AWG', expParams.(expName).baseName, [expParams.(expName).baseName, '-' devName, '.h5']);
            tmpSettings_fcn = GUIsetters(devName);
            tmpSettings_fcn(APSSettings)
        end
        
        %Update the number of segments
        digitizerSettings_fcn = GUIgetters('digitizer');
        digitizerSettings = digitizerSettings_fcn();
        digitizerSettings.averager.nbrSegments = expParams.(expName).nbrSegments;
        tmpSettings_fcn = GUIsetters('digitizer');
        tmpSettings_fcn(digitizerSettings);
        
        %Update the x-axis settings
        xaxisSettings_fcn = GUIgetters('xaxis');
        xaxisSettings = xaxisSettings_fcn();
        xaxisSettings.start = expParams.(expName).xaxis.start;
        xaxisSettings.step = expParams.(expName).xaxis.step;
        tmpSettings_fcn = GUIsetters('xaxis');
        tmpSettings_fcn(xaxisSettings);
        
        %Update the experiment name
        set(GUIsetters('exptBox'),'String',expParams.(expName).expName);
        
    end    

end