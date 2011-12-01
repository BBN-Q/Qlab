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
% File: path_selector.m
%
% Description: A GUI control for choosing a file path

function value_fcn = path_selector(parent, position, pathname)
    % FUNCTION path_selector
    % INPUTS:
    % parent - handle of parent window/figure
    % position - position vector of the form [left bottom]
    % OUTPUTS:
    % value_fcn - a function which returns the current selected filename
    % and path

    if ~ischar(pathname)
        pathname = '';
    end

    height = 25;
    width = 250;
    buttonWidth = 75;
    position = [position width height]; % create 4-element position vector
    labelPosition = position + [0 2*height-5 0 0];
    editboxPosition = position + [0 height 0 0];
    
    % right align the button with the edit box
    buttonPosition = position;
    buttonPosition(1) = position(1) + (width-buttonWidth);
    buttonPosition(3) = buttonWidth;

    uicontrol( ...
            'Parent', parent, ...
            'Style', 'text', ...
            'Units', 'pixels', ...
            'Position', labelPosition, ...
            'FontName', 'Helvetica', ...
            'FontSize', 10, ...
            'String', 'Data path');
        
     editbox = uicontrol( ...
            'Parent', parent, ...
            'Style', 'edit', ...
			'BackgroundColor', 'white', ...
            'Units', 'pixels', ...
            'Position', editboxPosition, ...
            'FontName', 'Helvetica', ...
            'FontSize', 10, ...
            'String', pathname);
        
     uicontrol( ...
            'Parent', parent, ...
            'Style', 'pushbutton', ...
            'Units', 'pixels', ...
            'Position', buttonPosition, ...
            'FontName', 'Helvetica', ...
            'FontSize', 10, ...
            'String', 'Choose', ...
            'Callback', {@choose_callback});
        
    value_fcn = @get_path;
        
    function pname = get_path()
        pname = get(editbox, 'String');
    end

    function choose_callback(hObject, eventData)
        % if there is already a path in the box, change to that directory
        % first
        pathname = uigetdir(get_path());
        if pathname ~= 0
            set(editbox, 'String', pathname);
        end
    end
    
end