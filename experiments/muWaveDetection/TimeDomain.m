%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Module Name :  TimeDomain.m
 %
 % Author/Date : Blake Johnson / October 19, 2010
 %
 % Description : A GUI sweeper for homodyneDetection2D.
 %
 % Version: 2.0
 %
 %    Modified    By    Reason
 %    --------    --    ------
 %    March 2012  Colm Ryan: Refactored to proper GUI layouts.
 %
 % Copyright 2010,2012 Raytheon BBN Technologies
 %
 % Licensed under the Apache License, Version 2.0 (the "License");
 % you may not use this file except in compliance with the License.
 % You may obtain a copy of the License at
 %
 %     http://www.apache.org/licenses/LICENSE-2.0
 %
 % Unless required by applicable law or agreed to in writing, software
 % distributed under the License is distributed on an "AS IS" BASIS,
 % WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 % See the License for the specific language governing permissions and
 % limitations under the License.
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function status = TimeDomain(cfg_file_name)
% This script will execute a time domain (2D) experiment using the
% default parameters found in the cfg file or specified using the GUI.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%     CLEAR      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% close open instruments
temp = instrfind;
if ~isempty(temp)
    fclose(temp);
    delete(temp)
end
clear temp;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%     BASIC INPUTS      %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% base_path is up two levels from this file
[base_path] = fileparts(mfilename('fullpath'));
base_path = parent_dir(base_path, 2);

data_path = [base_path '/experiments/muWaveDetection/data/'];
cfg_path = [base_path '/experiments/muWaveDetection/cfg/'];
basename = 'TimeDomain';

if nargin < 1
	cfg_file_name = [cfg_path 'TimeDomain.cfg'];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%     INITIALIZE PATH     %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%restoredefaultpath
addpath([ base_path '/experiments/muWaveDetection/'],'-END');
addpath([ base_path '/common/src'],'-END');
addpath([ base_path '/experiments/muWaveDetection/src'],'-END');
addpath([ base_path '/common/src/util/'],'-END');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%     CREATE GUI     %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

mainWindow = figure( ...
	'Tag', 'figure1', ...
	'Units', 'pixels', ...
	'Position', [25 25 1300 700], ...
	'Name', 'TimeDomain', ...
	'MenuBar', 'none', ...
	'NumberTitle', 'off', ...
	'Visible', 'off',...
    'KeyPressFcn', @keyPress);

% list of instruments expected in the settings structs
instrumentNames = {'scope', 'RFgen', 'LOgen', 'Specgen', 'Spec2gen', 'Spec3gen', 'TekAWG', 'BBNAPS'};
% load previous settings structs
[commonSettings, prevSettings] = get_previous_settings('TimeDomain', cfg_path, instrumentNames);

%Add a grid layout for all the controls
mainGrid = uiextras.Grid('Parent', mainWindow, 'Spacing', 20, 'Padding', 10);

%Add the digitizer panel
leftVBox = uiextras.VBox('Parent', mainGrid, 'Spacing', 10);
[get_digitizer_settings, set_digitizer_settings] = deviceGUIs.digitizer_settings_gui(leftVBox, prevSettings.InstrParams.scope);

%Add the Run/Stop buttons and scope checkbox
tmpHBox = uiextras.HButtonBox('Parent', leftVBox, 'ButtonSize', [120, 40]);
runButton = uicontrol('Parent', tmpHBox, 'Style', 'pushbutton', 'String', 'Run', 'FontSize', 10, 'Callback', @run_callback);
stopButton = uicontrol('Parent', tmpHBox, 'Style', 'pushbutton', 'String', 'Stop', 'FontSize', 10, 'Callback', @(~,~)warndlg('Oops, Not implemented yet') );
scopeButton = uicontrol('Parent', tmpHBox, 'Style', 'checkbox', 'FontSize', 10, 'String', 'Scope:'); 

leftVBox.Sizes = [-4,-1];

%Add the microwave sources
middleVBox = uiextras.VBox('Parent', mainGrid, 'Spacing', 10);
sourcePanel = uiextras.Panel('Parent', middleVBox, 'Title', 'Microwave Sources','FontSize',12, 'Padding', 5);
sourceTabPanel = uiextras.TabPanel('Parent', sourcePanel, 'Padding', 5, 'HighlightColor', 'k');
get_rf_settings = deviceGUIs.uW_source_settings_GUI(sourceTabPanel,'RF', prevSettings.InstrParams.RFgen);
get_lo_settings = deviceGUIs.uW_source_settings_GUI(sourceTabPanel, 'LO', prevSettings.InstrParams.LOgen);
get_spec_settings = deviceGUIs.uW_source_settings_GUI(sourceTabPanel, 'Spec', prevSettings.InstrParams.Specgen);
get_spec2_settings = deviceGUIs.uW_source_settings_GUI(sourceTabPanel, 'Spec2', prevSettings.InstrParams.Spec2gen);
get_spec3_settings = deviceGUIs.uW_source_settings_GUI(sourceTabPanel, 'Spec3', prevSettings.InstrParams.Spec3gen);
sourceTabPanel.TabNames = {'RF','LO','Spec','Spec2','Spec3'};
sourceTabPanel.SelectedChild = 1;

%Add the AWG's
AWGPanel = uiextras.Panel('Parent', middleVBox, 'Title', 'AWG''s','FontSize',12, 'Padding', 5);
AWGTabPanel = uiextras.TabPanel('Parent', AWGPanel, 'Padding', 5, 'HighlightColor', 'k');
[get_tekAWG_settings, set_tekAWG_GUI] = deviceGUIs.AWG5014_settings_GUI(AWGTabPanel, 'TekAWG', prevSettings.InstrParams.TekAWG);
[get_APS_settings, set_APS_settings] = deviceGUIs.APS_settings_GUI(AWGTabPanel, 'BBN APS', prevSettings.InstrParams.BBNAPS);
AWGTabPanel.TabNames = {'Tektronix','APS'};
AWGTabPanel.SelectedChild = 1;

%Add the Sweeps's
rightVBox = uiextras.VBox('Parent', mainGrid, 'Spacing', 10);
SweepPanel = uiextras.Panel('Parent', rightVBox, 'Title', 'Sweeps','FontSize',12, 'Padding', 5);
SweepTabPanel = uiextras.TabPanel('Parent', SweepPanel, 'Padding', 5, 'HighlightColor', 'k');
get_freqA_settings = sweepGUIs.FrequencySweepGUI(SweepTabPanel, 'A');
get_power_settings = sweepGUIs.PowerSweepGUI(SweepTabPanel, '');
get_phase_settings = sweepGUIs.PhaseSweepGUI(SweepTabPanel, '');
[get_time_settings, set_time_settings] = sweepGUIs.TimeSweepGUI(SweepTabPanel, '');


SweepTabPanel.TabNames = {'Freq. A', 'Power', 'Phase', 'X-Axis'};
SweepTabPanel.SelectedChild = 1;

% Add the measurement settings panels
MeasurementPanel = uiextras.Panel('Parent', rightVBox, 'Title', 'Measurement Processing','FontSize',12, 'Padding', 5);
measPanelVBox = uiextras.VBox('Parent', MeasurementPanel, 'Spacing', 5);
get_digitalHomodyne_settings = digitalHomodyne_GUI(measPanelVBox, prevSettings.ExpParams.digitalHomodyne);
get_boxcarFilter_settings = boxcarFilter_GUI(measPanelVBox, prevSettings.ExpParams.filter);

%Add some of the experiment setup buttons in a panel
ExpSetupPanel = uiextras.Panel('Parent', rightVBox, 'Title', 'Experiment Setup','FontSize',12, 'Padding', 5);
ExpSetupVBox = uiextras.VBox('Parent', ExpSetupPanel, 'Spacing', 5);

%Add sweep/loop selector
tmpGrid = uiextras.Grid('Parent', ExpSetupVBox, 'Spacing', 5);
[~, ~, fastLoop] = uiextras.labeledPopUpMenu(tmpGrid, 'Fast Loop:', 'fastloop',  {'frequencyA', 'power', 'phase', 'dc', 'TekCh', 'CrossDriveTuneUp', 'Repeat', 'nothing'});
[~, ~, softAvgs] = uiextras.labeledEditBox(tmpGrid, 'Soft Averages:', 'softAvgs', '1');
[~, ~, deviceNameHandle] = uiextras.labeledEditBox(tmpGrid, 'Device Name:', 'deviceName', '');
[~, ~, exptBox] = uiextras.labeledEditBox(tmpGrid, 'Experiment:', 'expName', '');
set(tmpGrid, 'RowSizes', [-1,-1], 'ColumnSizes', [-1, -1]);

tmpHBox = uiextras.HBox('Parent',ExpSetupVBox);
[~, ~, fileNum] = uiextras.labeledEditBox(tmpHBox, 'File Number:', 'fileNum', '001');
tmpButtonBox = uiextras.HButtonBox('Parent', tmpHBox);
uicontrol('Parent', tmpButtonBox, 'Style', 'pushbutton', 'String', 'Reset', 'Callback', @(~,~)warndlg('Oops, Not implemented yet'));

tmpHBox = uiextras.HBox('Parent',ExpSetupVBox, 'Spacing', 5);
uicontrol('Parent', tmpHBox, 'Style', 'text', 'String', 'Data Path:', 'FontSize', 10);
uicontrol('Parent', tmpHBox, 'Style', 'edit', 'BackgroundColor', [1,1,1], 'Max', 2, 'Min', 0);
tmpButtonBox = uiextras.HButtonBox('Parent', tmpHBox);
uicontrol('Parent', tmpButtonBox, 'Style', 'pushbutton', 'String', 'Choose', 'Callback', @(~,~)warndlg('Oops, Not implemented yet'));
uicontrol('Parent', tmpButtonBox, 'Style', 'pushbutton', 'String', 'Today', 'Callback', @(~,~)warndlg('Oops, Not implemented yet'));
tmpHBox.Sizes = [-1, -2, -1];

%Add the experiment quick picker
GUIgetters = containers.Map();
GUIgetters('TekAWG') = get_tekAWG_settings;
GUIgetters('BBNAPS') = get_APS_settings;
GUIgetters('digitizer') = get_digitizer_settings;
GUIgetters('xaxis') = get_time_settings;
GUIsetters = containers.Map();
GUIsetters('TekAWG') = set_tekAWG_GUI;
GUIsetters('BBNAPS') = set_APS_settings;
GUIsetters('digitizer') = set_digitizer_settings;
GUIsetters('xaxis') = set_time_settings;
GUIsetters('exptBox') = exptBox;

ExperimentQuickPicker_GUI(ExpSetupVBox, GUIgetters, GUIsetters);

ExpSetupVBox.Sizes = [-2, -1, -1, -3];


%Setup the file counter and initialize the field
global counter;
if ~isa(counter, 'Counter')
    initial_counter_value = 1;
    if isfield(commonSettings, 'counter')
        initial_counter_value = commonSettings.counter + 1;
    end
    counter = Counter(initial_counter_value);
end


%Try and patch up the sizing
uiextras.Empty('Parent', rightVBox);
rightVBox.Sizes = [-1, -1.25, -1.75, -.1];
set(mainGrid, 'RowSizes', -1, 'ColumnSizes', [-1.05 -1.2, -1]);
        
% 
% % add DC sources
% get_DCsource_settings = deviceGUIs.DCBias_settings_GUI(mainWindow, 240, 775, prevSettings.InstrParams.BBNdc);
% 
% 
% get_dc_settings = sweepGUIs.DCSweepGUI(DCtab, 5, 2, '');
% get_tekChannel_settings = sweepGUIs.TekChannelSweepGUI(TekChtab, 5, 2, '');
% 
% 
% % add path and file controls\
% %Crude hack to pull out a handle to the experiment editbox.
% [get_path_and_file, exptBox] = path_and_file_controls(mainWindow, [910 525], commonSettings, prevSettings);


%Now that everything is setup draw the window
drawnow;
set(mainWindow, 'Visible', 'on');

% add run callback

	function run_callback(~, ~)

		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		%%%%%%%%%%%%%%%%%%%%%%%     WRITE CONFIG     %%%%%%%%%%%%%%%%%%%%%%%%%%%
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

		% construct settings cluster
		settings = struct();
		
		% get instrument settings
		settings.InstrParams.scope = get_digitizer_settings();
		settings.InstrParams.RFgen = get_rf_settings();
		settings.InstrParams.LOgen = get_lo_settings();
		settings.InstrParams.Specgen = get_spec_settings();
        settings.InstrParams.Spec2gen = get_spec2_settings();
        settings.InstrParams.Spec3gen = get_spec3_settings();
		settings.InstrParams.TekAWG = get_tekAWG_settings();
        settings.InstrParams.BBNAPS = get_APS_settings();
		
		% get sweep settings
		settings.SweepParams.frequencyA = get_freqA_settings();
		settings.SweepParams.power = get_power_settings();
		settings.SweepParams.phase = get_phase_settings();
% 		settings.SweepParams.dc = get_dc_settings();
        settings.SweepParams.time = get_time_settings();
%         settings.SweepParams.TekCh = get_tekChannel_settings();
  
        %%%%%%%%%%%%%%%%%%%%%%% Hacked-in sweeps %%%%%%%%%%%%%%%%%%%%%%%%%%
        settings.SweepParams.CrossDriveTuneUp = struct('type', 'sweeps.CrossDriveTuneUp');
        settings.SweepParams.Repeat = struct('type', 'sweeps.Repeat', 'stop', 20);
		% add 'nothing' sweep
		settings.SweepParams.nothing = struct('type', 'sweeps.Nothing');
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        
        % time is always sweep number 1
        % label fast loop as sweep 2
        settings.SweepParams.time.number = 1;
        if ~strcmp(get_selected(fastLoop), 'Nothing')
            settings.SweepParams.(get_selected(fastLoop)).number = 2;
        end
		
		% get other experiment settings
		settings.ExpParams.digitalHomodyne = get_digitalHomodyne_settings();
        settings.ExpParams.filter = get_boxcarFilter_settings();
        settings.ExpParams.softAvgs = str2double(get(softAvgs, 'String'));
		settings.displayScope = get(scopeButton, 'Value');
		settings.SoftwareDevelopmentMode = 0;
        
        % get file path, counter, device name, and experiment name
        [temppath, counter, deviceName, exptName] = get_path_and_file();
        if ~strcmp(temppath, '')
            data_path = temppath;
        end
        if (~strcmp(exptName, '') && ~strcmp(deviceName, ''))
            basename = [deviceName '_' exptName];
        end
        settings.data_path = data_path;
        settings.deviceName = deviceName;
        settings.exptName = exptName;
        settings.counter = counter.value;
        
        % save settings to specific program cfg file as well as common cfg.
		cfg_file_name = [cfg_path 'TimeDomain.cfg'];
        common_cfg_name = [cfg_path 'common.cfg'];
		writeCfgFromStruct(cfg_file_name, settings);
        writeCfgFromStruct(common_cfg_name, settings);

		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		%%%%%%%%%%%%%%%%%%%     PREPARE FOR EXPERIMENT      %%%%%%%%%%%%%%%%%%%%%%%
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		% These methods are inherited from the superclass 'experiment'.  They are
		% generic for all Experiments
		Exp = expManager.homodyneDetection2D(data_path, cfg_file_name, basename, counter.value);
		Exp.parseExpcfgFile;

		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		%%%%%%%%%%%%%%%%%%%%%     RUN THE EXPERIMENT      %%%%%%%%%%%%%%%%%%%%%%%%%
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

		% Initialize the data file and record the parameters
		Exp.openDataFile;
		Exp.writeDataFileHeader;
        % increment counter
        counter.increment();

		% Run the actual experiment
		Exp.Init;
		Exp.Do;
		Exp.CleanUp;

		% Close the data file and end connection to all insturments.  This is 
		% another method inherited from 'experiment'
		Exp.finalizeData;

		status = 0;
    end

    function keyPress(~, event)
        if strcmp(event.Modifier{1},'control') && strcmp(event.Key,'r')
            run_callback()
        end
    end

end


