function varargout = FrequencySweep(varargin)
%FREQUENCYSWEEP M-file for FrequencySweep.fig
%      FREQUENCYSWEEP, by itself, creates a new FREQUENCYSWEEP or raises the existing
%      singleton*.
%
%      H = FREQUENCYSWEEP returns the handle to a new FREQUENCYSWEEP or the handle to
%      the existing singleton*.
%
%      FREQUENCYSWEEP('Property','Value',...) creates a new FREQUENCYSWEEP using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to FrequencySweep_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      FREQUENCYSWEEP('CALLBACK') and FREQUENCYSWEEP('CALLBACK',hObject,...) call the
%      local function named CALLBACK in FREQUENCYSWEEP.M with the given input
%      arguments.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help FrequencySweep

% Last Modified by GUIDE v2.5 15-Oct-2010 15:02:47

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @FrequencySweep_OpeningFcn, ...
                   'gui_OutputFcn',  @FrequencySweep_OutputFcn, ...
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


% --- Executes just before FrequencySweep is made visible.
function FrequencySweep_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   unrecognized PropertyName/PropertyValue pairs from the
%            command line (see VARARGIN)

% Choose default command line output for FrequencySweep
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes FrequencySweep wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = FrequencySweep_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function startFreq_Callback(hObject, eventdata, handles)
% hObject    handle to startFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of startFreq as text
%        str2double(get(hObject,'String')) returns contents of startFreq as a double


% --- Executes during object creation, after setting all properties.
function startFreq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to startFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function stopFreq_Callback(hObject, eventdata, handles)
% hObject    handle to stopFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of stopFreq as text
%        str2double(get(hObject,'String')) returns contents of stopFreq as a double


% --- Executes during object creation, after setting all properties.
function stopFreq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to stopFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function stepFreq_Callback(hObject, eventdata, handles)
% hObject    handle to stepFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of stepFreq as text
%        str2double(get(hObject,'String')) returns contents of stepFreq as a double


% --- Executes during object creation, after setting all properties.
function stepFreq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to stepFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function power_Callback(hObject, eventdata, handles)
% hObject    handle to power (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of power as text
%        str2double(get(hObject,'String')) returns contents of power as a double


% --- Executes during object creation, after setting all properties.
function power_CreateFcn(hObject, eventdata, handles)
% hObject    handle to power (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in genID.
function genID_Callback(hObject, eventdata, handles)
% hObject    handle to genID (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns genID contents as cell array
%        contents{get(hObject,'Value')} returns selected item from genID


% --- Executes during object creation, after setting all properties.
function genID_CreateFcn(hObject, eventdata, handles)
% hObject    handle to genID (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
