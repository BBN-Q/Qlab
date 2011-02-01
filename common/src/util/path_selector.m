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

function value_fcn = path_selector(parent, position)

    filename = '';
    pathname = '';

    height = position(4);
    width = position(3);
    labelPosition = position + [0 2*height-5 0 0];
    editboxPosition = position + [0 height 0 0];
    buttonPosition = position;
    buttonPosition(1) = position(1) + (width-75);
    buttonPosition(3) = 75;

    uicontrol( ...
            'Parent', parent, ...
            'Style', 'text', ...
            'Units', 'pixels', ...
            'Position', labelPosition, ...
            'FontName', 'Helvetica', ...
            'FontSize', 10, ...
            'String', 'File name');
        
     editbox = uicontrol( ...
            'Parent', parent, ...
            'Style', 'edit', ...
			'BackgroundColor', 'white', ...
            'Units', 'pixels', ...
            'Position', editboxPosition, ...
            'FontName', 'Helvetica', ...
            'FontSize', 10, ...
            'String', '');
        
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
        
    function [fname, pname] = get_path()
        fullname = get(editbox, 'String');
        [path name ext] = fileparts(fullname);
        fname = [name ext];
        pname = path;
    end

    function choose_callback(hObject, eventData)
        % if there is already a path in the box, change to that directory
        % first
        [tmp pname] = get_path();
        if ~strcmp(pname, '')
            savedir = pwd;
            cd(pname);
            [filename, pathname] = uiputfile();
            cd(savedir); % go back to the former path
        else
            [filename, pathname] = uiputfile();
        end
        set(editbox, 'String', [pathname filename]);
    end
    
end