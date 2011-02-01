function varargout = PowerSweep(varargin)
%POWERSWEEP M-file for PowerSweep.fig
%      POWERSWEEP, by itself, creates a new POWERSWEEP or raises the existing
%      singleton*.
%
%      H = POWERSWEEP returns the handle to a new POWERSWEEP or the handle to
%      the existing singleton*.
%
%      POWERSWEEP('Property','Value',...) creates a new POWERSWEEP using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to PowerSweep_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      POWERSWEEP('CALLBACK') and POWERSWEEP('CALLBACK',hObject,...) call the
%      local function named CALLBACK in POWERSWEEP.M with the given input
%      arguments.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help PowerSweep

% Last Modified by GUIDE v2.5 15-Oct-2010 15:06:20

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @PowerSweep_OpeningFcn, ...
                   'gui_OutputFcn',  @PowerSweep_OutputFcn, ...
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


% --- Executes just before PowerSweep is made visible.
function PowerSweep_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   unrecognized PropertyName/PropertyValue pairs from the
%            command line (see VARARGIN)

% Choose default command line output for PowerSweep
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes PowerSweep wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = PowerSweep_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function powStart_Callback(hObject, eventdata, handles)
% hObject    handle to powStart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of powStart as text
%        str2double(get(hObject,'String')) returns contents of powStart as a double


% --- Executes during object creation, after setting all properties.
function powStart_CreateFcn(hObject, eventdata, handles)
% hObject    handle to powStart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function powStop_Callback(hObject, eventdata, handles)
% hObject    handle to powStop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of powStop as text
%        str2double(get(hObject,'String')) returns contents of powStop as a double


% --- Executes during object creation, after setting all properties.
function powStop_CreateFcn(hObject, eventdata, handles)
% hObject    handle to powStop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function powStep_Callback(hObject, eventdata, handles)
% hObject    handle to powStep (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of powStep as text
%        str2double(get(hObject,'String')) returns contents of powStep as a double


% --- Executes during object creation, after setting all properties.
function powStep_CreateFcn(hObject, eventdata, handles)
% hObject    handle to powStep (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in genIDpow.
function genIDpow_Callback(hObject, eventdata, handles)
% hObject    handle to genIDpow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns genIDpow contents as cell array
%        contents{get(hObject,'Value')} returns selected item from genIDpow


% --- Executes during object creation, after setting all properties.
function genIDpow_CreateFcn(hObject, eventdata, handles)
% hObject    handle to genIDpow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in powerUnits.
function powerUnits_Callback(hObject, eventdata, handles)
% hObject    handle to powerUnits (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns powerUnits contents as cell array
%        contents{get(hObject,'Value')} returns selected item from powerUnits


% --- Executes during object creation, after setting all properties.
function powerUnits_CreateFcn(hObject, eventdata, handles)
% hObject    handle to powerUnits (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
