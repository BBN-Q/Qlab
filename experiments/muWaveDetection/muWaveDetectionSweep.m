%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Module Name :  muWaveDetectionSweep.m
 %
 % Author/Date : Blake Johnson / October 19, 2010
 %
 % Description : A GUI 2D sweeper for homodyneDetection.
 %
 % Version: 1.0
 %
 %    Modified    By    Reason
 %    --------    --    ------
 %    March 2012 Colm Ryan to add GUI Layouts
 %
 % Copyright 2010 Raytheon BBN Technologies
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
function muWaveDetectionSweep()
% This script will execute the experiment muWaveDetection using the
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
base_path = fileparts(mfilename('fullpath'));

data_path = [base_path, filesep 'data'];
cfg_path = [base_path, filesep, 'cfg'];
basename = 'muWaveDetection';

if nargin < 1
	cfg_file_name = fullfile(cfg_path, 'muWaveDetectionSweep.cfg');
end

% list of instruments expected in the settings structs
instrumentNames = {'scope', 'RFgen', 'LOgen', 'Specgen', 'Spec2gen', 'TekAWG', 'BBNAPS'};
% load previous settings structs
[commonSettings, prevSettings] = get_previous_settings('muWaveDetectionSweep', cfg_path, instrumentNames);

%Setup the file counter 
global counter;
if ~isa(counter, 'Counter')
    initial_counter_value = 1;
    if isfield(commonSettings, 'counter')
        initial_counter_value = commonSettings.counter + 1;
    end
    counter = Counter(initial_counter_value);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%     CREATE GUI     %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mainWindow = figure( ...
	'Tag', 'figure1', ...
	'Units', 'pixels', ...
	'Position', [50 50 1300 700], ...
	'Name', 'muWaveSweep', ...
	'MenuBar', 'none', ...
	'NumberTitle', 'off', ...
	'Color', get(0,'DefaultUicontrolBackgroundColor'), ...
	'Visible', 'off');


%Add a grid layout for all the controls
mainGrid = uiextras.Grid('Parent', mainWindow, 'Spacing', 20, 'Padding', 10);

%Add the digitizer panel
leftVBox = uiextras.VBox('Parent', mainGrid, 'Spacing', 10);
[get_digitizer_settings, ~] = deviceGUIs.digitizer_settings_gui(leftVBox, prevSettings.InstrParams.scope);

%Add the Run/Stop buttons and scope checkbox
tmpHBox = uiextras.HButtonBox('Parent', leftVBox, 'ButtonSize', [120, 40]);
runButton = uicontrol('Parent', tmpHBox, 'Style', 'pushbutton', 'String', 'Run', 'FontSize', 10, 'Callback', @run_callback);
uicontrol('Parent', tmpHBox, 'Style', 'pushbutton', 'String', 'Stop', 'FontSize', 10, 'Callback', @stop_callback );
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
sourceTabPanel.TabNames = {'RF','LO','Spec','Spec2'};
sourceTabPanel.SelectedChild = 1;

%Add the AWG's
AWGPanel = uiextras.Panel('Parent', middleVBox, 'Title', 'AWG''s','FontSize',12, 'Padding', 5);
AWGTabPanel = uiextras.TabPanel('Parent', AWGPanel, 'Padding', 5, 'HighlightColor', 'k');
[get_tekAWG_settings, ~] = deviceGUIs.AWG5014_settings_GUI(AWGTabPanel, 'TekAWG', prevSettings.InstrParams.TekAWG);
[get_APS_settings, ~] = deviceGUIs.APS_settings_GUI(AWGTabPanel, 'BBN APS', prevSettings.InstrParams.BBNAPS);
AWGTabPanel.TabNames = {'Tektronix','APS'};
AWGTabPanel.SelectedChild = 1;

%Add the Sweeps's
rightVBox = uiextras.VBox('Parent', mainGrid, 'Spacing', 10);
SweepPanel = uiextras.Panel('Parent', rightVBox, 'Title', 'Sweeps','FontSize',12, 'Padding', 5);
SweepTabPanel = uiextras.TabPanel('Parent', SweepPanel, 'Padding', 5, 'HighlightColor', 'k');
get_freqA_settings = sweepGUIs.FrequencySweepGUI(SweepTabPanel, 'A', prevSettings.SweepParams.frequencyA);
get_freqB_settings = sweepGUIs.FrequencySweepGUI(SweepTabPanel, 'B', prevSettings.SweepParams.frequencyB);
get_power_settings = sweepGUIs.PowerSweepGUI(SweepTabPanel, '');
get_phase_settings = sweepGUIs.PhaseSweepGUI(SweepTabPanel, '');

SweepTabPanel.TabNames = {'Freq. A', 'Freq. B', 'Power', 'Phase'};
SweepTabPanel.SelectedChild = 1;

% Add the measurement settings panels
MeasurementPanel = uiextras.Panel('Parent', rightVBox, 'Title', 'Measurement Processing','FontSize',12, 'Padding', 5);
measPanelVBox = uiextras.VBox('Parent', MeasurementPanel, 'Spacing', 5);
get_digitalHomodyne_settings = digitalHomodyne_GUI(measPanelVBox, prevSettings.ExpParams.digitalHomodyne);

%Add some of the experiment setup buttons in a panel
ExpSetupPanel = uiextras.Panel('Parent', rightVBox, 'Title', 'Experiment Setup','FontSize',12, 'Padding', 5);
ExpSetupVBox = uiextras.VBox('Parent', ExpSetupPanel, 'Spacing', 5);

%Add sweep/loop selector
tmpGrid = uiextras.Grid('Parent', ExpSetupVBox, 'Spacing', 5);
[~, ~, fastLoop] = uiextras.labeledPopUpMenu(tmpGrid, 'Fast Loop:', 'fastloop',  {'frequencyA', 'frequencyB', 'power', 'phase', 'dc', 'TekCh', 'nothing'});
[~, ~, slowLoop] = uiextras.labeledPopUpMenu(tmpGrid, 'Slow Loop:', 'slowloop',  {'frequencyA', 'frequencyB', 'power', 'phase', 'dc', 'TekCh', 'nothing'});
set(slowLoop, 'Value', 7);
[~, ~, deviceName_EditBox] = uiextras.labeledEditBox(tmpGrid, 'Device Name:', 'deviceName', prevSettings.deviceName);
[~, ~, exptName_EditBox] = uiextras.labeledEditBox(tmpGrid, 'Experiment:', 'expName', prevSettings.exptName);
set(tmpGrid, 'RowSizes', [-1, -1], 'ColumnSizes', [-1, -1]);

tmpHBox = uiextras.HBox('Parent',ExpSetupVBox);
[~, ~, fileNum_EditBox] = uiextras.labeledEditBox(tmpHBox, 'File Number:', 'fileNum', counter.value);
%Add a listener to the file number edit box to update with the counter value
fileNumberListener = addlistener(counter, 'valueChanged', @(src,~) set(fileNum_EditBox, 'String', sprintf('%03d',src.value)));
%Clear the listener when the uicontrol is delete so they don't pile up
set(fileNum_EditBox, 'DeleteFcn', @(~,~) delete(fileNumberListener));

tmpButtonBox = uiextras.HButtonBox('Parent', tmpHBox);
%Reset button is added below because we can't forward reference the
%dataPath_EditBox

tmpHBox = uiextras.HBox('Parent',ExpSetupVBox, 'Spacing', 5);
uicontrol('Parent', tmpHBox, 'Style', 'text', 'String', 'Data Path:', 'FontSize', 10);
dataPath_EditBox = uicontrol('Parent', tmpHBox, 'Style', 'edit', 'BackgroundColor', [1,1,1], 'Max', 2, 'Min', 0, 'String', prevSettings.data_path);
uicontrol('Parent', tmpButtonBox, 'Style', 'pushbutton', 'String', 'Reset', 'Callback', @(~,~) counter.reset(get(dataPath_EditBox, 'String')));
tmpButtonBox = uiextras.HButtonBox('Parent', tmpHBox);
uicontrol('Parent', tmpButtonBox, 'Style', 'pushbutton', 'String', 'Choose', 'Callback', @choose_data_path);
uicontrol('Parent', tmpButtonBox, 'Style', 'pushbutton', 'String', 'Today', 'Callback', @set_dataPath_today);
tmpHBox.Sizes = [-1, -2, -1];


%Try and patch up the sizing
ExpSetupVBox.Sizes = [-2, -1, -1];
uiextras.Empty('Parent', rightVBox);
rightVBox.Sizes = [-1, -0.75, -1.5, -1];
set(mainGrid, 'RowSizes', -1, 'ColumnSizes', [-1.05 -1.2, -1]);

% 
% % add DC sources
% get_DCsource_settings = deviceGUIs.DCBias_settings_GUI(mainWindow, 240, 775, prevSettings.InstrParams.BBNdc);
% %get_Yoko_settings = deviceGUIs.Yoko7651_GUI(mainWindow, 100, 755);

%Now that everything is setup draw the window
drawnow;
set(mainWindow, 'Visible', 'on');

%Add a callback for setting the directory
    function choose_data_path(~,~)
       newPath = uigetdir(get(dataPath_EditBox, 'String'));
       if newPath ~= 0
            set(dataPath_EditBox, 'String', newPath);
       end 
    end

%Add a callback to set the dataPath to today
    function set_dataPath_today(~,~)
        newPath = [data_path, filesep, get(deviceName_EditBox,'String'), filesep, datestr(now, 'yymmdd')];
        if ~exist(newPath, 'dir')
            mkdir(newPath);
        end
        set(dataPath_EditBox, 'String',newPath); 
    end

%Add the main run callback
	function run_callback(~, ~)
        
        %Disable the run button so we can't call it twice
        set(runButton, 'Enable', 'off');

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
		settings.InstrParams.TekAWG = get_tekAWG_settings();
        settings.InstrParams.BBNAPS = get_APS_settings();
% 		settings.InstrParams.BBNdc = get_DCsource_settings();
		
		% get sweep settings
		settings.SweepParams.frequencyA = get_freqA_settings();
		settings.SweepParams.frequencyB = get_freqB_settings();
		settings.SweepParams.power = get_power_settings();
		settings.SweepParams.phase = get_phase_settings();
% 		settings.SweepParams.dc = get_dc_settings();
%         settings.SweepParams.TekCh = get_tekChannel_settings();
		% add 'nothing' sweep
		settings.SweepParams.nothing = struct('type', 'sweeps.Nothing');
		
		% label fast and slop loops as sweeps 1 and 2
		settings.SweepParams.(get_selected(fastLoop)).number = 1;
		settings.SweepParams.(get_selected(slowLoop)).number = 2;
		
		% get other experiment settings
		settings.ExpParams.digitalHomodyne = get_digitalHomodyne_settings();
		settings.displayScope = get(scopeButton, 'Value');
		settings.SoftwareDevelopmentMode = 0;
        
        % get file path, counter, device name, and experiment name
        tmpDataPath = get(dataPath_EditBox, 'String');
        deviceName = get(deviceName_EditBox, 'String');
        exptName = get(exptName_EditBox, 'String');
        if ~isempty(tmpDataPath)
            data_path = tmpDataPath;
        end
        if ~isempty(exptName) && ~isempty(deviceName)
            basename = [deviceName '_' exptName];
        end
        settings.data_path = data_path;
        settings.deviceName = deviceName;
        settings.exptName = exptName;
        settings.counter = counter.value;
        
        % save settings to specific program cfg file as well as common cfg.
        common_cfg_name = fullfile(cfg_path, 'common.cfg');
		writeCfgFromStruct(cfg_file_name, settings);
        writeCfgFromStruct(common_cfg_name, settings);

		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		%%%%%%%%%%%%%%%%%%%     PREPARE AND RUN EXPERIMENT      %%%%%%%%%%%%%%%%%%%
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		
        % create experiment object
		Exp = expManager.homodyneDetection(data_path, cfg_file_name, basename, counter.value);
        
        
        % parse cfg file
		Exp.parseExpcfgFile;

		% Initialize the data file and record the parameters
		Exp.openDataFile;
		Exp.writeDataFileHeader;
        % increment counter
        counter.increment();

		% Run the actual experiment
		Exp.Init;
		Exp.Do;
		Exp.CleanUp;

		% Close the data file and end connection to all insturments.
		Exp.finalizeData;

        %Call the stop button call_back to clean-up
        stop_callback()
    end

    
    function stop_callback(~,~)
        %Reenable the start button
        set(runButton, 'Enable', 'on');
        
    end

end

