function [get_settings_fcn, set_settings_fcn] = digitizer_settings_gui(parent, settings)
% DIGITIZER_SETTINGS_GUID
%-------------------------------------------------------------------------------
% File name   : acqiris_settings_guid.m
% Generated on: 12 Dec. 2011
% Description : A GUI for setting the paramters of a digitizer card
%               Based of acqiris_settings_gui from Blake Johnson
% Author: Colm Ryan
%-------------------------------------------------------------------------------

% Copyright 2010,2011,2012 Raytheon BBN Technologies
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

% Initialize handles structure
handles = struct();

% If there is no parent figure given, generate a new one
if nargin < 1
    handles.parent = figure( ...
        'Tag', 'figure1', ...
        'Units', 'characters', ...
        'Position', [103.833333333333 13.8571428571429 95 40], ...
        'Name', 'Digitizer Settings', ...
        'MenuBar', 'none', ...
        'NumberTitle', 'off', ...
        'Color', get(0,'DefaultUicontrolBackgroundColor'));
    
    %Otherwise we are placed into a parent container so grab a handle to that
else
    handles.parent = parent;
end

% Instrument allowable parameters and mapping to API parameters
% These are specific to the particular digitizer card and used for
% drop-down menus.  Here we simply initialize empty maps and then a nested
% function fills them out depending on the card choice.
cardParams = struct();
%Whether the card performs on-board averaging
cardParams.cardModes = containers.Map();
%How the digitizer is clocked: internal, external, or 10MHz reference into
%PLL
cardParams.clockTypes = containers.Map();
%Vertical scaling
cardParams.scales = containers.Map();
%AC/DC coupling and impedence
cardParams.verticalCouplings = containers.Map();
%The on-board filtering for bandwidth
cardParams.bandwidths = containers.Map();
%Which channel is used for triggering
cardParams.trigChannels = containers.Map();
%How the trigger channel is coupled
cardParams.trigCouplings = containers.Map();
%The slope of the trigger: rising/falling.
cardParams.trigSlopes = containers.Map();
%How the card syncs????
cardParams.resyncs = containers.Map();
%The allowable sampling rates
cardParams.samplingRates = containers.Map();

%Setup a dictionary linking these parameters to UI tags for the pop-up
%menus
cardParamsUIDict = containers.Map();
cardParamsUIDict('acquire_mode') = 'cardModes';
cardParamsUIDict('clockType') = 'clockTypes';
cardParamsUIDict('verticalScale') = 'scales';
cardParamsUIDict('verticalCoupling') = 'verticalCouplings';
cardParamsUIDict('bandwidth') = 'bandwidths';
cardParamsUIDict('triggerSource') = 'trigChannels';
cardParamsUIDict('triggerCoupling') = 'trigCouplings';
cardParamsUIDict('triggerSlope') = 'trigSlopes';
cardParamsUIDict('trigResync') = 'resyncs';
cardParamsUIDict('samplingRate') = 'samplingRates';


% Call a subfunction to create all UI controls
build_gui();

%If we are not passed explicit settings then create an emtpy structure
if nargin < 2 || isempty(fieldnames(settings))
    settings = struct();
else
    %Set the card type
    set_selected(handles.cardType, find(strcmp(settings.deviceName, get(handles.cardType,'String'))))
end


%Update the GUI elements with the available choice for the given digitizer
%card and the current settings
card_switch()

% Assign function handles output
get_settings_fcn = @get_settings;
set_settings_fcn = @set_gui_elements;


%% ---------------------------------------------------------------------------
%Main function layout all the GUI elements
    function build_gui()
        % Creation of all uicontrols
        
        
        %Create the main panel containing everything with a VBox layout
        handles.mainPanel = uiextras.Panel('Parent', handles.parent, 'Title', 'Digitizer Settings', 'Padding', 5, 'FontSize', 12 );
        handles.mainVBox = uiextras.VBox('Parent',handles.mainPanel, 'Spacing', 10);
        
        %Add the digitizer card and mode options
        tmpGrid1 = uiextras.Grid('Parent', handles.mainVBox, 'Spacing', 10, 'Padding', 5);
        
        [~, ~, handles.cardType] = uiextras.labeledPopUpMenu(tmpGrid1, 'Card Type:', 'cardType', {'AgilentAP240', 'AlazarATS9870'});
        set(handles.cardType, 'Callback', @card_switch);
        [~, ~, handles.acquire_mode] = uiextras.labeledPopUpMenu(tmpGrid1, 'Card Mode:', 'acquire_mode', {''});
        
        set(tmpGrid1, 'RowSizes', [-1], 'ColumnSizes', [-1, -1]);
        
        %Setup the averager settings
        handles.averagerPanel = uiextras.Panel('Parent', handles.mainVBox, 'Title', 'Averager', 'Padding', 5, 'FontSize', 11);
        tmpGrid2 = uiextras.Grid('Parent', handles.averagerPanel, 'Spacing', 10, 'Padding', 10);
        
        [~, ~, handles.nbrWaveforms] = uiextras.labeledEditBox(tmpGrid2, 'Waveforms:', 'nbrWaveforms', '10000');
        [~, ~, handles.nbrRoundRobins] = uiextras.labeledEditBox(tmpGrid2, 'Round Robins:', 'nbrRoundRobins', '1');
        [~, ~, handles.nbrSegments] = uiextras.labeledEditBox(tmpGrid2, 'Segments:', 'nbrSegments', '1');
        [~, ~, handles.ditherRange] = uiextras.labeledEditBox(tmpGrid2, 'Dither Range:', 'ditherRange', '0');
        [~, ~, handles.trigResync] = uiextras.labeledPopUpMenu(tmpGrid2, 'Trigger:', 'trigResync', {''});
        
        set(tmpGrid2, 'RowSizes', -1*ones([1,3]), 'ColumnSizes', [-1, -1]);
        
        %Setup the acquisition settings
        handles.acquirePanel = uiextras.Panel('Parent', handles.mainVBox, 'Title', 'Acquisition', 'FontSize', 11);
        tmpGrid3 = uiextras.Grid('Parent', handles.acquirePanel, 'Spacing', 10, 'Padding', 10);
        
        [~, handles.statictext_vertScale, handles.verticalScale] = uiextras.labeledPopUpMenu(tmpGrid3, 'Scale:', 'verticalScale', {''});
        [~, ~, handles.verticalOffset] = uiextras.labeledEditBox(tmpGrid3, 'Offset:', 'verticalOffset', '0');
        [~, ~, handles.delayTime] = uiextras.labeledEditBox(tmpGrid3, 'Delay:', 'delayTime', '0');
        [~, ~, handles.recordLength] = uiextras.labeledEditBox(tmpGrid3, 'Samples:', 'recordLength', '0');
        [~, ~, handles.samplingRate] = uiextras.labeledPopUpMenu(tmpGrid3, 'Samp. Rate:', 'samplingRate', {''});
        [~, ~, handles.verticalCoupling] = uiextras.labeledPopUpMenu(tmpGrid3, 'Coupling:', 'verticalCoupling', {''});
        [~, ~, handles.bandwidth] = uiextras.labeledPopUpMenu(tmpGrid3, 'Bandwidth:', 'bandwidth', {''});
        [~, ~, handles.channel] = uiextras.labeledPopUpMenu(tmpGrid3, 'Channel:', 'channel', {''});
        [~, ~, handles.clockType] = uiextras.labeledPopUpMenu(tmpGrid3, 'Clock:', 'clockType', {''});
        
        set(tmpGrid3, 'RowSizes', -1*ones([1,5]), 'ColumnSizes', [-1, -1]);
        
        %Setup the trigger settings
        handles.triggerPanel = uiextras.Panel('Parent', handles.mainVBox, 'Title', 'Trigger', 'FontSize', 11);
        tmpGrid4 = uiextras.Grid('Parent', handles.triggerPanel, 'Spacing', 10, 'Padding', 10);
        
        [~, ~, handles.triggerLevel] = uiextras.labeledEditBox(tmpGrid4, 'Level(mV):', 'trigger_level', '500');
        [~, ~, handles.triggerSlope] = uiextras.labeledPopUpMenu(tmpGrid4, 'Slope:', 'trigger_slope', {''});
        [~, ~, handles.triggerCoupling] = uiextras.labeledPopUpMenu(tmpGrid4, 'Coupling:', 'trigger_coupling', {''});
        [~, ~, handles.triggerSource] = uiextras.labeledPopUpMenu(tmpGrid4, 'Channel:', 'trigger_ch', {''});
        
        set(tmpGrid4, 'RowSizes', -1*ones([1,2]), 'ColumnSizes', [-1, -1]);
        
        %Weight the vbox sizes
        set(handles.mainVBox, 'Sizes', [-1, -3, -4.5, -2])
        
    end %build_gui function

%Helper function to get a drop-down menu selection.
    function selected = get_selected(hObject)
        menu = get(hObject,'String');
        selected = menu{get(hObject,'Value')};
    end

%Helper function to set a drop-down menu.
    function set_selected(hObject, val)
        menu = get(hObject, 'String');
        index = find(strcmp(val, menu));
        if ~isempty(index)
            set(hObject, 'Value', index);
        end
    end

%Main function returned which gets all the GUI settings.
    function scope_settings = get_settings()
        
        scope_settings = struct();
        
        scope_settings.deviceName = get_selected(handles.cardType);
        scope_settings.Address = 'PCI::INSTR0';
        
        % set card mode
        scope_settings.acquire_mode = cardParams.cardModes(get_selected(handles.acquire_mode));
        scope_settings.clockType = cardParams.clockTypes(get_selected(handles.clockType));
        
        % set horizontal settings
        horizSettings.delayTime = str2double(get(handles.delayTime, 'String'));
        horizSettings.samplingRate = cardParams.samplingRates(get_selected(handles.samplingRate));
        %disp(horizSettings);
        scope_settings.horizontal = horizSettings;
        
        % set vertical settings
        vertSettings.verticalScale = cardParams.scales(get_selected(handles.verticalScale));
        vertSettings.verticalOffset = str2double(get(handles.verticalOffset,'String'));
        vertSettings.verticalCoupling = cardParams.verticalCouplings(get_selected(handles.verticalCoupling));
        vertSettings.bandwidth = cardParams.bandwidths(get_selected(handles.bandwidth));
        %disp(vertSettings);
        scope_settings.vertical = vertSettings;
        
        % set trigger settings
        trigSettings.triggerLevel = str2double(get(handles.triggerLevel,'String'));
        trigSettings.triggerSource = cardParams.trigChannels(get_selected(handles.triggerSource));
        trigSettings.triggerCoupling = cardParams.trigCouplings(get_selected(handles.triggerCoupling));
        trigSettings.triggerSlope = cardParams.trigSlopes(get_selected(handles.triggerSlope));
        %disp(trigSettings);
        scope_settings.trigger = trigSettings;
        
        % set averager settings
        avgSettings.recordLength = str2double(get(handles.recordLength,'String'));
        avgSettings.nbrSegments = str2double(get(handles.nbrSegments,'String'));
        avgSettings.nbrWaveforms = str2double(get(handles.nbrWaveforms,'String'));
        avgSettings.nbrRoundRobins = str2double(get(handles.nbrRoundRobins,'String'));
        avgSettings.ditherRange = str2double(get(handles.ditherRange,'String'));
        switch scope_settings.deviceName
            case 'AlazarATS9870'
                avgSettings.trigResync = 0;
            case {'AgilentAP240'}
                avgSettings.trigResync = cardParams.resyncs(get_selected(handles.trigResync));
        end
        scope_settings.averager = avgSettings;
    end

%Function to set and load card specific options
    function card_switch(varargin)
        %Load which card we are using
        curCard = get_selected(handles.cardType);
        %Now set the allowed parameters
        switch curCard
            case 'AgilentAP240'
                cardParams.cardModes = containers.Map({'Digitizer', 'Averager'}, {0, 2});
                cardParams.clockTypes = containers.Map({'Internal','External', 'Ext Ref (10 MHz)'}, {'int', 'ext', 'ref'});
                cardParams.scales = containers.Map({'50m','100m', '200m', '500m', '1', '2', '5'}, {.05, .1, .2, .5, 1, 2, 5});
                cardParams.verticalCouplings = containers.Map({'Ground','DC, 1 MOhm','AC, 1 MOhm','DC, 50 Ohm','AC, 50 Ohm'}, ...
                    {0,1,2,3,4});
                cardParams.bandwidths = containers.Map({'no limit','700 MHz','200 MHz','35 MHz','25 MHz','20 MHz'}, ...
                    {0,2,3,5,1,4});
                cardParams.trigChannels = containers.Map({'External','Ch 1', 'Ch 2'}, {-1, 1, 2});
                cardParams.trigCouplings = containers.Map({'DC','AC','DC, 50 Ohm','AC, 50 Ohm'},{0,1,3,4});
                cardParams.trigSlopes = containers.Map({'Rising','Falling'},{0,1});
                cardParams.resyncs = containers.Map({'Resync','No resync'},{1,0});
                cardParams.samplingRates = containers.Map({'1M','2M','2.5M','4M','5M','10M','20M','25M','40M','50M','100M','200M','250M','400M','500M','1G','2G'},{1e6, 2e6, 2.5e6, 4e6, 5e6, 10e6, 20e6, 25e6, 40e6, 50e6, 100e6, 200e6, 250e6, 400e6, 500e6, 1e9, 2e9});
                
                %Update the range text
                set(handles.statictext_vertScale,'String','Scale (Vpp):');
                
                %Update the settings structure
                if isfield(settings, 'deviceName')
                    if strcmp(settings.deviceName ,'AlazarATS9870')
                        settings.deviceName = 'AgilentAP240';
                        tmpMap = containers.Map({1, 5, 7}, {'int', 'ext', 'ref'});
                        settings.clockType = tmpMap(settings.clockType);
                        tmpMap = containers.Map({2, 5, 6, 7, 10, 11, 12}, {.05, .1, .2, .5, 1, 2, 5});
                        settings.vertical.verticalScale  = tmpMap(settings.vertical.verticalScale);
                        tmpMap = containers.Map({1, 2}, {4, 3});
                        settings.vertical.verticalCoupling  = tmpMap(settings.vertical.verticalCoupling);
                        tmpMap = containers.Map({0,1}, {0, 4});
                        settings.vertical.bandwidth  = tmpMap(settings.vertical.bandwidth);
                        tmpMap = containers.Map({2, 0, 1}, {-1, 1, 2});
                        settings.trigger.triggerSource  = tmpMap(settings.trigger.triggerSource);
                        tmpMap = containers.Map({2,1}, {0,1});
                        settings.trigger.triggerCoupling  = tmpMap(settings.trigger.triggerCoupling);
                        tmpMap = containers.Map({1e6, 10e6, 100e6, 250e6, 500e6, 1e9},{1e6, 10e6, 100e6, 250e6, 500e6, 1e9});
                        settings.horizontal.samplingRate  = tmpMap(settings.horizontal.samplingRate);
                    end
                end
                
            case 'AlazarATS9870'
                cardParams.cardModes = containers.Map({'Digitizer', 'Averager'}, {0, 2});
                cardParams.clockTypes = containers.Map({'Internal','External', 'Ext Ref (10 MHz)'}, {1, 5, 7});
                cardParams.scales = containers.Map({'40m','100m', '200m', '400m', '1', '2', '4'}, {2, 5, 6, 7, 10, 11, 12});
                cardParams.verticalCouplings = containers.Map({'AC, 50 Ohm','DC, 50 Ohm'}, {1, 2});
                cardParams.bandwidths = containers.Map({'no limit','20 MHz'}, {0,1});
                cardParams.trigChannels = containers.Map({'External','Ch A', 'Ch B'}, {2, 0, 1});
                cardParams.trigCouplings = containers.Map({'DC','AC'},{2,1});
                cardParams.trigSlopes = containers.Map({'Rising','Falling'},{0,1});
                cardParams.resyncs = containers.Map();
                cardParams.samplingRates = containers.Map({'1M','10M','100M','250M','500M','1G'},{1e6, 10e6, 100e6, 250e6, 500e6, 1e9});
                
                %Update the range text
                set(handles.statictext_vertScale,'String','Scale (Vp):');
                
                %Update the settings structure
                if isfield(settings, 'deviceName')
                    if strcmp(settings.deviceName ,'AgilentAP240')
                        settings.deviceName = 'AlazarATS9870';
                        tmpMap = containers.Map({'int', 'ext', 'ref'}, {1, 5, 7});
                        settings.clockType = tmpMap(settings.clockType);
                        tmpMap = containers.Map({.05, .1, .2, .5, 1, 2, 5}, {2, 5, 6, 7, 10, 11, 12});
                        settings.vertical.verticalScale  = tmpMap(settings.vertical.verticalScale);
                        tmpMap = containers.Map({0,1,2,3,4}, {2, 2, 1, 2, 1}); 
                        settings.vertical.verticalCoupling  = tmpMap(settings.vertical.verticalCoupling);
                        tmpMap = containers.Map({0,2,3,5,1,4}, {0, 1, 1, 1, 1, 1});  
                        settings.vertical.bandwidth  = tmpMap(settings.vertical.bandwidth);
                        tmpMap = containers.Map({-1, 1, 2}, {2, 0, 1});
                        settings.trigger.triggerSource  = tmpMap(settings.trigger.triggerSource);
                        tmpMap = containers.Map({0,1,3,4}, {2, 1, 2, 1});
                        settings.trigger.triggerCoupling  = tmpMap(settings.trigger.triggerCoupling);
                        tmpMap = containers.Map({1e6, 2e6, 2.5e6, 4e6, 5e6, 10e6, 20e6, 25e6, 40e6, 50e6, 100e6, 200e6, 250e6, 400e6, 500e6, 1e9, 2e9},...
                                                {1e6, 1e6, 1e6,   1e6, 10e6,10e6, 10e6, 10e6, 10e6, 100e6,100e6, 250e6, 250e6, 500e6, 500e6, 1e9, 1e9});
                        settings.horizontal.samplingRate  = tmpMap(settings.horizontal.samplingRate);
                    end
                end
                
        end
        
        set_gui_elements(settings)
        
    end

    function set_gui_elements(settings)
        % Define default values for the fields.
        % If given a settings structure, grab defaults from it'
        defaults = struct();
        if isempty(fieldnames(settings))
            defaults.acquire_mode = 'Averager';
            defaults.clockType = 'Ext Ref (10 MHz)';
            defaults.horizontal.delayTime = 0;
            defaults.horizontal.samplingRate = 10e9;
            defaults.vertical.verticalScale = '500m';
            defaults.vertical.verticalOffset = 0;
            defaults.vertical.verticalCoupling = 'DC, 50 Ohm';
            defaults.vertical.bandwidth = 'no limit';
            defaults.trigger.triggerLevel = 500;
            defaults.trigger.triggerSource = 'External';
            defaults.trigger.triggerCoupling = 'DC';
            defaults.trigger.triggerSlope = 'Rising';
            defaults.averager.recordLength = 10000;
            defaults.averager.nbrSegments = 1;
            defaults.averager.nbrWaveforms = 1000;
            defaults.averager.nbrRoundRobins = 1;
            defaults.averager.ditherRange = 0;
            defaults.averager.trigResync = 'Resync';
            
        else
            % construct inverse maps
            cardModesInv = invertMap(cardParams.cardModes);
            clockTypesInv = invertMap(cardParams.clockTypes);
            scalesInv = invertMap(cardParams.scales);
            verticalCouplingsInv = invertMap(cardParams.verticalCouplings);
            bandwidthsInv = invertMap(cardParams.bandwidths);
            trigChannelsInv = invertMap(cardParams.trigChannels);
            trigCouplingsInv = invertMap(cardParams.trigCouplings);
            trigSlopesInv = invertMap(cardParams.trigSlopes);
            if ~isempty(cardParams.resyncs)
                resyncsInv = invertMap(cardParams.resyncs);
            end
            % scope settings are two layers deep, need to go into horizontal,
            % vertical, trigger, and averager
            defaults.acquire_mode = cardModesInv(settings.acquire_mode);
            defaults.clockType = clockTypesInv(settings.clockType);
            % horizontal
            defaults.horizontal.delayTime = settings.horizontal.delayTime;
            defaults.horizontal.samplingRate = settings.horizontal.samplingRate;
            % vertical
            defaults.vertical.verticalScale = scalesInv(settings.vertical.verticalScale);
            defaults.vertical.verticalOffset = settings.vertical.verticalOffset;
            defaults.vertical.verticalCoupling = verticalCouplingsInv(settings.vertical.verticalCoupling);
            defaults.vertical.bandwidth = bandwidthsInv(settings.vertical.bandwidth);
            % trigger
            defaults.trigger.triggerLevel = settings.trigger.triggerLevel;
            defaults.trigger.triggerSource = trigChannelsInv(settings.trigger.triggerSource);
            defaults.trigger.triggerCoupling = trigCouplingsInv(settings.trigger.triggerCoupling);
            defaults.trigger.triggerSlope = trigSlopesInv(settings.trigger.triggerSlope);
            % averaging
            defaults.averager.recordLength = settings.averager.recordLength;
            defaults.averager.nbrSegments = settings.averager.nbrSegments;
            defaults.averager.nbrWaveforms = settings.averager.nbrWaveforms;
            defaults.averager.nbrRoundRobins = settings.averager.nbrRoundRobins;
            defaults.averager.ditherRange = settings.averager.ditherRange;
            if ~isempty(cardParams.resyncs)
                defaults.averager.trigResync = resyncsInv(settings.averager.trigResync);
            end
        end
        
        % depth first traversal of defaults using a stack
        s = stack();
        % push a cell array of the name and defaults onto the stack
        s.push({'' defaults});
        
        while ~s.isempty()
            u = s.pop();
            name = u{1};
            value = u{2};
            
            % if current element is itself a struct, add all its children to the
            % stack
            if isstruct(value)
                elementNames = fieldnames(value);
                len = numel(elementNames);
                for i = len:-1:1
                    s.push( {elementNames{i} value.(elementNames{i})} );
                end
            elseif isfield(handles, name)
                % strip everything before the last dot to get the handle
                switch get(handles.(name), 'Style')
                    case 'edit'
                        set(handles.(name), 'String', num2str(value));
                    case 'popupmenu'
                        %Some of the pop-up menus we want to order based on
                        %their numeric values
                        tmpKeys = keys(cardParams.(cardParamsUIDict(name)));
                        if(any(strcmp(name, {'verticalScale', 'bandwidth'})))
                            tmpValues = keys(cardParams.(cardParamsUIDict(name)));
                            tmpValues = strrep(tmpValues, 'm','e-3');
                            tmpValues = strrep(tmpValues, 'MHz','e6');
                            [~, sortOrder] = sort(str2double(tmpValues));
                            tmpKeys = tmpKeys(sortOrder);
                        end
                        if(isempty(tmpKeys))
                            set(handles.(name), 'Enable', 'off')
                        else
                            set(handles.(name), 'Enable', 'on')
                            %Set the allowable values
                            set(handles.(name), 'String', tmpKeys)
                            set_selected(handles.(name), value);
                        end
                    case 'checkbox'
                        set(handles.(name), 'Value', value);
                    case 'radiobutton'
                        set(handles.(name), 'Value', value);
                    otherwise
                        warning('unknown handle type');
                end
            end
        end
        
    end %set_gui_elements

end %total function
