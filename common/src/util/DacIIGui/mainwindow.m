%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Module Name : mainwindow
%
% Author/Date : B.C. Donovan / 21-Oct-08
%
% Description : mainwindow callbacks for 
%               DAC II Ccommand GUI
%             
%
% Restrictions/Limitations :
%
%    Requires mainwindow.fig. mainwindow.fig may be edited
%    with guide
%
% Change Descriptions :
%
% Classification : Unclassified
%
% References :
%
%
%    Modified    By    Reason
%    --------    --    ------
%                BCD
%
% CVS header info.
% ----------------
% $CVSfile$
% $Author: bdonovan $
% $Date: 2008/12/03 15:47:57 $
% $Locker:  $
% $Name:  $
% $Revision: 103 $
%
% $Log: mainwindow.m,v $
% Revision 1.6  2008/12/03 15:47:57  bdonovan
% Added support for multiple DAC boxes to libdacii. Updated dacii.m for new api.
%
% Revision 1.2  2008/10/23 20:41:35  bdonovan
% First version of CMD Builder GUI that uses C dll to communicate with DACII board.
%
% C library to communicate with board is in ./lib.
%
% Matlab code has been reorganized into classes. GUI is not edited with the guide command
% in matlab.
%
% Independent triggering of each of the 4 DACs has been confirmed for both software
%  and hardware triggering with cbl_dac2_r3beta.bit
%
%
% Copyright (C) BBN Technologies Corp. 2008 - 2011
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function varargout = mainwindow(varargin)
% dispatch if there are arguments
if nargin && ischar(varargin{1})
    callback = str2func(varargin{1});
    callback(varargin{2:end});
else
    gui = DacIIGui();
    feval(@mainwindow_OpeningFcn, gui, [], guihandles(gui), varargin{:});
end

% --- Executes just before mainwindow is made visible.
function mainwindow_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mainwindow (see VARARGIN)

% Choose default command line output for mainwindow
handles.output = hObject;

handles.guifunctions = guifunctions(handles);
numdevices = handles.guifunctions.dac.num_devices;
if (numdevices == 0)
    s = ['Not Found'];
else
    s = '[';
    for i = 0: (numdevices - 1)
        s = [ s num2str(i) ';'];
    end
    s = [s ']'];
    s = eval(s);
end

set(handles.pm_usb_ids,'String',s);
set(handles.pm_usb_ids,'Value',1);

if (numdevices ~= 0)
    handles.guifunctions.open_dac(1, handles.txt_bit_file_version);
end

% Update handles structure
guidata(hObject, handles);


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
if isfield(handles,'guifunctions')
    % gui functions may not have been set if there was an
    % error during figure load - usually only a problem
    % during development
    handles.guifunctions.close();
end
delete(hObject);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Open / Save Config Callbacks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in pb_save_config.
function pb_save_config_Callback(hObject, eventdata, handles)
[n,p] = uiputfile({'*.mat','Matlab files (*.mat)'}, 'Save Config');
handles.guifunctions.save([p n])

% --- Executes on button press in pb_open_config.
function pb_open_config_Callback(hObject, eventdata, handles)
[n,p] = uigetfile({'*.mat','Matlab Files (*.mat)'}, 'Load Config');
handles.guifunctions.load([p n]);
% load values into controls
handles.guifunctions.set_bit_file_controls(handles)
handles.guifunctions.set_waveform_controls(handles)

function id = getDacID(hObject)
tag = get(hObject,'tag');
id = str2num(tag(end));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Open Mat Files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function pb_open_mat_file_Callback(hObject, eventdata, handles)
id = getDacID(hObject);
txtHandle = sprintf('txt_wf_file_%i',id);
handles.guifunctions.open_mat_file(handles.(txtHandle),id);
handles.guifunctions.set_waveform_buttons_enable(handles,id,'On');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Waveform File Txtboxes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function txt_wf_file_Callback(hObject, eventdata, handles)
id = getDacID(hObject);
file_name = get(hObject,'String');
handles.guifunctions.waveforms(id+1).file_name = file_name;
handles.guifunctions.set_waveform_buttons_enable(handles,id,'On');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Trigger Types
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function pm_wf_trigger_Callback(hObject, eventdata, handles)
id = getDacID(hObject);
handles.guifunctions.set_wf_trigger_type(id,get(hObject,'Value'));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Scale Factors 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function txt_wf_scale_factor_Callback(hObject, eventdata, handles)
id = getDacID(hObject);
handles.guifunctions.set_wf_scale_factor(id,hObject);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Sample Rates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function pm_wf_sample_rate_Callback(hObject, eventdata, handles)
paired = [1 0 3 2];
val = get(hObject,'Value');
id = getDacID(hObject);
handles.guifunctions.set_wf_sample_rate(id,val);
txtHandle = sprintf('pm_wf_sample_rate_%i', paired(id+1));
set(handles.(txtHandle),'Value', val);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Offset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function txt_wf_offset_Callback(hObject, eventdata, handles)
id = getDacID(hObject);
handles.guifunctions.set_wf_offset(id,hObject)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot Waveform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Plot waveform file by calling plot method of waveform object
% Note that gui is index by 0 to match FPGA index but must index
% waveforms array by 1

% --- Executes on button press in pb_plot_wf_0.
function pb_plot_wf_Callback(hObject, eventdata, handles)
id = getDacID(hObject);
handles.guifunctions.waveforms(id+1).plot()

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load Waveform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in pb_load_wf_0.
function pb_load_wf_Callback(hObject, eventdata, handles)
id = getDacID(hObject);
handles.guifunctions.load_waveform(id, handles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Trigger Waveform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in pb_trigger_wf_0.
function pb_trigger_wf_Callback(hObject, eventdata, handles)
id = getDacID(hObject);
handles.guifunctions.trigger_waveform(id,handles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Pause Waveform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in pb_pause_wf_0.
function pb_pause_wf_Callback(hObject, eventdata, handles)
id = getDacID(hObject);
handles.guifunctions.pause_waveform(id,handles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Disable Waveform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in pb_disable_wf_0.
function pb_disable_wf_Callback(hObject, eventdata, handles)
id = getDacID(hObject);
handles.guifunctions.disable_waveform(id,handles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function txt_bit_file_name_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of txt_bit_file_name as
% text
file_name = get(hObject,'String');
handles.guifunctions.bit_file_name = file_name;
handles.guifunctions.set_waveform_buttons_enable(handles,0,'On');

function txt_bit_file_version_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of txt_bit_file_version as
% text

% --- Executes on button press in pb_open_bit_file.
function pb_open_bit_file_Callback(hObject, eventdata, handles)
handles.guifunctions.open_bit_file(handles.txt_bit_file_name);
set(handles.pb_load_bit_file,'Enable', 'on');

% --- Executes on button press in pb_load_bit_file.
function pb_load_bit_file_Callback(hObject, eventdata, handles)
handles.guifunctions.load_bit_file(handles.txt_bit_file_version);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Simultaneous Checkboxes (With DAC?)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in cb_simultaneous_0.
function cb_simultaneous_Callback(hObject, eventdata, handles)
id = getDacID(hObject);
paired = [1 0 3 2];
pair = paired(id+1);
val = get(hObject, 'Value');
txtHandle = sprintf('cb_simultaneous_%i',pair);
set(handles.(txtHandle),'Value', val);
% set both DACs to software trigger
handles.guifunctions.set_wf_trigger_type(id,1);
txtHandle = sprintf('pm_wf_trigger_%i',id);
set(handles.(txtHandle), 'Value',1);
handles.guifunctions.set_wf_trigger_type(pair,1);
txtHandle = sprintf('pm_wf_trigger_%i',pair);
set(handles.pm_wf_trigger_1, 'Value',1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% * All Callbacks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in pb_load_all.
function pb_load_all_Callback(hObject, eventdata, handles)
for i = 0:3
    handles.guifunctions.load_waveform(i,handles)
end
set( handles.pb_trigger_all, 'Enable', 'On');
set( handles.pb_pause_all,   'Enable', 'Off');
set( handles.pb_disable_all, 'Enable', 'Off');

% --- Executes on button press in pb_trigger_all.
function pb_trigger_all_Callback(hObject, eventdata, handles)
for i = 0:3
    handles.guifunctions.trigger_waveform(i,handles)
end
set( handles.pb_trigger_all, 'Enable', 'Off');
set( handles.pb_pause_all,   'Enable', 'On');
set( handles.pb_disable_all, 'Enable', 'On');

% --- Executes on button press in pb_pause_all.
function pb_pause_all_Callback(hObject, eventdata, handles)
for i = 0:3
    handles.guifunctions.pause_waveform(i,handles)
end
set( handles.pb_trigger_all, 'Enable', 'On');
set( handles.pb_pause_all,   'Enable', 'Off');
set( handles.pb_disable_all, 'Enable', 'On');

% --- Executes on button press in pb_disable_all.
function pb_disable_all_Callback(hObject, eventdata, handles)
for i = 0:3
    handles.guifunctions.disable_waveform(i,handles)
end
set( handles.pb_trigger_all, 'Enable', 'On');
set( handles.pb_pause_all,   'Enable', 'Off');
set( handles.pb_disable_all, 'Enable', 'Off');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% * Misc Callbacks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on selection change in pm_usb_ids.
function pm_usb_ids_Callback(hObject, eventdata, handles)
% Hints: contents = get(hObject,'String') returns pm_usb_ids contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pm_usb_ids
handles.guifunctions.open_dac(get(hObject,'Value'), handles.txt_bit_file_version);

% --- Executes on slider movement.
function sl_msg_Callback(hObject, eventdata, handles)
val = fix(get(hObject,'Value'));
handles.guifunctions.message_manager.update_controls(val);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Link List Enable Callbacks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function cb_ll_enable_Callback(hObject, eventdata, handles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Link List DC Mode Callbacks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in cb_ll_dc_0.
function cb_ll_dc_Callback(hObject, eventdata, handles)

