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
%
% File: path_and_file_controls.m
%
% Description: Creates the GUI inputs for data path, counter and basename
% inputs

function value_fcn = path_and_file_controls(parent, position, commonSettings, prevSettings)
    % FUNCTION path_and_file_controls
    % inputs:
    % parent - handle of parent window/figure
    % position - position vector of the form [left bottom]
    % commonSettings - common settings struct (will get initial counter and
    % deviceName values from here)
    % prevSettings - previous settings struct (will get initial exptName
    % value from here)
    % returns:
    % value_fcn which outputs [data_path counter deviceName exptName]
    
    % add file path selector
    data_path = '';
    if isfield(commonSettings, 'data_path')
        data_path = commonSettings.data_path;
    end
    get_path = path_selector(parent, position, data_path);

    % add file counter
    % use a GLOBAL counter to make it available and consistent across GUIs
    % if it isn't loaded already, grab the current value from common cfg
    global counter;
    if ~isa(counter, 'Counter')
        initial_counter_value = 1;
        if isfield(commonSettings, 'counter')
            initial_counter_value = commonSettings.counter;
        end
        counter = Counter(initial_counter_value);
    end
    position = position - [0 55]; % counter is down by gutter (10) + label height (20) + box height(25)
    file_counter(parent, position, counter);

    % add basename input
    deviceName = '';
    exptName = '';
    if isfield(commonSettings, 'deviceName')
        deviceName = commonSettings.deviceName;
    end
    if isfield(prevSettings, 'exptName')
        exptName = prevSettings.exptName;
    end
    position = position + [120 0]; % basename fields over by counter width (110) + gutter
    get_basename = basename_input(parent, position, deviceName, exptName);
    
    value_fcn = @get_inputs;
    
    function [data_path, counter_obj, deviceName, exptName] = get_inputs()
        data_path = get_path();
        counter_obj = counter;
        [deviceName, exptName] = get_basename();
    end
    
end