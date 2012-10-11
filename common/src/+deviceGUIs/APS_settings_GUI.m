function [get_settings_fcn, set_settings_fcn] = APS_settings_GUI(parent, name, settings)
%-------------------------------------------------------------------------------
% File name   : APS_settings_GUI.m
% Description : Copies from AWG5014_settings_GUI with minor modifications
%-------------------------------------------------------------------------------

pmval_to_sample_rate = [1200,600,300,100,40];
trigSourceMap = containers.Map({'External','Internal'}, {'external', 'internal'});
previousConfigFile = 'dummy';

% Initialize handles structure
handles = struct();

% if there is no parent figure given, generate one
if nargin < 1
    handles.parent = figure( ...
        'Tag', 'figure1', ...
        'Units', 'characters', ...
        'Position', [103.833333333333 13.8571428571429 90 20], ...
        'Name', 'BBN APS Settings', ...
        'MenuBar', 'none', ...
        'NumberTitle', 'off', ...
        'Color', get(0,'DefaultUicontrolBackgroundColor'));

    name = 'BBNAPS';
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
        
        tmpHBox1 = uiextras.HButtonBox('Parent', tmpVBox1, 'Spacing', 5, 'ButtonSize', [50,25]);
        uiextras.Empty('Parent', tmpHBox1);
        uicontrol('Parent', tmpHBox1, 'style', 'text', 'String', 'Ch1.');
        uicontrol('Parent', tmpHBox1, 'style', 'text', 'String', 'Ch2.');
        uicontrol('Parent', tmpHBox1, 'style', 'text', 'String', 'Ch3.');
        uicontrol('Parent', tmpHBox1, 'style', 'text', 'String', 'Ch4.');
        
        tmpHBox2 = uiextras.HButtonBox('Parent', tmpVBox1, 'Spacing', 5, 'ButtonSize', [50,25]);
        uicontrol('Parent', tmpHBox2, 'style', 'text', 'String', 'Amp.');
        handles.ch1amp = uicontrol('Parent', tmpHBox2, editBoxParams{:});
        handles.ch2amp = uicontrol('Parent', tmpHBox2, editBoxParams{:});
        handles.ch3amp = uicontrol('Parent', tmpHBox2, editBoxParams{:});
        handles.ch4amp = uicontrol('Parent', tmpHBox2, editBoxParams{:});
        
        tmpHBox3 = uiextras.HButtonBox('Parent', tmpVBox1, 'Spacing', 5, 'ButtonSize', [50,25]);
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
        
        tmpVBox2 =  uiextras.VBox('Parent', tmpHBox_top, 'Spacing', 5);
        [~, ~, handles.triggerSource] = uiextras.labeledPopUpMenu(tmpVBox2, 'Trigger Source:', 'triggerSource',  {'External','Internal'});
        [~, ~, handles.samplingRate] = uiextras.labeledPopUpMenu(tmpVBox2, 'Samp. Rate:', 'samplingRate', {'1.2 GHz'; '600 MHz'; '300 MHz'; '100 MHz'; '40 MHz'});
        [~, ~, handles.devID] = uiextras.labeledEditBox(tmpVBox2, 'Device ID:', 'devID', '');
        
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
        uiextras.Empty('Parent', tmpVBox1);
        tmpVBox1.Sizes = [-0.5, -1, -1, -1, -2];
        uiextras.Empty('Parent', tmpVBox2);
        tmpVBox2.Sizes = [-1, -1, -1, -2];
        tmpVBox_main.Sizes = [-1, -8, -1];
        
        
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
        settings.deviceName = 'APS';
        settings.Address = get(handles.devID, 'String');
        
        settings.chan_1.amplitude = get_numeric(handles.ch1amp);
        settings.chan_1.offset = get_numeric(handles.ch1off);
        settings.chan_1.enabled = get(handles.ch1enable, 'Value');
        settings.chan_2.amplitude = get_numeric(handles.ch2amp);
        settings.chan_2.offset = get_numeric(handles.ch2off);
        settings.chan_2.enabled = get(handles.ch2enable, 'Value');
        settings.chan_3.amplitude = get_numeric(handles.ch3amp);
        settings.chan_3.offset = get_numeric(handles.ch3off);
        settings.chan_3.enabled = get(handles.ch3enable, 'Value');
        settings.chan_4.amplitude = get_numeric(handles.ch4amp);
        settings.chan_4.offset = get_numeric(handles.ch4off);
        settings.chan_4.enabled = get(handles.ch4enable, 'Value');
        settings.seqfile = get(handles.seqfile, 'String');
        settings.lastseqfile = previousConfigFile;
        settings.seqforce = get(handles.seqforce, 'Value');
        settings.triggerSource = trigSourceMap(get_selected(handles.triggerSource));
        settings.samplingRate = pmval_to_sample_rate(get(handles.samplingRate, 'Value'));
        
        % save config file name
        previousConfigFile = settings.seqfile;
        
    end

    function set_GUI_fields(settings)
        % define default values for fields. If given a settings structure, grab
        % defaults from it
        defaults = struct();
        defaults.enable = 0;
        defaults.isMaster = 0;
        defaults.Address = 0;
        for i = 1:4
            channel = ['chan_' num2str(i)];
            defaults.(channel).amplitude = 1;
            defaults.(channel).offset = 0;
            defaults.(channel).enabled = 1;
        end
        defaults.seqfile = 'U:\APS\Trigger\Trigger.h5';
        defaults.seqforce = 0;
        defaults.triggerSource = 'Ext';
        defaults.samplingRate = 1200;
        
        if ~isempty(fieldnames(settings))
            fields = fieldnames(settings);
            for i = 1:length(fields)
                tmpName = fields{i};
                defaults.(tmpName) = settings.(tmpName);
            end
        end
        
        set(handles.enable, 'Value', defaults.enable);
        set(handles.isMaster, 'Value', defaults.isMaster);
        set(handles.devID, 'String', num2str(defaults.Address));
        for i = 1:4
            channel = ['chan_' num2str(i)];
            set(handles.(['ch' num2str(i) 'amp']), 'String', defaults.(channel).amplitude);
            set(handles.(['ch' num2str(i) 'off']), 'String', defaults.(channel).offset);
            set(handles.(['ch' num2str(i) 'enable']), 'Value', defaults.(channel).enabled);
        end
        set(handles.seqfile, 'String', defaults.seqfile);
        set(handles.seqforce, 'Value', defaults.seqforce);
        update_seqfile_callback()
        set_selected(handles.triggerSource, defaults.triggerSource);
        index = find(pmval_to_sample_rate == defaults.samplingRate);
        if ~isempty(index)
            set(handles.samplingRate, 'Value', index);
        end
    end

end
