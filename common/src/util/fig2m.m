function varargout = fig2m(guiName,outputDir,syscolorfig,cb_gen)
% FIG2M - Generate programmatic GUI M-File from a FIG-File
%
% Version : 1.0
% Created : 10/05/2006
% Modified: 14/04/2010
% Author  : Thomas Montagnon (The MathWorks France)
%
% >> outputFile = fig2m(guiName,outputDir,syscolorfig,cb_gen);
%
%    guiName     -> Name of the Fig-File (absolute or relative path)
%    outputDir   -> Directory where the generated M-File will be saved
%    syscolorfig -> Use system default background color (true or false)
%    cb_gen      -> Generate callbacks (true or false)
%    outputFile  -> Name of the generated M-File
%
% >> fig2m
%
%    If you call the function with no input arguments it will ask you for the
%    parameters.


% INPUT ARGUMENTS

if nargin < 4
  % Generate callbacks
  answer = questdlg('Do you want to generate the callbacks?','Callbacks','Yes','No','Yes');
  if strcmp(answer,'Yes')
    cb_gen = true;
  else
    cb_gen = false;
  end
end

if nargin < 3
  % Use system default background color
  answer = questdlg('Do you want to use the system default background color?','Background color','Yes','No','Yes');
  if strcmp(answer,'Yes')
    syscolorfig = true;
  else
    syscolorfig = false;
  end
end

if nargin == 1
  
  % Check if guiName is a directory or a file
  if exist(guiName,'dir')
    [guiName,guiPath] = uigetfile(fullfile(guiName,'*.fig'),'Choose a FIG-File');
    if isequal(guiName,0)
      return
    end
    guiName = fullfile(guiPath,guiName);
  end
  
  % Output directory
  outputDir = uigetdir(guiPath,'Choose the output directory');
  if isequal(outputDir,0)
    return
  end
  
end

if nargin == 0
  
  % Fig-File
  [guiName,guiPath] = uigetfile('*.fig','Choose a FIG-File');
  if isequal(guiName,0)
    return
  end
  guiName = fullfile(guiPath,guiName);
  
  % Output directory
  outputDir = uigetdir(guiPath,'Choose the output directory');
  if isequal(outputDir,0)
    return
  end
  
end



if ~exist(guiName,'file')
  error('Bad input argument');
end

% Get info about the FIG-File
[guiPath,guiName,guiExt] = fileparts(guiName);

% Stop the execution of the function if the FIG-File doesn't exist or is invalid
if ~strcmpi(guiExt,'.fig')
  uiwait(errordlg('Invalid GUI file','Error'));
  varargout{1} = '';
  return
end
if ~exist(fullfile(guiPath,[guiName,guiExt]),'file')
  uiwait(errordlg('GUI file not exists','Error'));
  varargout{1} = '';
  return
end

% Output file name
outputFile = [guiName '_build.m'];

% Name of the output file
outFile = fullfile(outputDir,outputFile);

% Graphic objects categories
Categories = {...
  'FIGURE',...
  'CONTEXT MENUS',...
  'MENU ITEMS',...
  'PANELS',...
  'AXES',...
  'LINES',...
  'SURFACES',...
  'STATIC TEXTS',...
  'PUSHBUTTONS',...
  'TOGGLE BUTTONS',...
  'RADIO BUTTONS',...
  'CHECKBOXES',...
  'EDIT TEXTS',...
  'LISTBOXES',...
  'POPUP MENU',...
  'SLIDERS',...
  'UITABLE',...
  'TOOLBAR', ...
  'PUSH TOOLS', ...
  'TOGGLE TOOLS'};

% Default Tags
DefTags = {...
  'figure',...
  'menu',...
  'menuitem',...
  'panel',...
  'axes',...
  'line',...
  'surf',...
  'text',...
  'pushbutton',...
  'togglebutton',...
  'radiobutton',...
  'checkbox',...
  'edit',...
  'listbox',...
  'popupmenu',...
  'slider',...
  'uitable',...
  'uitoolbar', ...
  'uipushtool', ...
  'uitoggletool'};

% Callbacks names
cb_names = { ...
  'Callback', ...
  'ButtonDownFcn', ...
  'CreateFcn', ...
  'DeleteFcn', ...
  'KeyPressFcn', ...
  'KeyReleaseFcn', ...
  'ResizeFcn', ...
  'WindowButtonDownFcn', ...
  'WindowButtonMotionFcn', ...
  'WindowButtonUpFcn', ...
  'WindowScrollWheelFcn', ...
  'SelectionChangeFcn', ...
  'ClickedCallback', ...
  'OffCallback', ...
  'OnCallback', ...
  'CellEditCallback', ...
  'CellSelectionCallback'};

% Default properties values
dprop = default_prop_values();

% Properties for each style of objects
prop = control_properties();

idList = fieldnames(prop);

% Ouput file header
header = sprintf([...
  'function fig_hdl = %s\n' ...
  '%% %s\n' ...
  '%%-------------------------------------------------------------------------------\n' ...
  '%% File name   : %-30s\n' ...
  '%% Generated on: %-30s\n' ...
  '%% Description :\n' ...
  '%%-------------------------------------------------------------------------------\n' ...
  '\n\n'], ...
  outputFile(1:end-2),...
  upper(outputFile(1:end-2)),...
  outputFile,...
  datestr(now));

try

  % Open the GUI
  cdir = pwd;
  cd(guiPath);
  figFcn = str2func(guiName);
  figHdl = figFcn();
  cd(cdir);
%   figHdl = openfig(fullfile(guiPath,[guiName,'.fig']));

pause(.1);

  % Set Window style & CloseRequestFcn for GUI in order to hide the figure
  set(figHdl,'WindowStyle','normal','CloseRequestFcn','closereq','visible','off');
  
  pause(.1);

  % List all the graphic object by category
  list.Fg = figHdl;
  list.Cm = sort(findobj(figHdl,'Type', 'uicontextmenu'));
  list.Mb = sort(findobj(figHdl,'Type', 'uimenu'));
  list.Pa = sort(findobj(figHdl,'Type', 'uipanel'));
  list.Ax = sort(findobj(figHdl,'Type', 'axes'));
  list.Li = sort(findobj(figHdl,'Type', 'line'));
  list.Sf = sort(findobj(figHdl,'Type', 'surface'));
  list.Ta = sort(findobj(figHdl,'Type', 'uitable'));
  list.To = sort(findobj(figHdl,'Type' ,'uitoolbar'));
  list.Pt = sort(findobj(figHdl,'Type' ,'uipushtool'));
  list.Tt = sort(findobj(figHdl,'Type' ,'uitoggletool'));
  list.St = sort(findobj(figHdl,'Style','text'));
  list.Pb = sort(findobj(figHdl,'Style','pushbutton'));
  list.Tb = sort(findobj(figHdl,'Style','togglebutton'));
  list.Rb = sort(findobj(figHdl,'Style','radiobutton'));
  list.Cb = sort(findobj(figHdl,'Style','checkbox'));
  list.Ed = sort(findobj(figHdl,'Style','edit'));
  list.Lb = sort(findobj(figHdl,'Style','listbox'));
  list.Pu = sort(findobj(figHdl,'Style','popupmenu'));
  list.Sl = sort(findobj(figHdl,'Style','slider'));
  
  % Init callback list
  if cb_gen
    cb_list = {};
  end

  % Start writing the output file
  str = sprintf('%s',header);
  
  % Add command to init the handles structure
  str = sprintf('%s%% Initialize handles structure\nhandles = struct();\n\n',str);
  
  % Creat all controls
  str = sprintf('%s%% Create all UI controls\nbuild_gui();\n\n',str);
  
  % Add command line to assign output variable
  str = sprintf('%s%% Assign function output\nfig_hdl = handles.%s;\n\n',...
    str,get(list.Fg,'Tag'));
  
  % Create a nested function to build all uicontrols
  str = sprintf('%s%%%% ---------------------------------------------------------------------------\n',str);
  str = sprintf('%s\tfunction build_gui()\n%% Creation of all uicontrols\n\n',str);

  % Write the generation code for all the objects, grouped by category
  for indCat=1:length(idList)

    % Handles vector and properties list for the current category
    hdlsTemp = list.(idList{indCat});
    propTemp = prop.(idList{indCat});

    % Object creation function depending on the category
    switch idList{indCat}
      case 'Fg'
        ctrlFcn = 'figure';
      case 'Pa'
        ctrlFcn = 'uipanel';
      case 'Ta'
        ctrlFcn = 'uitable';
      case 'Mb'
        ctrlFcn = 'uimenu';
      case 'Cm'
        ctrlFcn = 'uicontextmenu';
      case 'Ax'
        ctrlFcn = 'axes';
      case 'Li'
        ctrlFcn = 'line';
      case 'Sf'
        ctrlFcn = 'surf';
      case 'To'
        ctrlFcn = 'uitoolbar';
      case 'Pt'
        ctrlFcn = 'uipushtool';
      case 'Tt'
        ctrlFcn = 'uitoggletool';
      otherwise
        ctrlFcn = 'uicontrol';
    end

    % If there are objects from the current category then write code
    if ~isempty(hdlsTemp)

      % Category name
      str = sprintf('%s\t\t%% --- %s -------------------------------------\n',str,Categories{indCat});

      % Init index for empty tags
      idxTag = 1;
      
      % Browse all the object belonging to the current category
      for indObj=1:length(hdlsTemp)

        % Get property values for the current object
        listTemp = get(hdlsTemp(indObj));
        
        % If tag is empty then create one
        if isempty(listTemp.Tag)
          listTemp.Tag = sprintf('%s%u',DefTags{indCat},idxTag);
          set(hdlsTemp(indObj),'Tag',listTemp.Tag);
          idxTag = idxTag + 1;
        end

        % Special treatment for UIButtongroup (UIButtongroup are UIPanel with
        % the SelectedObject property): Change creation function name
        if strcmp(idList{indCat},'Pa')
          if isfield(listTemp,'SelectedObject')
            ctrlFcn = 'uibuttongroup';
          end
        end

        % Start object creation code
        % (store all the objects handles in a handles structure)
        str = sprintf('%s\t\thandles.%s = %s( ...\n',str,listTemp.Tag,ctrlFcn);

        % Browse the object properties
        for indProp=1:length(propTemp)

          % For Parent & UIContextMenu properties, value is an object handle
          if strcmp(propTemp{indProp},'Parent') || strcmp(propTemp{indProp},'UIContextMenu')
            if ~isempty(listTemp.(propTemp{indProp}))
              propVal = sprintf('handles.%s',get(listTemp.(propTemp{indProp}),'Tag'));
            else
              propVal = [];
            end
          else
            propVal = listTemp.(propTemp{indProp});
          end
          
          if ~isfield(dprop,propTemp{indProp}) || ~isequal(propVal,dprop.(propTemp{indProp}))

            % Create Property/Value string according to the class of the property
            % value
            switch class(listTemp.(propTemp{indProp}))

              case 'char'
                s = format_char();

              case {'double','single','uint8'}
                s = format_numeric();
                
              case 'cell'
                s = format_cell();
                
              case 'logical'
                s = format_logical();

            end % end of switch

            % Write the code line 'Property','Value',...
            str = sprintf('%s\t\t\t''%s'', %s, ...\n',str,propTemp{indProp},s);

          end % end isequal

        end % Next property
        
        % Callbacks
        if cb_gen
          
          % Extract all property names
          l = fieldnames(listTemp);
          
          % Find defined callback properties
          [iprop,icb] = find(strcmp(repmat(l,1,length(cb_names)),repmat(cb_names,length(l),1))); %#ok<ASGLU>
          
          for indCb=1:length(icb)
            if ~isempty(listTemp.(cb_names{icb(indCb)}))
              cb_list{end+1} = [listTemp.Tag '_' cb_names{icb(indCb)}]; %#ok<AGROW>
              str = sprintf('%s\t\t\t''%s'', %s, ...\n',str,cb_names{icb(indCb)},['@' cb_list{end}]);
            end
          end
          
        end

        % Suppress the 5 last characters (, ...) and finish the creation command
        str(end-5:end) = '';
        str = sprintf('%s);\n\n',str);

      end % Next object

    end % End if ~isempty(hdlsTemp)

  end % Next object category
  
  % Close the build_gui nested function
  str = sprintf('%s\n\tend\n\n',str);
  
  % Add callback functions
  if cb_gen
    for indCb=1:length(cb_list)
      str = sprintf('%s%%%% ---------------------------------------------------------------------------\n',str);
      str = sprintf('%s\tfunction %s(hObject,evendata) %%#ok<INUSD>\n\n',str,cb_list{indCb});
      str = sprintf('%s\tend\n\n',str);
    end
  end
  
  % Close main function
  str = sprintf('%send\n',str);

  % Close the figure
  close(figHdl);

  % Write the output file
  fid = fopen(outFile,'w');
  fprintf(fid,'%s',str);
  fclose(fid);
  
  % Open the generated M-File in the editor
  edit(outFile);

  % Return the name of the output file
  varargout{1} = outFile;

catch ME
  varargout{1} = outFile;
  try %#ok<TRYNC>
    close(figHdl);
  end
  disp(listTemp.Tag);
  disp(ME.message);
end


  function s = format_cell()
    
    % Cell arrays (Create a single string with each cell separated by
    % a | character)
    
    if strcmpi(propTemp{indProp},'ColumnFormat') && all(cellfun(@isempty,propVal))
      s = ['{' repmat('''char'' ',size(propVal)) '}'];
      
    elseif strcmpi(propTemp{indProp},'ColumnFormat')
      s = sprintf('''%s'',',propVal{:});
      s = ['{' strrep(s(1:end-1),'''''','[]') '}']; % Handles the case of automatic column format
      
    elseif strcmpi(propTemp{indProp},'ColumnWidth')
      s = propVal;
      s(cellfun(@isstr,s))     = cellfun(@(string) ['''' string ''''],s(cellfun(@isstr,s)),'UniformOutput',false);
      s(cellfun(@isnumeric,s)) = cellfun(@num2str,s(cellfun(@isnumeric,s)),'UniformOutput',false);
      s = sprintf('%s,',s{:});
      s = ['{' s(1:end-1) '}'];
      
    elseif strcmpi(propTemp{indProp},'Data')
      ft = struct('char','''%s'',','logical','logical(%d),','double','%f,');
      classes = cellfun(@class,propVal(1,:),'UniformOutput',false);
      s = cellfun(@(s) ft.(s),classes,'UniformOutput',false);
      fmt = [s{:}];
      fmt = [fmt(1:end-1) ';'];
      propVal = propVal';
      s = sprintf(fmt,propVal{:});
      s = strrep(s,'logical(0)','false');
      s = strrep(s,'logical(1)','true');
      s = ['{' s(1:end-1) '}'];
      
    else
      s = sprintf('''%s'',',propVal{:});
      s = ['{' s(1:end-1) '}'];
    end
    
  end

  function s = format_numeric()
    % Numeric (Convert numerical value into string)
    
    
    if syscolorfig && strcmpi(idList{indCat},'Fg') && strcmpi(propTemp{indProp},'Color')
      % When using the system default background colors then override the
      % property value
      s = 'get(0,''DefaultUicontrolBackgroundColor'')';
      
    elseif any(strcmpi(propTemp{indProp},{'BackgroundColor','ForegroundColor','Color'}))
      % Limit to 3 digits for all colors vectors/matrices
      s = mat2str(propVal,3);
      
    elseif any(strcmpi(propTemp{indProp},{'Parent','UIContextMenu'}))
      % Simply output the handles.<tag> characters string when the property is
      % either Parent or UIContextMenu
      s = sprintf('%s',propVal);
      
    else
      if length(size(propVal)) > 2
        matLin = propVal(:);
        s = sprintf(',%u',size(propVal));
        s = sprintf('reshape(%s%s)',mat2str(matLin),s);
      else
        s = mat2str(propVal);
      end
      
    end
    
  end

  function s = format_char()
    % Characters
    
    if size(propVal,1) > 1
      % For character arrays that have more than 1 line
      s = 'sprintf(''';
      for j=1:size(propVal,1)
        s = sprintf('%s\t\t%s\\n',s,strrep(propVal(j,:),'''',''''''));
      end
      s = [s ''')'];
      
    elseif ~isempty(findstr(propVal,char(13)))
      % For character arrays that contain new line character
      s = sprintf('sprintf(''%s'')',strrep(strrep(strrep(propVal,char(13),'\n'),char(10),''),'''',''''''));
      
    else
      % For character arrays that have a single line and no new line
      s = sprintf('''%s''',strrep(propVal,'''',''''''));
      
    end
    
  end

  function s = format_logical()
    % Format logical property values
    
    trueFalse = {'false,','true,'};
    s = trueFalse(propVal+1);
    s = [s{:}];
    s = ['[' s(1:end-1) ']'];
    
  end

end


%-------------------------------------------------------------------------------
function cprop = control_properties()

% Common objects properties
prop.Def   = {'Parent','Tag','UserData','Visible'};
prop.Font  = {'FontAngle','FontName','FontSize','FontUnits','FontWeight'};
prop.Color = {'ForegroundColor','BackgroundColor'};
prop.Pos   = {'Units','Position'};
prop.Str   = {'String','TooltipString'};

% Properties for each style of objects
cprop.Fg = [{'Tag'}, prop.Pos, {'Name','MenuBar','NumberTitle','Color','Resize','UIContextMenu'}];
cprop.Cm = [prop.Def];
cprop.Mb = [prop.Def, {'Label','Checked','Enable','ForegroundColor'}];
cprop.Pa = [prop.Def, prop.Pos, prop.Font, prop.Color, {'Title','TitlePosition','BorderType','BorderWidth','HighlightColor','ShadowColor','UIContextMenu'}];
cprop.Ax = [prop.Def, prop.Pos, {'UIContextMenu'}];
cprop.Li = {'BeingDeleted','BusyAction','ButtonDownFcn','Color','CreateFcn','DeleteFcn','DisplayName','EraseMode','HandleVisibility','HitTest','Interruptible','LineStyle','LineWidth','Marker','MarkerEdgeColor','MarkerFaceColor','MarkerSize','Parent','Selected','SelectionHighlight','Tag','UIContextMenu','UserData','Visible','XData','YData','ZData'};
cprop.Sf = {'AlphaData','AlphaDataMapping','CData','CDataMapping','DisplayName','EdgeAlpha','EdgeColor','EraseMode','FaceAlpha','FaceColor','LineStyle','LineWidth','Marker','MarkerEdgeColor','MarkerFaceColor','MarkerSize','MeshStyle','XData','YData','ZData','FaceLighting','EdgeLighting','BackFaceLighting','AmbientStrength','DiffuseStrength','SpecularStrength','SpecularExponent','SpecularColorReflectance','VertexNormals','NormalMode','ButtonDownFcn','Selected','SelectionHighlight','Tag','UIContextMenu','UserData','Visible','Parent','XDataMode','XDataSource','YDataMode','YDataSource','CDataMode','CDataSource','ZDataSource'};
cprop.St = [prop.Def, {'Style'}, prop.Pos, prop.Font, prop.Color, prop.Str, {'Enable','HorizontalAlignment'}];
cprop.Pb = [prop.Def, {'Style'}, prop.Pos, prop.Font, prop.Color, prop.Str, {'Enable','UIContextMenu','CData'}];
cprop.Tb = [prop.Def, {'Style'}, prop.Pos, prop.Font, prop.Color, prop.Str, {'Enable','UIContextMenu','CData'}];
cprop.Rb = [prop.Def, {'Style'}, prop.Pos, prop.Font, prop.Color, prop.Str, {'Enable','UIContextMenu'}];
cprop.Cb = [prop.Def, {'Style'}, prop.Pos, prop.Font, prop.Color, prop.Str, {'Enable','UIContextMenu'}];
cprop.Ed = [prop.Def, {'Style'}, prop.Pos, prop.Font, prop.Color, prop.Str, {'Enable','UIContextMenu','HorizontalAlignment','Min','Max'}];
cprop.Lb = [prop.Def, {'Style'}, prop.Pos, prop.Font, prop.Color, prop.Str, {'Enable','UIContextMenu','Min','Max'}];
cprop.Pu = [prop.Def, {'Style'}, prop.Pos, prop.Font, prop.Color, prop.Str, {'Enable','UIContextMenu'}];
cprop.Sl = [prop.Def, {'Style'}, prop.Pos, prop.Font, prop.Color, prop.Str, {'Enable','UIContextMenu','Min','Max','SliderStep'}];
cprop.Ta = [prop.Def, prop.Pos, prop.Font, prop.Color, {'ColumnEditable','ColumnFormat','ColumnName','ColumnWidth','Data','Enable','RearrangeableColumns','RowName','RowStriping','TooltipString','UIContextMenu'}];
cprop.To = [prop.Def];
cprop.Pt = [prop.Def, {'TooltipString','CData','Enable','Separator'}];
cprop.Tt = [prop.Def, {'TooltipString','CData','Enable','Separator','State'}];
end


%-------------------------------------------------------------------------------
function dprop = default_prop_values()

dprop = struct( ...
  'MenuBar'             , 'figure', ...
  'NumberTitle'         , 'on', ...
  'Resize'              , 'off', ...
  'UIContextMenu'       , [], ...
  'FontAngle'           , 'normal', ...
  'FontName'            , 'MS Sans Serif', ...
  'FontSize'            , 8, ...
  'FontUnits'           , 'points', ...
  'FontWeight'          , 'normal', ...
  'ForegroundColor'     , [0 0 0], ...
  'BackgroundColor'     , get(0,'DefaultUicontrolBackgroundColor'), ...
  'TitlePosition'       , 'lefttop', ...
  'BorderType'          , 'etchedin', ...
  'BorderWidth'         , 1, ...
  'HighlightColor'      , [1 1 1], ...
  'ShadowColor'         , [0.5 0.5 0.5], ...
  'HorizontalAlignment' , 'center', ...
  'TooltipString'       , '', ...
  'CData'               , [], ...
  'Enable'              , 'on', ...
  'SliderStep'          , [.01 .1], ...
  'Min'                 , 0, ...
  'Max'                 , 1, ...
  'UserData'            , [], ...
  'BeingDeleted'        , 'off', ...
  'BusyAction'          , 'queue', ...
  'ColumnEditable'      , [], ...
  'ColumnFormat'        , [], ...
  'ColumnName'          , 'numbered', ...
  'ColumnWidth'         , 'auto', ...
  'Data'                , {cell(4,2)}, ...
  'RearrangeableColumns', 'off', ...
  'RowName'             , 'numbered', ...
  'RowStriping'         , 'on', ...
  'Visible'             , 'on', ...
  'String'              , '', ...
  'Separator'           , 'off', ...
  'State'               , 'off');
end

