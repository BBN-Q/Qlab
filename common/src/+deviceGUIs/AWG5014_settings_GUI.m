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
	name = 'TekAWG';
else
	handles.parent = parent;
end

% Create all UI controls
build_gui();

if nargin < 3
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
        
        tmpHBox0 = uiextras.HBox('Parent', tmpVBox_main, 'Spacing', 5);
        
        handles.enable = uicontrol('Parent', tmpHBox0, 'Style', 'checkbox', 'FontSize', 10, 'String', 'Enable');
        handles.isMaster = uicontrol('Parent', tmpHBox0, 'Style', 'checkbox', 'FontSize', 10, 'String', 'Master');

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

        %Setup a file system watcher for TimeDomain parameters and update
        %the offsets
        cfgFileWatcher = System.IO.FileSystemWatcher();
        cfgFileWatcher.Path = getpref('qlab','cfgDir');
        cfgFileWatcher.Filter = 'TimeDomain.json';
        cfgFileWatcher.EnableRaisingEvents = true;
        cfgFileListener = addlistener(cfgFileWatcher, 'Changed', @updateOffsets);
        set(handles.ch1off, 'DeleteFcn', @(~,~) delete(cfgFileListener));

        
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
        [~, ~, handles.triggerSource] = uiextras.labeledPopUpMenu(tmpVBox2, 'Trigger Source:', 'triggerSource',  {'External','Internal'});
        [~, ~, handles.samplingRate] = uiextras.labeledEditBox(tmpVBox2, 'Samp. Rate:', 'samplingRate', '1');
        [~, ~, handles.triggerInterval] = uiextras.labeledEditBox(tmpVBox2, 'Trigger Int. (s):', 'triggerInterval', '');
        [~, ~, handles.gpibAddress] = uiextras.labeledEditBox(tmpVBox2, 'GPIB:', 'gpibAddress', '');
        
        tmpHBox5 = uiextras.HBox('Parent', tmpVBox_main, 'Spacing', 5); 
        uicontrol('Parent', tmpHBox5, 'Style', 'text', 'String', 'Sequence File:');
        handles.seqfile = uicontrol('Parent', tmpHBox5, 'Style', 'edit', 'BackgroundColor', [1 1 1], 'Callback', @update_seqfile_callback);
        handles.seqforce = uicontrol('Parent', tmpHBox5, 'Style', 'checkbox', 'String', 'Force Reload?', 'Tag', 'seqForceBox');
        
        %Setup a file system watcher to see if the file changes and recheck
        %the sequence force checkbox
        handles.seqFileWatcher = System.IO.FileSystemWatcher();
        
        seqFileListener = addlistener(handles.seqFileWatcher, 'Changed', @(~,~) set(handles.seqforce, 'Value', true));
        %Clear the listener when the uicontrol is deleted so they don't pile up
        set(handles.seqfile, 'DeleteFcn', @(~,~) delete(seqFileListener));
        
        
        %Try and size things up
        tmpHBox5.Sizes = [-1, -3.5, -1.25];
        tmpVBox_main.Sizes = [-1, -8, -1];
        tmpVBox1.Sizes = [-0.5, -1, -1, -1, -2];

    end

    function update_seqfile_callback(~,~)
        %Point the FileSystemWatcher to the new file
        [path, fileName, ext] = fileparts(get(handles.seqfile, 'String'));
        handles.seqFileWatcher.Path = path;
        handles.seqFileWatcher.Filter = [fileName, ext];
        handles.seqFileWatcher.EnableRaisingEvents = true;
        %Update the force loader checkbox
        set(handles.seqforce, 'Value', true);
    end
    
    function updateOffsets(~,~)
        params = jsonlab.loadjson(fullfile(getpref('qlab', 'cfgDir'), 'TimeDomain.json'));
        for ct = 1:4
            channelOffset = params.InstrParams.(name).(['chan_' num2str(ct)]).offset;
            set(handles.(['ch' num2str(ct) 'off']), 'String', channelOffset);
        end
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
        settings.isMaster = get(handles.isMaster, 'Value');
		settings.deviceName = 'Tek5014';
		settings.Address = get(handles.gpibAddress, 'String');

		settings.scaleMode = get_selected(handles.scaleMode);
		switch settings.scaleMode
			case 'Amp/Off'
				upperField = 'amplitude';
				lowerField = 'offset';
			case 'Hi/Lo'
				upperField = 'analogHigh';
				lowerField = 'analogLow';
			otherwise
				error('AWG5014GUI', 'Unknown scale mode');
		end
		settings.chan_1.(upperField) = get_numeric(handles.ch1amp);
		settings.chan_1.(lowerField) = get_numeric(handles.ch1off);
		settings.chan_1.enabled = get(handles.ch1enable, 'Value');
		settings.chan_2.(upperField) = get_numeric(handles.ch2amp);
		settings.chan_2.(lowerField) = get_numeric(handles.ch2off);
		settings.chan_2.enabled = get(handles.ch2enable, 'Value');
		settings.chan_3.(upperField) = get_numeric(handles.ch3amp);
		settings.chan_3.(lowerField) = get_numeric(handles.ch3off);
		settings.chan_3.enabled = get(handles.ch3enable, 'Value');
		settings.chan_4.(upperField) = get_numeric(handles.ch4amp);
		settings.chan_4.(lowerField) = get_numeric(handles.ch4off);
		settings.chan_4.enabled = get(handles.ch4enable, 'Value');
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
        defaults.isMaster = 0;
		defaults.Address = 'GPIB0::2::INSTR';
		defaults.scaleMode = 'Amp/Off';
        for ct = 1:4
            channel = ['chan_' num2str(ct)];
            defaults.(channel).amplitude = 1;
            defaults.(channel).offset = 0;
            defaults.(channel).enabled = 1;
        end
        defaults.seqfile = 'U:\AWG\Trigger\Trigger.awg';
        defaults.seqforce = 0;
        defaults.triggerSource = 'Ext';
        defaults.InternalRate = '';
        defaults.samplingRate = 1e9;

		if ~isempty(fieldnames(settings))
			fields = fieldnames(settings);
			for ct = 1:length(fields)
				tmpName = fields{ct};
				defaults.(tmpName) = settings.(tmpName);
			end
		end
		
		set(handles.enable, 'Value', defaults.enable);
		set(handles.isMaster, 'Value', defaults.isMaster);
        set(handles.gpibAddress, 'String', num2str(defaults.Address));
		set_selected(handles.scaleMode, defaults.scaleMode);
        for ct = 1:4
            channel = ['chan_' num2str(ct)];
            set(handles.(['ch' num2str(ct) 'amp']), 'String', defaults.(channel).amplitude);
            set(handles.(['ch' num2str(ct) 'off']), 'String', defaults.(channel).offset);
            set(handles.(['ch' num2str(ct) 'enable']), 'Value', defaults.(channel).enabled);
        end
		set(handles.seqfile, 'String', defaults.seqfile);
        update_seqfile_callback()
		set(handles.seqforce, 'Value', defaults.seqforce);
		set_selected(handles.triggerSource, defaults.triggerSource);
        set(handles.triggerInterval, 'String', num2str(defaults.InternalRate));
        set(handles.samplingRate, 'String', num2str(defaults.samplingRate/1e9));
	end

end
