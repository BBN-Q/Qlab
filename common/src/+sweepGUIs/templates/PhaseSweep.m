function varargout = PhaseSweep(varargin)
%PHASESWEEP M-file for PhaseSweep.fig
%      PHASESWEEP, by itself, creates a new PHASESWEEP or raises the existing
%      singleton*.
%
%      H = PHASESWEEP returns the handle to a new PHASESWEEP or the handle to
%      the existing singleton*.
%
%      PHASESWEEP('Property','Value',...) creates a new PHASESWEEP using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to PhaseSweep_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      PHASESWEEP('CALLBACK') and PHASESWEEP('CALLBACK',hObject,...) call the
%      local function named CALLBACK in PHASESWEEP.M with the given input
%      arguments.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help PhaseSweep

% Last Modified by GUIDE v2.5 15-Oct-2010 15:05:52

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @PhaseSweep_OpeningFcn, ...
                   'gui_OutputFcn',  @PhaseSweep_OutputFcn, ...
                   'gui_LayoutFcn',  [], ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
   gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before PhaseSweep is made visible.
function PhaseSweep_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   unrecognized PropertyName/PropertyValue pairs from the
%            command line (see VARARGIN)

% Choose default command line output for PhaseSweep
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes PhaseSweep wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = PhaseSweep_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function phaseStart_Callback(hObject, eventdata, handles)
% hObject    handle to phaseStart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of phaseStart as text
%        str2double(get(hObject,'String')) returns contents of phaseStart as a double


% --- Executes during object creation, after setting all properties.
function phaseStart_CreateFcn(hObject, eventdata, handles)
% hObject    handle to phaseStart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function phaseStop_Callback(hObject, eventdata, handles)
% hObject    handle to phaseStop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of phaseStop as text
%        str2double(get(hObject,'String')) returns contents of phaseStop as a double


% --- Executes during object creation, after setting all properties.
function phaseStop_CreateFcn(hObject, eventdata, handles)
% hObject    handle to phaseStop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function phaseStep_Callback(hObject, eventdata, handles)
% hObject    handle to phaseStep (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of phaseStep as text
%        str2double(get(hObject,'String')) returns contents of phaseStep as a double


% --- Executes during object creation, after setting all properties.
function phaseStep_CreateFcn(hObject, eventdata, handles)
% hObject    handle to phaseStep (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in genIDphase.
function genIDphase_Callback(hObject, eventdata, handles)
% hObject    handle to genIDphase (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns genIDphase contents as cell array
%        contents{get(hObject,'Value')} returns selected item from genIDphase


% --- Executes during object creation, after setting all properties.
function genIDphase_CreateFcn(hObject, eventdata, handles)
% hObject    handle to genIDphase (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
