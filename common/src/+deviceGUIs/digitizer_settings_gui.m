function settings_fcn = digitizer_settings_gui(parent, left, bottom, settings)
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
if nargin < 1 || ~isnumeric(parent)
    handles.parent = figure( ...
        'Tag', 'figure1', ...
        'Units', 'characters', ...
        'Position', [103.833333333333 13.8571428571429 55 65], ...
        'Name', 'Digitizer Settings', ...
        'MenuBar', 'none', ...
        'NumberTitle', 'off', ...
        'Color', get(0,'DefaultUicontrolBackgroundColor'));
    
    left = 1.0;
    bottom = 0.5;
    %Otherwise we are placed into a parent container so grab a handle to that
else
    handles.parent = figure(parent);
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
cardParams.vert_couplings = containers.Map();
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
cardParamsUIDict('vert_scale') = 'scales';
cardParamsUIDict('vert_coupling') = 'vert_couplings';
cardParamsUIDict('bandwidth') = 'bandwidths';
cardParamsUIDict('trigger_ch') = 'trigChannels';
cardParamsUIDict('trigger_coupling') = 'trigCouplings';
cardParamsUIDict('trigger_slope') = 'trigSlopes';
cardParamsUIDict('trigResync') = 'resyncs';
cardParamsUIDict('samplingRate') = 'samplingRates';


% Call a subfunction to create all UI controls
build_gui();

%If we are not passed explicit settings then create an emtpy structure
if nargin < 4
    settings = struct();
end

%Update the GUI elements with the available choice for the given digitizer
%card and the current settings
card_switch()

%Return a function handle to the subfunction which returns all the current
%settings
settings_fcn = @get_settings;

%% ---------------------------------------------------------------------------
%Main function layout all the GUI elements
    function build_gui()
        % Creation of all uicontrols

        %Base settings for each type
        baseLabelString = {'Style', 'text',  'HorizontalAlignment', 'right', 'FontSize', 10};
        basePopUpMenu = {'Style','popupmenu', 'FontSize',10, 'BackgroundColor', [1 1 1], 'String', {''}};
        baseEdit = {'Style','edit','FontSize', 10, 'BackgroundColor', [1 1 1], 'HorizontalAlignment', 'right' };

        %Create the main panel containing everything with a VBox layout
        handles.mainPanel = uiextras.Panel('Parent', handles.parent, 'Title', 'Digitizer Settings', 'Padding', 5, 'FontSize', 12 );
        handles.mainVBox = uiextras.VBox('Parent',handles.mainPanel, 'Spacing', 10);
        
        %Add the digitizer card and mode options
        tmpGrid1 = uiextras.Grid('Parent', handles.mainVBox, 'Spacing', 10, 'Padding', 5);

        uicontrol(baseLabelString{:}, 'Parent', tmpGrid1, 'String', 'Card Type:')
        uicontrol(baseLabelString{:}, 'Parent', tmpGrid1, 'String', 'Card Mode:')

        handles.cardType = uicontrol( basePopUpMenu{:}, 'Parent', tmpGrid1, 'Tag', 'cardType', ...
            'String', {'AcqirisPT120', 'AlazarATS9870'}, 'Callback', @card_switch);
        
        handles.acquire_mode = uicontrol(basePopUpMenu{:}, 'Parent', tmpGrid1, 'Tag', 'acquire_mode');

        set(tmpGrid1, 'RowSizes', [-1, -1], 'ColumnSizes', [-1, 120]); 
        
        %Setup the averager settings
        handles.averagerPanel = uiextras.Panel('Parent', handles.mainVBox, 'Title', 'Averager', 'Padding', 5, 'FontSize', 11);
        tmpGrid2 = uiextras.Grid('Parent', handles.averagerPanel, 'Spacing', 10, 'Padding', 10);
        uicontrol(baseLabelString{:}, 'Parent', tmpGrid2, 'String', 'Waveforms:')
        uicontrol(baseLabelString{:}, 'Parent', tmpGrid2, 'String', 'Round Robins:')
        uicontrol(baseLabelString{:}, 'Parent', tmpGrid2, 'String', 'Nbr. Segments:')
        uicontrol(baseLabelString{:}, 'Parent', tmpGrid2, 'String', 'Dither Range:')
        uicontrol(baseLabelString{:}, 'Parent', tmpGrid2, 'String', 'Trigger:')

        handles.nbrWaveforms = uicontrol( baseEdit{:}, 'Parent', tmpGrid2, 'Tag', 'nbrWaveforms', 'String', '10000');
        handles.nbrRoundRobins = uicontrol( baseEdit{:}, 'Parent', tmpGrid2, 'Tag', 'nbrRoundRobins', 'String', '1');
        handles.nbrSegments = uicontrol( baseEdit{:}, 'Parent', tmpGrid2, 'Tag', 'nbrSegments', 'String', '1');
        handles.ditherRange = uicontrol( baseEdit{:}, 'Parent', tmpGrid2, 'Tag', 'ditherRange', 'String', '0');
        handles.trigResync = uicontrol( basePopUpMenu{:}, 'Parent', tmpGrid2, 'Tag', 'trigResync');

        set(tmpGrid2, 'RowSizes', -1*ones([1,5]), 'ColumnSizes', [-1, 110]); 
           
        %Setup the acquisition settings
        handles.acquirePanel = uiextras.Panel('Parent', handles.mainVBox, 'Title', 'Acquisition', 'FontSize', 11);
        tmpGrid3 = uiextras.Grid('Parent', handles.acquirePanel, 'Spacing', 10, 'Padding', 10);

        handles.statictext_vertScale = uicontrol(baseLabelString{:}, 'Parent', tmpGrid3, 'String', 'Full Scale:');
        uicontrol(baseLabelString{:}, 'Parent', tmpGrid3, 'String', 'Offset:')
        uicontrol(baseLabelString{:}, 'Parent', tmpGrid3, 'String', 'Delay:')
        uicontrol(baseLabelString{:}, 'Parent', tmpGrid3, 'String', 'Samples:')
        uicontrol(baseLabelString{:}, 'Parent', tmpGrid3, 'String', 'Sampling Rate:')
        uicontrol(baseLabelString{:}, 'Parent', tmpGrid3, 'String', 'Coupling:')
        uicontrol(baseLabelString{:}, 'Parent', tmpGrid3, 'String', 'Bandwidth:')
        uicontrol(baseLabelString{:}, 'Parent', tmpGrid3, 'String', 'Channel:')
        uicontrol(baseLabelString{:}, 'Parent', tmpGrid3, 'String', 'Clock:')

        handles.vert_scale = uicontrol( basePopUpMenu{:}, 'Parent', tmpGrid3, 'Tag', 'vert_scale');
        handles.offset = uicontrol( baseEdit{:}, 'Parent', tmpGrid3, 'Tag', 'offset', 'String', '0');
        handles.delayTime = uicontrol( baseEdit{:}, 'Parent', tmpGrid3, 'Tag', 'delayTime', 'String', '0');
        handles.recordLength = uicontrol( baseEdit{:}, 'Parent', tmpGrid3, 'Tag', 'recordLength', 'String', '1024');
        handles.sampleRate = uicontrol( basePopUpMenu{:}, 'Parent', tmpGrid3, 'Tag', 'sampleRate');
        handles.vert_coupling = uicontrol( basePopUpMenu{:}, 'Parent', tmpGrid3, 'Tag', 'vert_coupling');
        handles.bandwidth = uicontrol( basePopUpMenu{:}, 'Parent', tmpGrid3, 'Tag', 'bandwidth');
        handles.channel = uicontrol( basePopUpMenu{:}, 'Parent', tmpGrid3, 'Tag', 'channel');
        handles.clockType = uicontrol( basePopUpMenu{:}, 'Parent', tmpGrid3, 'Tag', 'clockType');
        
        set(tmpGrid3, 'RowSizes', -1*ones([1,9]), 'ColumnSizes', [-1, 110]); 

        %Setup the trigger settings
        handles.triggerPanel = uiextras.Panel('Parent', handles.mainVBox, 'Title', 'Trigger', 'FontSize', 11);
        tmpGrid4 = uiextras.Grid('Parent', handles.triggerPanel, 'Spacing', 10, 'Padding', 10);
        
        uicontrol(baseLabelString{:}, 'Parent', tmpGrid4, 'String', 'Level (mV):')
        uicontrol(baseLabelString{:}, 'Parent', tmpGrid4, 'String', 'Slope:')
        uicontrol(baseLabelString{:}, 'Parent', tmpGrid4, 'String', 'Coupling:')
        uicontrol(baseLabelString{:}, 'Parent', tmpGrid4, 'String', 'Channel:')
        
        handles.trigger_level = uicontrol( baseEdit{:}, 'Parent', tmpGrid4, 'Tag', 'trigger_level', 'String', 500);
        handles.trigger_slope = uicontrol( basePopUpMenu{:}, 'Parent', tmpGrid4, 'Tag', 'trigger_slope');
        handles.trigger_coupling = uicontrol( basePopUpMenu{:}, 'Parent', tmpGrid4, 'Tag', 'trigger_coupling');
        handles.trigger_ch = uicontrol( basePopUpMenu{:}, 'Parent', tmpGrid4, 'Tag', 'trigger_ch');

       set(tmpGrid4, 'RowSizes', -1*ones([1,4]), 'ColumnSizes', [-1, 110]); 

        %Weight the vbox sizes
        set(handles.mainVBox, 'Sizes', [-1.5, -5, -9, -4])
        
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
        horizSettings.sampleInterval = str2double(get(handles.sampleInterval, 'String'));
        %disp(horizSettings);
        scope_settings.horizontal = horizSettings;
        
        % set vertical settings
        vertSettings.vert_scale = cardParams.scales(get_selected(handles.vert_scale));
        vertSettings.offset = str2double(get(handles.offset,'String'));
        vertSettings.vert_coupling = cardParams.vert_couplings(get_selected(handles.vert_coupling));
        vertSettings.bandwidth = cardParams.bandwidths(get_selected(handles.bandwidth));
        %disp(vertSettings);
        scope_settings.vertical = vertSettings;
        
        % set trigger settings
        trigSettings.level = str2double(get(handles.trigger_level,'String'));
        trigSettings.source = cardParams.trigChannels(get_selected(handles.trigger_ch));
        trigSettings.coupling = cardParams.trigCouplings(get_selected(handles.trigger_coupling));
        trigSettings.slope = cardParams.trigSlopes(get_selected(handles.trigger_slope));
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
                avgSettings.trigResync = false;
            case 'AcquirisPT240'
                avgSettings.trigResync = cardParams.resyncs(get_selected(handles.trigResync));
        end
        
        %disp(avgSettings);
        %scope_settings.channel_on = 1;
        scope_settings.averager = avgSettings;
    end

%Function to set and load card specific options
    function card_switch(varargin)
        %Load which card we are using
        curCard = get_selected(handles.cardType);
        %Now set the allowed parameters
        switch curCard
            case 'AcqirisPT120'
                cardParams.cardModes = containers.Map({'Digitizer', 'Averager'}, {0, 2});
                cardParams.clockTypes = containers.Map({'Internal','External', 'Ext Ref (10 MHz)'}, {'int', 'ext', 'ref'});
                cardParams.scales = containers.Map({'50m','100m', '200m', '500m', '1', '2', '5'}, {.05, .1, .2, .5, 1, 2, 5});
                cardParams.vert_couplings = containers.Map({'Ground','DC, 1 MOhm','AC, 1 MOhm','DC, 50 Ohm','AC, 50 Ohm'}, ...
                    {0,1,2,3,4});
                cardParams.bandwidths = containers.Map({'no limit','700 MHz','200 MHz','35 MHz','25 MHz','20 MHz'}, ...
                    {0,2,3,5,1,4});
                cardParams.trigChannels = containers.Map({'External','Ch 1', 'Ch 2'}, {-1, 1, 2});
                cardParams.trigCouplings = containers.Map({'DC','AC','DC, 50 Ohm','AC, 50 Ohm'},{0,1,3,4});
                cardParams.trigSlopes = containers.Map({'Rising','Falling'},{0,1});
                cardParams.resyncs = containers.Map({'Resync','No resync'},{1,0});
                cardParams.samplingRates = containers.Map({'1M','2M','2.5M','4M','5M','10M','20M','25M','40M','50M','100M','200M','250M','400M','500M','1G','2G'},{1e6, 2e6, 2.5e6, 4e6, 5e6, 10e6, 20e6, 25e6, 40e6, 50e6, 100e6, 200e6, 250e6, 400e6, 500e6, 1e9, 2e9});
                
                %Update the range text
                set(handles.statictext_vertScale,'String','Full Scale (Vpp)');
            case 'AlazarATS9870'
                cardParams.cardModes = containers.Map({'Digitizer', 'Averager'}, {0, 2});
                cardParams.clockTypes = containers.Map({'Internal','External', 'Ext Ref (10 MHz)'}, {1, 5, 7});
                cardParams.scales = containers.Map({'40m','100m', '200m', '400m', '1', '2', '4'}, {2, 5, 6, 7, 10, 11, 12});
                cardParams.vert_couplings = containers.Map({'AC, 50 Ohm','DC, 50 Ohm'}, {1, 2});
                cardParams.bandwidths = containers.Map({'no limit','20 MHz'}, {0,1});
                cardParams.trigChannels = containers.Map({'External','Ch A', 'Ch B'}, {2, 0, 1});
                cardParams.trigCouplings = containers.Map({'DC','AC'},{2,1});
                cardParams.trigSlopes = containers.Map({'Rising','Falling'},{0,1});
                cardParams.resyncs = containers.Map();
                cardParams.samplingRates = containers.Map({'1M','10M','100M','250M','500M','1G'},{1e6, 10e6, 100e6, 250e6, 500e6, 1e9});
                
                %Update the range text
                set(handles.statictext_vertScale,'String','Full Scale (Vp)');
                
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
            defaults.horizontal.sampleInterval = 1e-9;
            defaults.vertical.vert_scale = '500m';
            defaults.vertical.offset = 0;
            defaults.vertical.vert_coupling = 'DC, 50 Ohm';
            defaults.vertical.bandwidth = 'no limit';
            defaults.trigger.trigger_level = 500;
            defaults.trigger.trigger_ch = 'External';
            defaults.trigger.trigger_coupling = 'DC';
            defaults.trigger.trigger_slope = 'Rising';
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
            vert_couplingsInv = invertMap(cardParams.vert_couplings);
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
            defaults.horizontal.sampleInterval = settings.horizontal.sampleInterval;
            % vertical
            defaults.vertical.vert_scale = scalesInv(settings.vertical.vert_scale);
            defaults.vertical.offset = settings.vertical.offset;
            defaults.vertical.vert_coupling = vert_couplingsInv(settings.vertical.vert_coupling);
            defaults.vertical.bandwidth = bandwidthsInv(settings.vertical.bandwidth);
            % trigger
            defaults.trigger.trigger_level = settings.trigger.trigger_level;
            defaults.trigger.trigger_ch = trigChannelsInv(settings.trigger.trigger_ch);
            defaults.trigger.trigger_coupling = trigCouplingsInv(settings.trigger.trigger_coupling);
            defaults.trigger.trigger_slope = trigSlopesInv(settings.trigger.trigger_slope);
            % averaging
            defaults.averager.recordLength = settings.averager.recordLength;
            defaults.averager.nbrSegments = settings.averager.nbrSegments;
            defaults.averager.nbrWaveforms = settings.averager.nbrWaveforms;
            defaults.averager.nbrRoundRobins = settings.averager.nbrRoundRobins;
            defaults.averager.ditherRange = settings.averager.ditherRange;
            defaults.averager.trigResync = resyncsInv(settings.averager.trigResync);
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
                        if(any(strcmp(name, {'vert_scale', 'bandwidth'})))
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
